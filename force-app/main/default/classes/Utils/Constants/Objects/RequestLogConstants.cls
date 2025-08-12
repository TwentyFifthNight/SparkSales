public class RequestLogConstants {
    public final Integer MAX_ATTEMPT_NUMBER {
        get {
            return 3;
        }
    }

    public final Integer MAX_PRODUCTS_PER_REQUEST {
        get {
            return 50;
        }
    }

    public final Integer MAX_REQUESTS_PER_BATCH {
        get {
            return 1;
        }
    }

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