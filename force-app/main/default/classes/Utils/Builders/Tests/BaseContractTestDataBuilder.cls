public virtual class BaseContractTestDataBuilder extends TestDataBuilder {
    public BaseContractTestDataBuilder() {
        record = new Contract();
    }

    protected virtual override void prepare() {
        Contract contract = (Contract)record;
        if (String.isBlank(contract.Name)) {
            contract.Name = 'TestContract';
        }
    }

    public BaseContractTestDataBuilder withAccount(Account account) {
        Contract contract = (Contract)record;
        contract.AccountId = account.Id;
        return this;
    }
}