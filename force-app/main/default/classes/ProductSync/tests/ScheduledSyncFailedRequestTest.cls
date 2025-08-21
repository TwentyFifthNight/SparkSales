@isTest
private class ScheduledSyncFailedRequestTest {

    @isTest
    static void testResendNewDataToExternal() {
        Integer productCount = 3;
        List<Product2> productsToSend = new ProductTestDataFactory().buildData(productCount, new BaseProductTestDataBuilder());

        List<RequestLog__c> requestLogs = new List<RequestLog__c>();
        requestLogs.add((RequestLog__c) new RequestLogTestDataBuilder().withAttemptNumber(1).withStatus(Constants.RequestLog.Status.FAILED).create());
        insert requestLogs;

        List<RequestProduct__c> requestProducts = new List<RequestProduct__c>();
        for (Product2 product : productsToSend) {
            requestProducts.add((RequestProduct__c) new BaseRequestProductTestDataBuilder().withRequest(requestLogs[0]).withProduct(product).create());
        }
        insert requestProducts;

        Test.setMock(HttpCalloutMock.class, new MockProductSyncREST());
        Test.startTest();
        new ScheduledSyncFailedRequest().execute(null);
        Test.stopTest();

        List<RequestLog__c> newRequestLogs = [SELECT Id, Status__c, AttemptNumber__c FROM RequestLog__c WHERE Status__c = :Constants.RequestLog.Status.SUCCESS];
        
        Assert.areEqual(1, newRequestLogs.size());
        Assert.areEqual(2, newRequestLogs[0].AttemptNumber__c);

        List<RequestProduct__c> newRequestProducts = [SELECT Id FROM RequestProduct__c WHERE RequestLog__c = :newRequestLogs[0].Id];
        Assert.areEqual(productCount, newRequestProducts.size());
    }

    @isTest
    static void testResendBigAmountOfData() {
        Integer productCount = 50;
        Integer requestCount = 150;
        List<Product2> productsToSend = new ProductTestDataFactory().buildData(productCount, new BaseProductTestDataBuilder());

        new TestDataFactory().buildData(requestCount, new RequestLogTestDataBuilder().withAttemptNumber(1).withStatus(Constants.RequestLog.Status.FAILED));

        List<RequestProduct__c> requestProducts = new List<RequestProduct__c>();
        for (RequestLog__c requestLog : [SELECT Id FROM RequestLog__c]) {
            for (Product2 product : productsToSend) {
                requestProducts.add((RequestProduct__c) new BaseRequestProductTestDataBuilder().withRequest(requestLog).withProduct(product).create());
            }
        }
        insert requestProducts;

        Test.setMock(HttpCalloutMock.class, new MockProductSyncREST());
        Test.startTest();
        new ScheduledSyncFailedRequest().execute(null);
        Test.stopTest();
        
        Integer successCount = [SELECT Count() FROM RequestLog__c WHERE Status__c = :Constants.RequestLog.Status.SUCCESS];
        Assert.areEqual(requestCount, successCount);

        List<RequestLog__c> newRequestLogs = [SELECT Id, Status__c, AttemptNumber__c FROM RequestLog__c WHERE Status__c = :Constants.RequestLog.Status.SUCCESS LIMIT 1];
        Assert.areEqual(2, newRequestLogs[0].AttemptNumber__c, 'Attempt Number should be 2');

        List<RequestProduct__c> newRequestProducts = [SELECT Id FROM RequestProduct__c WHERE RequestLog__c = :newRequestLogs[0].Id];
        Assert.areEqual(productCount, newRequestProducts.size(), 'Only 50 products should be in the new request products');
    }

    @isTest
    static void testResendBigAmountOfRequests() {
        Integer productCount = 2;
        Integer requestCount = 2000;
        List<Product2> productsToSend = new ProductTestDataFactory().buildData(productCount, new BaseProductTestDataBuilder());

        new TestDataFactory().buildData(requestCount, new RequestLogTestDataBuilder().withAttemptNumber(1).withStatus(Constants.RequestLog.Status.FAILED));

        List<RequestProduct__c> requestProducts = new List<RequestProduct__c>();
        for (RequestLog__c requestLog : [SELECT Id FROM RequestLog__c]) {
            for (Product2 product : productsToSend) {
                requestProducts.add((RequestProduct__c) new BaseRequestProductTestDataBuilder().withRequest(requestLog).withProduct(product).create());
            }
        }
        insert requestProducts;

        Test.setMock(HttpCalloutMock.class, new MockProductSyncREST());
        Test.startTest();
        new ScheduledSyncFailedRequest().execute(null);
        Test.stopTest();
        
        Integer successCount = [SELECT Count() FROM RequestLog__c WHERE Status__c = :Constants.RequestLog.Status.SUCCESS];
        Assert.areEqual(requestCount, successCount);

        List<RequestLog__c> newRequestLogs = [SELECT Id, Status__c, AttemptNumber__c FROM RequestLog__c WHERE Status__c = :Constants.RequestLog.Status.SUCCESS LIMIT 1];
        Assert.areEqual(2, newRequestLogs[0].AttemptNumber__c, 'Attempt Number should be 2');

        List<RequestProduct__c> newRequestProducts = [SELECT Id FROM RequestProduct__c WHERE RequestLog__c = :newRequestLogs[0].Id];
        Assert.areEqual(productCount, newRequestProducts.size(), 'Only 2 products should be in the new request products');
    }

