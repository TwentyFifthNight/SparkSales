@isTest
private class ItemDiscountEvaluatorTest {

    @isTest
    static void testEmptyDiscountList() {
        String strategy = Constants.Discount.strategy.HIGHEST;
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();
        Test.startTest();
        List<ItemDiscountEvaluator.EvaluatedDiscount> result = ItemDiscountEvaluator.applyStrategy(discounts, strategy);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testInvalidStrategy() {
        String strategy = 'Nothing';
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = createTestDiscounts(new List<Decimal>{100, 200});

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
        String strategy = Constants.Discount.strategy.HIGHEST;
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = createTestDiscounts(new List<Decimal>{100, 235, 57, 5});
        
        Test.startTest();
        List<ItemDiscountEvaluator.EvaluatedDiscount> result = ItemDiscountEvaluator.applyStrategy(discounts, strategy);
        Test.stopTest();
        System.assertEquals(1, result.size());
        System.Assert.areEqual(235, result[0].discountAmount);
    }

    @isTest
    static void testLowestStrategy() {
        String strategy = Constants.Discount.strategy.LOWEST;
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = createTestDiscounts(new List<Decimal>{100, 235, 57, 5});
        
        Test.startTest();
        List<ItemDiscountEvaluator.EvaluatedDiscount> result = ItemDiscountEvaluator.applyStrategy(discounts, strategy);
        Test.stopTest();
        System.assertEquals(1, result.size());
        System.Assert.areEqual(5, result[0].discountAmount);
    }

    @isTest
    static void testCombinedStrategy() {
        String strategy = Constants.Discount.strategy.COMBINED;
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = createTestDiscounts(new List<Decimal>{100, 235, 57, 8});
        
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

    private static List<ItemDiscountEvaluator.EvaluatedDiscount> createTestDiscounts(List<Decimal> amounts) {
        List<ItemDiscountEvaluator.EvaluatedDiscount> discounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();
        for (Decimal amount : amounts) {
            Discount__c discount = (Discount__c)new BaseDiscountTestDataBuilder().create();
            discounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(discount, amount));
        }
        return discounts;
    }
}