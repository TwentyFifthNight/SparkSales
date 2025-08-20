public with sharing class ProductSearchService {
    public static Integer getRecordCount(ProductSearchController.ParameterWrapper parameters){
        Id priceBookId = getPricebookId(parameters.opportunityId);
        
        String orderOfQuery = '(1 OR 2) AND 3';
        if(!String.isBlank(parameters.Family)){
            orderOfQuery += ' AND 4';
        }
        
        String pricebookProductRelationship = PricebookEntry.Product2Id.getDescribe().getRelationshipName();
        QueryBuilder query = new QueryBuilder(PricebookEntry.sObjectType)
            .addConditionsWithOrder(orderOfQuery)
            .add(new QueryBuilder.LikeCondition(pricebookProductRelationship + '.' + Product2.Name).likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.LikeCondition(pricebookProductRelationship + '.' + Product2.ProductCode).likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.SimpleCondition(PricebookEntry.Pricebook2Id + ' = \'' + priceBookId + '\''))
            .add(new QueryBuilder.SimpleCondition(pricebookProductRelationship + '.' + Product2.Family + ' = \'' + parameters.Family + '\''))
            .endConditions();
        return Database.countQuery(query.toStringCount());
    }

    public static List<Product2> getRecordList(ProductSearchController.ParameterWrapper parameters){
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

        String pricebookProductRelationship = PricebookEntry.Product2Id.getDescribe().getRelationshipName();
        QueryBuilder query = new QueryBuilder(PricebookEntry.sObjectType)
            .addField(PricebookEntry.Product2Id)
            .addField(PricebookEntry.Product2Id, Product2.Name)
            .addField(PricebookEntry.Product2Id, Product2.ProductCode)
            .addField(PricebookEntry.Product2Id, Product2.Family)
            .addField(PricebookEntry.Product2Id, Product2.ExternalId__c)
            .addConditionsWithOrder(orderOfQuery)
            .add(new QueryBuilder.LikeCondition(PricebookEntry.Product2Id, Product2.Name).likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.LikeCondition(PricebookEntry.Product2Id, Product2.ProductCode).likeAnyBoth(parameters.NameAndCode))
            .add(new QueryBuilder.SimpleCondition(PricebookEntry.Pricebook2Id + ' = \'' + priceBookId + '\''))
            .add(new QueryBuilder.SimpleCondition(pricebookProductRelationship + '.' + Product2.Family + ' = \'' + parameters.Family + '\''))
            .endConditions()
            .setLimit(parameters.recordsPerPage)
            .setOffset(parameters.offset);
        List<PricebookEntry> pricebookEntries = Database.query(query.toString());
        return pricebookEntryToProduct(pricebookEntries);
    }

    private static Id getPricebookId(String opportunityId) {
        Id priceBookId;
        if (opportunityId != null){
            priceBookId = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :opportunityId LIMIT 1].Pricebook2Id;
        }
        if (priceBookId == null){
            priceBookId = Constants.STANDARD_PRICEBOOK_ID;
        }
        return priceBookId;
    }

    private static List<Product2> pricebookEntryToProduct(List<PricebookEntry> pricebookEntries){
        List<Product2> products = new List<Product2>();
        for(PricebookEntry pricebookEntry : pricebookEntries){
            Product2 product = new Product2(
                Id = pricebookEntry.Product2Id, 
                Name = pricebookEntry.Product2.Name, 
                Family = pricebookEntry.Product2.Family, 
                ProductCode = pricebookEntry.Product2.ProductCode,
                ExternalId__c = pricebookEntry.Product2.ExternalId__c
            );
            products.add(product);
        }
        Formula.recalculateFormulas(products);
        return products;
    }

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

    public static List<ProductSearchController.OrderItemWrapper> generateOrderItemsFromProducts(List<Product2> products, Id opportunityId){
        List<ProductSearchController.OrderItemWrapper> orderItems = new List<ProductSearchController.OrderItemWrapper>();

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
            ProductSearchController.OrderItemWrapper orderItem = new ProductSearchController.OrderItemWrapper();
            orderItem.product2Id = product.Id;
            orderItem.quantity = quantity;
            orderItem.unitPrice = unitPrice;
            orderItem.name = product.Name;
            orderItem.pricebookId = opportunit.Pricebook2Id;
            orderItems.add(orderItem);
        }
        return orderItems;
    }

    public static List<OrderItemsDiscountEvaluator.ItemDiscountResult> evaluateOrderItemsDiscounts(List<ProductSearchController.OrderItemWrapper> orderItemWrappers, Id opportunityId) {
        Opportunity opportunit = [
            SELECT Pricebook2Id
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        List<OrderItem> orderItems = new List<OrderItem>();
        for (ProductSearchController.OrderItemWrapper orderItemWrapper : orderItemWrappers) {
            OrderItem item = new OrderItem();
            item.Id = null;
            item.Product2Id = orderItemWrapper.product2Id;
            item.Quantity = orderItemWrapper.quantity;
            item.UnitPrice = orderItemWrapper.unitPrice;
            orderItems.add(item);
        }
        List<OrderItemsDiscountEvaluator.ItemDiscountResult> results = OrderItemsDiscountEvaluator.evaluate(orderItems, opportunit.Pricebook2Id);
        return results;
    }

    public static Id createNewOrder(List<ProductSearchController.OrderItemWrapper> orderItemWrappers, Id opportunityId){
        List<Opportunity> opportunity = [
            SELECT AccountId, Pricebook2Id, OwnerId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        if (opportunity.size() < 1) {
            throw new AuraHandledException(System.Label.Opportunity_Not_Found);
        }
        List<Id> productId = new List<Id>();
        for(ProductSearchController.OrderItemWrapper orderItem : orderItemWrappers){
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
            order.Status = Constants.Order.Status.DRAFT;
            order.EffectiveDate = System.today();
            order.AccountId = opportunity[0].AccountId;
            order.OwnerId = opportunity[0].OwnerId;
            if(opportunity[0].Pricebook2Id != null){
                order.Pricebook2Id = pricebookId;
            } else {
                order.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
            }
            insert order;

            List<OrderItem> orderItemsToInsert = orderItemWrapperToOrderItem(orderItemWrappers, order.Id, pricebookEntriesByProductId);
            insert orderItemsToInsert;
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

    private static List<OrderItem> orderItemWrapperToOrderItem(List<ProductSearchController.OrderItemWrapper> orderItems, Id orderId, Map<Id, PricebookEntry> pricebookEntriesByProductId) {
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        for(ProductSearchController.OrderItemWrapper orderItem : orderItems){
            OrderItem item = new OrderItem();
            item.OrderId = orderId;
            item.Product2Id = orderItem.product2Id;
            item.Quantity = orderItem.quantity;
            item.UnitPrice = orderItem.unitPrice;
            item.PricebookEntryId = pricebookEntriesByProductId.get(orderItem.product2Id).Id;
            orderItemsToInsert.add(item);
        }
        return orderItemsToInsert;
    }
}