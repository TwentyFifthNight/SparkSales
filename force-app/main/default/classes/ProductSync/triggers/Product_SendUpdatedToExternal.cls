public class Product_SendUpdatedToExternal implements TriggerAction.AfterUpdate {
    public void afterUpdate(List<Product2> newList, List<Product2> oldList){
        List<Product2> products = new List<Product2>();
        for(Product2 product : newList){
            products.add(product);
        }
        
        AsyncSendProductsToExternal job = new AsyncSendProductsToExternal(products, Constants.RestAPI.Method.PATCH);
        System.enqueueJob(job);
    }
}