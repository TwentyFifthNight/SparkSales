@isTest
private class OrderItemsDiscountEvaluatorTest {
    @testSetup
    static void setup(){
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        List<Product2> products = TestDataFactory.ConstructProducts(5);
        insert products;

        List<PricebookEntry> pricebookEntries = TestDataFactory.ConstructPricebookEntries(products);
        insert pricebookEntries;

        Order order = new Order();
        order.Name = 'TestOrder';
        order.Status = 'Draft';
        order.AccountId = acc.Id;
        order.EffectiveDate = System.today();
        order.Pricebook2Id = standardPricebook.Id;
        insert order;

        List<OrderItem> orderItems = TestDataFactory.ConstructOrderItems(5, order, pricebookEntries);
        insert orderItems;
    }

    @isTest
    static void testEmptyOrderItemList() {
        List<OrderItem> orderItems = new List<OrderItem>();
        Id pricebookId = Test.getStandardPricebookId();
        Test.startTest();
        List<OrderItemsDiscountEvaluator.ItemDiscountResult> result = OrderItemsDiscountEvaluator.Evaluate(orderItems, pricebookId);
        Test.stopTest();
        System.Assert.areEqual(0, result.size());
    }

    @isTest
    static void testPercentageDiscount() {
        List<OrderItem> orderItems = [SELECT UnitPrice, Quantity, PricebookEntryId, Product2Id FROM OrderItem];

        Id pricebookId = Test.getStandardPricebookId();

        List<Discount__c> timedDiscounts = CreateTestTimedDiscounts(true, 'Percentage', 5, 5);
        insert timedDiscounts;
        timedDiscounts = CreateTestTimedDiscounts(false, 'Percentage', 5, 5);
        insert timedDiscounts;

        Test.startTest();
        List<OrderItemsDiscountEvaluator.ItemDiscountResult> result = OrderItemsDiscountEvaluator.Evaluate(orderItems, pricebookId);
        Test.stopTest();

        List<ItemDiscountEvaluator.EvaluatedDiscount> appliedDiscounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();
        Decimal totalDiscount = 0;
        for (OrderItemsDiscountEvaluator.ItemDiscountResult resultItem : result) {
            for (ItemDiscountEvaluator.EvaluatedDiscount appliedDiscount : resultItem.appliedDiscounts) {
                appliedDiscounts.add(appliedDiscount);
            }
            totalDiscount += resultItem.totalDiscount;
        }
        System.assertEquals(5, appliedDiscounts.size());
        System.assertEquals(2.5, totalDiscount);
    }

    @isTest
    static void testInvalidTimedDiscount() {
        List<OrderItem> orderItems = [SELECT UnitPrice, Quantity, PricebookEntryId, Product2Id FROM OrderItem];

        Id pricebookId = Test.getStandardPricebookId();
        List<Discount__c> timedDiscounts = CreateTestTimedDiscounts(false, 'Percentage', 5, 5);
        insert timedDiscounts;

        Test.startTest();
        List<OrderItemsDiscountEvaluator.ItemDiscountResult> result = OrderItemsDiscountEvaluator.Evaluate(orderItems, pricebookId);
        Test.stopTest();

        List<ItemDiscountEvaluator.EvaluatedDiscount> appliedDiscounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();
        Decimal totalDiscount = 0;
        for (OrderItemsDiscountEvaluator.ItemDiscountResult resultItem : result) {
            for (ItemDiscountEvaluator.EvaluatedDiscount appliedDiscount : resultItem.appliedDiscounts) {
                appliedDiscounts.add(appliedDiscount);
            }
            totalDiscount += resultItem.totalDiscount;
        }
        System.assertEquals(0, appliedDiscounts.size());
        System.assertEquals(0, totalDiscount);
    }

    private static List<Discount__c> CreateTestTimedDiscounts(Boolean valid, String amountType, Decimal value, Integer cnt) {
        List<Product2> products = [SELECT Id FROM Product2];
        
        Id pricebookId = Constants.STANDARD_PRICEBOOK_ID;
        Date startDate = Date.today().addDays(-2);
        Date endDate = Date.today().addDays(2);
        if (!valid) {
            startDate = Date.today().addDays(2);
            endDate = Date.today().addDays(5);
        }

        List<Discount__c> discounts = new List<Discount__c>();
        for (Integer i = 0; i < cnt; i++) {
            Discount__c discount = new Discount__c();
            discount.Pricebook__c = pricebookId;
            discount.Product__c = products[Math.mod(i, products.size())].Id;
            discount.Type__c = 'Timed';
            discount.Start_Date__c = startDate;
            discount.End_Date__c = endDate;
            discount.Name = 'Test';
            discount.Amount_Type__c = amountType;
            if (amountType == 'Percentage') {
                discount.Percentage__c = value;
            } else {
                discount.Amount__c = value;
            }
            discount.isActive__c = true;
            discounts.add(discount);
        }
        return discounts;
    }

    private static List<Discount__c> CreateTestRecuringDiscounts(Boolean valid, String amountType, Decimal value, String recurrenceType, Integer cnt) {
        List<Product2> products = [SELECT Id FROM Product2];
        Id pricebookId = Test.getStandardPricebookId();
        Date startDate = Date.today();
        if (!valid) {
            startDate = Date.today().addDays(2);
        }

        List<Discount__c> discounts = new List<Discount__c>();
        for (Integer i = 0; i < cnt; i++) {
            Discount__c discount = new Discount__c();
            discount.Pricebook__c = pricebookId;
            discount.Product__c = products[Math.mod(i, products.size())].Id;
            discount.Type__c = 'Recurring';
            discount.Recurrence_Type__c = recurrenceType;
            discount.Recurrence_Day_Of_Month__c = String.valueOf(startDate.day());
            discount.Recurrence_Month_Of_Year__c = String.valueOf(startDate.month());
            discount.Name = 'Test';
            discount.Amount_Type__c = amountType;
            discount.Percentage__c = value;
            discount.isActive__c = true;
            discounts.add(discount);
        }
        return discounts;
    }
}