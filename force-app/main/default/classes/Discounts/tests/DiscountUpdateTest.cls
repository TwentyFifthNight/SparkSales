@isTest
private class DiscountUpdateTest {

    @testSetup
    static void setup() {
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Discount__c discount = (Discount__c)new DiscountTestDataBuilder().create();
        insert discount;
        
        Account account = (Account)new BaseAccountTestDataBuilder().create();
        insert account;

        Order order = (Order)new OrderTestDataBuilder()
            .withAccount(account)
            .create();
        insert order;
    }

    @isTest
    static void testUpdateOnNotUsedDiscount () {
        Discount__c discount = [SELECT Name FROM Discount__c WHERE Name = 'Test Discount' LIMIT 1];
        discount.Name = 'Updated Discount Name';
        Test.startTest();
        update discount;
        Test.stopTest();
        Discount__c updatedDiscount = [SELECT Name FROM Discount__c WHERE Id = :discount.Id];
        Assert.areEqual('Updated Discount Name', updatedDiscount.Name);
    }

    @isTest
    static void testUpdateOnUsedDiscount() {

        Order order = [SELECT Name FROM Order WHERE Name = 'Test Order' LIMIT 1];
        Discount__c discount = [SELECT Name FROM Discount__c WHERE Name = 'Test Discount' LIMIT 1];
        OrderDiscount__c orderDiscount = (OrderDiscount__c)new OrderDiscountTestDataBuilder()
            .withOrder(order)
            .withDiscount(discount)
            .create();
        insert orderDiscount;

        discount.Name = 'Updated Discount Name';
        Test.startTest();
        try {
            update discount;
            Assert.fail('Expected DiscountException');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains(System.Label.Restrict_Used_Discount_Edit_Error), 'Expected error message not found: ' + e.getMessage());
        }
        Test.stopTest();
        Discount__c updatedDiscount = [SELECT Id, Name FROM Discount__c WHERE Id = :discount.Id];
        Assert.areNotEqual('Updated Discount Name', updatedDiscount.Name, 'Discount name should not be updated when used in an order');
    }

    @isTest
    static void testUpdateActiveOnUsedDiscount() {

        Order order = [SELECT Name FROM Order WHERE Name = 'Test Order' LIMIT 1];
        Discount__c discount = [SELECT Name FROM Discount__c WHERE Name = 'Test Discount' LIMIT 1];
        OrderDiscount__c orderDiscount = (OrderDiscount__c)new OrderDiscountTestDataBuilder()
            .withOrder(order)
            .withDiscount(discount)
            .create();
        insert orderDiscount;

        discount.isActive__c = true;
        Test.startTest();
        try {
            update discount;
        } catch (DmlException e) {
            Assert.fail('Expected no exception, but got: ' + e.getMessage());
        }
        Test.stopTest();
        Discount__c updatedDiscount = [SELECT isActive__c FROM Discount__c WHERE Id = :discount.Id];
        Assert.areEqual(true, updatedDiscount.isActive__c, 'Discount should be active after update');
    }

    private class DiscountTestDataBuilder extends TestDataBuilder {
        public DiscountTestDataBuilder() {
            record = new Discount__c();
        }
        
        protected override void prepare(){
            Discount__c discount = (Discount__c) record;
            discount.Name = 'Test Discount';
            discount.Type__c = Constants.Discount.Type.TIMED;
            discount.Start_Date__c = System.today();
            discount.End_Date__c = System.today().addDays(30);
            discount.Threshold_Amount__c = 100;
            discount.Amount_Type__c = Constants.Discount.AmountType.PERCENTAGE;
            discount.Percentage__c = 10;
        }
    }

    private class OrderDiscountTestDataBuilder extends BaseOrderDiscountTestDataBuilder {
        protected override void prepare(){
            super.prepare();
            OrderDiscount__c orderDiscount = (OrderDiscount__c) record;
            orderDiscount.Discount_Amount__c = 10;
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
}