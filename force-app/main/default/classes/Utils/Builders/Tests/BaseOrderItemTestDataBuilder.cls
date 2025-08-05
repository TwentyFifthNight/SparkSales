public virtual class BaseOrderItemTestDataBuilder extends TestDataBuilder {
    public BaseOrderItemTestDataBuilder() {
        record = new OrderItem();
    }

    public BaseOrderItemTestDataBuilder withOrder(Order order) {
        OrderItem orderItem = (OrderItem) record;
        orderItem.OrderId = order.Id;
        return this;
    }

    public BaseOrderItemTestDataBuilder withPricebookEntry(PricebookEntry pricebookEntry) {
        OrderItem orderItem = (OrderItem) record;
        orderItem.PricebookEntryId = pricebookEntry.Id;
        orderItem.Product2Id = pricebookEntry.Product2Id;
        return this;
    }
}