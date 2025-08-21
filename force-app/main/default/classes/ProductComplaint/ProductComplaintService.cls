public class ProductComplaintService {
    public static List<Product2> getProducts(String orderId) {
        List<OrderItem> orderProducts = [SELECT Product2Id FROM OrderItem WHERE OrderId = :orderId];
        List<Id> productIds = new List<Id>();
        for (OrderItem orderProduct : orderProducts) {
            productIds.add(orderProduct.Product2Id);
        }
        
        return [SELECT Name, ProductCode, Family, IsExternal__c FROM Product2 WHERE Id IN :productIds];
    }

    public static ProductComplaintController.ComplaintResult submitComplaints(List<Id> productIds, String orderId) {
        List<Product2> products = [
            SELECT Id, IsExternal__c, ExternalId__c
            FROM Product2
            WHERE Id IN :productIds
        ];

        String trackingId = UUID.randomUUID().toString();
        List<Product2> internalProducts = new List<Product2>();
        List<Id> externalIds = new List<Id>();
        for (Product2 product : products) {
            if (product.IsExternal__c) {
                externalIds.add(product.ExternalId__c);
            } else {
                internalProducts.add(product);
            }
        }

        ProductComplaintController.ComplaintResult result = new ProductComplaintController.ComplaintResult();
        result.status = 'PENDING';
        result.trackingId = trackingId;

        if (!externalIds.isEmpty()) {
            try {
                sendExternalEvent(trackingId, externalIds);
            } catch (Exception e) {
                throw new AuraHandledException(System.Label.externalComplaintSendingError);
            }
        } else {
            result.status = 'SUCCESS';
        }

        createApprovalProcesses(internalProducts, orderId);

        return result;
    }

    private static void sendExternalEvent(String trackingId, List<Id> externalIds) {
        Map<String, String> event = new Map<String, String>();
        event.put('TrackingId__c', trackingId);
        event.put('ProductIds__c', JSON.serialize(externalIds));

        HttpRequest req = new HttpRequest();
        req.setEndpoint(Constants.EXTERNAL_COMPLAINT_EVENT_API_ENDPOINT);
        req.setMethod(Constants.RestAPI.Method.POST);
        req.setHeader('Content-Type', 'application/json');

        req.setBody(JSON.serialize(event));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 201) {
            throw new CalloutException(res.getBody());
        }
    }

    private static void createApprovalProcesses(List<Product2> products, String orderId) {
        Case newCase = new Case(
            Subject = 'Product complaint',
            Status = 'New',
            Origin = 'Internal'
        );
        insert newCase;

        List<ComplaintItem__c> complaintItems = new List<ComplaintItem__c>();
        for (Product2 product : products) {
            ComplaintItem__c newComplaintItem = new ComplaintItem__c(
                Product__c = product.Id,
                Case__c = newCase.Id,
                Order__c = orderId
            );
            complaintItems.add(newComplaintItem);
        }
        insert complaintItems;

        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        for (ComplaintItem__c complaintItem : complaintItems) {
            Approval.ProcessSubmitRequest reqApproval = new Approval.ProcessSubmitRequest();
            reqApproval.setObjectId(complaintItem.Id);
            approvalRequests.add(reqApproval);
        }

        try {
             Approval.process(approvalRequests);
        } catch (Exception ex) {
            throw new AuraHandledException(System.Label.approvalProcessCreationError);
        }
    }
}