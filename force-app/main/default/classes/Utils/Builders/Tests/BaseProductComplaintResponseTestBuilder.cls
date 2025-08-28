public virtual class BaseProductComplaintResponseTestBuilder extends TestDataBuilder {
    public BaseProductComplaintResponseTestBuilder() {
        record = new ProductComplaintResponseEvent__e();
    }

    protected virtual override void prepare(){
        ProductComplaintResponseEvent__e event = (ProductComplaintResponseEvent__e) record;
        if (String.isBlank(event.CaseId__c)) {
            event.CaseId__c = 'TestExternalCase';
        }
    }

    public BaseProductComplaintResponseTestBuilder withTrackingId(String trackingId) {
        ProductComplaintResponseEvent__e event = (ProductComplaintResponseEvent__e) record;
        event.TrackingId__c = trackingId;
        return this;
    }
}