public class BatchStatusTracker {
	public static Boolean isBatchRunning(String jobName) {
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = :jobName
            AND Status NOT IN ('Completed', 'Aborted')
            LIMIT 1
        ];
        return !jobs.isEmpty();
    }
}