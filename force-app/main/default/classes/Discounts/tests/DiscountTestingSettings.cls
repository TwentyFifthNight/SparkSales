@isTest
public class DiscountTestingSettings {
    public static Discount_Strategy_Setting__mdt setting {
        get {
            if(setting == null) {
                setting = new Discount_Strategy_Setting__mdt(
                    Maximum_Discount__c = 35,
                    Strategy__c = Constants.Discount.Strategy.HIGHEST
                );
            }
            return setting;
        }
        set {
            setting = value;
        }
    }
}