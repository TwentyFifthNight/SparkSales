public class Order_ResetSignedStatusAfterActivation implements TriggerAction.BeforeUpdate {
    public void beforeUpdate(List<Order> newList, List<Order> oldList){
        Map<Id, Order> oldMap = new Map<Id, Order>(oldList);
        
        for (Order newOrder : newList) {
            Order oldOrder = oldMap.get(newOrder.Id);
            if (newOrder.Status == Constants.Order.Status.ACTIVATED && oldOrder.Status != Constants.Order.Status.ACTIVATED) {
                newOrder.isSigned__c = false;
            }
        }
    }
}