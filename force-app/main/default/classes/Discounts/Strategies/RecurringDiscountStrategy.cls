public class RecurringDiscountStrategy extends BaseDiscountStrategy {
    public override Boolean isApplicable(Discount__c discount, Decimal totalOrderAmount) {
        Date today = Date.today();

        try{
            String className = String.valueOf(this).split(':')[0];
            RecurrenceType recurrenceType = (RecurrenceType)Type.forName(className + '.' + discount.Recurrence_Type__c).newInstance();
            return recurrenceType.isApplicable(discount, totalOrderAmount);
        } catch (Exception e) {
            throw new DiscountException(System.Label.Unsuported_Recurrence_Type + discount.Recurrence_Type__c);
        }
    }

    public interface RecurrenceType {
        Boolean isApplicable(Discount__c discount, Decimal totalOrderAmount);
    }

    public class Monthly implements RecurrenceType {
        public Boolean isApplicable(Discount__c discount, Decimal totalOrderAmount) {
            return Date.today().day() == Integer.valueOf(discount.Recurrence_Day_Of_Month__c);
        }
    }

    public class Yearly implements RecurrenceType {
        public Boolean isApplicable(Discount__c discount, Decimal totalOrderAmount) {
            Date today = Date.today();
            return today.day() == Integer.valueOf(discount.Recurrence_Day_Of_Month__c) &&
                today.month() == Integer.valueOf(discount.Recurrence_Month_Of_Year__c);
        }
    }
}