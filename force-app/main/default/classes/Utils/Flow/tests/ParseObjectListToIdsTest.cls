@isTest
private class ParseObjectListToIdsTest {

    @isTest
    static void testParseObjectListToIdList() {
        List<Account> accounts = (List<Account>)new TestDataFactory().buildData(2, new BaseAccountTestDataBuilder());
        List<Case> cases = (List<Case>)new TestDataFactory().buildData(2, new BaseCaseTestDataBuilder());

        List<List<SObject>> input = new List<List<SObject>>{
            accounts,
            cases
        };
        List<List<String>> expected = new List<List<String>>{
            new List<String>{ accounts[0].Id, accounts[1].Id },
            new List<String>{ cases[0].Id, cases[1].Id }
        };
        List<List<String>> result = ParseObjectListToIds.parseObjectListToIds(input);
        Assert.areEqual(expected, result, 'The parsed Id lists do not match the expected result.');
    }

    @isTest
    static void testParseObjectListToIdList_EmptyList() {
        List<Account> accounts = (List<Account>)new TestDataFactory().buildData(2, new BaseAccountTestDataBuilder());
        List<Case> cases = new List<Case>();

        List<List<SObject>> input = new List<List<SObject>>{
            accounts,
            cases
        };
        List<List<String>> expected = new List<List<String>>{
            new List<String>{ accounts[0].Id, accounts[1].Id },
            new List<String>{}
        };
        List<List<String>> result = ParseObjectListToIds.parseObjectListToIds(input);
        Assert.areEqual(expected, result, 'The parsed Id lists do not match the expected result.');
    }

    @isTest
    static void testParseObjectListToIdList_NullList() {
        List<Account> accounts = (List<Account>)new TestDataFactory().buildData(2, new BaseAccountTestDataBuilder());
        List<Case> cases = null;

        List<List<SObject>> input = new List<List<SObject>>{
            accounts,
            cases
        };
        List<List<String>> expected = new List<List<String>>{
            new List<String>{ accounts[0].Id, accounts[1].Id },
            new List<String>{}
        };
        List<List<String>> result = ParseObjectListToIds.parseObjectListToIds(input);
        Assert.areEqual(expected, result, 'The parsed Id lists do not match the expected result.');
    }

    @isTest
    static void testParseObjectListToIdList_NullListValue() {
        List<Account> accounts = (List<Account>)new TestDataFactory().buildData(2, new BaseAccountTestDataBuilder());
        accounts.add(1, null);

        List<List<SObject>> input = new List<List<SObject>>{
            accounts
        };

        List<List<String>> expected = new List<List<String>>{
            new List<String>{ accounts[0].Id, accounts[2].Id }
        };
        List<List<String>> result = ParseObjectListToIds.parseObjectListToIds(input);
        Assert.areEqual(expected, result, 'The parsed Id lists do not match the expected result.');
    }

    @isTest
    static void testParseObjectListToIdList_NullInput() {
        List<List<SObject>> input = null;
        List<List<String>> expected = new List<List<String>>{};

        List<List<String>> result = ParseObjectListToIds.parseObjectListToIds(input);
        Assert.areEqual(expected, result, 'The parsed Id lists do not match the expected result.');
    }
}