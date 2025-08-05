public class DiscountStrategyFactory {
    public static IDiscountStrategy getStrategy(Discount__c discount) {
        String className = discount.Type__c + 'DiscountStrategy';
        try{
            return (IDiscountStrategy)Type.forName(className).newInstance();
        } catch (Exception e) {
            throw new DiscountException(System.Label.Unsuported_Discount_Type + discount.Type__c);
        }
    }
}