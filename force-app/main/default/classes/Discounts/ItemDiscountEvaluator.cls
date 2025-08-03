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
        if (candidates.isEmpty()) return new List<EvaluatedDiscount>();

        if (strategy == 'Highest') {
            EvaluatedDiscount highest = candidates.get(0);
            for (EvaluatedDiscount candidate : candidates) {
                if (candidate.discountAmount > highest.discountAmount) {
                    highest = candidate;
                }
            }
            return new List<EvaluatedDiscount>{ highest };
        } else if (strategy == 'Lowest') {
            EvaluatedDiscount lowest = candidates.get(0);
            for (EvaluatedDiscount candidate : candidates) {
                if (candidate.discountAmount < lowest.discountAmount) {
                    lowest = candidate;
                }
            }
            return new List<EvaluatedDiscount>{ lowest };
        } else if (strategy == 'Combined') {
            return candidates;
        }

        throw new DiscountException('Invalid strategy type: ' + strategy);
    }
}