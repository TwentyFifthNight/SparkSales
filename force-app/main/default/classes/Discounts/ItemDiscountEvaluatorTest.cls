@isTest
private class ItemDiscountEvaluatorTest {

    @isTest
    static void testEmptyDiscountList() {
        String strategy = Constants.Discount.STRATEGY_HIGHEST;
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();
        Test.startTest();
        List<ItemDiscountEvaluator.EvaluatedDiscount> result = ItemDiscountEvaluator.applyStrategy(discounts, strategy);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testInvalidStrategy() {
        String strategy = 'Nothing';
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 100));

        Test.startTest();
        try{
            List<ItemDiscountEvaluator.EvaluatedDiscount> result = ItemDiscountEvaluator.applyStrategy(discounts, strategy);
            System.assert(false, 'Expected DiscountException');
        } catch (DiscountException e) {
            System.assertEquals(System.Label.Unsuported_Discount_Strategy_Type + strategy, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testHighestStrategy() {
        String strategy = Constants.Discount.STRATEGY_HIGHEST;
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 100));
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 235));
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 57));
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 5));
        
        Test.startTest();
        List<ItemDiscountEvaluator.EvaluatedDiscount> result = ItemDiscountEvaluator.applyStrategy(discounts, strategy);
        Test.stopTest();
        System.assertEquals(1, result.size());
        System.Assert.areEqual(235, result[0].discountAmount);
    }

    @isTest
    static void testLowestStrategy() {
        String strategy = Constants.Discount.STRATEGY_LOWEST;
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 100));
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 235));
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 57));
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 5));
        
        Test.startTest();
        List<ItemDiscountEvaluator.EvaluatedDiscount> result = ItemDiscountEvaluator.applyStrategy(discounts, strategy);
        Test.stopTest();
        System.assertEquals(1, result.size());
        System.Assert.areEqual(5, result[0].discountAmount);
    }

    @isTest
    static void testCombinedStrategy() {
        String strategy = Constants.Discount.STRATEGY_COMBINED;
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 100));
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 235));
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 57));
        discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(new Discount__c(Name = 'Test'), 8));
        
        Test.startTest();
        List<ItemDiscountEvaluator.EvaluatedDiscount> result = ItemDiscountEvaluator.applyStrategy(discounts, strategy);
        Test.stopTest();
        System.assertEquals(4, result.size());
        Decimal total = 0;
        for (ItemDiscountEvaluator.EvaluatedDiscount item : result) {
            total += item.discountAmount;
        }
        System.Assert.areEqual(400, total);
    }
}