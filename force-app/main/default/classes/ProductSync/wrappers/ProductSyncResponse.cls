public class ProductSyncResponse {
    public class ResponseWrapper{
        public List<ItemWrapper> responseList = new List<ItemWrapper>();
    }

    public class ItemWrapper{
        public BodyWrapper body;
        public Integer httpStatusCode;
    }

    public class BodyWrapper {
        public Boolean success;
        public List<String> errorMessages = new List<String>();
    }
}