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

    public static RequestLogSetting__mdt REQUEST_LOG_SETTING {
        get {
            if (REQUEST_LOG_SETTING == null) {
                List<RequestLogSetting__mdt> settings = [SELECT MaxAttemptNumber__c, MaxProductsPerRequest__c, MaxRequestsPerBatch__c FROM RequestLogSetting__mdt LIMIT 1];
                if (settings.size() > 0) {
                    REQUEST_LOG_SETTING = settings[0];
                } else {
                    return new RequestLogSetting__mdt(
                        MaxAttemptNumber__c = 3,
                        MaxProductsPerRequest__c = 50,
                        MaxRequestsPerBatch__c = 1
                    );
                }
            }
            return REQUEST_LOG_SETTING;
        }
        private set;
    }

    public static final String PRODUCT_SYNC_API_ENDPOINT { 
        get { 
            return 'callout:External_Data_Org/services/apexrest/Product/sync/';
        }
    }

    public static final String EXTERNAL_COMPLAINT_EVENT_API_ENDPOINT {
        get {
            return 'callout:External_Data_Org/services/data/v62.0/sobjects/ProductComplaintEvent__e/';
        }
    }

    public static final AccountConstants Account {
        get {
            return new AccountConstants();
        }
    }

    public static final OrderConstants Order {
        get {
            return new OrderConstants();
        }
    }

    public static final ProductConstants Product {
        get {
            return new ProductConstants();
        }
    }

    public static final DiscountConstants Discount {
        get {
            return new DiscountConstants();
        }
    }

    public static final ContractConstants Contract {
        get {
            return new ContractConstants();
        }
    }

    public static final OpportunityConstants Opportunity {
        get {
            return new OpportunityConstants();
        }
    }

    public static final RESTConstants RestAPI {
        get {
            return new RESTConstants();
        }
    }

    public static final RequestLogConstants RequestLog {
        get {
            return new RequestLogConstants();
        }
    }
}