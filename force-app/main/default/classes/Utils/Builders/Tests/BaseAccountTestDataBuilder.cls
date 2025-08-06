public virtual class BaseAccountTestDataBuilder extends TestDataBuilder {
    public BaseAccountTestDataBuilder() {
        record = new Account();
    }
    
    protected virtual override void prepare(){
        Account account = (Account) record;
        if (String.isBlank(account.Name)) {
            account.Name = 'Test Account';
        }
    }
}