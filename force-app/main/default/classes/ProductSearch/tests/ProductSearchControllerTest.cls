@isTest
private class ProductSearchControllerTest {
    
    @TestSetup
    static void setup(){
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        List<String> familyNames = new List<String>{
            Constants.Product.Family.ADAPTERS,
            Constants.Product.Family.NETWORKING,
            Constants.Product.Family.CABLES
        };

        List<Product2> products = constructProducts(30, familyNames);
        insert products;

        List<PricebookEntry> pricebookEntries = constructPricebookEntries(products);
        insert pricebookEntries;

        Account account = (Account)new BaseAccountTestDataBuilder().create();
        insert account;

        List<Opportunity> opportunities = constructOpportunities(2, account);
        insert opportunities;

        List<OpportunityLineItem> opportunityLineItems = constructOpportunityLineItems(16, opportunities, products);
        insert opportunityLineItems;
    }

    private static List<Product2> constructProducts(Integer count, List<String> familyNames) {
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < count; i++) {
            Product2 product = (Product2)new ProductTestDataBuilder()
                .withName('Product ' + i)
                .withCode('Test ' + i)
                .withFamily(familyNames[Math.mod(i, familyNames.size())])
                .create();
            products.add(product);
        }
        return products;
    }

    private static List<PricebookEntry> constructPricebookEntries(List<Product2> products){
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for(Product2 product : products){
            PricebookEntry entry = (PricebookEntry)new PricebookEntryTestDataBuilder()
                .withProduct(product)
                .create();
            pricebookEntries.add(entry);
        }
        return pricebookEntries;
    }

    private static List<Opportunity> constructOpportunities(Integer count, Account account) {
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            Opportunity opportunity = (Opportunity)new OpportunityTestDataBuilder()
                .withAccount(account)
                .create();
            opportunities.add(opportunity);
        }
        return opportunities;
    }

    private static List<OpportunityLineItem> constructOpportunityLineItems(Integer count, List<Opportunity> opportunities, List<Product2> products) {
        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        for (Integer i = 0; i < count; i++) {
            OpportunityLineItem lineItem = (OpportunityLineItem)new OpportunityLineItemTestDataBuilder()
                .withOpportunity(opportunities[Math.mod(i, opportunities.size())])
                .withProduct(products[Math.mod(i, products.size())])
                .create();
            opportunityLineItems.add(lineItem);
        }
        return opportunityLineItems;
    }

    @isTest
    static void testProductCountWithoutParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        Test.startTest();
        Integer count = ProductSearchController.getRecordCount(wrapper);
        Test.stopTest();
        System.assertEquals(30, count, 'Expected product count to be 30 without any parameters');
    }

    @isTest
    static void testProductCountWithoutFamily() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'Product 1';
        Test.startTest();
        Integer count = ProductSearchController.getRecordCount(wrapper);
        Test.stopTest();
        System.assertEquals(11, count, 'Expected product count to be 11 for name "Product 1" without family filter');
    }

    @isTest
    static void testProductCountWithAllParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'est';
        wrapper.family = Constants.Product.Family.ADAPTERS;
        Test.startTest();
        Integer count = ProductSearchController.getRecordCount(wrapper);
        Test.stopTest();
        System.assertEquals(10, count, 'Expected product count to be 10 with name "est" and family "Adapters"');
    }

    @isTest
    static void testProductListWithoutParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(10, products.size(), 'Expected product list size to be 10 without any parameters');
    }

    @isTest
    static void testProductListWithRecordLimit() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        wrapper.recordsPerPage = 35;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(30, products.size(), 'Expected product list size to return all (30) records with recordsPerPage set to 35');
    }

    @isTest
    static void testProductListWithOffset() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        wrapper.offset = 5;
        wrapper.recordsPerPage = 30;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(25, products.size(), 'Expected product list size to be 25 with offset of 5 and recordsPerPage of 30');
    }

    @isTest
    static void testProductListWithoutFamily() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'Test 1';
        wrapper.recordsPerPage = 30;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(11, products.size(), 'Expected product list size to be 11 for name "Test 1" without family filter');
    }

    @isTest
    static void testProductListWithAllParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'est';
        wrapper.family = Constants.Product.Family.ADAPTERS;
        wrapper.recordsPerPage = 30;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(10, products.size(), 'Expected product list size to be 10 with name "est" and family "Adapters"');
    }

    @isTest
    static void testProductListWithInvalidPaginationParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        wrapper.offset = -1;
        wrapper.recordsPerPage = null;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(10, products.size(), 'Expected product list size to be 10 with invalid pagination parameters');
    }

    @isTest
    static void testOpportunityProducts() {
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Product2> opportunityProducts = ProductSearchController.getOpportunityProducts(opportunities[0].Id);
        Test.stopTest();
        System.assertEquals(8, opportunityProducts.size(), 'Expected 8 products associated with the opportunity');
    }

    @isTest
    static void testCreateNewOrder() {
        List<ProductSearchController.OrderItemWrapper> orderItems = new List<ProductSearchController.OrderItemWrapper>();
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 10];
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity LIMIT 1];
        
        for (Product2 product : products){
            ProductSearchController.OrderItemWrapper orderItem = new ProductSearchController.OrderItemWrapper();
            orderItem.product2Id = product.Id;
            orderItem.quantity = 1;
            orderItem.unitPrice = 15;
            orderItems.add(orderItem);
        }

        Test.startTest();
        Id orderId = ProductSearchController.createNewOrder(orderItems, opportunities[0].Id);
        Test.stopTest();
        List<OrderItem> orderItemsList = [SELECT Id FROM OrderItem WHERE OrderId = :orderId];
        System.assertEquals(10, orderItemsList.size(), 'Expected 10 order items to be created for the new order');
    }

    @isTest
    static void testNewOrderItemList() {
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityLineItem> opportunityLineItems = [SELECT Product2Id FROM OpportunityLineItem WHERE OpportunityId = :opportunities[0].Id];
        
        Set<Id> opportunityLineItemProductIds = new Set<Id>();
        for (OpportunityLineItem opportunityLineItem : opportunityLineItems){
            opportunityLineItemProductIds.add(opportunityLineItem.Product2Id);
        }
        List<Product2> products = [SELECT Id, Name FROM Product2 WHERE Id IN :opportunityLineItemProductIds];
        
        Test.startTest();
        List<ProductSearchController.OrderItemWrapper> orderItems = ProductSearchController.generateOrderItemsFromProducts(products, opportunities[0].Id);
        Test.stopTest();
        System.assertEquals(8, orderItems.size(), 'Expected 8 order items to be generated from products associated with the opportunity');
        for(ProductSearchController.OrderItemWrapper orderItem : orderItems){
            System.assertEquals(5, orderItem.quantity, 'Expected each order item to have a quantity of 5');
            System.assertEquals(10, orderItem.unitPrice, 'Expected each order item to have a unit price of 10');
        }
    }

    private class ProductTestDataBuilder extends BaseProductTestDataBuilder {
        protected override void prepare() {
            super.prepare();
            Product2 product = (Product2) record;
            product.IsActive = true;
        }

        public ProductTestDataBuilder withFamily(String family) {
            Product2 product = (Product2) record;
            product.Family = family;
            return this;
        }

        public ProductTestDataBuilder withName(String name) {
            Product2 product = (Product2) record;
            product.Name = name;
            return this;
        }

        public ProductTestDataBuilder withCode(String code) {
            Product2 product = (Product2) record;
            product.ProductCode = code;
            return this;
        }
    }

    private class PricebookEntryTestDataBuilder extends BasePricebookEntryTestDataBuilder {
        protected override void prepare() {
            super.prepare();
            PricebookEntry entry = (PricebookEntry) record;
            entry.UnitPrice = 100;
            entry.IsActive = true;
            entry.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
        }
    }

    private class OpportunityTestDataBuilder extends BaseOpportunityTestDataBuilder {
        protected override void prepare() {
            super.prepare();
            Opportunity opportunity = (Opportunity) record;
            opportunity.Type = Constants.Opportunity.Type.NEW_BUSINESS;
            opportunity.StageName = Constants.Opportunity.StageName.QUALIFICATION;
            opportunity.CloseDate = System.today();
            opportunity.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
            opportunity.Amount = 1000;
        }
    }

    private class OpportunityLineItemTestDataBuilder extends BaseOpportunityLineItemTestDataBuilder {
        protected override void prepare() {
            super.prepare();
            OpportunityLineItem lineItem = (OpportunityLineItem) record;
            lineItem.Quantity = 5;
            lineItem.UnitPrice = 10;
        }
    }
}