trigger OrderActivated on Order (after update, after insert, before update) {
    if(Trigger.isBefore){
        OrderActivatedHelper.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter) {
        OrderActivatedHelper.handleAfterUpdateOrInsert(Trigger.new, Trigger.oldMap);
    }   
}