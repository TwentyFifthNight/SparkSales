public class ProductSendToExternalHelper {
    public static void createPendingRequests(List<Product2> newList) {
        List<Product2> productGroup = new List<Product2>();
        Integer asyncBatchSize = System.Limits.getLimitDmlRows() / 2;

        for (Product2 product : newList){
            productGroup.add(product);
            if (productGroup.size() == asyncBatchSize) {
                AsyncCreateRequest asyncCreateRequest = new AsyncCreateRequest(productGroup);
                System.enqueueJob(asyncCreateRequest);
            }
        }
        if (!productGroup.isEmpty()) {
            AsyncCreateRequest asyncCreateRequest = new AsyncCreateRequest(productGroup);
            System.enqueueJob(asyncCreateRequest);
        }
    }

    private class AsyncCreateRequest implements Queueable {
        private List<Product2> newList;
        public AsyncCreateRequest(List<Product2> newList) {
            this.newList = newList;
        }

        public void execute(QueueableContext context) {
            List<Product2> productGroup = new List<Product2>();
            List<RequestItem> requestItems = new List<RequestItem>();
            List<RequestLog__c>  requestLogsToInsert = new List<RequestLog__c>();
            Integer batchSize = (Integer) Constants.REQUEST_LOG_SETTING.MaxProductsPerRequest__c;
            String requestStatus = Constants.RequestLog.Status.PENDING;

            for(Product2 product : newList){
                productGroup.add(product);
                if (productGroup.size() == batchSize) {
                    RequestItem requestItem = new RequestItem(productGroup, requestStatus);
                    requestItems.add(requestItem);
                    requestLogsToInsert.add(requestItem.requestLog);
                    productGroup.clear();
                }
            }
            if (!productGroup.isEmpty()) {
                RequestItem requestItem = new RequestItem(productGroup, requestStatus);
                requestItems.add(requestItem);
                requestLogsToInsert.add(requestItem.requestLog);
            }
            insert requestLogsToInsert;

            List<RequestProduct__c> requestProductsToInsert = new List<RequestProduct__c>();
            for (RequestItem requestItem : requestItems) {
                for (Product2 product : requestItem.products) {
                    RequestProduct__c requestProduct = new RequestProduct__c(
                        RequestLog__c = requestItem.requestLog.Id,
                        Product__c = product.Id
                    );
                    requestProductsToInsert.add(requestProduct);
                }
            }
            insert requestProductsToInsert;

            Integer requestsPerBatch = (Integer)Constants.REQUEST_LOG_SETTING.MaxRequestsPerBatch__c;
            if (Test.isRunningTest()) {
                requestsPerBatch = 2000;
            }

            if (!BatchStatusTracker.isBatchRunning(BatchSyncFailedRequest.class.getName())) {
                Database.executeBatch(new BatchSyncFailedRequest(), requestsPerBatch);
            }
        }
    }

    private class RequestItem {
        public RequestLog__c requestLog { get; set; }
        public List<Product2> products { get; set; }

        public RequestItem(List<Product2> products, String status) {
            this.products = products;
            this.requestLog = new RequestLog__c(Status__c = status, AttemptNumber__c = 1);
        }
    }
}