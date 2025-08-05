public class Constants {
    
    public static Id STANDARD_PRICEBOOK_ID {
        get {
            if (STANDARD_PRICEBOOK_ID == null) {
                STANDARD_PRICEBOOK_ID = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
            }
            return STANDARD_PRICEBOOK_ID;
        }
        private set;
    }

    public static AccountConstants Account {
        get {
            if (Account == null) {
                Account = new AccountConstants();
            }
            return Account;
        }
        private set;
    }

    public static PricebookEntryConstants PricebookEntry {
        get {
            if (PricebookEntry == null) {
                PricebookEntry = new PricebookEntryConstants();
            }
            return PricebookEntry;
        }
        private set;
    }

    public static OrderConstants Order {
        get {
            if (Order == null) {
                Order = new OrderConstants();
            }
            return Order;
        }
        private set;
    }

    public static ProductConstants Product {
        get {
            if (Product == null) {
                Product = new ProductConstants();
            }
            return Product;
        }
        private set;
    }

    public static DiscountConstants Discount {
        get {
            if (Discount == null) {
                Discount = new DiscountConstants();
            }
            return Discount;
        }
        private set;
    }
}