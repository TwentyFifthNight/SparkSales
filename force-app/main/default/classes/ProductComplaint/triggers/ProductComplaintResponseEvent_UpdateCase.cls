public class ProductComplaintResponseEvent_UpdateCase implements TriggerAction.AfterInsert {
    public void afterInsert(List<ProductComplaintResponseEvent__e> newList){
        Set<Id> caseIds = new Set<Id>();
        for (ProductComplaintResponseEvent__e event : newList) {
            if (event.TrackingId__c != null) {
                caseIds.add(event.TrackingId__c);
            }
        }

        Map<Id, Case> casesToUpdate = new Map<Id, Case>([
            SELECT ExternalCaseId__c
            FROM Case
            WHERE Id IN :caseIds
        ]);

        for (ProductComplaintResponseEvent__e event : newList) {
            if (casesToUpdate.containsKey(event.TrackingId__c)) {
                Case caseUpdate = casesToUpdate.get(event.TrackingId__c);
                caseUpdate.ExternalCaseId__c = event.CaseId__c;
            }
        }

        update casesToUpdate.values();
    }
}