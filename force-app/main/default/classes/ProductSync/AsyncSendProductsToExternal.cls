public class AsyncSendProductsToExternal implements Queueable, Database.AllowsCallouts{
    List<Product2> products;
    String method;

    public AsyncSendProductsToExternal(List<Product2> products, String method){
        this.products = products;
        this.method = method;
    }

    public void execute(QueueableContext context) {
        List<RequestLog> requestLogs = new List<RequestLog>();
        List<Product2> productBatch = new List<Product2>();
        Integer batchSize = (Integer)Constants.REQUEST_LOG_SETTING.MaxProductsPerRequest__c;
        for (Integer i = 0; i < products.size(); i++) {
            productBatch.add(products[i]);
            if (productBatch.size() == batchSize) {
                RequestLog log = sendBatchOfProducts(productBatch);
                requestLogs.add(log);
                productBatch.clear();
            }
        }
        if (!productBatch.isEmpty()) {
            RequestLog log = sendBatchOfProducts(productBatch);
            requestLogs.add(log);
            productBatch.clear();
        }

        List<RequestLog__c> requestsToInsert = new List<RequestLog__c>();
        for(RequestLog requestLog : requestLogs) {
            requestsToInsert.add(requestLog.log);
        }
        insert requestsToInsert;

        LIst<RequestProduct__c> requestProductsToInsert = new List<RequestProduct__c>();
        for(Integer i = 0; i < requestLogs.size(); i++) {
            List<RequestProduct__c> requestProducts = requestLogs[i].requestProducts;
            Id requestId = requestsToInsert[i].Id;
            for(RequestProduct__c requestProduct : requestProducts) {
                requestProduct.RequestLog__c = requestId;
            }
            requestProductsToInsert.addAll(requestProducts);
        }
        insert requestProductsToInsert;
    }

    private RequestLog sendBatchOfProducts(List<Product2> products) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Constants.PRODUCT_SYNC_API_ENDPOINT);
        request.setMethod(Constants.RestAPI.Method.POST);
        request.setHeader('Content-Type', 'application/json');
        
        ProductSyncRequest.ItemWrapper requestItem = new ProductSyncRequest.ItemWrapper();
        requestItem.body = ProductSyncRequest.productListToRequestBody(products);
        requestItem.body.method = this.method;
        ProductSyncRequest.RequestWrapper requestContent = new ProductSyncRequest.RequestWrapper();
        requestContent.requestList.add(requestItem);
        String body = JSON.serialize(requestContent);
        request.setBody(body);
        try {
            HttpResponse response = http.send(request);
            String requestBody = JSON.serialize(requestItem.body);
            RequestLog__c requestLog = createRequestLog(response, requestBody, products);
            List<RequestProduct__c> requestProducts = createRequestProducts(products);
            return new RequestLog(requestLog, requestProducts);
        } catch (Exception e) {
            RequestLog__c requestLog = createRequestLog(e.getMessage(), JSON.serialize(requestItem.body), 500);
            List<RequestProduct__c> requestProducts = createRequestProducts(products);
            return new RequestLog(requestLog, requestProducts);
        }
    }

    private RequestLog__c createRequestLog(HttpResponse response, String requestBody, List<Product2> products) {
        String responseBody;
        Integer responseCode;
        try {
            if (response.getStatus() == 'OK') {
                ProductSyncResponse.ResponseWrapper responseObject = (ProductSyncResponse.ResponseWrapper) JSON.deserialize(response.getBody(), ProductSyncResponse.ResponseWrapper.class);
                responseBody = JSON.serialize(responseObject.responseList.get(0).body);
                responseCode = responseObject.responseList.get(0).httpStatusCode;
            } else {
                responseBody = response.getBody();
                responseCode = response.getStatusCode();
            }
        } catch (Exception e) {
            responseBody = e.getMessage();
            responseCode = 500;
        }

        RequestLog__c requestLog = createRequestLog(responseBody, requestBody, responseCode);
        return requestLog;
    }

    private RequestLog__c createRequestLog(String responseBody, String requestBody, Integer responseCode) {
        RequestLog__c requestLog = new RequestLog__c();
        requestLog.ResponseBody__c = responseBody;
        Boolean requestSucceeded = String.valueOf(responseCode).startsWith('2');
        requestLog.Status__c = requestSucceeded ? Constants.RequestLog.Status.SUCCESS : Constants.RequestLog.Status.FAILED;
        requestLog.RequestBody__c = requestBody;
        requestLog.AttemptNumber__c = 1;

        return requestLog;
    }

    private List<RequestProduct__c> createRequestProducts(List<Product2> products) {
        List<RequestProduct__c> requestProducts = new List<RequestProduct__c>();
        for(Product2 product : products){
            RequestProduct__c requestProduct = new RequestProduct__c();
            requestProduct.Product__c = product.Id;
            requestProducts.add(requestProduct);
        }
        return requestProducts;
    }

    private class RequestLog {
        public RequestLog__c log;
        public List<RequestProduct__c> requestProducts;
        
        public RequestLog(RequestLog__c log, List<RequestProduct__c> requestProducts) {
            this.log = log;
            this.requestProducts = requestProducts;
        }
    }
}