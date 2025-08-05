trigger UsedDiscountUpdated on Discount__c (before update) {
    Set<Id> usedDiscountIds = new Set<Id>();
    for(OrderDiscount__c orderDiscount : [SELECT Id, Discount__c FROM OrderDiscount__c WHERE Discount__c IN :Trigger.newMap.keySet()]){
        usedDiscountIds.add(orderDiscount.Discount__c);
    }

    for(Discount__c discount: Trigger.new){
        if (!usedDiscountIds.contains(discount.Id)) {
            continue;
        }
        
        SObject oldObject = Trigger.oldMap.get(discount.Id);
        SObject newObject = Trigger.newMap.get(discount.Id);
        List<String> changedFields = RestrictUsedDiscountHelper.getUpdatedRestrictedFields(oldObject, newObject);
        if (changedFields.size() > 0){
            discount.addError(System.Label.Restrict_Used_Discount_Edit_Error);
        }
    }

}