public abstract class BaseDiscountStrategy implements IDiscountStrategy {
    public abstract Boolean isApplicable(Discount__c discount, Decimal totalOrderAmount);
    private static final String PREFIX = BaseDiscountStrategy.class.getName().split(':')[0];

    public Decimal calculateDiscount(OrderItem item, Discount__c discount) {
        try{
            AmountType amountType = (AmountType) Type.forName(PREFIX + '.' + discount.Amount_Type__c).newInstance();
            return amountType.calculate(item, discount);
        } catch (Exception e) {
            throw new DiscountException(System.Label.Unsuported_Amount_Type + discount.Amount_Type__c);
        }
    }

    public interface AmountType {
        Decimal calculate(OrderItem item, Discount__c discount);
    }

    public class Fixed_Amount implements AmountType {
        public Decimal calculate(OrderItem item, Discount__c discount) {
            return discount.Amount__c * item.Quantity;
        }
    }

    public class Percentage implements AmountType {
        public Decimal calculate(OrderItem item, Discount__c discount) {
            Decimal price = item.UnitPrice * item.Quantity;
            return price * discount.Percentage__c / 100;
        }
    }
}