@isTest
private class ProductComplaintServiceTest {

    @testSetup
    static void setup(){
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        List<Product2> products = (List<Product2>)new ProductTestDataFactory().buildData(6, new BaseProductTestDataBuilder());
        Account account = (Account)new BaseAccountTestDataBuilder().create();
        insert account;
        List<Order> orders = (List<Order>)new TestDataFactory().buildData(2, new OrderTestDataBuilder().withAccount(account));

        List<PricebookEntry> pricebookEntries = createPricebookEntries(products);

        List<OrderItem> orderProducts = new List<OrderItem>();
        for (Integer i = 0; i < pricebookEntries.size(); i++) {
            OrderItem orderProduct = (OrderItem)new OrderItemTestDataBuilder().withOrder(orders[Math.mod(i, orders.size())]).withPricebookEntry(pricebookEntries[i]).create();
            orderProducts.add(orderProduct);
        }
        insert orderProducts;
    }

    private static List<PricebookEntry> createPricebookEntries(List<Product2> products) {
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for (Product2 product : products) {
            PricebookEntry entry = (PricebookEntry)new PricebookEntryTestDataBuilder().withProduct(product).create();
            pricebookEntries.add(entry);
        }
        insert pricebookEntries;
        return pricebookEntries;
    }

    @isTest
    static void testGetProducts() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        List<OrderItem> items = [SELECT Id FROM OrderItem WHERE orderId = :order.Id];
        Test.startTest();
        List<Product2> products = ProductComplaintService.getProducts(order.Id);
        Assert.areEqual(items.size(), products.size());
        Test.stopTest();
    }

    @isTest
    static void testGetProducts_EmptyOrder() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Order order = (Order)new OrderTestDataBuilder().withAccount(account).create();
        Test.startTest();
        List<Product2> products = ProductComplaintService.getProducts(order.Id);
        Assert.areEqual(0, products.size());
        Test.stopTest();
    }

    @isTest
    static void testSubmitComplaints() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        List<OrderItem> items = [SELECT Product2Id FROM OrderItem WHERE orderId = :order.Id];
        List<Id> productIds = new List<Id>();
        for (OrderItem item : items) {
            productIds.add(item.Product2Id);

        }
        Test.startTest();
        ProductComplaintController.ComplaintResult result = ProductComplaintService.submitComplaints(productIds, order.Id);
        Assert.isNotNull(result.trackingId);
        Assert.areEqual('SUCCESS', result.status);
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WHERE Id = :result.trackingId];
        Assert.areEqual(1, cases.size());
        List<ComplaintItem__c> complaintItems = [SELECT Id, Status__c FROM ComplaintItem__c WHERE Case__c = :result.trackingId];
        Assert.areEqual(items.size(), complaintItems.size());
    }

    @isTest
    static void testSubmitDuplicateComplaints() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        List<OrderItem> items = [SELECT Product2Id FROM OrderItem WHERE orderId = :order.Id];
        List<Id> productIds = new List<Id>();
        for (OrderItem item : items) {
            productIds.add(item.Product2Id);

        }
        Test.startTest();
        ProductComplaintController.ComplaintResult result = ProductComplaintService.submitComplaints(productIds, order.Id);
        try {
            ProductComplaintService.submitComplaints(productIds, order.Id);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (Exception e) {
            Assert.areEqual(System.Label.duplicateComplaintError, e.getMessage(), 'Unexpected exception message');
        }
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WHERE Id = :result.trackingId];
        Assert.areEqual(1, cases.size());
        List<ComplaintItem__c> complaintItems = [SELECT Id, Status__c FROM ComplaintItem__c WHERE Case__c = :result.trackingId];
        Assert.areEqual(items.size(), complaintItems.size());
    }

    @isTest
    static void testSubmitExternalComplaints() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        Product2 externalProduct = prepareExternalProduct();

        Test.setMock(HttpCalloutMock.class, new ExternalComplaintEventMock());
        Test.startTest();
        ProductComplaintController.ComplaintResult result = ProductComplaintService.submitComplaints(new List<Id>{ externalProduct.Id }, order.Id);
        Assert.isNotNull(result.trackingId);
        Assert.areEqual('PENDING', result.status);
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WHERE Id = :result.trackingId];
        Assert.areEqual(1, cases.size());
        List<ComplaintItem__c> complaintItems = [SELECT Id, Status__c FROM ComplaintItem__c WHERE Case__c = :result.trackingId];
        Assert.areEqual(1, complaintItems.size());
    }

    private static Product2 prepareExternalProduct() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        Product2 externalProduct = (Product2)new ExternalProductTetsDataBuilder().withExternalId('01tgL000004DWahQWG').create();
        insert externalProduct;
        PricebookEntry externalPbe = (PricebookEntry)new PricebookEntryTestDataBuilder().withProduct(externalProduct).create();
        insert externalPbe;
        OrderItem externalOrderItem = (OrderItem)new OrderItemTestDataBuilder().withOrder(order).withPricebookEntry(externalPbe).create();
        insert externalOrderItem;

        return externalProduct;
    }

    private class PricebookEntryTestDataBuilder extends BasePricebookEntryTestDataBuilder {
        protected override void prepare(){
            super.prepare();
            PricebookEntry entry = (PricebookEntry) record;
            entry.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
            entry.UnitPrice = 1;
            entry.IsActive = true;
        }
    }

    private class OrderTestDataBuilder extends BaseOrderTestDataBuilder {
        protected override void prepare(){
            super.prepare();
            Order order = (Order) record;
            order.Status = Constants.Order.Status.DRAFT;
            order.EffectiveDate = System.today();
            order.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
        }
    }

    private class OrderItemTestDataBuilder extends BaseOrderItemTestDataBuilder {
        protected override void prepare(){
            super.prepare();
            OrderItem orderItem = (OrderItem) record;
            orderItem.Quantity = 1;
            orderItem.UnitPrice = 10;
        }
    }

    private class ExternalProductTetsDataBuilder extends BaseProductTestDataBuilder {
        public ExternalProductTetsDataBuilder withExternalId(String externalId) {
            Product2 product = (Product2) record;
            product.ExternalId__c = externalId;
            return this;
        }
    }
}