public class OrderActivatedHelper {
    public static void handleBeforeUpdate(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        for (Order order : newOrders) {
            Order oldOrder = oldOrderMap.get(order.Id);
            if (order.Status == Constants.Order.STATUS_ACTIVATED && oldOrder.Status != Constants.Order.STATUS_ACTIVATED) {
                order.isSigned__c = false;
            }
        }
    }

    public static void handleAfterUpdateOrInsert(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        List<Id> activatedOrderIds = new List<Id>();
        for (Order order : newOrders) {
            Order oldOrder = oldOrderMap != null ? oldOrderMap.get(order.Id) : null;
            if (order.Status == Constants.Order.STATUS_ACTIVATED && (oldOrder == null || oldOrder.Status != Constants.Order.STATUS_ACTIVATED)) {
                activatedOrderIds.add(order.Id);
            }
        }
        OrderInvoiceService.handleActivatedOrders(activatedOrderIds);
    }
}