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
        @AuraEnabled
        public String opportunityId {get;set;}
        
        public ParameterWrapper(){
            recordsPerPage = 10;
            offset = 0;
        }
    }

    public class OrderItemWrapper{
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public Decimal unitPrice {get;set;}
        @AuraEnabled
        public Decimal quantity {get;set;}
        @AuraEnabled
        public String product2Id {get;set;}
        @AuraEnabled
        public String pricebookId {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static Integer getRecordCount(ParameterWrapper parameters){
        return ProductSearchService.getRecordCount(parameters);
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getRecordList(ParameterWrapper parameters){
        return ProductSearchService.getRecordList(parameters);
    }

    @AuraEnabled(cacheable=false)
    public static List<Product2> getOpportunityProducts(Id opportunityId){
        return ProductSearchService.getOpportunityProducts(opportunityId);
    }

    @AuraEnabled(cacheable=false)
    public static List<OrderItemWrapper> generateOrderItemsFromProducts(List<Product2> products, Id opportunityId){
        return ProductSearchService.generateOrderItemsFromProducts(products, opportunityId);
    }

    @AuraEnabled(cacheable=false)
    public static List<OrderItemsDiscountEvaluator.ItemDiscountResult> evaluateOrderItemsDiscounts(List<OrderItemWrapper> orderItemWrappers, Id opportunityId) {
        return ProductSearchService.evaluateOrderItemsDiscounts(orderItemWrappers, opportunityId);
    }

    @AuraEnabled(cacheable=false)
    public static Id createNewOrder(List<OrderItemWrapper> orderItemWrappers, Id opportunityId){
        return ProductSearchService.createNewOrder(orderItemWrappers, opportunityId);
    }
}