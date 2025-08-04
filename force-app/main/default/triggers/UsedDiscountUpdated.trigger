trigger UsedDiscountUpdated on Discount__c (before update) {
    for(Discount__c discount: Trigger.new){
        SObject oldObject = Trigger.oldMap.get(discount.Id);
        SObject newObject = Trigger.newMap.get(discount.Id);
        List<String> changedFields = RestrictUsedDiscountHelper.getUpdatedRestrictedFields(oldObject, newObject);
        if (changedFields.size() > 0){
            discount.addError('You cannot edit a discount that is already in use');
        }
    }

}