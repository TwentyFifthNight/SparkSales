public class SpecialDiscountStrategy extends BaseDiscountStrategy {
    public override Boolean isApplicable(Discount__c discount, Decimal totalOrderAmount) {
        return totalOrderAmount >= discount.Threshold_Amount__c;
    }
}