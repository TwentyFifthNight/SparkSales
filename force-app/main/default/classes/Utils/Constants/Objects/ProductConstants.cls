public class ProductConstants {
    public final Family Family {
        get {
            return new Family();
        }
    }

    public class Family {
        public final String ADAPTERS { get { return 'Adapters'; } }
        public final String CABLES { get { return 'Cables'; } }
        public final String NETWORKING { get { return 'Networking'; } }
    }
}