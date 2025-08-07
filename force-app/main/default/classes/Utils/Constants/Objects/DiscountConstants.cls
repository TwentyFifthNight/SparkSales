public class DiscountConstants {
    public final Type Type {
        get {
            return new Type();
        }
    }
    public final AmountType AmountType {
        get {
            return new AmountType();
        }
    }
    public final Strategy Strategy {
        get {
            return new Strategy();
        }
    }

    public class Type {
        public final String TIMED { get { return 'Timed'; } }
        public final String SPECIAL { get { return 'Special'; } }
        public final String RECURRING { get { return 'Recurring'; } }
    }

    public class AmountType {
        public final String PERCENTAGE { get { return 'Percentage'; } }
        public final String FIXED { get { return 'Fixed_Amount'; } }
    }

    public class Strategy {
        public final String HIGHEST { get { return 'Highest'; } }
        public final String LOWEST { get { return 'Lowest'; } }
        public final String COMBINED { get { return 'Combined'; } }
    }
}