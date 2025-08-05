@isTest
private class DiscountUpdateTest {

    @testSetup
    static void setup() {
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Discount__c discount = new Discount__c(
            Name = 'Test Discount',
            Amount_Type__c = Constants.Discount.PERCENTAGE_AMOUNT_TYPE,
            Percentage__c = 10,
            Type__c = Constants.Discount.TIMED_TYPE,
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(30)
        );
        insert discount;
        
        Account account = new Account(Name = 'Test Account');
        insert account;

        Order order = new Order(
            Name = 'Test Order',
            Status = Constants.Order.STATUS_DRAFT,
            AccountId = account.Id,
            EffectiveDate = System.today(),
            Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID
        );
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
        System.assertEquals('Updated Discount Name', updatedDiscount.Name);
    }

    @isTest
    static void testUpdateOnUsedDiscount() {

        Order order = [SELECT Name FROM Order WHERE Name = 'Test Order' LIMIT 1];
        Discount__c discount = [SELECT Name FROM Discount__c WHERE Name = 'Test Discount' LIMIT 1];
        OrderDiscount__c orderDiscount = new OrderDiscount__c(
            Order__c = order.Id,
            Discount__c = discount.Id,
            Discount_Amount__c = 10,
            Name = 'Test Order Discount'
        );
        insert orderDiscount;

        discount.Name = 'Updated Discount Name';
        Test.startTest();
        try {
            update discount;
            System.assert(false, 'Expected DiscountException');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains(System.Label.Restrict_Used_Discount_Edit_Error), 'Expected error message not found: ' + e.getMessage());
        }
        Test.stopTest();
        Discount__c updatedDiscount = [SELECT Id, Name FROM Discount__c WHERE Id = :discount.Id];
        System.assertNotEquals('Updated Discount Name', updatedDiscount.Name, 'Discount name should not be updated when used in an order');
    }

    @isTest
    static void testUpdateActiveOnUsedDiscount() {

        Order order = [SELECT Name FROM Order WHERE Name = 'Test Order' LIMIT 1];
        Discount__c discount = [SELECT Name FROM Discount__c WHERE Name = 'Test Discount' LIMIT 1];
        OrderDiscount__c orderDiscount = new OrderDiscount__c(
            Order__c = order.Id,
            Discount__c = discount.Id,
            Discount_Amount__c = 10,
            Name = 'Test Order Discount'
        );
        insert orderDiscount;

        discount.isActive__c = true;
        Test.startTest();
        try {
            update discount;
            System.assert(true, 'Update should not throw an exception');
        } catch (DmlException e) {
            System.assert(false, 'Expected no exception, but got: ' + e.getMessage());
        }
        Test.stopTest();
        Discount__c updatedDiscount = [SELECT isActive__c FROM Discount__c WHERE Id = :discount.Id];
        System.assertEquals(true, updatedDiscount.isActive__c, 'Discount should be active after update');
    }
}