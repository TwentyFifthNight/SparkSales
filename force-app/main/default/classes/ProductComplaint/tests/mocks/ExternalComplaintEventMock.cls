@isTest
global class ExternalComplaintEventMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();

        if (request.getMethod() != Constants.RestAPI.Method.POST) {
            response.setStatusCode(405);
            return response;
        }
        if (request.getEndpoint() != Constants.EXTERNAL_COMPLAINT_EVENT_API_ENDPOINT) {
            response.setStatusCode(404);
            return response;
        }

        try {
            Map<String, String> item = (Map<String, String>) JSON.deserializeUntyped(request.getBody());
            String trackingId = (String) item.get('CaseId__c');
            List<String> productIds = (List<String>) JSON.deserialize(item.get('ProductIds__c'), List<String>.class);
            List<Decimal> prices = (List<Decimal>) JSON.deserialize(item.get('Prices__c'), List<Decimal>.class);
            List<Decimal> quantities = (List<Decimal>) JSON.deserialize(item.get('Quantities__c'), List<Decimal>.class);
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