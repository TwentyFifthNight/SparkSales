@isTest
private class SignatureControllerTest {
    @TestSetup
    static void setup(){
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        TestDataFactory.insertTestData(5);

        Account account = (Account)new BaseAccountTestDataBuilder().create(); 
        insert account;

        Contract contract = (Contract)new ContractTestDataBuilder()
            .withAccount(account)
            .create();
        insert contract;

        Order order = (Order)new OrderTestDataBuilder()
            .withContract(contract)
            .withAccount(account)
            .create();
        
        insert order;

        contract.Status = Constants.Contract.Status.ACTIVATED;
        update contract;

        PricebookEntry entry = [SELECT Id FROM PricebookEntry LIMIT 1];
        OrderItem orderItem = new OrderItem(OrderId = order.Id, Quantity = 1, PricebookEntryId=entry.Id, UnitPrice=10);
        insert orderItem;
    }

    @isTest
    static void testSigningInvoice() {
        Order order = [SELECT Id, Status FROM Order LIMIT 1];
        Test.startTest();
        order.Status = Constants.Order.Status.ACTIVATED;
        update order;

        SignatureController.saveSignature('ssdbfsdfg34q4', order.Id);
        Test.stopTest();
        List<ContentVersion> orderFiles = [SELECT ContentDocumentId, PathOnClient, Title, FileExtension FROM ContentVersion WHERE FirstPublishLocationId = :order.Id];
        System.assertEquals(1, orderFiles.size(), 'Order should have one file attached');
        System.assertEquals('pdf', orderFiles[0].FileExtension, 'File should be a PDF');
    }

    @isTest
    static void testSigningInvoiceWithoutPdf() {
        Order order = [SELECT Id, Status FROM Order LIMIT 1];
        Test.startTest();
        SignatureController.saveSignature('ssdbfsdfg34q4', order.Id);
        Test.stopTest();
        List<ContentVersion> orderFiles = [SELECT ContentDocumentId, PathOnClient, Title, FileExtension FROM ContentVersion WHERE FirstPublishLocationId = :order.Id];
        System.assertEquals(0, orderFiles.size(), 'Order should not have any files attached without a PDF');
    }

    private class ContractTestDataBuilder extends BaseContractTestDataBuilder {
        protected override void prepare() {
            super.prepare();
            Contract contract = (Contract)record;
            contract.Status = Constants.Contract.Status.DRAFT;
            contract.StartDate = Date.today();
            contract.ContractTerm = 12;
        }
    }

    private class OrderTestDataBuilder extends BaseOrderTestDataBuilder {
        protected override void prepare() {
            super.prepare();
            Order order = (Order)record;
            order.Status = Constants.Order.Status.DRAFT;
            order.EffectiveDate = Date.today();
            order.Pricebook2Id = Test.getStandardPricebookId();
        }

        public OrderTestDataBuilder withContract(Contract contract) {
            Order order = (Order) record;
            order.ContractId = contract.Id;
            return this;
        }
    }
}