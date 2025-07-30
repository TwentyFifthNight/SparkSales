@isTest
private class OrderInvoiceControllerTest {
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

        List<PricebookEntry> entries = [SELECT Id FROM PricebookEntry];
        List<OrderItem> orderItems = new List<OrderItem>();
        for(PricebookEntry item : entries) {
            OrderItem orderItem = new OrderItem(OrderId = order.Id, Quantity = 1, PricebookEntryId = item.Id, UnitPrice = 10);
            orderItems.add(orderItem);
        }
        insert orderItems;
    }

    @isTest
    static void testInvoiceData() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        Integer orderItemsSize = [SELECT COUNT() FROM OrderItem WHERE OrderId = :order.Id];

        Test.setCurrentPage(Page.OrderInvoice);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(order.Id));
        Test.startTest();
            OrderInvoiceController controller = new OrderInvoiceController(new ApexPages.StandardController(order));
            AggregateResult[] ordersPrice = [SELECT OrderId, SUM(TotalPrice) Total FROM OrderItem WHERE OrderId=:order.Id GROUP BY OrderId];
            Decimal subtotal = (Decimal)ordersPrice[0].get('Total');
            System.assertEquals(subtotal, controller.SubTotal);
            System.assertEquals(subtotal + subtotal * controller.Tax / 100 , controller.TotalAmount);
            System.assertEquals(orderItemsSize, controller.OrderItems.size());
        Test.stopTest();
    }
}