public class RequestLogConstants {
    public final Status Status {
        get {
            return new Status();
        }
    }

    public class Status {
        public final String SUCCESS { get { return 'Success'; } }
        public final String FAILED { get { return 'Failed'; } }
        public final String REATTEMPTED { get { return 'Reattempted'; } }
    }
}