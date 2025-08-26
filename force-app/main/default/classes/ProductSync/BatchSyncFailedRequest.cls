public class BatchSyncFailedRequest implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    List<Id> requestToEmailIds;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        requestToEmailIds = new List<Id>();
        Integer maxAttemptNumber = (Integer)Constants.REQUEST_LOG_SETTING.MaxAttemptNumber__c;

        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = :BatchSyncFailedRequest.class.getName()
            AND Status NOT IN ('Completed', 'Aborted')
        ];

        if(jobs.size() > 1) {
            return Database.getQueryLocator([
                SELECT Id, AttemptNumber__c, Status__c, SourceLog__c
                FROM RequestLog__c
                WHERE Id = null
            ]);
        }

        return Database.getQueryLocator([
            SELECT Id, AttemptNumber__c, Status__c, SourceLog__c
            FROM RequestLog__c
            WHERE Status__c = :Constants.RequestLog.Status.PENDING
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<RequestLog__c> scope) {
        Map<Id, RequestLog__c> requestLogMap = new Map<Id, RequestLog__c>();
        for (RequestLog__c requestLog : scope) {
            requestLogMap.put(requestLog.Id, requestLog);
        }

        List<RequestProduct__c> requestProducts = [
            SELECT RequestLog__r.Id, Product__c 
            FROM RequestProduct__c 
            WHERE RequestLog__r.Id IN :requestLogMap.keySet()
        ];

        Set<Id> productIds = new Set<Id>();
        for (RequestProduct__c requestProduct : requestProducts) {
            productIds.add(requestProduct.Product__c);
        }
        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Name, ProductCode, Family, IsActive, ExternalId__c, IsExternal__c, LastModifiedDate 
            FROM Product2 
            WHERE Id IN :productIds
        ]);

        Map<Id, RequestItem> requestItemsMap = new Map<Id, RequestItem>();
        for (RequestProduct__c requestProduct : requestProducts) {
            if (!requestItemsMap.containsKey(requestProduct.RequestLog__r.Id)) {
                requestItemsMap.put(
                    requestProduct.RequestLog__r.Id, 
                    new RequestItem(
                        requestLogMap.get(requestProduct.RequestLog__r.Id)
                    )
                );
            }
            requestItemsMap.get(requestProduct.RequestLog__r.Id).products.add(
                products.get(requestProduct.Product__c)
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
        List<RequestLog__c> requestLogsToUpdate = new List<RequestLog__c>();
        if (response.getStatus() == 'OK') {
            ProductSyncResponse.ResponseWrapper responseObject = (ProductSyncResponse.ResponseWrapper) JSON.deserialize(response.getBody(), ProductSyncResponse.ResponseWrapper.class);
            requestLogsToUpdate = createUpdatedLogs(responseObject, requestItems);
        } else {
            String responseBody = response.getBody();
            Integer responseCode = response.getStatusCode();
            for (RequestItem item : requestItems) {
                RequestLog__c requestLog = createRequestLog(item, responseBody, responseCode);
                requestLogsToUpdate.add(requestLog);
            }
        }
        
        update requestLogsToUpdate;

        Integer maxAttempt = (Integer)Constants.REQUEST_LOG_SETTING.MaxAttemptNumber__c;
        for (RequestLog__c log : requestLogsToUpdate) {
            if (log.Status__c == Constants.RequestLog.Status.FAILED && log.AttemptNumber__c == maxAttempt) {
                requestToEmailIds.add(log.Id);
            }
        }

        List<Id> oldLogIds = new List<Id>();
        for (RequestLog__c requestLog : requestLogsToUpdate) {
            if (requestLog.SourceLog__c != null) {
                oldLogIds.add(requestLog.SourceLog__c);
            }
        }

        List<RequestLog__c> oldLogs = [SELECT Id FROM RequestLog__c WHERE Id IN :oldLogIds];
        for (RequestLog__c oldLog : oldLogs) {
            oldLog.Status__c = Constants.RequestLog.Status.REATTEMPTED;
        }
        update oldLogs;
    }

    private List<RequestLog__c> createUpdatedLogs(ProductSyncResponse.ResponseWrapper responseObject, List<RequestItem> requestItems) {
        List<RequestLog__c> updatedLogs = new List<RequestLog__c>();
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
            updatedLogs.add(requestLog);
        }
        return updatedLogs;
    }

    private RequestLog__c createRequestLog(RequestItem item, String responseBody, Integer responseCode) {
        RequestLog__c requestLog = item.log;
        requestLog.ResponseBody__c = responseBody;
        requestLog.RequestBody__c = item.requestBody;
        Boolean requestSucceeded = String.valueOf(responseCode).startsWith('2');
        requestLog.Status__c = requestSucceeded ? Constants.RequestLog.Status.SUCCESS : Constants.RequestLog.Status.FAILED;
        return requestLog;
    }

    public void finish(Database.BatchableContext bc) {
        sendFailedRequestsEmail();
        
        if (Test.isRunningTest()) {
            return;
        }
        Integer remaining = [SELECT COUNT() FROM RequestLog__c WHERE Status__c = :Constants.RequestLog.Status.PENDING];
        if (remaining > 0) {
            Database.executeBatch(new BatchSyncFailedRequest(), (Integer)Constants.REQUEST_LOG_SETTING.MaxRequestsPerBatch__c);
        }
    }

    private void sendFailedRequestsEmail() {
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