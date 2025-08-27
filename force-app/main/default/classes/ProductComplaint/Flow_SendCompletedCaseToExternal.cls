public with sharing class Flow_SendCompletedCaseToExternal {
    @InvocableMethod(label='Send Completed Case to External System' description='Sends the completed case information to the external system' category='Product Complaint')
    public static void sendCompletedCaseToExternal(List<Id> caseId) {
        List<String> externalCaseIds = new List<String>();
        for (Case c : [SELECT ExternalCaseId__c FROM Case WHERE Id IN :caseId]) {
            if (c.ExternalCaseId__c != null) {
                externalCaseIds.add(c.ExternalCaseId__c);
            }
        }
        if (externalCaseIds.isEmpty()) {
            return;
        }
        System.enqueueJob(new AsyncSendEventToExternal(externalCaseIds));
    }

    public class AsyncSendEventToExternal implements Queueable, Database.AllowsCallouts {
        private List<String> externalCaseIds;

        public AsyncSendEventToExternal(List<String> externalCaseIds) {
            this.externalCaseIds = externalCaseIds;
        }

        public void execute(QueueableContext context) {
            Map<String, String> event = new Map<String, String>();
            event.put('CaseIds__c', JSON.serialize(externalCaseIds));

            HttpRequest req = new HttpRequest();
            req.setEndpoint(Constants.EXTERNAL_COMPLAINT_COMPLETED_EVENT_API_ENDPOINT);
            req.setMethod(Constants.RestAPI.Method.POST);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(event));
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 201) {
                throw new CalloutException('Error sending event to external system');
            }
        }
    }
}