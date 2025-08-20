public virtual class BaseRequestLogTestDataBuilder extends TestDataBuilder {
    public BaseRequestLogTestDataBuilder() {
         record = new RequestLog__c();
    }

    protected override void prepare() {
        RequestLog__c requestLog = (RequestLog__c) record;
        if (String.isBlank(requestLog.Status__c)) {
            requestLog.Status__c = Constants.RequestLog.Status.SUCCESS;
        }
        if (requestLog.AttemptNumber__c == null) {
            requestLog.AttemptNumber__c = 1;
        }
    }
}