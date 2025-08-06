public virtual class BaseOrderDiscountTestDataBuilder extends TestDataBuilder {
    public BaseOrderDiscountTestDataBuilder() {
        record = new OrderDiscount__c();
    }
    
    protected virtual override void prepare(){
        OrderDiscount__c orderDiscount = (OrderDiscount__c) record;
        if (String.isBlank(orderDiscount.Name)) {
            orderDiscount.Name = 'Test Order Discount';
        }
    }

    public BaseOrderDiscountTestDataBuilder withOrder(Order order) {
        OrderDiscount__c orderDiscount = (OrderDiscount__c) record;
        orderDiscount.Order__c = order.Id;
        return this;
    }

    public BaseOrderDiscountTestDataBuilder withDiscount(Discount__c discount) {
        OrderDiscount__c orderDiscount = (OrderDiscount__c) record;
        orderDiscount.Discount__c = discount.Id;
        return this;
    }
}