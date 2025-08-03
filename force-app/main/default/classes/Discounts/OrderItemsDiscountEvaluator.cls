public class OrderItemsDiscountEvaluator {
    public class ItemDiscountResult {
        public Id orderItemId;
        public List<ItemDiscountEvaluator.EvaluatedDiscount> appliedDiscounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();
        public Decimal totalDiscount = 0;
    }

    public static List<ItemDiscountResult> evaluate(List<OrderItem> items, Id pricebookId) {
        if (items.isEmpty()) return new List<ItemDiscountResult>();

        Decimal grandTotal = 0;
        for (OrderItem item : items) {
            Decimal itemTotal = item.UnitPrice * item.Quantity;
            grandTotal += itemTotal;
        }

        Discount_Strategy_Setting__mdt setting;
        if (!Test.isRunningTest()){
            setting = [
                SELECT Maximum_Discount__c, Strategy__c
                FROM Discount_Strategy_Setting__mdt
                LIMIT 1
            ];
        } else {
            setting = DiscountTestingSettings.setting;
        }

        Decimal discountPoolRemaining = grandTotal * (setting.Maximum_Discount__c / 100);

        Set<Id> productIds = new Set<Id>();
        for (OrderItem item : items) {
            productIds.add(item.Product2Id);
        }

        List<Discount__c> allDiscounts = [
            SELECT Type__c, Amount_Type__c, Amount__c, Percentage__c,
                Recurrence_Type__c, Recurrence_Day_Of_Month__c, Recurrence_Month_Of_Year__c,
                Start_Date__c, End_Date__c, Threshold_Amount__c,
                Product__c
            FROM Discount__c
            WHERE isActive__c = true AND Product__c IN :productIds AND Pricebook__c = :pricebookId
        ];

        Map<Id, List<Discount__c>> discountsByProductId = new Map<Id, List<Discount__c>>();
        for (Discount__c discount : allDiscounts) {
            if (!discountsByProductId.containsKey(discount.Product__c)) {
                discountsByProductId.put(discount.Product__c, new List<Discount__c>());
            }
            discountsByProductId.get(discount.Product__c).add(discount);
        }

        List<ItemDiscountResult> results = new List<ItemDiscountResult>();
        for (OrderItem item : items) {
            List<ItemDiscountEvaluator.EvaluatedDiscount> validDiscounts = new List<ItemDiscountEvaluator.EvaluatedDiscount>();

            if (!discountsByProductId.containsKey(item.Product2Id)) {
                continue;
            }
            for (Discount__c discount : discountsByProductId.get(item.Product2Id)) {
                IDiscountStrategy strategy = DiscountStrategyFactory.getStrategy(discount);
                if (strategy.isApplicable(discount, grandTotal)) {
                    Decimal amount = strategy.calculateDiscount(item, discount);
                    validDiscounts.add(new ItemDiscountEvaluator.EvaluatedDiscount(discount, amount));
                }
            }

            List<ItemDiscountEvaluator.EvaluatedDiscount> selectedDiscounts =
                ItemDiscountEvaluator.applyStrategy(validDiscounts, setting.Strategy__c);

            Decimal totalForItem = 0;
            for (ItemDiscountEvaluator.EvaluatedDiscount discount : selectedDiscounts) {
                if (discountPoolRemaining >= discount.discountAmount) {
                    totalForItem += discount.discountAmount;
                    discountPoolRemaining -= discount.discountAmount;
                } else {
                    totalForItem += discountPoolRemaining;
                    discountPoolRemaining = 0;
                    break;
                }
            }

            ItemDiscountResult result = new ItemDiscountResult();
            result.orderItemId = item.Id;
            result.totalDiscount = totalForItem;
            result.appliedDiscounts = selectedDiscounts;
            results.add(result);
        }

        return results;
    }
}