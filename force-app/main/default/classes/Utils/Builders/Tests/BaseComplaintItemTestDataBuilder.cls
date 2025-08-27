public virtual class BaseComplaintItemTestDataBuilder extends TestDataBuilder {
    public BaseComplaintItemTestDataBuilder() {
        record = new ComplaintItem__c();
    }
    
    protected virtual override void prepare(){
        ComplaintItem__c complaint = (ComplaintItem__c) record;
        if (complaint.UnitPrice__c == null) {
            complaint.UnitPrice__c = 100;
        }
        if (complaint.Quantity__c == null) {
            complaint.Quantity__c = 1;
        }
    }

    public BaseComplaintItemTestDataBuilder withProduct(Product2 product) {
        ComplaintItem__c complaint = (ComplaintItem__c) record;
        complaint.Product__c = product.Id;
        return this;
    }

    public BaseComplaintItemTestDataBuilder withCase(Case caseRecord) {
        ComplaintItem__c complaintItem = (ComplaintItem__c) record;
        complaintItem.Case__c = caseRecord.Id;
        return this;
    }
}