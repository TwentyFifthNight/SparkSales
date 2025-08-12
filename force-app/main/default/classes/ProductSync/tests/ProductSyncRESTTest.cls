@isTest
private class ProductSyncRESTTest {

    @isTest
    static void testInsertNewData() {
        RestRequest request = new RestRequest();
        request.requestURI = '/Product/sync/';
        request.httpMethod = Constants.RestAPI.Method.POST;
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.headers.put('Content-Type', 'application/json');
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 3; i++) {
            products.add((Product2)new ProductTestDataBuilder().create());
        }
        
        String body = createRequestBody(products, Constants.RestAPI.Method.POST);
        request.requestBody = Blob.valueOf(body);

        Test.startTest();
        ProductSyncREST.syncProducts();
        Test.stopTest();
        ProductSyncResponse.ResponseWrapper responseWrapper = (ProductSyncResponse.ResponseWrapper)JSON.deserialize(response.responseBody.toString(), ProductSyncResponse.ResponseWrapper.class);
        Assert.areEqual(1, responseWrapper.responseList.size(), 'ResponseList should have 1 item.');
        Assert.areEqual(200, responseWrapper.responseList.get(0).httpStatusCode, 'Response should have status code 200.');
        Assert.isTrue(responseWrapper.responseList.get(0).body.success, 'Response should have succeded.');
        Assert.areEqual(0, responseWrapper.responseList.get(0).body.errorMessages.size(), 'Response should not have error messages.');

