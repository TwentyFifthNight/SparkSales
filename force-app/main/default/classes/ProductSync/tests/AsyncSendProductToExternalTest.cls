@isTest
private class AsyncSendProductToExternalTest {

    @isTest
    static void testSendNewDataToExternal() {
        Test.setMock(HttpCalloutMock.class, new MockProductSyncREST());

        List<Product2> productsToSend = new ProductTestDataFactory().buildData(3, new BaseProductTestDataBuilder());

        AsyncSendProductsToExternal job = new AsyncSendProductsToExternal(productsToSend, Constants.RestAPI.Method.POST);
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        List<RequestLog__c> requestLogs = [SELECT Id, Status__c, AttemptNumber__c FROM RequestLog__c];
        Assert.areEqual(1, requestLogs.size(), 'Should be 1 RequestLog__c record');
        Assert.areEqual(Constants.RequestLog.Status.SUCCESS, requestLogs[0].Status__c, 'Request should succeed');
        Assert.areEqual(1, requestLogs[0].AttemptNumber__c, 'Should be 1 attempt');
    }
}