public class ContractConstants {
    public final Status Status {
        get {
            return new Status();
        }
    }

    public class Status {
        public final String ACTIVATED { get { return 'Activated'; } }
        public final String DRAFT { get { return 'Draft'; } }
    }
}