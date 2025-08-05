public abstract class BaseDiscountStrategy implements IDiscountStrategy {
    public abstract Boolean isApplicable(Discount__c discount, Decimal totalOrderAmount);
    
    public Decimal calculateDiscount(OrderItem item, Discount__c discount) {
        if (discount.Amount_Type__c == Constants.Discount.FIXED_AMOUNT_TYPE) {
            return discount.Amount__c * item.Quantity;
        } else if (discount.Amount_Type__c == Constants.Discount.PERCENTAGE_AMOUNT_TYPE) {
            Decimal price = item.UnitPrice * item.Quantity;
            return price * discount.Percentage__c / 100;
        } else {
            return 0;
        }
    }
}