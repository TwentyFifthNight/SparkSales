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
        Id priceBookId = getPricebookId(parameters.opportunityId);
        String orderOfQuery = '(1 OR 2) AND 3';
        if(!String.isBlank(parameters.Family)){
            orderOfQuery += ' AND 4';
        }
        QueryBuilder query = new QueryBuilder('PricebookEntry')
            .addConditionsWithOrder(orderOfQuery)
            .add(new QueryBuilder.LikeCondition('Product2.Name').likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.LikeCondition('Product2.ProductCode').likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.SimpleCondition('Pricebook2Id = \'' + priceBookId + '\''))
            .add(new QueryBuilder.SimpleCondition('Product2.Family = \'' + parameters.Family + '\''))
            .endConditions();
        return Database.countQuery(query.toStringCount());
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getRecordList(ParameterWrapper parameters){
        Id priceBookId = getPricebookId(parameters.opportunityId);
        if (parameters.recordsPerPage == null || parameters.recordsPerPage < 1) {
            parameters.recordsPerPage = 10;
        }
        if (parameters.offset == null || parameters.offset < 0) {
            parameters.offset  = 0;
        }

        String orderOfQuery = '(1 OR 2) AND 3';
        if(!String.isBlank(parameters.Family)){
            orderOfQuery += ' AND 4';
        }

        QueryBuilder query = new QueryBuilder('PricebookEntry')
            .addField('Product2Id')
            .addField('Product2.Name')
            .addField('Product2.ProductCode')
            .addField('Product2.Family')
            .addConditionsWithOrder(orderOfQuery)
            .add(new QueryBuilder.LikeCondition('Product2.Name').likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.LikeCondition('Product2.ProductCode').likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.SimpleCondition('Pricebook2Id = \'' + priceBookId + '\''))
            .add(new QueryBuilder.SimpleCondition('Product2.Family = \'' + parameters.Family + '\''))
            .endConditions()
            .setLimit(parameters.recordsPerPage)
            .setOffset(parameters.offset);
        List<PricebookEntry> pricebookEntries = Database.query(query.toString());
        return pricebookEntryToProduct(pricebookEntries);
    }

    private static Id getPricebookId(String opportunityId) {
        Id priceBookId;
        if (opportunityId != null){
            priceBookId = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :opportunityId LIMIT 1].Pricebook2Id;
        }
        if (priceBookId == null){
            priceBookId = Constants.STANDARD_PRICEBOOK_ID;
        }
        return priceBookId;
    }

    private static List<Product2> pricebookEntryToProduct(List<PricebookEntry> pricebookEntries){
        List<Product2> products = new List<Product2>();
        for(PricebookEntry pricebookEntry : pricebookEntries){
            Product2 product = new Product2(Id = pricebookEntry.Product2Id, Name = pricebookEntry.Product2.Name, Family = pricebookEntry.Product2.Family, ProductCode = pricebookEntry.Product2.ProductCode);
            products.add(product);
        }
        return products;
    }

    @AuraEnabled(cacheable=false)
    public static List<Product2> getOpportunityProducts(Id opportunityId){
        List<OpportunityLineItem> opportunityLineItems = [
            SELECT Product2.Id, Product2.Name, Product2.Family, Product2.ProductCode
            FROM OpportunityLineItem 
            WHERE OpportunityId = :opportunityId
        ];
        List<Product2> products = new List<Product2>();
        for(OpportunityLineItem opportunityLineItem : opportunityLineItems){
            Product2 product = new Product2(
                Id = opportunityLineItem.Product2.Id,
                Name = opportunityLineItem.Product2.Name,
                Family = opportunityLineItem.Product2.Family,
                ProductCode = opportunityLineItem.Product2.ProductCode
            );
            products.add(product);
        }
        return products;
    }

    @AuraEnabled(cacheable=false)
    public static List<OrderItemWrapper> generateOrderItemsFromProducts(List<Product2> products, Id opportunityId){
        List<OrderItemWrapper> orderItems = new List<OrderItemWrapper>();

        Map<Id, OpportunityLineItem> opportunityLineItemsByProductId = new Map<Id, OpportunityLineItem>();
        for (OpportunityLineItem opportunityLineItem : [
            SELECT Product2Id, Quantity, UnitPrice
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
            AND Product2Id IN :products
        ]) {
            opportunityLineItemsByProductId.put(opportunityLineItem.Product2Id, opportunityLineItem);
        }
        
        Opportunity opportunit = [
            SELECT Pricebook2Id
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        Map<Id, Decimal> standardPricesByProductId = new Map<Id, Decimal>();
        for (PricebookEntry pricebookEntry : [
            SELECT Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE IsActive = true AND Pricebook2Id = :Constants.STANDARD_PRICEBOOK_ID AND Product2Id IN :products
        ]) {
            standardPricesByProductId.put(pricebookEntry.Product2Id, pricebookEntry.UnitPrice);
        }

        Map<Id, Decimal> pricebookPricesByProductId = new Map<Id, Decimal>();
        if (opportunit.Pricebook2Id != null) {
            for (PricebookEntry pricebookEntry : [
                SELECT Product2Id, UnitPrice
                FROM PricebookEntry
                WHERE IsActive = true AND Pricebook2Id = :opportunit.Pricebook2Id AND Product2Id IN :products
            ]) {
                pricebookPricesByProductId.put(pricebookEntry.Product2Id, pricebookEntry.UnitPrice);
            }
        }

        for (Product2 product : products) {
            Decimal quantity = 0;
            Decimal unitPrice = 0;

            if (opportunityLineItemsByProductId.containsKey(product.Id)) {
                OpportunityLineItem lineItem = opportunityLineItemsByProductId.get(product.Id);
                quantity = lineItem.Quantity;
                unitPrice = lineItem.UnitPrice;
            } else if (pricebookPricesByProductId.containsKey(product.Id)){
                unitPrice = pricebookPricesByProductId.get(product.Id);
            } else if (standardPricesByProductId.containsKey(product.Id)) {
                unitPrice = standardPricesByProductId.get(product.Id);
            }
            OrderItemWrapper orderItem = new OrderItemWrapper();
            orderItem.product2Id = product.Id;
            orderItem.quantity = quantity;
            orderItem.unitPrice = unitPrice;
            orderItem.name = product.Name;
            orderItem.pricebookId = opportunit.Pricebook2Id;
            orderItems.add(orderItem);
        }
        return orderItems;
    }

    @AuraEnabled(cacheable=false)
    public static Id createNewOrder(List<OrderItemWrapper> orderItemWrappers, Id opportunityId){
        List<Opportunity> opportunity = [
            SELECT AccountId, Pricebook2Id, OwnerId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        if (opportunity.size() < 1) {
            throw new AuraHandledException('The Opportunity was not found');
        }
        List<Id> productId = new List<Id>();
        for(OrderItemWrapper orderItem : orderItemWrappers){
            productId.add(orderItem.product2Id);
        }
        
        Id pricebookId = opportunity[0].Pricebook2Id;
        if (pricebookId == null) {
            pricebookId = Constants.STANDARD_PRICEBOOK_ID;
        }
        Map<Id, PricebookEntry> pricebookEntriesByProductId = getPricebookEntriesByProductId(pricebookId, productId);

        Savepoint savePoint = Database.setSavepoint();
        try{
            Order order = new Order();
            order.Status = 'Draft';
            order.EffectiveDate = System.today();
            order.AccountId = opportunity[0].AccountId;
            order.OwnerId = opportunity[0].OwnerId;
            if(opportunity[0].Pricebook2Id != null){
                order.Pricebook2Id = pricebookId;
            } else {
                order.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
            }
            insert order;

            List<OrderItem> orderItemToInsert = orderItemWrapperToOrderItem(orderItemWrappers, order.Id, pricebookEntriesByProductId);
            insert orderItemToInsert;
            return order.Id;
        } catch (Exception e) {
            Database.rollback(savePoint);
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Map<Id, PricebookEntry> getPricebookEntriesByProductId(Id pricebookId, List<Id> productId) {
        Map<Id, PricebookEntry> pricebookEntriesByProductId = new Map<Id, PricebookEntry>();
        for(PricebookEntry pricebookEntry : [
            SELECT Id, Product2Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId AND Product2Id IN :productId
        ]) {
            pricebookEntriesByProductId.put(pricebookEntry.Product2Id, pricebookEntry);
        }
        return pricebookEntriesByProductId;
    }

    private static List<OrderItem> orderItemWrapperToOrderItem(List<OrderItemWrapper> orderItems, Id orderId, Map<Id, PricebookEntry> pricebookEntriesByProductId) {
        List<OrderItem> orderItemToInsert = new List<OrderItem>();
        for(OrderItemWrapper orderItem : orderItems){
            OrderItem item = new OrderItem();
            item.OrderId = orderId;
            item.Product2Id = orderItem.product2Id;
            item.Quantity = orderItem.quantity;
            item.UnitPrice = orderItem.unitPrice;
            item.PricebookEntryId = pricebookEntriesByProductId.get(orderItem.product2Id).Id;
            orderItemToInsert.add(item);
        }
        return orderItemToInsert;
    }
}