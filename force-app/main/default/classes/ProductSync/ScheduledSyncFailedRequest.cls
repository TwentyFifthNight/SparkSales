public class ScheduledSyncFailedRequest implements Schedulable {
    public void execute( SchedulableContext context ) {
        if (!Test.isRunningTest()) {
            Database.executeBatch(new BatchSyncFailedRequest(), (Integer)Constants.REQUEST_LOG_SETTING.MaxRequestsPerBatch__c);
        } else {
            Database.executeBatch(new BatchSyncFailedRequest(), 2000);
        }
    }
}