@isTest
private class OrderInvoiceControllerTest {
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

        List<PricebookEntry> entries = [SELECT Id, Product2Id FROM PricebookEntry];
        List<OrderItem> orderItems = generateOrderItems(order, entries);
        insert orderItems;
    }

    private static List<OrderItem> generateOrderItems(Order order, List<PricebookEntry> pricebookEntries) {
        List<OrderItem> orderItems = new List<OrderItem>();
        for(PricebookEntry item : pricebookEntries) {
            OrderItem orderItem = (OrderItem)new OrderItemTestDataBuilder()
                .withOrder(order)
                .withPricebookEntry(item)
                .create();
            orderItems.add(orderItem);
        }
        return orderItems;
    }

    @isTest
    static void testInvoiceData() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        Integer orderItemsSize = [SELECT COUNT() FROM OrderItem WHERE OrderId = :order.Id];

        Test.setCurrentPage(Page.OrderInvoice);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(order.Id));
        Test.startTest();
        OrderInvoiceController controller = new OrderInvoiceController(new ApexPages.StandardController(order));
        Test.stopTest();
        
        AggregateResult[] ordersPrice = [SELECT OrderId, SUM(TotalPrice) Total FROM OrderItem WHERE OrderId=:order.Id GROUP BY OrderId];
        Decimal subtotal = (Decimal)ordersPrice[0].get('Total');
        Assert.areEqual(subtotal, controller.SubTotal, 'Subtotal should match the total price of order items');
        Assert.areEqual(subtotal + subtotal * controller.Tax / 100 , controller.TotalAmount, 'Total amount should include tax');
        Assert.areEqual(orderItemsSize, controller.OrderItems.size(), 'Order items size should match the number of order items');
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

    private class OrderItemTestDataBuilder extends BaseOrderItemTestDataBuilder {
        protected override void prepare() {
            super.prepare();
            OrderItem orderItem = (OrderItem)record;
            orderItem.Quantity = 1;
            orderItem.UnitPrice = 10;
        }
    }
}