    @isTest
    static void testResendBigAmountOfProducts() {
        Integer productCount = 200;
        Integer requestCount = 3;
        List<Product2> productsToSend = new ProductTestDataFactory().buildData(productCount, new BaseProductTestDataBuilder());

        new TestDataFactory().buildData(requestCount, new RequestLogTestDataBuilder().withAttemptNumber(1).withStatus(Constants.RequestLog.Status.FAILED));

        List<RequestProduct__c> requestProducts = new List<RequestProduct__c>();
        for (RequestLog__c requestLog : [SELECT Id FROM RequestLog__c]) {
            for (Product2 product : productsToSend) {
                requestProducts.add((RequestProduct__c) new BaseRequestProductTestDataBuilder().withRequest(requestLog).withProduct(product).create());
            }
        }
        insert requestProducts;

        Test.setMock(HttpCalloutMock.class, new MockProductSyncREST());
        Test.startTest();
        new ScheduledSyncFailedRequest().execute(null);
        Test.stopTest();
        
        Integer successCount = [SELECT Count() FROM RequestLog__c WHERE Status__c = :Constants.RequestLog.Status.SUCCESS];
        Assert.areEqual(requestCount, successCount);

        List<RequestLog__c> newRequestLogs = [SELECT Id, Status__c, AttemptNumber__c FROM RequestLog__c WHERE Status__c = :Constants.RequestLog.Status.SUCCESS LIMIT 1];
        Assert.areEqual(2, newRequestLogs[0].AttemptNumber__c, 'Attempt Number should be 2');

        List<RequestProduct__c> newRequestProducts = [SELECT Id FROM RequestProduct__c WHERE RequestLog__c = :newRequestLogs[0].Id];
        Assert.areEqual(productCount, newRequestProducts.size(), 'Only 200 products should be in the new request products');
    }

    @isTest
    static void testResendThirdAttemptFailure() {
        Integer productCount = 2;
        Integer requestCount = 3;
        List<Product2> productsToSend = new ProductTestDataFactory().buildData(productCount, new BaseProductTestDataBuilder());

        new TestDataFactory().buildData(requestCount, new RequestLogTestDataBuilder().withAttemptNumber(2).withStatus(Constants.RequestLog.Status.FAILED));

        List<RequestProduct__c> requestProducts = new List<RequestProduct__c>();
        for (RequestLog__c requestLog : [SELECT Id FROM RequestLog__c]) {
            for (Product2 product : productsToSend) {
                requestProducts.add((RequestProduct__c) new BaseRequestProductTestDataBuilder().withRequest(requestLog).withProduct(product).create());
            }
        }
        insert requestProducts;

        MockProductSyncREST mock = new MockProductSyncREST();
        mock.statusCode = 400;
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        new ScheduledSyncFailedRequest().execute(null);
        Test.stopTest();
        
        Integer successCount = [SELECT Count() FROM RequestLog__c WHERE Status__c = :Constants.RequestLog.Status.SUCCESS];
        Assert.areEqual(0, successCount);

        List<RequestLog__c> newRequestLogs = [SELECT Id, Status__c, AttemptNumber__c FROM RequestLog__c WHERE Status__c = :Constants.RequestLog.Status.FAILED LIMIT 1];
        Assert.areEqual(3, newRequestLogs[0].AttemptNumber__c, 'Attempt Number should be 3');
    }

    @isTest
    static void testResendAfterLastAttempt() {
        Integer productCount = 2;
        Integer requestCount = 3;
        List<Product2> productsToSend = new ProductTestDataFactory().buildData(productCount, new BaseProductTestDataBuilder());
        Integer maxAttempt = (Integer)Constants.REQUEST_LOG_SETTING.MaxAttemptNumber__c;

        new TestDataFactory().buildData(requestCount, new RequestLogTestDataBuilder().withAttemptNumber(maxAttempt).withStatus(Constants.RequestLog.Status.FAILED));

        List<RequestProduct__c> requestProducts = new List<RequestProduct__c>();
        for (RequestLog__c requestLog : [SELECT Id FROM RequestLog__c]) {
            for (Product2 product : productsToSend) {
                requestProducts.add((RequestProduct__c) new BaseRequestProductTestDataBuilder().withRequest(requestLog).withProduct(product).create());
            }
        }
        insert requestProducts;

        Test.setMock(HttpCalloutMock.class, new MockProductSyncREST());
        Test.startTest();
        new ScheduledSyncFailedRequest().execute(null);
        Test.stopTest();
        
        Integer successCount = [SELECT Count() FROM RequestLog__c];
        Assert.areEqual(requestCount, successCount, 'No New Request Logs should be created');
    }

    private class RequestLogTestDataBuilder extends BaseRequestLogTestDataBuilder {
        public RequestLogTestDataBuilder withAttemptNumber(Integer attemptNumber) {
            RequestLog__c requestLog = (RequestLog__c) record;
            requestLog.AttemptNumber__c = attemptNumber;
            return this;
        }

        public RequestLogTestDataBuilder withStatus(String status) {
            RequestLog__c requestLog = (RequestLog__c) record;
            requestLog.Status__c = status;
            return this;
        }
    }
}