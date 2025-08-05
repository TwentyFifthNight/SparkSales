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

        QueryBuilder query = new QueryBuilder(Constants.Discount.OBJECT_NAME)
            .addField(Constants.Discount.NAME_FIELD)
            .addField(Constants.Discount.PRODUCT_NAME_FIELD)
            .addField(Constants.Discount.PRICEBOOK_NAME_FIELD)
            .addField(Constants.Discount.IS_ACTIVE_FIELD)
            .setLimit(recordsPerPage)
            .setOffset(offset);
        List<Discount__c> discounts = Database.query(query.toString());
        return discounts;
    }
}