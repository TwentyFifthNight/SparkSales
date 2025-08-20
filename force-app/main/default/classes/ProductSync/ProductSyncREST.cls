@RestResource(urlMapping='/Product/sync/*')
global class ProductSyncREST {
    private static final String HANDLER_SUFFIX = 'Handler';

    @HttpPost
    global static void syncProducts() {
        String jsonString = RestContext.request.requestBody.toString();
        ProductSyncRequest.RequestWrapper requestWrapper = 
            (ProductSyncRequest.RequestWrapper) JSON.deserialize(jsonString, ProductSyncRequest.RequestWrapper.class);

        ProductSyncResponse.ResponseWrapper response = new ProductSyncResponse.ResponseWrapper();
        for (ProductSyncRequest.ItemWrapper item : requestWrapper.requestList){
            try {
                String className = ProductSyncREST.class.getName();
                String handlerName = className + '.' + item.body.method + HANDLER_SUFFIX;
                APIMethodHandler methodHandler = (APIMethodHandler)Type.forName(handlerName).newInstance();
                response.responseList.add(methodHandler.run(item.body.records));
            } catch (Exception e) {
                response.responseList.add(new ResponseItemBuilder().withStatus(400).withSuccess(false).withErrorMessage(e.getMessage()).create());
            }
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
    }

    public interface APIMethodHandler {
        ProductSyncResponse.ItemWrapper run(List<ProductSyncRequest.RecordWrapper> products);
    }

    public class POSTHandler implements APIMethodHandler {
        public ProductSyncResponse.ItemWrapper run(List<ProductSyncRequest.RecordWrapper> records) {
            if (Limits.getDmlStatements() > Limits.getLimitDmlStatements() - 1) {
                return new ResponseItemBuilder().withStatus(409).withSuccess(false).withErrorMessage(System.Label.productSyncApiDmlExceeded).create();
            }
            try {
                List<Product2> productsToInsert = new List<Product2>();
                for(ProductSyncRequest.RecordWrapper record : records){
                    Product2 product = record.getProduct();
                    product.ExternalId__c = product.Id;
                    product.Id = null;
                    productsToInsert.add(product);
                }

                MetadataTriggerHandler.bypass(Product_SendInsertedToExternal.class.getName());
                insert productsToInsert;
                MetadataTriggerHandler.clearBypass(Product_SendInsertedToExternal.class.getName());
                return new ResponseItemBuilder().withStatus(200).withSuccess(true).create();
            } catch (Exception e) {
                return new ResponseItemBuilder().withStatus(400).withSuccess(false).withErrorMessage(e.getMessage()).create();
            }
        }
    }

    public class PATCHHandler implements APIMethodHandler {
        public ProductSyncResponse.ItemWrapper run(List<ProductSyncRequest.RecordWrapper> records) {
            if (Limits.getDmlStatements() > Limits.getLimitDmlStatements() - 2) {
                return new ResponseItemBuilder().withStatus(409).withSuccess(false).withErrorMessage(System.Label.productSyncApiDmlExceeded).create();
            }
            Savepoint sp = Database.setSavepoint();
            try {
                List<Product2> productsToUpdate = new List<Product2>();
                List<Product2> productsToUpsert = new List<Product2>();
                for(ProductSyncRequest.RecordWrapper record : records){
                    Product2 product = record.getProduct();
                    if(record.isExternal_c) {
                        product.Id = product.ExternalId__c;
                        product.ExternalId__c = null;
                        productsToUpdate.add(product);
                    } else {
                        product.ExternalId__c = product.Id;
                        product.Id = null;
                        productsToUpsert.add(product);
                    }
                }
                MetadataTriggerHandler.bypass(Product_SendUpdatedToExternal.class.getName());
                MetadataTriggerHandler.bypass(Product_SendInsertedToExternal.class.getName());
                update productsToUpdate;
                upsert productsToUpsert ExternalId__c;
                MetadataTriggerHandler.clearBypass(Product_SendUpdatedToExternal.class.getName());
                MetadataTriggerHandler.clearBypass(Product_SendInsertedToExternal.class.getName());

                return new ResponseItemBuilder().withStatus(200).withSuccess(true).create();
            } catch (Exception e) {
                Database.rollback(sp);
                return new ResponseItemBuilder().withStatus(400).withSuccess(false).withErrorMessage(e.getMessage()).create();
            }
        }
    }

    private class ResponseItemBuilder {
        ProductSyncResponse.ItemWrapper record;

        public ResponseItemBuilder() {
            record = new ProductSyncResponse.ItemWrapper();
            record.body = new ProductSyncResponse.BodyWrapper();
        }

        public ResponseItemBuilder withStatus(Integer status) {
            record.httpStatusCode = status;
            return this;
        }

        public ResponseItemBuilder withSuccess(Boolean success) {
            record.body.success = success;
            return this;
        }

        public ResponseItemBuilder withErrorMessage(String errorMessage) {
            record.body.errorMessages.add(errorMessage);
            return this;
        }

        public ProductSyncResponse.ItemWrapper create() {
            return record;
        }
    }
}