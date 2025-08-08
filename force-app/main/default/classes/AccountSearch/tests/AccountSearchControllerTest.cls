@isTest
private class AccountSearchControllerTest {

    @TestSetup
    static void setup(){
        List<Account> accounts = new List<Account>();
        accounts.addAll(generateAccounts(30, Constants.Account.Type.PROSPECT, Constants.Account.Industry.BANKING));
        accounts.addAll(generateAccounts(30, Constants.Account.Type.OTHER, Constants.Account.Industry.BANKING));
        accounts.addAll(generateAccounts(30, Constants.Account.Type.OTHER, Constants.Account.Industry.CHEMICALS));
        insert accounts;
    }

    private static List<Account> generateAccounts(Integer count, String type, String industry) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            Account account = (Account)new AccountTestDataBuilder()
                .withType(type)
                .withIndustry(industry)
                .create();
            accounts.add(account);
        }
        return accounts;
    }

    @isTest
    static void testSearchAccountByName() {
        String name = 'Acc';
        Test.startTest();
        List<Account> accounts = AccountSearchController.searchAccounts(name, null, null, 1, 100);
        Test.stopTest();
        Assert.areEqual(90, accounts.size());
    }

    @isTest
    static void testSearchAccountByTypeAndIndustry() {
        String type = Constants.Account.Type.OTHER;
        String industry = Constants.Account.Industry.BANKING;
        Test.startTest();
        List<Account> accounts = AccountSearchController.searchAccounts(null, type, industry, 1, 100);
        Test.stopTest();

        Assert.areEqual(30, accounts.size());
    }

    @isTest
    static void testSearchAccountWithoutPaginationParameters() {
        Test.startTest();
        List<Account> accounts = AccountSearchController.searchAccounts(null, null, null, null, null);
        Test.stopTest();

        Assert.areEqual(10, accounts.size());
    }

    @isTest
    static void testSearchAccountCountByName() {
        String name = 'Acc';
        Test.startTest();
        Integer accountCount = AccountSearchController.getAccountCount(name, null, null);
        Test.stopTest();

        Assert.areEqual(90, accountCount);
    }

    @isTest
    static void testExternalSearchAccountCount() {
        Test.setMock(HttpCalloutMock.class, new MockWiktorOrgSearchResponse());
        Test.startTest();
        Integer accountCount = AccountSearchController.getAccountCountFromWiktor(null, null, null);
        Test.stopTest();

        Assert.areEqual(3, accountCount);
    }

    @isTest
    static void testExternalSearchAccount() {
        Test.setMock(HttpCalloutMock.class, new MockWiktorOrgSearchResponse());
        Test.startTest();
        List<Account> accounts = AccountSearchController.searchAccountsFromWiktor(null, null, null, null, null);
        Test.stopTest();

        Assert.isNotNull(accounts);
        Assert.areEqual(3, accounts.size());
    }

    @isTest
    static void testCreateAccount() {
        String name = 'Acc';
        String type = Constants.Account.Type.PROSPECT;
        String industry = Constants.Account.Industry.BANKING;

        Test.startTest();
        Boolean result = AccountSearchController.createNewAccount(name, type, industry, 'Local');
        Test.stopTest();

        Assert.isTrue(result);
        Account[] account = [SELECT Id, Name FROM Account WHERE Name = :name AND Type = :type AND Industry = :industry];
        Assert.isNotNull(account);
        Assert.areEqual(1, account.size());
    }

    @isTest
    static void testCreateExternalAccount() {
        String name = 'Acc';
        String type = Constants.Account.Type.PROSPECT;
        String industry = Constants.Account.Industry.BANKING;
        Test.setMock(HttpCalloutMock.class, new MockWiktorOrgCreateUpdateResponse());
        Test.startTest();
        Boolean result = AccountSearchController.createNewAccount(name, type, industry, 'External');
        Test.stopTest();
        Assert.isTrue(result);
    }

    @isTest
    static void testUpdateAccount() {
        String name = 'Acc';
        String type = Constants.Account.Type.PROSPECT;
        String industry = Constants.Account.Industry.BANKING;

        Account account = new Account(Name = name, Type = type, Industry = industry);
        insert account;
        name = name + 'updated';

        Test.startTest();
        Boolean result = AccountSearchController.updateAccount(account.Id, name, type, industry, 'Local');
        Test.stopTest();

        Assert.isTrue(result);
        Account[] accounts = [SELECT Id, Name FROM Account WHERE Name = :name AND Type = :type AND Industry = :industry];
        Assert.isNotNull(accounts);
        Assert.areEqual(1, accounts.size());
    }

    @isTest
    static void testUpdateExternalAccount() {
        String name = 'Acc';
        String type = Constants.Account.Type.PROSPECT;
        String industry = Constants.Account.Industry.BANKING;

        Test.setMock(HttpCalloutMock.class, new MockWiktorOrgCreateUpdateResponse());
        Test.startTest();
        Boolean result = AccountSearchController.updateAccount('001gL00000AGSEsFQP', name, type, industry, 'External');
        Test.stopTest();

        Assert.isTrue(result);
    }

    private class AccountTestDataBuilder extends BaseAccountTestDataBuilder {
        public AccountTestDataBuilder withType(String type) {
            Account account = (Account) record;
            account.Type = type;
            return this;
        }

        public AccountTestDataBuilder withIndustry(String industry) {
            Account account = (Account) record;
            account.Industry = industry;
            return this;
        }
    }
}