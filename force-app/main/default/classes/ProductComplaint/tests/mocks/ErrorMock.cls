@isTest
global class ErrorMock implements HttpCalloutMock {
    global HttpResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(400);
        return response;
    }
}