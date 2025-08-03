public class TimedDiscountStrategy extends BaseDiscountStrategy {
    public override Boolean isApplicable(Discount__c discount, Decimal totalOrderAmount) {
        Date today = Date.today();
        return today >= discount.Start_Date__c && today <= discount.End_Date__c;
    }
}