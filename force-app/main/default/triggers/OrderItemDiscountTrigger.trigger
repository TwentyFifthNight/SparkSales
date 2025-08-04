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

    Map<Id, List<OrderItem>> orderIdToItems = new Map<Id, List<OrderItem>>();
    for (orderItem item : [SELECT OrderId, Quantity, UnitPrice, Product2Id FROM OrderItem WHERE OrderId IN :ordersIds]) {
        if (!orderIdToItems.containsKey(item.OrderId)) {
            orderIdToItems.put(item.OrderId, new List<OrderItem>());
        }
        orderIdToItems.get(item.OrderId).add(item);
    }

    Map<Id, Id> orderIdToPricebook = new Map<Id, Id>();
    for (Order order : [SELECT Id, Pricebook2Id FROM Order WHERE Id IN :ordersIds]) {
        if (order.Pricebook2Id != null) {
            orderIdToPricebook.put(order.Id, order.Pricebook2Id);
        } else {
            orderIdToPricebook.put(order.Id, Constants.STANDARD_PRICEBOOK_ID);
        }
    }

    Map<Id, List<OrderItemsDiscountEvaluator.ItemDiscountResult>> orderIdToDiscounts = new Map<Id, List<OrderItemsDiscountEvaluator.ItemDiscountResult>>();
    for (Id orderId : orderIdToItems.keySet()) {
        List<OrderItemsDiscountEvaluator.ItemDiscountResult> discounts = OrderItemsDiscountEvaluator.evaluate(orderIdToItems.get(orderId), orderIdToPricebook.get(orderId));
        if (discounts != null && !discounts.isEmpty()) {
            orderIdToDiscounts.put(orderId, discounts);
        }
    }

    delete [SELECT Id FROM OrderDiscount__c WHERE Order__c IN :ordersIds];
    
    List<OrderDiscount__c> discountsToInsert = new List<OrderDiscount__c>();
    for (Id orderId : orderIdToDiscounts.keySet()) {
        for (OrderItemsDiscountEvaluator.ItemDiscountResult itemDiscounts : orderIdToDiscounts.get(orderId)) {
            for (ItemDiscountEvaluator.EvaluatedDiscount evaluatedDiscount : itemDiscounts.appliedDiscounts) {
                OrderDiscount__c orderDiscount = new OrderDiscount__c();
                orderDiscount.Order__c = orderId;
                orderDiscount.Discount__c = evaluatedDiscount.discount.Id;
                orderDiscount.Discount_Amount__c = evaluatedDiscount.discountAmount;
                orderDiscount.Name = evaluatedDiscount.discount.Name;
                discountsToInsert.add(orderDiscount);
            }
        }
    }
    insert discountsToInsert;
}