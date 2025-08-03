public with sharing class DiscountController {
    @AuraEnabled(cacheable=false)
    public static Integer getRecordCount(){
        Integer totalCount = [SELECT COUNT() FROM Discount__c];
        return totalCount;
    }

    @AuraEnabled(cacheable=false)
    public static List<Discount__c> getRecordList(Integer recordsPerPage, Integer offset){
        if (recordsPerPage == null || recordsPerPage < 1) {
            recordsPerPage = 10;
        }
        if (offset == null || offset < 0) {
            offset  = 0;
        }

        QueryBuilder query = new QueryBuilder('Discount__c')
            .addField('Name')
            .addField('Product__r.Name')
            .addField('Pricebook__r.Name')
            .addField('isActive__c')
            .setLimit(recordsPerPage)
            .setOffset(offset);
        return Database.query(query.toString());
    }
}