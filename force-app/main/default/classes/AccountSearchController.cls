public with sharing class AccountSearchController {
    private static final String QUERY_WIKTOR_ENDPOINT = 'callout:Wiktor_Named/services/data/v62.0/query?q=';
    private static final String POST_ACCOUNT_WIKTOR_ENDPOINT = 'callout:Wiktor_Named/services/data/v62.0/sobjects/Account/';
    
    @AuraEnabled(cacheable=false)
    public static Integer getAccountCount(String name, String type, String industry){
        Map<String,String> fieldToValueMap = new Map<String,String>{
            'Name' => name,
            'Type' => type,
            'Industry' => industry
        };
        List<String> whereClauses = buildWhereClauses(fieldToValueMap);
        
        String queryString = buildQueryString('SELECT COUNT()', whereClauses);
        return Database.countQuery(queryString);
    }

    private static String queryStringToURLFormat(String query){
        return query.trim().replace(' ', '+').replace('%', '%25');
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Account> searchAccounts(String name, String type, String industry, Integer pageNumber, Integer recordsPerPage) {
        if (pageNumber == null || pageNumber < 1) {
            pageNumber = 1;
        }
        if (recordsPerPage == null || recordsPerPage < 1) {
            recordsPerPage = 10;
        }

        Map<String,String> fieldToValueMap = new Map<String,String>{
            'Name' => name,
            'Type' => type,
            'Industry' => industry
        };
        List<String> whereClauses = buildWhereClauses(fieldToValueMap);
        Integer queryOffset = recordsPerPage * (pageNumber - 1);
        
        String query = buildQueryString('SELECT Id, Name, Type, Industry, Phone', whereClauses, recordsPerPage, queryOffset);
        return Database.query(query);
    }
    
    @AuraEnabled(cacheable=false)
    public static Integer getAccountCountFromWiktor(String name, String type, String industry){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Map<String,String> fieldToValueMap = new Map<String,String>{
            'Name' => name,
            'Type' => type,
            'Industry' => industry
        };
        List<String> whereClauses = buildWhereClauses(fieldToValueMap);
        String queryString = buildQueryString('SELECT COUNT()', whereClauses);
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
        if(offset == null || offset < 0) {
            offset = 0;
        }
        if(recordsPerPage == null || recordsPerPage < 1) {
            recordsPerPage = 10;
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Map<String,String> fieldToValueMap = new Map<String,String>{
            'Name' => name,
            'Type' => type,
            'Industry' => industry
        };
        List<String> whereClauses = buildWhereClauses(fieldToValueMap);
        String queryString = buildQueryString('SELECT Id, Name, Type, Industry, Phone', whereClauses, recordsPerPage, offset);
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
                    Account account = new Account();
                    account.Id = (String) recordMap.get('Id');
                    account.Name = (String) recordMap.get('Name');
                    account.Type = (String) recordMap.get('Type');
                    account.Industry = (String) recordMap.get('Industry');
                    account.Phone = (String) recordMap.get('Phone');
                    accounts.add(account);
                }
            }
        }
        return accounts;
    }

    private static List<String> buildWhereClauses(Map<String, String> fieldToValueMap) {
        List<String> whereClauses = new List<String>();
        for(String fieldName : fieldToValueMap.keySet()){
            String fieldValue = fieldToValueMap.get(fieldName);
            if(!String.isBlank(fieldValue)){
                String filter = fieldName + ' LIKE \'%' + fieldValue + '%\'';
                whereClauses.add(filter);
            }
        }
        return whereClauses;
    }

    private static String buildQueryString(String queryHead, List<String> whereClauses, Integer queryLimit, Integer queryOffset){
        String queryTemplate = '{0} LIMIT {1} OFFSET {2}';
        String queryString = String.format(
            queryTemplate,
            new List<String> {
                buildQueryString(queryHead, whereClauses),
                String.valueOf(queryLimit),
                String.valueOf(queryOffset)
            }
        );
        return queryString;
    }

    private static String buildQueryString(String queryHead, List<String> whereClauses){
        String queryTemplate = '{0} FROM Account {1} {2}';
        String queryString = String.format(
            queryTemplate,
            new List<String> {
                queryHead,
                whereClauses.size() > 0 ? 'WHERE' : '',
                String.join(whereClauses, ' AND ')
            }
        );
        return queryString;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean createNewAccount(String name, String type, String industry, String destination){
        if (destination == 'Local'){
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
        else if (destination == 'External'){
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
            'name' => name,
            'type' => type,
            'industry' => industry
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
        if (destination == 'Local'){
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
        else if (destination == 'External'){
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
            'name' => name,
            'type' => type,
            'industry' => industry
        });
        request.setBody(requestBody);
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 204) {
            return true;
        }
        return false;
    }
}
