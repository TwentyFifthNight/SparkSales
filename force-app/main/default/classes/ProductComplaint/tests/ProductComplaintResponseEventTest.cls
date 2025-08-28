@isTest
private class ProductComplaintResponseEventTest {

    @isTest
    static void testEventUpdatesCase() {
        String externalId = 'TestExternalId';
        Case testCase = (Case)new BaseCaseTestDataBuilder().create();
        insert testCase;

        ProductComplaintResponseEvent__e evt = (ProductComplaintResponseEvent__e) new ProductComplaintResponseTestBuilder()
            .withCaseId(externalId)
            .withTrackingId(testCase.Id)
            .create();

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(evt);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), 'Event should be published successfully');
        Case updatedCase = [SELECT Id, ExternalCaseId__c FROM Case WHERE Id = :testCase.Id];
        Assert.areEqual(externalId, updatedCase.ExternalCaseId__c, 'External case id should be updated');
    }

    @isTest
    static void testEventWithInvalidCaseIdDoesNothing() {
        String externalId = 'TestExternalId';
        ProductComplaintResponseEvent__e evt = (ProductComplaintResponseEvent__e) new ProductComplaintResponseTestBuilder()
            .withCaseId(externalId)
            .withTrackingId('500000000000000AAA')
            .create();

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(evt);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), 'Event should be published successfully');

        Integer countCases = [SELECT COUNT() FROM Case WHERE ExternalCaseId__c = :externalId];
        Assert.areEqual(0, countCases, 'No case should be updated for invalid TrackingId');
    }

    private class ProductComplaintResponseTestBuilder extends BaseProductComplaintResponseTestBuilder {
        public ProductComplaintResponseTestBuilder withCaseId(String caseId) {
            ProductComplaintResponseEvent__e event = (ProductComplaintResponseEvent__e) record;
            event.CaseId__c = caseId;
            return this;
        }
    }
}