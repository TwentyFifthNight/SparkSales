public interface IDiscountStrategy {
    Boolean isApplicable(Discount__c discount, Decimal totalOrderAmount);
    Decimal calculateDiscount(OrderItem item, Discount__c discount);
}