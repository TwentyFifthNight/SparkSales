public class RESTConstants {
    public final Method Method {
        get {
            return new Method();
        }
    }

    public class Method {
        public final String POST { get { return 'POST'; } }
        public final String PATCH { get { return 'PATCH'; } }
    }
}