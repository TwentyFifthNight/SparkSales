@isTest
private class SendCompletedCaseToExternalTest {

    @isTest
    static void testNoExternalCaseId() {
        Case caseRecord = (Case)new BaseCaseTestDataBuilder().create();
        insert caseRecord;
        Assert.isNull(caseRecord.ExternalCaseId__c, 'External case id should not be set');

        try {
            Test.startTest();
            Flow_SendCompletedCaseToExternal.sendCompletedCaseToExternal(new List<Id>{caseRecord.Id});
            Test.stopTest();
        } catch (Exception e) {
            Assert.fail('Nothing should be enqueued, so no exception should be thrown');
        }
    }

    @isTest
    static void testWithExternalCaseId_Success() {
        Case caseRecord = (Case)new ExternalCaseTetsDataBuilder().withExternalId('TestExternalId').create();
        insert caseRecord;

        Test.setMock(HttpCalloutMock.class, new ExternalComplaintCompletedEventMock());

        try {
            Test.startTest();
            Flow_SendCompletedCaseToExternal.sendCompletedCaseToExternal(new List<Id>{caseRecord.Id});
            Test.stopTest();
        } catch (Exception e) {
            Assert.fail('Queueable should not throw exception');
        }
    }

    @isTest
    static void testWithExternalCaseId_Error() {
        Case caseRecord = (Case)new ExternalCaseTetsDataBuilder().withExternalId('TestExternalId').create();
        insert caseRecord;

        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        try {
            Test.startTest();
            Flow_SendCompletedCaseToExternal.sendCompletedCaseToExternal(new List<Id>{caseRecord.Id});
            Test.stopTest();
            Assert.fail('Queueable should throw exception');
        } catch (Exception e) {
            Assert.areEqual('Error sending event to external system', e.getMessage(), 'Unexpected exception message');
        }
    }

    private class ExternalCaseTetsDataBuilder extends BaseCaseTestDataBuilder {
        public ExternalCaseTetsDataBuilder withExternalId(String externalId) {
            Case caseRecord = (Case) record;
            caseRecord.ExternalCaseId__c = externalId;
            return this;
        }
    }
}