@isTest
global class MockWiktorOrgSearchResponse implements HttpCalloutMock {
    private static final String QUERY_WIKTOR_ENDPOINT = 'callout:Wiktor_Named/services/data/v62.0/query';
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        Assert.areEqual(QUERY_WIKTOR_ENDPOINT, request.getEndpoint().substringBefore('?'));
        Assert.areEqual('GET', request.getMethod());

        response.setHeader('Content-Type', 'application/json;charset=UTF-8');
        response.setBody('{"totalSize":3,"done":true,"records":[{"attributes":{"type":"Account","url":"/services/data/v62.0/sobjects/Account/001gL00000AVJGlQAP"},"Id":"001gL00000AVJGlQAP","Name":"Edge Communications","Type":"Customer - Direct","Industry":"Electronics","Phone":"(512) 757-6000"},{"attributes":{"type":"Account","url":"/services/data/v62.0/sobjects/Account/001gL00000AVJGmQAP"},"Id":"001gL00000AVJGmQAP","Name":"Burlington Textiles Corp of America","Type":"Customer - Direct","Industry":"Apparel","Phone":"(336) 222-7000"},{"attributes":{"type":"Account","url":"/services/data/v62.0/sobjects/Account/001gL00000AVJGnQAP"},"Id":"001gL00000AVJGnQAP","Name":"Pyramid Construction Inc.","Type":"Customer - Channel","Industry":"Construction","Phone":"(014) 427-4427"}]}');
        response.setStatusCode(200);
        return response;
    }
}