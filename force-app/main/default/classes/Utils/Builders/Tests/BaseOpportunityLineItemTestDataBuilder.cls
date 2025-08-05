public virtual class BaseOpportunityLineItemTestDataBuilder extends TestDataBuilder {
    public BaseOpportunityLineItemTestDataBuilder() {
        record = new OpportunityLineItem();
    }

    public BaseOpportunityLineItemTestDataBuilder withOpportunity(Opportunity opportunity) {
        OpportunityLineItem lineItem = (OpportunityLineItem) record;
        lineItem.OpportunityId = opportunity.Id;
        return this;
    }

    public BaseOpportunityLineItemTestDataBuilder withProduct(Product2 product) {
        OpportunityLineItem lineItem = (OpportunityLineItem) record;
        lineItem.Product2Id = product.Id;
        return this;
    }
}