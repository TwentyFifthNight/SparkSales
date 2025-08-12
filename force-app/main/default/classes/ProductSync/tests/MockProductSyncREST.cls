@isTest
global class MockProductSyncREST implements HttpCalloutMock {
    global Integer statusCode { get; set; }
    global String errorMessage { get; set; }

    global MockProductSyncREST() {
        this.statusCode = 200;
        this.errorMessage = null;
    }

    global MockProductSyncREST(Integer statusCode, String errorMessage) {
        this.statusCode = statusCode;
        this.errorMessage = errorMessage;
    }

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        response.setStatus('OK');

        ProductSyncResponse.ResponseWrapper responseWrapper = new ProductSyncResponse.ResponseWrapper();
        
        if (request.getBody() != null) {
            ProductSyncRequest.RequestWrapper requestWrapper = 
                (ProductSyncRequest.RequestWrapper) JSON.deserialize(request.getBody(), ProductSyncRequest.RequestWrapper.class);
            
            for (ProductSyncRequest.ItemWrapper item : requestWrapper.requestList) {
                ProductSyncResponse.ItemWrapper itemWrapper = new ProductSyncResponse.ItemWrapper();
                itemWrapper.httpStatusCode = statusCode;
                itemWrapper.body = new ProductSyncResponse.BodyWrapper();
                if (statusCode == 200) {
                    itemWrapper.body.success = true;
                } else {
                    itemWrapper.body.success = false;
                    itemWrapper.body.errorMessages = new List<String>{errorMessage};
                }
                responseWrapper.responseList.add(itemWrapper);
            }
        }

        response.setBody(JSON.serialize(responseWrapper));
        return response;
    }
}