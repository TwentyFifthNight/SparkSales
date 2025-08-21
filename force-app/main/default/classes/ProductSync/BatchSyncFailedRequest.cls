public class BatchSyncFailedRequest implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    List<Id> requestToEmailIds;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        requestToEmailIds = new List<Id>();
        Integer maxAttemptNumber = (Integer)Constants.REQUEST_LOG_SETTING.MaxAttemptNumber__c;
        return Database.getQueryLocator([
            SELECT Id, AttemptNumber__c, Status__c
            FROM RequestLog__c
            WHERE Status__c = :Constants.RequestLog.Status.FAILED
            AND AttemptNumber__c < :maxAttemptNumber
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<RequestLog__c> scope) {
        Map<Id, RequestLog__c> requestLogMap = new Map<Id, RequestLog__c>();
        for (RequestLog__c requestLog : scope) {
            requestLogMap.put(requestLog.Id, requestLog);
        }

        List<RequestProduct__c> failedRequestProducts = [
            SELECT RequestLog__r.Id, Product__c 
            FROM RequestProduct__c 
            WHERE RequestLog__r.Id IN :requestLogMap.keySet()
        ];

        Set<Id> productIds = new Set<Id>();
        for (RequestProduct__c failedRequest : failedRequestProducts) {
            productIds.add(failedRequest.Product__c);
        }
        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Name, ProductCode, Family, IsActive, ExternalId__c, IsExternal__c, LastModifiedDate 
            FROM Product2 
            WHERE Id IN :productIds
        ]);

        Map<Id, RequestItem> requestItemsMap = new Map<Id, RequestItem>();
        for (RequestProduct__c failedRequest : failedRequestProducts) {
            if (!requestItemsMap.containsKey(failedRequest.RequestLog__r.Id)) {
                requestItemsMap.put(
                    failedRequest.RequestLog__r.Id, 
                    new RequestItem(
                        requestLogMap.get(failedRequest.RequestLog__r.Id)
                    )
                );
            }
            requestItemsMap.get(failedRequest.RequestLog__r.Id).products.add(
                products.get(failedRequest.Product__c)
            );
        }

        HttpResponse response = sendProducts(requestItemsMap.values());
        createRequestLogs(response, requestItemsMap.values());
    }

    private class RequestItem {
        public RequestLog__c log;
        public List<Product2> products;
        public String requestBody;

        public RequestItem(RequestLog__c log) {
            this.log = log;
            products = new List<Product2>();
        }
    }

    private HttpResponse sendProducts(List<RequestItem> items) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Constants.PRODUCT_SYNC_API_ENDPOINT);
        request.setMethod(Constants.RestAPI.Method.POST);
        request.setHeader('Content-Type', 'application/json');

        ProductSyncRequest.RequestWrapper requestContent = new ProductSyncRequest.RequestWrapper();
        for (RequestItem item : items) {
            ProductSyncRequest.ItemWrapper requestItem = new ProductSyncRequest.ItemWrapper();
            requestItem.body = ProductSyncRequest.productListToRequestBody(item.products);
            requestItem.body.method = Constants.RestAPI.Method.PATCH;
            requestContent.requestList.add(requestItem);
            item.requestBody = JSON.serialize(requestItem.body);
        }
        
        String body = JSON.serialize(requestContent);
        request.setBody(body);
        HttpResponse response = http.send(request);
        
        return response;
    }

    private void createRequestLogs(HttpResponse response, List<RequestItem> requestItems) {
        Map<Id, RequestLog__c> oldIdToNewRequestLog = new Map<Id, RequestLog__c>();
        if (response.getStatus() == 'OK') {
            ProductSyncResponse.ResponseWrapper responseObject = (ProductSyncResponse.ResponseWrapper) JSON.deserialize(response.getBody(), ProductSyncResponse.ResponseWrapper.class);
            oldIdToNewRequestLog = createOldIdToNewRequestLogMap(responseObject, requestItems);
        } else {
            String responseBody = response.getBody();
            Integer responseCode = response.getStatusCode();
            for (RequestItem item : requestItems) {
                RequestLog__c requestLog = createRequestLog(item, responseBody, responseCode);
                oldIdToNewRequestLog.put(item.log.Id, requestLog);
            }
        }
        
        insert oldIdToNewRequestLog.values();

        Integer maxAttempt = (Integer)Constants.REQUEST_LOG_SETTING.MaxAttemptNumber__c;
        for (RequestLog__c log : oldIdToNewRequestLog.values()) {
            if (log.Status__c == Constants.RequestLog.Status.FAILED && log.AttemptNumber__c == maxAttempt) {
                requestToEmailIds.add(log.Id);
            }
        }

        List<RequestProduct__c> newRequestProducts = new List<RequestProduct__c>();
        for (RequestItem item : requestItems) {
            for (Product2 product : item.products) {
                RequestProduct__c newProduct = new RequestProduct__c(RequestLog__c = oldIdToNewRequestLog.get(item.log.Id).Id, Product__c = product.Id);
                newRequestProducts.add(newProduct);
            }
        }
        insert newRequestProducts;


        List<RequestLog__c> oldLogs = new List<RequestLog__c>();
        for (RequestItem item : requestItems) {
            item.log.Status__c = Constants.RequestLog.Status.REATTEMPTED;
            oldLogs.add(item.log);
        }
        update oldLogs;
    }

    private Map<Id, RequestLog__c> createOldIdToNewRequestLogMap(ProductSyncResponse.ResponseWrapper responseObject, List<RequestItem> requestItems) {
        Map<Id, RequestLog__c> oldIdToNewRequestLog = new Map<Id, RequestLog__c>();
        for (Integer i = 0; i < requestItems.size(); i += 1) {
            RequestItem item = requestItems[i];
            String responseBody;
            Integer responseCode;
            if (responseObject.responseList.size() <= i) {
                responseCode = 500;
                responseBody = System.Label.missingServerResponse;
            } else {
                responseCode = responseObject.responseList.get(i).httpStatusCode;
                responseBody = JSON.serialize(responseObject.responseList.get(i).body);
            }
            RequestLog__c requestLog = createRequestLog(item, responseBody, responseCode);
            oldIdToNewRequestLog.put(item.log.Id, requestLog);
        }
        return oldIdToNewRequestLog;
    }

    private RequestLog__c createRequestLog(RequestItem item, String responseBody, Integer responseCode) {
        RequestLog__c requestLog = new RequestLog__c();
        requestLog.ResponseBody__c = responseBody;
        requestLog.RequestBody__c = item.requestBody;
        Boolean requestSucceeded = String.valueOf(responseCode).startsWith('2');
        requestLog.Status__c = requestSucceeded ? Constants.RequestLog.Status.SUCCESS : Constants.RequestLog.Status.FAILED;
        requestLog.AttemptNumber__c = item.log.AttemptNumber__c + 1;
        requestLog.SourceLog__c = item.log.Id;
        return requestLog;
    }

    public void finish(Database.BatchableContext bc) {
        List<RequestLog__c> requestLogsToEmail = [
            SELECT Name 
            FROM RequestLog__c 
            WHERE Id IN :requestToEmailIds
        ];
        
        if (requestLogsToEmail.isEmpty()){
            return;
        }

        List<Admin_Email_Recipients__c> adminEmails; 
        if (!Test.isRunningTest()) {
            adminEmails = [SELECT Email_Address__c FROM Admin_Email_Recipients__c];
        } else {
            adminEmails = new List<Admin_Email_Recipients__c>{
                new Admin_Email_Recipients__c(Email_Address__c = 'example@example.com')
            };
        }
        if (adminEmails.isEmpty()) {
            return;
        }
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String>toAddresses = new List<String>{};
    
        for(Admin_Email_Recipients__c admin : adminEmails){
            toAddresses.add(admin.Email_Address__c);
        }

        EmailTemplate emailTemplate = [SELECT Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'SyncRequestFailed' LIMIT 1];
        String htmlBody = emailTemplate.HtmlValue;
        htmlBody = htmlBody.replace('{!logsPlaceholder}', buildHtmlEmailBody(requestLogsToEmail));
        mail.setToAddresses(toAddresses);
        mail.setHtmlBody(htmlBody);
        mail.setSubject(emailTemplate.Subject);
        mails.add(mail);

        Messaging.sendEmail(mails);
    }

    private String buildHtmlEmailBody(List<RequestLog__c> requestLogsToEmail) {
        String body = '';
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        for(RequestLog__c log : requestLogsToEmail){
            String recordlink = baseUrl + '/' + log.Id;
            body += '<a href="' + recordlink + '">' + log.Name + '</a><br>';
        }
        return body;
    }
}