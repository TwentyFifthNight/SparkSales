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
            return new AccountConstants();
        }
        private set;
    }

    public static OrderConstants Order {
        get {
            return new OrderConstants();
        }
        private set;
    }

    public static ProductConstants Product {
        get {
            return new ProductConstants();
        }
        private set;
    }

    public static DiscountConstants Discount {
        get {
            return new DiscountConstants();
        }
        private set;
    }

    public static ContractConstants Contract {
        get {
            return new ContractConstants();
        }
        private set;
    }

    public static OpportunityConstants Opportunity {
        get {
            return new OpportunityConstants();
        }
        private set;
    }
}