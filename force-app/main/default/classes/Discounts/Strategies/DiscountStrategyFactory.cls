public class DiscountStrategyFactory {
    public static IDiscountStrategy getStrategy(Discount__c discount) {
        switch on discount.Type__c {
            when 'Recurring' {
                return new RecurringDiscountStrategy();
            }
            when 'Timed' {
                return new TimedDiscountStrategy();
            }
            when 'Special' {
                return new SpecialDiscountStrategy();
            }
            when else {
                throw new DiscountException('Unsupported discount type: ' + discount.Type__c);
            }
        }
    }
}