@isTest
global class ExternalComplaintCompletedEventMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();

        if (request.getMethod() != Constants.RestAPI.Method.POST) {
            response.setStatusCode(405);
            return response;
        }
        if (request.getEndpoint() != Constants.EXTERNAL_COMPLAINT_COMPLETED_EVENT_API_ENDPOINT) {
            response.setStatusCode(404);
            return response;
        }

        try {
            Map<String, String> item = (Map<String, String>) JSON.deserialize(request.getBody(), Map<String, String>.class);
            List<String> caseIds = (List<String>) JSON.deserialize(item.get('CaseIds__c'), List<String>.class);
        } catch (Exception e) {
            response.setStatusCode(400);
            response.setBody('{"Status" : "Bad Request"}');
            return response;
        }

        response.setStatusCode(201);
        response.setBody('{"success":true}');
        return response;
    }
}