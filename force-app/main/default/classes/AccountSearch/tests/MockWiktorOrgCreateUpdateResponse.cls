@isTest
global class MockWiktorOrgCreateUpdateResponse implements HttpCalloutMock {
    private static final String ACCOUNT_WIKTOR_ENDPOINT = 'callout:Wiktor_Named/services/data/v62.0/sobjects/Account/';
    global HttpResponse respond(HttpRequest request) {
        Assert.isTrue(request.getMethod() == 'POST' || request.getMethod() == 'PATCH');
        HttpResponse response = new HttpResponse();
        Assert.areEqual(ACCOUNT_WIKTOR_ENDPOINT, request.getEndpoint().substringBeforeLast('/') + '/');
        

        response.setHeader('Content-Type', 'application/json;charset=UTF-8');

        if(request.getMethod() == 'POST'){
            Map<String,Object> fieldToValueMap = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());
            if(!fieldToValueMap.containsKey('name') || String.isBlank((String)fieldToValueMap.get('name'))){
                response.setStatusCode(400);
                response.setBody('{"message" : "Required fields are missing: [Name]","errorCode" : "REQUIRED_FIELD_MISSING","fields" : [ "Name" ] }');
                return response;
            }
            response.setStatusCode(201);
            response.setBody('{"id":"abc","success":true,"errors":[]}');
            return response;
        } 

        if(String.isBlank(request.getEndpoint().substringAfterLast('/'))){
            response.setStatusCode(405);
            return response;
        }

        response.setStatusCode(204);
        return response;
        
    }
}