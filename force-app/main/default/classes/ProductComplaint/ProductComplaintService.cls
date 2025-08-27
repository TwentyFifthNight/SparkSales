public with sharing class ProductComplaintService {
    public static List<Product2> getProducts(String orderId) {
        List<OrderItem> orderProducts = [SELECT Product2Id FROM OrderItem WHERE OrderId = :orderId];
        List<Id> productIds = new List<Id>();
        for (OrderItem orderProduct : orderProducts) {
            productIds.add(orderProduct.Product2Id);
        }
        
        return [SELECT Name, ProductCode, Family, IsExternal__c FROM Product2 WHERE Id IN :productIds];
    }

    public static ProductComplaintController.ComplaintResult submitComplaints(List<Id> productIds, String orderId) {
        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Id, IsExternal__c, ExternalId__c
            FROM Product2
            WHERE Id IN :productIds
        ]);

        Map<Id, OrderItem> orderItems = new Map<Id, OrderItem>([
            SELECT Id, Product2Id, Quantity, UnitPrice
            FROM OrderItem
            WHERE OrderId = :orderId AND Product2Id IN :productIds AND UnitPrice > 0
        ]);

        ExternalEventBody eventBody = new ExternalEventBody();
        eventBody.externalIds = new List<Id>();
        eventBody.quantities = new List<Decimal>();
        eventBody.prices = new List<Decimal>();
        for (OrderItem orderItem : orderItems.values()) {
            Product2 product = products.get(orderItem.Product2Id);
            if (product.IsExternal__c) {
                eventBody.externalIds.add(product.ExternalId__c);
                eventBody.quantities.add(orderItem.Quantity);
                eventBody.prices.add(orderItem.UnitPrice);
            }
        }

        Id caseId = createApprovalProcesses(orderItems, products, orderId);
        eventBody.trackingId = caseId;

        ProductComplaintController.ComplaintResult result = new ProductComplaintController.ComplaintResult();
        result.status = 'PENDING';
        result.trackingId = caseId;

        if (!eventBody.externalIds.isEmpty()) {
            try {
                sendExternalEvent(eventBody);
            } catch (Exception e) {
                throw newAuraException(System.Label.externalComplaintSendingError);
            }
        } else {
            result.status = 'SUCCESS';
        }

        return result;
    }

    private static Id createApprovalProcesses(Map<Id, OrderItem> orderProducts, Map<Id, Product2> products, String orderId) {
        List<ComplaintItem__c> existingComplaintItems = [
            SELECT Id
            FROM ComplaintItem__c
            WHERE OrderProduct__c IN :orderProducts.keySet()
        ];
        if (!existingComplaintItems.isEmpty()) {
            throw newAuraException(System.Label.duplicateComplaintError);
        }

        Case newCase = new Case(
            Subject = 'Product complaint',
            Status = Constants.CaseConstants.Status.NEW_STATUS,
            Origin = Constants.CaseConstants.Origin.INTERNAL,
            Order__c = orderId
        );
        insert newCase;
        
        List<ComplaintItem__c> complaintItems = new List<ComplaintItem__c>();
        for (OrderItem orderProduct : orderProducts.values()) {
            ComplaintItem__c newComplaintItem = new ComplaintItem__c(
                Product__c = orderProduct.Product2Id,
                Case__c = newCase.Id,
                Order__c = orderId,
                IsExternalProduct__c = products.get(orderProduct.Product2Id).IsExternal__c,
                OrderProduct__c = orderProduct.Id,
                Quantity__c = orderProduct.Quantity,
                UnitPrice__c = orderProduct.UnitPrice
            );
            complaintItems.add(newComplaintItem);
        }
        insert complaintItems;

        List<ComplaintItem__c> internalComplaintItems = new List<ComplaintItem__c>();
        for (ComplaintItem__c complaintItem : complaintItems) {
            if (!complaintItem.IsExternalProduct__c) {
                internalComplaintItems.add(complaintItem);
            }
        }

        for (ComplaintItem__c complaintItem : internalComplaintItems) {
            Map<String, String> params = new Map<String, String>();
            params.put('recordId', complaintItem.Id);
            params.put('submitter', UserInfo.getUserId());
            Flow.Interview.Order_Item_Complaint flow = new Flow.Interview.Order_Item_Complaint(params);
            try {
                flow.start();
            } catch (Exception ex) {
                throw newAuraException(System.Label.approvalProcessCreationError);
            }
        }

        return newCase.Id;
    }

    private static void sendExternalEvent(ExternalEventBody eventBody) {
        System.enqueueJob(new AsyncSendExternalEvent(eventBody));
    }

    public class AsyncSendExternalEvent implements Queueable, Database.AllowsCallouts {
        private ExternalEventBody eventBody;

        public AsyncSendExternalEvent(ExternalEventBody eventBody) {
            this.eventBody = eventBody;
        }

        public void execute(QueueableContext context) {
            Map<String, String> event = new Map<String, String>();
            event.put('CaseId__c', eventBody.trackingId);
            event.put('ProductIds__c', JSON.serialize(eventBody.externalIds));
            event.put('Quantities__c', JSON.serialize(eventBody.quantities));
            event.put('Prices__c', JSON.serialize(eventBody.prices));

            HttpRequest req = new HttpRequest();
            req.setEndpoint(Constants.EXTERNAL_COMPLAINT_EVENT_API_ENDPOINT);
            req.setMethod(Constants.RestAPI.Method.POST);
            req.setHeader('Content-Type', 'application/json');

            try {
                req.setBody(JSON.serialize(event));

                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() != 201) {
                    updateComplaintsOnError(eventBody.trackingId, eventBody.externalIds);
                }
            } catch (Exception e) {
                updateComplaintsOnError(eventBody.trackingId, eventBody.externalIds);
                throw e;
            }
        }
    }

    private static void updateComplaintsOnError(Id caseId, List<Id> externalProductIds) {
        List<Product2> products = [
            SELECT Id
            FROM Product2
            WHERE ExternalId__c IN :externalProductIds
        ];
        List<ComplaintItem__c> complaintItems = [
            SELECT Id, Status__c
            FROM ComplaintItem__c
            WHERE Case__c = :caseId AND Product__c IN :products
        ];
        for (ComplaintItem__c complaintItem : complaintItems) {
            complaintItem.Status__c = Constants.ComplaintItem.Status.ERROR;
        }
        update complaintItems;
    }

    private class ExternalEventBody {
        public String trackingId;
        public List<Id> externalIds;
        public List<Decimal> quantities;
        public List<Decimal> prices;
    }

    private static AuraHandledException newAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}