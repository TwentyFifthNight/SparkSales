public class RESTConstants {
    public final Method Method {
        get {
            return new Method();
        }
    }

    public final Integer MAX_REQUESTS_PER_BATCH {
        get {
            return 50;
        }
    }

    public class Method {
        public final String GET { get { return 'GET'; } }
        public final String POST { get { return 'POST'; } }
        public final String PATCH { get { return 'PATCH'; } }
    }
}