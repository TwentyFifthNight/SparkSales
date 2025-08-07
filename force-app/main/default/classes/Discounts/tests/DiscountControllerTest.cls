@isTest
private class DiscountControllerTest {

    @isTest
    static void testDiscountRecordCount() {
        createTestDiscounts();
        Test.startTest();
        Integer result = DiscountController.getRecordCount();
        Test.stopTest();
        System.assertEquals(30, result);
    }

    @isTest
    static void testGetDiscountRecords() {
        createTestDiscounts();
        Test.startTest();
        List<Discount__c> result = DiscountController.getRecordList(30, 0);
        Test.stopTest();
        System.assertEquals(30, result.size());
    }

    @isTest
    static void testGetDiscountRecordsWithNullRecordPerPage() {
        createTestDiscounts();
        Test.startTest();
        List<Discount__c> result = DiscountController.getRecordList(null, 0);
        Test.stopTest();
        System.assertEquals(10, result.size());
    }

    @isTest
    static void testGetDiscountRecordsWithNullOffset() {
        createTestDiscounts();
        Test.startTest();
        List<Discount__c> result = DiscountController.getRecordList(20, null);
        Test.stopTest();
        System.assertEquals(20, result.size());
    }

    @isTest
    static void testGetDiscountRecordsWithNoRecords() {
        Test.startTest();
        List<Discount__c> result = DiscountController.getRecordList(20, 0);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testGetDiscountRecordsWithOffset() {
        createTestDiscounts();
        Test.startTest();
        List<Discount__c> result = DiscountController.getRecordList(30, 10);
        Test.stopTest();
        System.assertEquals(20, result.size());
    }

    private static void createTestDiscounts() {
        List<Discount__c> discounts = new List<Discount__c>();
        for (Integer i = 0; i < 30; i++) {
            discounts.add((Discount__c) new DiscountTestDataBuilder().create());
        }
        insert discounts;
    }

    private class DiscountTestDataBuilder extends BaseDiscountTestDataBuilder {
        protected override void prepare(){
            super.prepare();
            Discount__c discount = (Discount__c) record;
            discount.Type__c = Constants.Discount.Type.SPECIAL;
            discount.Threshold_Amount__c = 100;
            discount.Amount_Type__c = Constants.Discount.AmountType.FIXED;
            discount.Amount__c = 10;
        }
    }
}