@isTest
private class ProductSearchControllerTest {

    @TestSetup
    static void setup(){
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        List<String> familyNames = new List<String>{
            Constants.Product.ADAPTERS_FAMILY,
            Constants.Product.NETWORKING_FAMILY,
            Constants.Product.CABLES_FAMILY
        };

        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 30; i++){
            products.add(new Product2(Name = 'Product ' + i, ProductCode = 'Test ' + i, Family = familyNames[Math.mod(i, familyNames.size())], IsActive = true));
        }
        insert products;

        List<PricebookEntry> pricebookEntries = ConstructPricebookEntries(products);
        insert pricebookEntries;

        Account account = new Account(Name = 'Account');
        insert account;
        List<Opportunity> opportunities = new List<Opportunity>();
        for(Integer i = 0; i < 2; i++){
            Opportunity opportunity = new Opportunity(AccountId = account.Id, Name = 'Opportunity ' + i, Type = 'New Business', Amount = 1000, StageName = 'Qualification', CloseDate = System.today(), Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID);
            opportunities.add(opportunity);
        }
        insert opportunities;

        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        for(Integer i = 0; i < 16; i++){
            OpportunityLineItem opportunityLineItem = new OpportunityLineItem(OpportunityId = opportunities[Math.mod(i, 2)].Id, Product2Id = products[i].Id, Quantity = 5, UnitPrice = 10);
            opportunityLineItems.add(opportunityLineItem);
        }
        insert opportunityLineItems;
    }

    private static List<PricebookEntry> ConstructPricebookEntries(List<Product2> products){
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for(Product2 product : products){
            PricebookEntry entry = new PricebookEntry();
            entry.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
            entry.Product2Id = product.Id;
            entry.IsActive = true;
            entry.UnitPrice = 100;
            pricebookEntries.add(entry);
        }
        return pricebookEntries;
    }

    @isTest
    static void testProductCountWithoutParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        Test.startTest();
        Integer count = ProductSearchController.getRecordCount(wrapper);
        Test.stopTest();
        System.assertEquals(30, count);
    }

    @isTest
    static void testProductCountWithoutFamily() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'Product 1';
        Test.startTest();
        Integer count = ProductSearchController.getRecordCount(wrapper);
        Test.stopTest();
        System.assertEquals(11, count);
    }

    @isTest
    static void testProductCountWithAllParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'est';
        wrapper.family = Constants.Product.ADAPTERS_FAMILY;
        Test.startTest();
        Integer count = ProductSearchController.getRecordCount(wrapper);
        Test.stopTest();
        System.assertEquals(10, count);
    }

    @isTest
    static void testProductListWithoutParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(10, products.size());
    }

    @isTest
    static void testProductListWithRecordLimit() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        wrapper.recordsPerPage = 35;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(30, products.size());
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
        System.assertEquals(25, products.size());
    }

    @isTest
    static void testProductListWithoutFamily() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'Test 1';
        wrapper.recordsPerPage = 30;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(11, products.size());
    }

    @isTest
    static void testProductListWithAllParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'est';
        wrapper.family = Constants.Product.ADAPTERS_FAMILY;
        wrapper.recordsPerPage = 30;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(10, products.size());
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
        System.assertEquals(10, products.size());
    }

    @isTest
    static void testOpportunityProducts() {
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Product2> opportunityProducts = ProductSearchController.getOpportunityProducts(opportunities[0].Id);
        Test.stopTest();
        System.assertEquals(8, opportunityProducts.size());
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
        System.assertEquals(10, orderItemsList.size());
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
        System.assertEquals(8, orderItems.size());
        for(ProductSearchController.OrderItemWrapper orderItem : orderItems){
            System.assertEquals(5, orderItem.quantity);
            System.assertEquals(10, orderItem.unitPrice);
        }
    }
}