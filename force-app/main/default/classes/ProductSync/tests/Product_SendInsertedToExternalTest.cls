@isTest
private class Product_SendInsertedToExternalTest {

    @isTest
    static void testSendBigDataChunk() {
        Test.setMock(HttpCalloutMock.class, new MockProductSyncREST());

        Integer productCount = 10000;
        List<Product2> productsToSend = new List<Product2>();
        for (Integer i = 0; i < productCount; i++) {
            productsToSend.add((Product2) new BaseProductTestDataBuilder().create());
        }
        Test.startTest();
        insert productsToSend;
        Test.stopTest();

        Integer expectedSize = productCount / Constants.RequestLog.MAX_PRODUCTS_PER_REQUEST;
        List<RequestLog__c> requestLogs = [SELECT Id, Status__c, AttemptNumber__c FROM RequestLog__c];
        Assert.areEqual(expectedSize, requestLogs.size());
    }
}