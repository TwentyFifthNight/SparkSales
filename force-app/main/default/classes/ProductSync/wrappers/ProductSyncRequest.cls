public class ProductSyncRequest {
    public class RequestWrapper{
        public List<ItemWrapper> requestList = new List<ItemWrapper>();
    }

    public class ItemWrapper{
        public BodyWrapper body;
    }

    public class BodyWrapper {
        public String method;
        public List<RecordWrapper> records;
    }

    public class RecordWrapper {
        public String id;
        public String name;
        public String productCode;
        public String family;
        public Boolean isActive;
        public String externalId_c;
        public Boolean isExternal_c;
        public Datetime lastModifiedDate;

        public RecordWrapper(Product2 product) {
            this.id = product.Id;
            this.name = product.Name;
            this.productCode = product.ProductCode;
            this.family = product.Family;
            this.isActive = product.IsActive;
            this.externalId_c = product.ExternalId__c;
            this.isExternal_c = product.IsExternal__c;
            this.lastModifiedDate = product.LastModifiedDate;
        }

        public Product2 getProduct() {
            Product2 product = new Product2();
            product.Id = this.id;
            product.Name = this.name;
            product.ProductCode = this.productCode;
            product.Family = this.family;
            product.IsActive = this.isActive;
            product.ExternalId__c = this.externalId_c;
            return product;
        }
    }

    public static BodyWrapper productListToRequestBody(List<Product2> products) {
        BodyWrapper result = new BodyWrapper();
        List<RecordWrapper> records = new List<RecordWrapper>();
        for(Product2 product : products){
            RecordWrapper record = new RecordWrapper(product);
            records.add(record);
        }
        result.records = records;
        return result;
    }
}