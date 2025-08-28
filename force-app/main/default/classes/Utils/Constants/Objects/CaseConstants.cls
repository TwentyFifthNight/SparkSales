public class CaseConstants {
    public final Status Status {
        get {
            return new Status();
        }
    }
    public final Origin Origin {
        get {
            return new Origin();
        }
    }

    public class Status {
        public final String NEW_STATUS { get { return 'New'; } }
    }

    public class Origin {
        public final String INTERNAL { get { return 'Internal'; } }
    }
}