public class Discount_BlockUpdateOfUsed implements TriggerAction.BeforeUpdate {
    public void beforeUpdate(List<Discount__c> newList, List<Discount__c> oldList){
        Map<Id, Discount__c> newMap = new Map<Id, Discount__c>(newList);
        Map<Id, Discount__c> oldMap = new Map<Id, Discount__c>(oldList);

        Set<Id> usedDiscountIds = getUsedDiscountIds(newMap.keySet());

        for(Discount__c discount: newMap.values()){
            if (!usedDiscountIds.contains(discount.Id)) {
                continue;
            }
            
            SObject oldObject = oldMap.get(discount.Id);
            SObject newObject = newMap.get(discount.Id);
            if(isRestrictedFieldChanged(oldObject, newObject)) {
                discount.addError(System.Label.Restrict_Used_Discount_Edit_Error);
            }
        }
    }

    private Set<Id> getUsedDiscountIds(Set<Id> discountIds) {
        Set<Id> usedDiscountIds = new Set<Id>();
        for(OrderDiscount__c orderDiscount : [SELECT Discount__c FROM OrderDiscount__c WHERE Discount__c IN :discountIds]){
            usedDiscountIds.add(orderDiscount.Discount__c);
        }
        return usedDiscountIds;
    }

    private Boolean isRestrictedFieldChanged(SObject oldObject, SObject newObject){
        String sobjectApiName = String.valueOf(Discount__c.sObjectType);
        String activeFieldName = Discount__c.isActive__c.getDescribe().getName().toLowerCase();
        List<String> changedFields = ObjectUpdatedFieldsHelper.getUpdatedFields(oldObject, newObject, sobjectApiName, new List<String>{activeFieldName});
        return !changedFields.isEmpty();
    }
}