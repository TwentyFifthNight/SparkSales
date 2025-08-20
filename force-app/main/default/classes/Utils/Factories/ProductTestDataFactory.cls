public class ProductTestDataFactory extends TestDataFactory {
    public override List<sObject> buildData(Integer count, TestDataBuilder builder){

        List<Product2> products = new List<Product2>();
        Product2 product = (Product2)builder.create();
        for(Integer i = 0; i < count; i++){
            products.add(product.clone(false, false, false, false));
        }
        MetadataTriggerHandler.bypass(Product_SendInsertedToExternal.class.getName());
        insert products;
        MetadataTriggerHandler.clearBypass(Product_SendInsertedToExternal.class.getName());
        return products;
    }
}