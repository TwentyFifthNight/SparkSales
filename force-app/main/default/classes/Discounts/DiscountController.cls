public with sharing class DiscountController {
    @AuraEnabled(cacheable=false)
    public static Integer getRecordCount(){
        return DiscountService.getRecordCount();
    }

    @AuraEnabled(cacheable=false)
    public static List<Discount__c> getRecordList(Integer recordsPerPage, Integer offset){
        return DiscountService.getRecordList(recordsPerPage, offset);
    }
}