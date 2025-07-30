public with sharing class ProductSearchController {
    public class ParameterWrapper{
        @AuraEnabled
        public String nameAndCode {get;set;}
        @AuraEnabled
        public String family {get;set;}
        @AuraEnabled
        public Integer recordsPerPage {get;set;}
        @AuraEnabled
        public Integer offset {get;set;}
        
        public ParameterWrapper(){
            recordsPerPage = 10;
            offset = 0;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getRecordCount(ParameterWrapper parameters){
        String orderOfQuery = '(1 OR 2)';
        if(!String.isBlank(parameters.Family)){
            orderOfQuery += ' AND 3';
        }
        QueryBuilder query = new QueryBuilder('Product2')
            .addConditionsWithOrder(orderOfQuery)
            .add(new QueryBuilder.LikeCondition('Name').likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.LikeCondition('ProductCode').likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.SimpleCondition('Family = \'' + parameters.Family + '\''))
            .endConditions();
        return Database.countQuery(query.toStringCount());
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getRecordList(ParameterWrapper parameters){
        if (parameters.recordsPerPage == null || parameters.recordsPerPage < 1) {
            parameters.recordsPerPage = 10;
        }
        if (parameters.offset == null || parameters.offset < 0) {
            parameters.offset  = 0;
        }

        String orderOfQuery = '(1 OR 2)';
        if(!String.isBlank(parameters.Family)){
            orderOfQuery += ' AND 3';
        }

        QueryBuilder query = new QueryBuilder('Product2')
            .addField('Name')
            .addField('ProductCode')
            .addField('Family')
            .addConditionsWithOrder(orderOfQuery)
            .add(new QueryBuilder.LikeCondition('Name').likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.LikeCondition('ProductCode').likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.SimpleCondition('Family = \'' + parameters.Family + '\''))
            .endConditions()
            .setLimit(parameters.recordsPerPage)
            .setOffset(parameters.offset);
        return Database.query(query.toString());
    }
}