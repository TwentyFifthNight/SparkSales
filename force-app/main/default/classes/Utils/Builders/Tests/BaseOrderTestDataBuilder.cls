public virtual class BaseOrderTestDataBuilder extends TestDataBuilder {
    public BaseOrderTestDataBuilder() {
        record = new Order();
    }
    
    protected virtual override void prepare(){
        Order order = (Order) record;
        if (String.isBlank(order.Name)) {
            order.Name = 'Test Order';
        }
    }

    public BaseOrderTestDataBuilder withAccount(Account account) {
        Order order = (Order) record;
        order.AccountId = account.Id;
        return this;
    }
}