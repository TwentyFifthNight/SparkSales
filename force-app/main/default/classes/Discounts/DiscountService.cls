public  class DiscountService {
    public static Integer getRecordCount(){
        Integer totalCount = [SELECT COUNT() FROM Discount__c];
        return totalCount;
    }

    public static List<Discount__c> getRecordList(Integer recordsPerPage, Integer offset){
        if (recordsPerPage == null || recordsPerPage < 1) {
            recordsPerPage = 10;
        }
        if (offset == null || offset < 0) {
            offset = 0;
        }

        QueryBuilder query = new QueryBuilder(Discount__c.sObjectType)
            .addField(Discount__c.Name)
            .addField(Discount__c.Product__c, Product2.Name)
            .addField(Discount__c.Pricebook__c, Pricebook2.Name)
            .addField(Discount__c.isActive__c)
            .setLimit(recordsPerPage)
            .setOffset(offset);
        List<Discount__c> discounts = Database.query(query.toString());
        return discounts;
    }
}