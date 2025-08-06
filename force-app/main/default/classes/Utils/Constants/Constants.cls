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

    public static Discount_Strategy_Setting__mdt DISCOUNT_STRATEGY_SETTING {
        get {
            if (DISCOUNT_STRATEGY_SETTING == null) {
                DISCOUNT_STRATEGY_SETTING = [SELECT Maximum_Discount__c, Strategy__c FROM Discount_Strategy_Setting__mdt LIMIT 1];
            }
            return DISCOUNT_STRATEGY_SETTING;
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

    public static ContractConstants Contract {
        get {
            if (Contract == null) {
                Contract = new ContractConstants();
            }
            return Contract;
        }
        private set;
    }
}