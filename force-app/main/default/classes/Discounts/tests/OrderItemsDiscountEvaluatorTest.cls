@isTest
private class OrderItemsDiscountEvaluatorTest {
    @testSetup
    static void setup(){
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Account account = (Account)new BaseAccountTestDataBuilder().create();
        insert account;

        List<Product2> products = ConstructProducts(5);
        insert products;

        List<PricebookEntry> pricebookEntries = ConstructPricebookEntries(products);
        insert pricebookEntries;

        Order order = (Order) new OrderTestDataBuilder()
            .withAccount(account)
            .create();
        insert order;

        List<OrderItem> orderItems = ConstructOrderItems(5, order, pricebookEntries);
        insert orderItems;
    }

    private static List<Product2> ConstructProducts(Integer count) {
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < count; i++) {
            Product2 product = (Product2) new ProductTestDataBuilder().create();
            products.add(product);
        }
        return products;
    }

    private static List<PricebookEntry> ConstructPricebookEntries(List<Product2> products) {
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for (Product2 product : products) {
            PricebookEntry entry = (PricebookEntry) new PricebookEntryTestDataBuilder().withProduct(product).create();
            pricebookEntries.add(entry);
        }
        return pricebookEntries;
    }

    private static List<OrderItem> ConstructOrderItems(Integer count, Order order, List<PricebookEntry> pricebookEntries) {
        List<OrderItem> orderItems = new List<OrderItem>();
        for (Integer i = 0; i < count; i++) {
            OrderItem oi = (OrderItem) new OrderItemTestDataBuilder()
                .withOrder(order)
                .withPricebookEntry(pricebookEntries[Math.mod(i, pricebookEntries.size())])
                .create();
            orderItems.add(oi);
        }
        return orderItems;
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

        List<Discount__c> timedDiscounts = CreateTestTimedPercentageDiscounts(true, 5, 5);
        insert timedDiscounts;
        timedDiscounts = CreateTestTimedPercentageDiscounts(false, 5, 5);
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
        System.assertEquals(5, appliedDiscounts.size(), 'Expected 5 applied discounts');
        System.assertEquals(2.5, totalDiscount, 'Expected total discount to be 2.5');
    }

    @isTest
    static void testInvalidTimedDiscount() {
        List<OrderItem> orderItems = [SELECT UnitPrice, Quantity, PricebookEntryId, Product2Id FROM OrderItem];
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Discount__c> timedDiscounts = CreateTestTimedPercentageDiscounts(false, 5, 5);
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
        System.assertEquals(0, appliedDiscounts.size(), 'Expected 0 applied discounts');
        System.assertEquals(0, totalDiscount, 'Expected total discount to be 0');
    }

    private static List<Discount__c> CreateTestTimedPercentageDiscounts(Boolean valid, Decimal value, Integer cnt) {
        Date startDate = Date.today().addDays(-2);
        Date endDate = Date.today().addDays(2);
        if (!valid) {
            startDate = Date.today().addDays(2);
            endDate = Date.today().addDays(5);
        }

        List<Product2> products = [SELECT Id FROM Product2];
        List<Discount__c> discounts = new List<Discount__c>();
        for (Integer i = 0; i < cnt; i++) {
            Discount__c discount = (Discount__c) new DiscountTestDataBuilder()
                .withProduct(products[Math.mod(i, products.size())])
                .withType(Constants.Discount.Type.TIMED)
                .withStartDate(startDate)
                .withEndDate(endDate)
                .withAmountType(Constants.Discount.AmountType.PERCENTAGE)
                .withPercentage(value)
                .create();
            discounts.add(discount);
        }
        return discounts;
    }

    private static List<Discount__c> CreateTestRecuringAmountDiscounts(Boolean valid, Decimal value, String recurrenceType, Integer cnt) {
        Date startDate = Date.today();
        if (!valid) {
            startDate = Date.today().addDays(2);
        }

        List<Product2> products = [SELECT Id FROM Product2];
        List<Discount__c> discounts = new List<Discount__c>();
        for (Integer i = 0; i < cnt; i++) {
            Discount__c discount = (Discount__c) new DiscountTestDataBuilder()
                .withProduct(products[Math.mod(i, products.size())])
                .withType(Constants.Discount.Type.RECURRING)
                .withRecurrenceType(recurrenceType)
                .withRecurrenceDate(startDate)
                .withAmountType(Constants.Discount.AmountType.FIXED)
                .withAmount(value)
                .create();
            discounts.add(discount);
        }
        return discounts;
    }

    private class DiscountTestDataBuilder extends BaseDiscountTestDataBuilder {
        protected override void prepare(){
            super.prepare();
            Discount__c discount = (Discount__c) record;
            discount.Pricebook__c = Constants.STANDARD_PRICEBOOK_ID;
            discount.isActive__c = true;
        }

        public DiscountTestDataBuilder withProduct(Product2 product) {
            Discount__c discount = (Discount__c) record;
            discount.Product__c = product.Id;
            return this;
        }

        public DiscountTestDataBuilder withType(String type) {
            Discount__c discount = (Discount__c) record;
            discount.Type__c = type;
            return this;
        }

        public DiscountTestDataBuilder withAmountType(String amountType) {
            Discount__c discount = (Discount__c) record;
            discount.Amount_Type__c = amountType;
            return this;
        }

        public DiscountTestDataBuilder withPercentage(Decimal percentage) {
            Discount__c discount = (Discount__c) record;
            discount.Percentage__c = percentage;
            return this;
        }

        public DiscountTestDataBuilder withAmount(Decimal amount) {
            Discount__c discount = (Discount__c) record;
            discount.Amount__c = amount;
            return this;
        }

        public DiscountTestDataBuilder withStartDate(Date startDate) {
            Discount__c discount = (Discount__c) record;
            discount.Start_Date__c = startDate;
            return this;
        }

        public DiscountTestDataBuilder withEndDate(Date endDate) {
            Discount__c discount = (Discount__c) record;
            discount.End_Date__c = endDate;
            return this;
        }

        public DiscountTestDataBuilder withRecurrenceType(String recurrenceType) {
            Discount__c discount = (Discount__c) record;
            discount.Recurrence_Type__c = recurrenceType;
            return this;
        }

        public DiscountTestDataBuilder withRecurrenceDate(Date dateValue) {
            Discount__c discount = (Discount__c) record;
            discount.Recurrence_Day_Of_Month__c = dateValue.day();
            discount.Recurrence_Month_Of_Year__c = dateValue.month();
            return this;
        }
    }

    private class ProductTestDataBuilder extends BaseProductTestDataBuilder {
        protected override void prepare(){
            super.prepare();
            Product2 product = (Product2) record;
            product.IsActive = true;
        }
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
}