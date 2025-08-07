public class AccountConstants {
    public final Type Type {
        get {
            return new Type();
        }
    }

    public final Industry Industry {
        get {
            return new Industry();
        }
    }

    public class Type {
        public final String PROSPECT { get { return 'Prospect'; } }
        public final String OTHER { get { return 'Other'; } }
    }

    public class Industry {
        public final String BANKING { get { return 'Banking'; } }
        public final String CHEMICALS { get { return 'Chemicals'; } }
    }
}