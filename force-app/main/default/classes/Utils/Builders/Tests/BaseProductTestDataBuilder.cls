public virtual class BaseProductTestDataBuilder extends TestDataBuilder {
    public BaseProductTestDataBuilder() {
        record = new Product2();
    }

    protected virtual override void prepare(){
        Product2 product = (Product2) record;
        if (String.isBlank(product.Name)) {
            product.Name = 'Test Product';
        }
    }
}