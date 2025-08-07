public with sharing class AccountSearchController {
    private static final String QUERY_WIKTOR_ENDPOINT = 'callout:Wiktor_Named/services/data/v62.0/query?q=';
    private static final String POST_ACCOUNT_WIKTOR_ENDPOINT = 'callout:Wiktor_Named/services/data/v62.0/sobjects/Account/';
    private static final String DESTINATION_LOCAL = 'Local';
    private static final String DESTINATION_EXTERNAL = 'External';
    private static final String REQUEST_NAME_FIELD = 'name';
    private static final String REQUEST_TYPE_FIELD = 'type';
    private static final String REQUEST_INDUSTRY_FIELD = 'industry';

    @AuraEnabled(cacheable=false)
    public static Integer getAccountCount(String name, String type, String industry){
        return Database.countQuery(buildCountQuery(name, type, industry));
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Account> searchAccounts(String name, String type, String industry, Integer pageNumber, Integer recordsPerPage) {
        if (pageNumber == null || pageNumber < 1) {
            pageNumber = 1;
        }
        if (recordsPerPage == null || recordsPerPage < 1) {
            recordsPerPage = 10;
        }
        Integer queryOffset = recordsPerPage * (pageNumber - 1);
        String query = buildSearchQuery(name, type, industry, queryOffset, recordsPerPage);
        return Database.query(query);
    }
    
    @AuraEnabled(cacheable=false)
    public static Integer getAccountCountFromWiktor(String name, String type, String industry){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String queryString = buildCountQuery(name, type, industry);
        queryString = queryStringToURLFormat(queryString);
        String endpoint = QUERY_WIKTOR_ENDPOINT + queryString;
        
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (result.containsKey('totalSize')) {
                return (Integer) result.get('totalSize');
            }
        }
        return 0;
    }

    @AuraEnabled(cacheable=false)
    public static List<Account> searchAccountsFromWiktor(String name, String type, String industry, Integer offset, Integer recordsPerPage){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String queryString = buildSearchQuery(name, type, industry, offset, recordsPerPage);
        queryString = queryStringToURLFormat(queryString);
        String endpoint = QUERY_WIKTOR_ENDPOINT + queryString;
        
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        List<Account> accounts = new List<Account>();
        if(response.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (result.containsKey('records')) {
                List<Object> records = (List<Object>) result.get('records');
                for (Object record : records) {
                    Map<String,Object> recordMap = (Map<String,Object>) record;
                    Account accountRecord = new Account();
                    accountRecord.Id = (String)recordMap.get(String.valueOf(Account.Id));
                    accountRecord.Name = (String)recordMap.get(String.valueOf(Account.Name));
                    accountRecord.Type = (String)recordMap.get(String.valueOf(Account.Type));
                    accountRecord.Industry = (String)recordMap.get(String.valueOf(Account.Industry));
                    accountRecord.Phone = (String)recordMap.get(String.valueOf(Account.Phone));
                    accounts.add(accountRecord);
                }
            }
        }
        return accounts;
    }

    private static String buildCountQuery(String name, String type, String industry) {
        if (String.isBlank(name)) {
            name = '';
        }
        String orderOfQuery = '1';
        if(!String.isBlank(type)){
            orderOfQuery += ' AND 2';
        }
        if(!String.isBlank(industry)){
            orderOfQuery += ' AND 3';
        }
        
        QueryBuilder query = new QueryBuilder(Account.sObjectType)
            .addConditionsWithOrder(orderOfQuery)
            .add(new QueryBuilder.LikeCondition(Account.Name).likeAnyBoth(name))
            .add(new QueryBuilder.SimpleCondition(Account.Type + '= \'' + type + '\''))
            .add(new QueryBuilder.SimpleCondition(Account.Industry + '= \'' + industry + '\''))
            .endConditions();
        return query.toStringCount();
    }

    private static String buildSearchQuery(String name, String type, String industry, Integer offsetValue, Integer recordsPerPage){
        if (offsetValue == null || offsetValue < 0) {
            offsetValue  = 0;
        }
        if (recordsPerPage == null || recordsPerPage < 1) {
            recordsPerPage = 10;
        }
        
        if (String.isBlank(name)) {
            name = '';
        }
        String orderOfQuery = '1';
        if(!String.isBlank(type)){
            orderOfQuery += ' AND 2';
        }
        if(!String.isBlank(industry)){
            orderOfQuery += ' AND 3';
        }

        QueryBuilder query = new QueryBuilder(Account.sObjectType)
            .addFields(new List<Schema.SObjectField>{
                Account.Id, Account.Name, Account.Type, 
                Account.Industry, Account.Phone
            })
            .addConditionsWithOrder(orderOfQuery)
            .add(new QueryBuilder.LikeCondition(Account.Name).likeAnyBoth(name))
            .add(new QueryBuilder.SimpleCondition(Account.Type + ' = \'' + type + '\''))
            .add(new QueryBuilder.SimpleCondition(Account.Industry + ' = \'' + industry + '\''))
            .endConditions()
            .setOffset(offsetValue)
            .setLimit(recordsPerPage);
        return query.toString();
    }

    private static String queryStringToURLFormat(String query){
        return query.trim().replace(' ', '+').replace('%', '%25');
    }
    
    @AuraEnabled(cacheable=false)
    public static Boolean createNewAccount(String name, String type, String industry, String destination){
        if (destination == DESTINATION_LOCAL){
            try {
                Account newAccount = new Account(
                    Name = name,
                    Type = type,
                    Industry = industry
                );
                insert newAccount;
                return true;
            } catch(DmlException e) {
                return false;
            }
        }
        else if (destination == DESTINATION_EXTERNAL){
            return createWiktorAccount(name, type, industry);
        }

        return false;
    }

    private static Boolean createWiktorAccount(String name, String type, String industry){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(POST_ACCOUNT_WIKTOR_ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        String requestBody = JSON.serialize(new Map<String, String>{
            REQUEST_NAME_FIELD => name,
            REQUEST_TYPE_FIELD => type,
            REQUEST_INDUSTRY_FIELD => industry
        });
        request.setBody(requestBody);
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 201) {
            return true;
        }
        return false;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean updateAccount(String accountId, String name, String type, String industry, String destination){
        if (destination == DESTINATION_LOCAL){
            try {
                Account oldAccount = [SELECT Name, Type, Industry FROM Account WHERE Id = :accountId];
                oldAccount.Type = type;
                oldAccount.Industry = industry;
                oldAccount.Name = name;
                update oldAccount;
                return true;
            } catch(QueryException e) {
                return false;
            }
        }
        else if (destination == DESTINATION_EXTERNAL){
            return updateWiktorAccount(accountId, name, type, industry);
        }
        return false;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean updateWiktorAccount(String accountId, String name, String type, String industry){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(POST_ACCOUNT_WIKTOR_ENDPOINT + accountId);
        request.setMethod('PATCH');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        String requestBody = JSON.serialize(new Map<String, String>{
            REQUEST_NAME_FIELD => name,
            REQUEST_TYPE_FIELD => type,
            REQUEST_INDUSTRY_FIELD => industry
        });
        request.setBody(requestBody);
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 204) {
            return true;
        }
        return false;
    }
}
