trigger OrderActivated on Order (after update, after insert, before update) {
    if(Trigger.isBefore){
        for(Order order : Trigger.new){
            if(order.Status == 'Activated' && Trigger.oldMap.get(order.Id).Status != 'Activated'){
                order.isSigned__c = false;   
            }
        }
    } else if (Trigger.isAfter) {
        List<Id> activatedOrderIds = new List<Id>();
        for(Order order : Trigger.new){
            if(order.Status == 'Activated' && Trigger.oldMap.get(order.Id).Status != 'Activated'){
                activatedOrderIds.add(order.Id);   
            }
        }
        OrderInvoiceService.handleActivatedOrders(activatedOrderIds);
    }   
}