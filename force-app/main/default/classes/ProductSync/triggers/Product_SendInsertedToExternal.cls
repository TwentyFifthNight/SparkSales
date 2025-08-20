public class Product_SendInsertedToExternal implements TriggerAction.AfterInsert {
    public void afterInsert(List<Product2> newList){
        List<Product2> products = new List<Product2>();
        for(Product2 product : newList){
            if(product.IsExternal__c == false){
                products.add(product);
            }
        }
        if (!products.isEmpty()) {
            AsyncSendProductsToExternal job = new AsyncSendProductsToExternal(products, Constants.RestAPI.Method.POST);
            System.enqueueJob(job);
        }
    }
}