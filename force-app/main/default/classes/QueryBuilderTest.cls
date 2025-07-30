@isTest
private class QueryBuilderTest {
    private static List<Account> createAccounts(Integer cnt) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < cnt; i++) {
            Account account = new Account(Name = 'Test ' + i);
            accounts.add(account);
        }
        return accounts;
    }

    @isTest
    static void testQueryWithoutFields() {
        insert createAccounts(1);
        String queryString = new QueryBuilder('Account')
            .toString();
        List<Account> accounts = Database.query(queryString);
        System.assertEquals(1, accounts.size());
        System.assert(accounts[0].Id != null);
    }

    @isTest
    static void testQueryWithNameField() {
        insert createAccounts(1);
        String queryString = new QueryBuilder('Account')
            .addField('Name')
            .toString();
        List<Account> accounts = Database.query(queryString);
        System.assertEquals(1, accounts.size());
        System.assertEquals('Test 0', accounts[0].Name);
    }

    @isTest
    static void testQueryWithLimit(){
        insert createAccounts(5);
        String queryString = new QueryBuilder('Account')
            .setLimit(3)
            .toString();
        List<Account> accounts = Database.query(queryString.toString());
        System.assertEquals(3, accounts.size());
    }

    @isTest
    static void testQueryWithOffset(){
        insert createAccounts(5);
        String queryString = new QueryBuilder('Account')
            .setOffset(2)
            .toString();
        List<Account> accounts = Database.query(queryString.toString());
        System.assertEquals(3, accounts.size());
    }

    @isTest
    static void testQueryWithOrderByAsc(){
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Zaid'),
            new Account(Name = 'Andrew'),
            new Account(Name= 'Sandra')
        };
        insert accounts;
        String queryString = new QueryBuilder('Account')
            .addField('Name')
            .addOrderBy('Name ASC')
            .toString();
        accounts = Database.query(queryString);
        System.assertEquals(3, accounts.size());
        System.assertEquals('Andrew', accounts[0].Name);
        System.assertEquals('Zaid', accounts[2].Name);
    }

    @isTest
    static void testQueryWithOrderByDesc(){
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Zaid'),
            new Account(Name = 'Andrew'),
            new Account(Name= 'Sandra')
        };
        insert accounts;
        String queryString = new QueryBuilder('Account')
            .addField('Name')
            .addOrderBy('Name DESC')
            .toString();
        accounts = Database.query(queryString);
        System.assertEquals(3, accounts.size());
        System.assertEquals('Zaid', accounts[0].Name);
        System.assertEquals('Andrew', accounts[2].Name);
    }

    @isTest
    static void testQueryWithSimpleCondition(){
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Zaid'),
            new Account(Name = 'Andrew'),
            new Account(Name= 'Sandra')
        };
        insert accounts;
        String queryString = new QueryBuilder('Account')
            .addField('Name')
            .addConditions()
            .add(new QueryBuilder.SimpleCondition('Name = \'Zaid\''))
            .endConditions()
            .toString();
        accounts = Database.query(queryString);
        System.assertEquals(1, accounts.size());
        System.assertEquals('Zaid', accounts[0].Name);
    }

    @isTest
    static void testQueryWithLikeAnyBothCondition(){
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Zaid', Type = 'Prospect'),
            new Account(Name = 'Andrew', Type = 'Other')
        };
        insert accounts;
        String queryString = new QueryBuilder('Account')
            .addField('Name')
            .addConditions()
            .add(new QueryBuilder.LikeCondition('Name').likeAnyBoth('ai'))
            .add(new QueryBuilder.SimpleCondition('Type = \'Prospect\''))
            .endConditions()
            .toString();
        accounts = Database.query(queryString);
        System.AssertEquals(1, accounts.size());
        System.AssertEquals('Zaid', accounts[0].Name);
    }

    @isTest
    static void testQueryWithLikeAnyLeftCondition(){
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Zaid', Type = 'Prospect'),
            new Account(Name = 'Andrew', Type = 'Other')
        };
        insert accounts;
        String queryString = new QueryBuilder('Account')
            .addField('Name')
            .addConditions()
            .add(new QueryBuilder.LikeCondition('Name').likeAnyLeft('rew'))
            .endConditions()
            .toString();
        accounts = Database.query(queryString);
        System.AssertEquals(1, accounts.size());
        System.AssertEquals('Andrew', accounts[0].Name);
    }

    @isTest
    static void testQueryWithLikeAnyRightCondition(){
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Zaid', Type = 'Prospect'),
            new Account(Name = 'Andrew', Type = 'Other')
        };
        insert accounts;
        String queryString = new QueryBuilder('Account')
            .addField('Name')
            .addConditions()
            .add(new QueryBuilder.LikeCondition('Name').likeAnyRight('And'))
            .endConditions()
            .toString();
        accounts = Database.query(queryString);
        System.AssertEquals(1, accounts.size());
        System.AssertEquals('Andrew', accounts[0].Name);
    }

    @isTest
    static void testQueryWithNotLikeAnyBothCondition(){
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Zaid', Type = 'Prospect'),
            new Account(Name = 'Andrew', Type = 'Other')
        };
        insert accounts;
        String queryString = new QueryBuilder('Account')
            .addField('Name')
            .addConditions()
            .add(new QueryBuilder.LikeCondition('Name').notLikeAnyBoth('dre'))
            .endConditions()
            .toString();
        accounts = Database.query(queryString);
        System.AssertEquals(1, accounts.size());
        System.AssertEquals('Zaid', accounts[0].Name);
    }

    @isTest
    static void testCountQuery(){
        List<Account> accounts = createAccounts(15);
        insert accounts;
        String queryString = new QueryBuilder('Account')
            .toStringCount();
        Integer accountCount = Database.countQuery(queryString);
        System.AssertEquals(15, accountCount);
    }

    @isTest
    static void testQueryWithOrderedConditions(){
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Zaid', Type = 'Prospect'),
            new Account(Name = 'Andrew', Type = 'Prospect'),
            new Account(Name = 'Sam', Type = 'Other')
        };
        insert accounts;
        String queryString = new QueryBuilder('Account')
            .addField('Type')
            .addConditionsWithOrder('1 OR 2')
            .add(new QueryBuilder.SimpleCondition('Name = ' + '\'Zaid\''))
            .add(new QueryBuilder.SimpleCondition('Type = ' + '\'Prospect\''))
            .endConditions()
            .toString();
        accounts = Database.query(queryString);
        System.AssertEquals(2, accounts.size());
    }

    @isTest
    static void testQueryWithEmptyCondition(){
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Zaid', Type = 'Prospect'),
            new Account(Name = 'Andrew', Type = 'Prospect'),
            new Account(Name = 'Sam', Type = 'Other')
        };
        insert accounts;
        String queryString = new QueryBuilder('Account')
            .addConditions()
            .add(new QueryBuilder.SimpleCondition(''))
            .add(new QueryBuilder.LikeCondition('').likeAnyLeft('and'))
            .endConditions()
            .toString();
        accounts = Database.query(queryString);
        System.AssertEquals(3, accounts.size());
    }
}