public class BaseComplaintItemCompletedTestBuilder extends TestDataBuilder {
    public BaseComplaintItemCompletedTestBuilder() {
        record = new ComplaintItemCompleted__e();
    }

    public BaseComplaintItemCompletedTestBuilder withComplaintItems(String complaintItems) {
        ComplaintItemCompleted__e event = (ComplaintItemCompleted__e) record;
        event.ComplaintItems__c = complaintItems;
        return this;
    }
}