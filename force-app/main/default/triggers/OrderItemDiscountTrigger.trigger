trigger OrderItemDiscountTrigger on OrderItem (after insert, after update, after delete) {
    Set<Id> ordersIds = new Set<Id>();
    if(Trigger.isDelete) {
        for (OrderItem item : Trigger.old) {
            if (item.OrderId != null) {
                ordersIds.add(item.OrderId);
            }
        }
    } else {
        for (OrderItem item : Trigger.new) {
            if (item.OrderId != null) {
                ordersIds.add(item.OrderId);
            }
        }
    }

    OrderItemDiscountTriggerHelper.handleAfter(ordersIds);
}