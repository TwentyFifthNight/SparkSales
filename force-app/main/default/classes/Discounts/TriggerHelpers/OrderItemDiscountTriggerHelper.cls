public class OrderItemDiscountTriggerHelper {
    public static void handleAfter(Set<Id> orderIds){
        Map<Id, List<OrderItem>> orderIdToItems = getOrderIdToItems(orderIds);
        Map<Id, Id> orderIdToPricebookId = getOrderIdToPricebookId(orderIds);
        Map<Id, List<OrderItemsDiscountEvaluator.ItemDiscountResult>> orderIdToDiscounts = getOrderIdToDiscounts(orderIdToItems, orderIdToPricebookId);

        delete [SELECT Id FROM OrderDiscount__c WHERE Order__c IN :orderIds];
        
        List<OrderDiscount__c> discountsToInsert = new List<OrderDiscount__c>();
        for (Id orderId : orderIdToDiscounts.keySet()) {
            for (OrderItemsDiscountEvaluator.ItemDiscountResult itemDiscounts : orderIdToDiscounts.get(orderId)) {
                discountsToInsert.addAll(createOrderDiscounts(itemDiscounts.appliedDiscounts, orderId));
            }
        }
        insert discountsToInsert;
    }

    private static Map<Id, List<OrderItem>> getOrderIdToItems(Set<Id> orderIds) {
        Map<Id, List<OrderItem>> orderIdToItems = new Map<Id, List<OrderItem>>();
        for (orderItem item : [SELECT OrderId, Quantity, UnitPrice, Product2Id FROM OrderItem WHERE OrderId IN :orderIds]) {
            if (!orderIdToItems.containsKey(item.OrderId)) {
                orderIdToItems.put(item.OrderId, new List<OrderItem>());
            }
            orderIdToItems.get(item.OrderId).add(item);
        }
        return orderIdToItems;
    }

    private static Map<Id, Id> getOrderIdToPricebookId(Set<Id> orderIds) {
        Map<Id, Id> orderIdToPricebookId = new Map<Id, Id>();
        for (Order order : [SELECT Id, Pricebook2Id FROM Order WHERE Id IN :orderIds]) {
            if (order.Pricebook2Id != null) {
                orderIdToPricebookId.put(order.Id, order.Pricebook2Id);
            } else {
                orderIdToPricebookId.put(order.Id, Constants.STANDARD_PRICEBOOK_ID);
            }
        }
        return orderIdToPricebookId;
    }

    private static Map<Id, List<OrderItemsDiscountEvaluator.ItemDiscountResult>> getOrderIdToDiscounts(Map<Id, List<OrderItem>> orderIdToItems, Map<Id, Id> orderIdToPricebookId) {
        Map<Id, List<OrderItemsDiscountEvaluator.ItemDiscountResult>> orderIdToDiscounts = new Map<Id, List<OrderItemsDiscountEvaluator.ItemDiscountResult>>();
        for (Id orderId : orderIdToItems.keySet()) {
            List<OrderItemsDiscountEvaluator.ItemDiscountResult> discounts = OrderItemsDiscountEvaluator.evaluate(orderIdToItems.get(orderId), orderIdToPricebookId.get(orderId));
            if (discounts != null && !discounts.isEmpty()) {
                orderIdToDiscounts.put(orderId, discounts);
            }
        }
        return orderIdToDiscounts;
    }

    private static List<OrderDiscount__c> createOrderDiscounts(List<ItemDiscountEvaluator.EvaluatedDiscount> evaluatedDiscounts, Id orderId) {
        List<OrderDiscount__c> discounts = new List<OrderDiscount__c>();
        for (ItemDiscountEvaluator.EvaluatedDiscount evaluatedDiscount : evaluatedDiscounts) {
            OrderDiscount__c orderDiscount = new OrderDiscount__c();
            orderDiscount.Order__c = orderId;
            orderDiscount.Discount__c = evaluatedDiscount.discount.Id;
            orderDiscount.Discount_Amount__c = evaluatedDiscount.discountAmount;
            orderDiscount.Name = evaluatedDiscount.discount.Name;
            discounts.add(orderDiscount);
        }
        return discounts;
    }
}