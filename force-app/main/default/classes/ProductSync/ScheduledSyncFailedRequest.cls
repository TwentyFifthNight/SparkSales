public class ScheduledSyncFailedRequest implements Schedulable {
    public void execute( SchedulableContext context ) {
        if (!Test.isRunningTest()) {
            Database.executeBatch(new BatchSyncFailedRequest(), Constants.RequestLog.MAX_REQUESTS_PER_BATCH);
        } else {
            Database.executeBatch(new BatchSyncFailedRequest(), 2000);
        }
    }
}