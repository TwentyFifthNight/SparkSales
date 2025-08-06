public virtual class BaseDiscountTestDataBuilder extends TestDataBuilder{
    public BaseDiscountTestDataBuilder() {
        record = new Discount__c();
    }

    protected virtual override void prepare(){
        Discount__c discount = (Discount__c) record;
        if (String.isBlank(discount.Name)) {
            discount.Name = 'Test Discount';
        }
    }
}