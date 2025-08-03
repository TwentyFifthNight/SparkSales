public class RecurringDiscountStrategy extends BaseDiscountStrategy {
    public override Boolean isApplicable(Discount__c discount, Decimal totalOrderAmount) {
        Date today = Date.today();
        if (discount.Recurrence_Type__c == 'Monthly') {
            return today.day() == Integer.valueOf(discount.Recurrence_Day_Of_Month__c);
        } else if (discount.Recurrence_Type__c == 'Yearly') {
            return today.day() == Integer.valueOf(discount.Recurrence_Day_Of_Month__c) &&
                today.month() == Integer.valueOf(discount.Recurrence_Month_Of_Year__c);
        }
        return false;
    }
}