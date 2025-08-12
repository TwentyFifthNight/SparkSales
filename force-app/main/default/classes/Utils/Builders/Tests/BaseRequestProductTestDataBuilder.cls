public virtual class BaseRequestProductTestDataBuilder extends TestDataBuilder {
    public BaseRequestProductTestDataBuilder() {
         record = new RequestProduct__c();
    }

    public BaseRequestProductTestDataBuilder withProduct(Product2 product) {
        RequestProduct__c requestProduct = (RequestProduct__c) record;
        requestProduct.Product__c = product.Id;
        return this;
    }

    public BaseRequestProductTestDataBuilder withRequest(RequestLog__c request) {
        RequestProduct__c requestProduct = (RequestProduct__c) record;
        requestProduct.RequestLog__c = request.Id;
        return this;
    }
}