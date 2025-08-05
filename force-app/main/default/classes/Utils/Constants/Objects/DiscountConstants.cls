public class DiscountConstants {
    public final String OBJECT_NAME {
        get {
            return 'Discount__c';
        }
        private set;
    }

    public final String NAME_FIELD {
        get {
            return 'Name';
        }
        private set;
    }

    public final String PRODUCT_NAME_FIELD {
        get {
            return 'Product__r.Name';
        }
        private set;
    }

    public final String PRICEBOOK_NAME_FIELD {
        get {
            return 'Pricebook__r.Name';
        }
        private set;
    }

    public final String IS_ACTIVE_FIELD {
        get {
            return 'isActive__c';
        }
        private set;
    }

    public final String SPECIAL_TYPE {
        get {
            return 'Special';
        }
        private set;
    }

    public final String TIMED_TYPE {
        get {
            return 'Timed';
        }
        private set;
    }

    public final String RECURRING_TYPE {
        get {
            return 'Recurring';
        }
        private set;
    }

    public final String FIXED_AMOUNT_TYPE {
        get {
            return 'Fixed_Amount';
        }
        private set;
    }

    public final String PERCENTAGE_AMOUNT_TYPE {
        get {
            return 'Percentage';
        }
        private set;
    }

    public final String STRATEGY_HIGHEST {
        get {
            return 'Highest';
        }
        private set;
    }

    public final String STRATEGY_LOWEST {
        get {
            return 'Lowest';
        }
        private set;
    }

    public final String STRATEGY_COMBINED {
        get {
            return 'Combined';
        }
        private set;
    }
}