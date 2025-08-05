public class UsedDiscountUpdatedHelper {
    public static void handleBeforeUpdate(Map<Id, Discount__c> newDiscountMap, Map<Id, Discount__c> oldDiscountMap) {
        Set<Id> usedDiscountIds = new Set<Id>();
        for(OrderDiscount__c orderDiscount : [SELECT Id, Discount__c FROM OrderDiscount__c WHERE Discount__c IN :newDiscountMap.keySet()]){
            usedDiscountIds.add(orderDiscount.Discount__c);
        }

        for(Discount__c discount: newDiscountMap.values()){
            if (!usedDiscountIds.contains(discount.Id)) {
                continue;
            }
            
            SObject oldObject = oldDiscountMap.get(discount.Id);
            SObject newObject = newDiscountMap.get(discount.Id);
            String sobjectApiName = Constants.Discount.OBJECT_NAME;
            String activeFieldName = Constants.Discount.IS_ACTIVE_FIELD.toLowerCase();
            List<String> changedFields = ObjectUpdatedFieldsHelper.getUpdatedFields(oldObject, newObject, sobjectApiName, new List<String>{activeFieldName});
            if (!changedFields.isEmpty()){
                discount.addError(System.Label.Restrict_Used_Discount_Edit_Error);
            }
        }
    }
}