        List<Product2> insertedProducts = [SELECT Id FROM Product2];
        Assert.areEqual(3, insertedProducts.size(), 'Product list should have 3 items.');
    }

    @isTest
    static void testInvalidMethodName() {
        RestRequest request = new RestRequest();
        request.requestURI = '/Product/sync/';
        request.httpMethod = Constants.RestAPI.Method.POST;
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.headers.put('Content-Type', 'application/json');
        List<Product2> products = new List<Product2> {
            (Product2) new ProductTestDataFactory().buildData(1, new BaseProductTestDataBuilder())[0]
        };
        String body = createRequestBody(products, 'GET');
        request.requestBody = Blob.valueOf(body);

        Test.startTest();
        ProductSyncREST.syncProducts();
        Test.stopTest();
        ProductSyncResponse.ResponseWrapper responseWrapper = (ProductSyncResponse.ResponseWrapper)JSON.deserialize(response.responseBody.toString(), ProductSyncResponse.ResponseWrapper.class);
        Assert.areEqual(1, responseWrapper.responseList.size(), 'ResponseList should have 1 item.');
        Assert.areEqual(400, responseWrapper.responseList.get(0).httpStatusCode, 'Response should have status code 400.');
        Assert.isFalse(responseWrapper.responseList.get(0).body.success, 'Response shouldn\'t have succeded.');
        Assert.areEqual(1, responseWrapper.responseList.get(0).body.errorMessages.size(), 'Response should have 1 error message.');
    }

    @isTest
    static void testUpdateLocalData() {
        String name = 'Test';

        RestRequest request = new RestRequest();
        request.requestURI = '/Product/sync/';
        request.httpMethod = Constants.RestAPI.Method.POST;
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.headers.put('Content-Type', 'application/json');
        List<Product2> products = (List<Product2>) new ProductTestDataFactory().buildData(3, new ProductTestDataBuilder().withName(name));

        products = [SELECT Name, IsActive, ProductCode, Family, LastModifiedDate FROM Product2 WHERE Id IN :products];
        for (Product2 product : products) {
            product.Name = name + '_Updated';
            product.ExternalId__c = product.Id;
        }
        Formula.recalculateFormulas(products);

        String body = createRequestBody(products, Constants.RestAPI.Method.PATCH);
        request.requestBody = Blob.valueOf(body);
        
        Test.startTest();
        ProductSyncREST.syncProducts();
        Test.stopTest();

        ProductSyncResponse.ResponseWrapper responseWrapper = (ProductSyncResponse.ResponseWrapper)JSON.deserialize(response.responseBody.toString(), ProductSyncResponse.ResponseWrapper.class);
        Assert.areEqual(1, responseWrapper.responseList.size(), 'ResponseList should have 1 item.');
        Assert.areEqual(200, responseWrapper.responseList.get(0).httpStatusCode, 'Response should have status code 200.');
        Assert.isTrue(responseWrapper.responseList.get(0).body.success, 'Response should have succeded.');
        Assert.areEqual(0, responseWrapper.responseList.get(0).body.errorMessages.size(), 'Response should not have error messages.');

        List<Product2> updatedProducts = [SELECT Id, Name FROM Product2];
        Assert.areEqual(3, updatedProducts.size(), 'Product list should have 3 items.');
        for (Product2 product : updatedProducts) { 
            Assert.areEqual(name + '_Updated', product.Name, 'Product name should be updated.');
        }
    }

    @isTest
    static void testUpdateExternalData() {
        String name = 'Test';

        RestRequest request = new RestRequest();
        request.requestURI = '/Product/sync/';
        request.httpMethod = Constants.RestAPI.Method.POST;
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.headers.put('Content-Type', 'application/json');
        List<Product2> products = new List<Product2>();
        ProductTestDataBuilder productBuilder = new ProductTestDataBuilder().withName(name);
        for (Integer i = 0; i < 3; i++) {
            productBuilder.withExternalId('01tgL000004lJ' + i + 'tQAE');
            products.addAll((List<Product2>) new ProductTestDataFactory().buildData(1, productBuilder));
        }

        products = [SELECT Name, IsActive, ProductCode, Family, LastModifiedDate, ExternalId__c FROM Product2 WHERE Id IN :products];
        for (Product2 product : products) {
            product.Name = name + '_Updated';
            product.id = product.ExternalId__c;
            product.ExternalId__c = null;
        }
        Formula.recalculateFormulas(products);

        String body = createRequestBody(products, Constants.RestAPI.Method.PATCH);
        request.requestBody = Blob.valueOf(body);
        
        Test.startTest();
        ProductSyncREST.syncProducts();
        Test.stopTest();

        ProductSyncResponse.ResponseWrapper responseWrapper = (ProductSyncResponse.ResponseWrapper)JSON.deserialize(response.responseBody.toString(), ProductSyncResponse.ResponseWrapper.class);
        Assert.areEqual(1, responseWrapper.responseList.size(), 'ResponseList should have 1 item.');
        Assert.areEqual(200, responseWrapper.responseList.get(0).httpStatusCode, 'Response should have status code 200.');
        Assert.isTrue(responseWrapper.responseList.get(0).body.success, 'Response should have succeded.');
        Assert.areEqual(0, responseWrapper.responseList.get(0).body.errorMessages.size(), 'Response should not have error messages.');

        List<Product2> updatedProducts = [SELECT Id, Name FROM Product2];
        Assert.areEqual(3, updatedProducts.size(), 'Product list should have 3 items.');
        for (Product2 product : updatedProducts) { 
            Assert.areEqual(name + '_Updated', product.Name, 'Product name should be updated.');
        }
    }

    @isTest
    static void testUpdateLocalWithoutRecord() {
        String name = 'Test';

        RestRequest request = new RestRequest();
        request.requestURI = '/Product/sync/';
        request.httpMethod = Constants.RestAPI.Method.POST;
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.headers.put('Content-Type', 'application/json');
        List<Product2> products = new List<Product2> {
            (Product2)new ProductTestDataBuilder().withName(name).withExternalId('01tgL000004lJcrQAE').create()
        };
        Formula.recalculateFormulas(products);

        String body = createRequestBody(products, Constants.RestAPI.Method.PATCH);
        request.requestBody = Blob.valueOf(body);
        
        Test.startTest();
        ProductSyncREST.syncProducts();
        Test.stopTest();

        ProductSyncResponse.ResponseWrapper responseWrapper = (ProductSyncResponse.ResponseWrapper)JSON.deserialize(response.responseBody.toString(), ProductSyncResponse.ResponseWrapper.class);
        Assert.areEqual(1, responseWrapper.responseList.size(), 'ResponseList should have 1 item.');
        Assert.areEqual(400, responseWrapper.responseList.get(0).httpStatusCode, 'Response should have status code 400.');
        Assert.isFalse(responseWrapper.responseList.get(0).body.success, 'Response shouldn\'t have succeded.');
        Assert.areEqual(1, responseWrapper.responseList.get(0).body.errorMessages.size(), 'Response should have 1 error messages.');

        List<Product2> updatedProducts = [SELECT Id, Name FROM Product2];
        Assert.areEqual(0, updatedProducts.size(), 'Product list should be empty.');
    }

    private static String createRequestBody(List<Product2> products, String method) {
        ProductSyncRequest.BodyWrapper result = new ProductSyncRequest.BodyWrapper();
        List<ProductSyncRequest.RecordWrapper> records = new List<ProductSyncRequest.RecordWrapper>();
        for(Product2 product : products){
            ProductSyncRequest.RecordWrapper record = new ProductSyncRequest.RecordWrapper(product);
            records.add(record);
        }
        result.records = records;
        ProductSyncRequest.ItemWrapper requestItem = new ProductSyncRequest.ItemWrapper();
        requestItem.body = result;
        requestItem.body.method = method;
        ProductSyncRequest.RequestWrapper requestBody = new ProductSyncRequest.RequestWrapper();
        requestBody.requestList.add(requestItem);
        String body = JSON.serialize(requestBody);
        return body;
    }

    private class ProductTestDataBuilder extends BaseProductTestDataBuilder {
        public ProductTestDataBuilder withName(String name) {
            Product2 product = (Product2) this.record;
            product.Name = name;
            return this;
        }
        public ProductTestDataBuilder withExternalId(String externalId) {
            Product2 product = (Product2) this.record;
            product.ExternalId__c = externalId;
            return this;
        }
    }
}