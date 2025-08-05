public with sharing class TestDataFactory {
    public static List<Product2> ConstructProducts(Integer cnt){
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < cnt; i++){
            Product2 product = new Product2();
            product.Name = 'TEST' + i;
            product.IsActive = true;
            products.add(product);
        }
        return products;
    }

    public static List<PricebookEntry> ConstructPricebookEntries(List<Product2> products){
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for(Product2 p : products){
            PricebookEntry entry = new PricebookEntry();
            entry.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
            entry.Product2Id = p.Id;
            entry.IsActive = true;
            entry.UnitPrice = 1;
            pricebookEntries.add(entry);
        }
        return pricebookEntries;
    }

    public static List<OrderItem> ConstructOrderItems(Integer cnt, Order order, List<PricebookEntry> pricebookEntries){
        List<OrderItem> orderItems = new List<OrderItem>();
        for(Integer i = 0; i < cnt; i++){
            OrderItem oi = new OrderItem();
            oi.OrderId = order.Id;
            oi.PricebookEntryId = pricebookEntries[Math.mod(i, pricebookEntries.size())].Id;
            oi.Quantity = 1;
            oi.UnitPrice = 10;
            oi.Product2Id = pricebookEntries[Math.mod(i, pricebookEntries.size())].Product2Id;
            orderItems.add(oi);
        }
        return orderItems;
    }

    public static void insertTestData(Integer cnt){
        List<Product2> products = ConstructProducts(cnt);
        insert products;

        List<PricebookEntry> pricebookEntries = ConstructPricebookEntries(products);
        insert pricebookEntries;
    }
}