public class Order_CreateInvoiceWhenActivated implements TriggerAction.AfterUpdate, TriggerAction.AfterInsert {
    public void afterUpdate(List<Order> newList, List<Order> oldList){
        Map<Id, Order> oldOrderMap = new Map<Id, Order>(oldList);

        List<Id> activatedOrderIds = new List<Id>();
        for (Order order : newList) {
            Order oldOrder = oldOrderMap.get(order.Id);
            if (order.Status == Constants.Order.Status.ACTIVATED && oldOrder.Status != Constants.Order.Status.ACTIVATED) {
                activatedOrderIds.add(order.Id);
            }
        }
        OrderInvoiceService.handleActivatedOrders(activatedOrderIds);
    }

    public void afterInsert(List<Order> newList){
        List<Id> activatedOrderIds = new List<Id>();
        for (Order order : newList) {
            if (order.Status == Constants.Order.Status.ACTIVATED) {
                activatedOrderIds.add(order.Id);
            }
        }
        OrderInvoiceService.handleActivatedOrders(activatedOrderIds);
    }
}