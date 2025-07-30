@isTest
private class SignatureControllerTest {
    @TestSetup
    static void setup(){
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        TestDataFactory.insertTestData(5);

        Account account = new Account(Name = 'Account');
        insert account;

        Contract contract = new Contract(
            Status = 'Draft',
            AccountId = account.Id,
            StartDate = Date.today(),
            ContractTerm = 12
        );
        insert contract;

        Order order = new Order(
            Status = 'Draft',
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            ContractId = contract.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert order;

        contract.Status = 'Activated';
        update contract;

        PricebookEntry entry = [SELECT Id FROM PricebookEntry LIMIT 1];
        OrderItem orderItem = new OrderItem(OrderId = order.Id, Quantity = 1, PricebookEntryId=entry.Id, UnitPrice=10);
        insert orderItem;
    }

    @isTest
    static void testSigningInvoice() {
        Order order = [SELECT Id, Status FROM Order LIMIT 1];
        Test.startTest();
        order.Status = 'Activated';
        update order;

        SignatureController.saveSignature('ssdbfsdfg34q4', order.Id);
        Test.stopTest();
        List<ContentVersion> orderFiles = [SELECT ContentDocumentId, PathOnClient, Title, FileExtension FROM ContentVersion WHERE FirstPublishLocationId = :order.Id];
        System.assertEquals(1, orderFiles.size());
        System.assertEquals('pdf', orderFiles[0].FileExtension);
    }

    @isTest
    static void testSigningInvoiceWithoutPdf() {
        Order order = [SELECT Id, Status FROM Order LIMIT 1];
        Test.startTest();
        SignatureController.saveSignature('ssdbfsdfg34q4', order.Id);
        Test.stopTest();
        List<ContentVersion> orderFiles = [SELECT ContentDocumentId, PathOnClient, Title, FileExtension FROM ContentVersion WHERE FirstPublishLocationId = :order.Id];
        System.assertEquals(0, orderFiles.size());
    }
}