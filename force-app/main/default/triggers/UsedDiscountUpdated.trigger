trigger UsedDiscountUpdated on Discount__c (before update) {
    UsedDiscountUpdatedHelper.handleBeforeUpdate(Trigger.newMap, Trigger.oldMap);
}