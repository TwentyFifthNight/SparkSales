public class ScheduledSyncFailedRequest implements Schedulable {
    public void execute( SchedulableContext context ) {
        Integer maxAttemptNumber = (Integer)Constants.REQUEST_LOG_SETTING.MaxAttemptNumber__c;
        List<RequestLog__c> failedRequests = [
            SELECT Id, AttemptNumber__c, Status__c
            FROM RequestLog__c
            WHERE Status__c = :Constants.RequestLog.Status.FAILED
            AND AttemptNumber__c < :maxAttemptNumber
        ];

        List<RequestLog__c> newRequests = new List<RequestLog__c>();
        for (RequestLog__c failedRequest : failedRequests) {
            RequestLog__c newRequest = new RequestLog__c(
                Status__c = Constants.RequestLog.Status.PENDING,
                AttemptNumber__c = failedRequest.AttemptNumber__c + 1,
                SourceLog__c = failedRequest.Id
            );   
            newRequests.add(newRequest);
        }

        List<RequestProduct__c> oldRequestProducts = [
            SELECT Id, Product__c, RequestLog__c 
            FROM RequestProduct__c 
            WHERE RequestLog__c IN :failedRequests
        ];
        Map<Id, List<RequestProduct__c>> oldRequestToRequestProduct = new Map<Id, List<RequestProduct__c>>();
        for (RequestProduct__c requestProduct : oldRequestProducts) {
            if (!oldRequestToRequestProduct.containsKey(requestProduct.RequestLog__c)) {
                oldRequestToRequestProduct.put(requestProduct.RequestLog__c, new List<RequestProduct__c>());
            }
            oldRequestToRequestProduct.get(requestProduct.RequestLog__c).add(requestProduct);
        }

        insert newRequests;

        List<RequestProduct__c> newRequestProducts = new List<RequestProduct__c>();
        for (RequestLog__c request : newRequests) {
            for (RequestProduct__c requestProduct : oldRequestToRequestProduct.get(request.SourceLog__c)) {
                RequestProduct__c newRequestProduct = new RequestProduct__c(
                    RequestLog__c = request.Id,
                    Product__c = requestProduct.Product__c
                );
                newRequestProducts.add(newRequestProduct);
            }
        }
        insert newRequestProducts;

        if (!Test.isRunningTest()) {
            if (!BatchStatusTracker.isBatchRunning(BatchSyncFailedRequest.class.getName())) {
                Database.executeBatch(new BatchSyncFailedRequest(), (Integer)Constants.REQUEST_LOG_SETTING.MaxRequestsPerBatch__c);
            }
        } else {
            Database.executeBatch(new BatchSyncFailedRequest(), 2000);
        }
    }
}