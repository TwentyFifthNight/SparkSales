public class ItemDiscountEvaluator {
    public class EvaluatedDiscount {
        public Decimal discountAmount;
        public Discount__c discount;

        public EvaluatedDiscount(Discount__c discount, Decimal discountAmount) {
            this.discountAmount = discountAmount;
            this.discount = discount;
        }
    }

    public static List<EvaluatedDiscount> applyStrategy(List<EvaluatedDiscount> candidates, String strategy) {
        if (candidates.isEmpty()) {
            return new List<EvaluatedDiscount>();
        }

        try{
            String className = ItemDiscountEvaluator.class.getName();
            StrategyType strategyType = (StrategyType)Type.forName(className + '.' + strategy).newInstance();
            return strategyType.evaluate(candidates);
        } catch (Exception e) {
            throw new DiscountException(System.Label.Unsuported_Discount_Strategy_Type + strategy);
        }
    }

    public interface StrategyType {
        List<EvaluatedDiscount> evaluate(List<EvaluatedDiscount> candidates);
    }

    public class Highest implements StrategyType {
        public List<EvaluatedDiscount> evaluate(List<EvaluatedDiscount> candidates) {
            EvaluatedDiscount highest = candidates.get(0);
            for (EvaluatedDiscount candidate : candidates) {
                if (candidate.discountAmount > highest.discountAmount) {
                    highest = candidate;
                }
            }
            return new List<EvaluatedDiscount>{ highest };
        }
    }
    
    public class Lowest implements StrategyType {
        public List<EvaluatedDiscount> evaluate(List<EvaluatedDiscount> candidates) {
            EvaluatedDiscount lowest = candidates.get(0);
            for (EvaluatedDiscount candidate : candidates) {
                if (candidate.discountAmount < lowest.discountAmount) {
                    lowest = candidate;
                }
            }
            return new List<EvaluatedDiscount>{ lowest };
        }
    }

    public class Combined implements StrategyType {
        public List<EvaluatedDiscount> evaluate(List<EvaluatedDiscount> candidates) {
            return candidates;
        }
    }
}