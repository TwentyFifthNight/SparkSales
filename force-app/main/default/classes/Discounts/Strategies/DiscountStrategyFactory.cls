public class DiscountStrategyFactory {
    private static final String CLASS_SUFFIX = 'DiscountStrategy';
    
    public static IDiscountStrategy getStrategy(Discount__c discount) {
        String className = discount.Type__c + CLASS_SUFFIX;
        try{
            return (IDiscountStrategy)Type.forName(className).newInstance();
        } catch (Exception e) {
            throw new DiscountException(System.Label.Unsuported_Discount_Type + discount.Type__c);
        }
    }
}