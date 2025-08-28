public class ComplaintItemConstants {
    public final Status Status {
        get {
            return new Status();
        }
    }
    
    public final RefundType RefundType {
        get {
            return new RefundType();
        }
    }

    public class Status {
        public final String ERROR { get { return 'Error'; } }
        public final String APPROVED { get { return 'Approved'; } }
        public final String REJECTED { get { return 'Rejected'; } }
    }

    public class RefundType {
        public final String FULL { get { return 'Full'; } }
        public final String PARTIAL { get { return 'Partial'; } }
    }
}