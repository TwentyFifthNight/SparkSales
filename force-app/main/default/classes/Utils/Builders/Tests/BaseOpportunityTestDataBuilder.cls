public virtual class BaseOpportunityTestDataBuilder extends TestDataBuilder {
    public BaseOpportunityTestDataBuilder() {
        record = new Opportunity();
    }

    protected virtual override void prepare() {
        Opportunity opportunity = (Opportunity) record;
        if (String.isBlank(opportunity.Name)) {
            opportunity.Name = 'Test Opportunity';
        }
    }

    public BaseOpportunityTestDataBuilder withAccount(Account account) {
        Opportunity opportunity = (Opportunity) record;
        opportunity.AccountId = account.Id;
        return this;
    }
}