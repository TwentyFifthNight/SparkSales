public virtual class BasePricebookEntryTestDataBuilder extends TestDataBuilder {
    public BasePricebookEntryTestDataBuilder() {
        record = new PricebookEntry();
    }

    public BasePricebookEntryTestDataBuilder withProduct(Product2 product) {
        PricebookEntry entry = (PricebookEntry) record;
        entry.Product2Id = product.Id;
        return this;
    }
}