public class OpportunityConstants {
    public final Type Type {
        get {
            return new Type();
        }
    }
    public final StageName StageName {
        get {
            return new StageName();
        }
    }

    public class Type {
        public final String NEW_BUSINESS { get { return 'New Business'; } }
    }

    public class StageName {
        public final String QUALIFICATION { get { return 'Qualification'; } }
    }
}