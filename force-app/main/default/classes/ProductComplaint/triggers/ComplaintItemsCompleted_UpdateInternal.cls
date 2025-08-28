public with sharing class ComplaintItemsCompleted_UpdateInternal implements TriggerAction.AfterInsert {
    public void afterInsert(List<ComplaintItemCompleted__e> newList){
        List<ComplaintBody> complaints = new List<ComplaintBody>();
        Set<String> externalProductIds = new Set<String>();
        Set<String> caseIds = new Set<String>();
        for (ComplaintItemCompleted__e event : newList) {
            try {
                List<ComplaintBody> eventComplaints = (List<ComplaintBody>) JSON.deserialize(event.ComplaintItems__c, List<ComplaintBody>.class);
                for(ComplaintBody complaint : eventComplaints){
                    if(complaint.ProductId != null){
                        externalProductIds.add(complaint.ProductId);
                    }
                    if(complaint.CaseId != null){
                        caseIds.add(complaint.CaseId);
                    }
                }
                complaints.addAll(eventComplaints);
            } catch (Exception e) {
                System.debug('Error deserializing event data: ' + e.getMessage());
            }
        }

        List<Product2> products = [
            SELECT Id, ExternalId__c
            FROM Product2 
            WHERE ExternalId__c IN :externalProductIds
        ];

        Map<String, Product2> externalIdToProduct = new Map<String, Product2>();
        for(Product2 product : products){
            externalIdToProduct.put(product.ExternalId__c, product);
        }
        
        List<ComplaintItem__c> complaintItemsToUpdate = [
            SELECT Id, Status__c, Product__c, Case__c, RefundAmount__c, RefundType__c
            FROM ComplaintItem__c
            WHERE Product__c IN :products AND Case__c IN :caseIds
        ];

        Map<Id, Map<Id, ComplaintItem__c>> caseIdToProductIdToComplaintItem = new Map<Id, Map<Id, ComplaintItem__c>>();
        for(ComplaintItem__c item : complaintItemsToUpdate){
            if(!caseIdToProductIdToComplaintItem.containsKey(item.Case__c)){
                caseIdToProductIdToComplaintItem.put(item.Case__c, new Map<Id, ComplaintItem__c>());
            }
            caseIdToProductIdToComplaintItem.get(item.Case__c).put(item.Product__c, item);
        }
        
        List<ComplaintItem__c> itemsToUpdate = new List<ComplaintItem__c>();
        for(ComplaintBody complaint : complaints){
            if(complaint.CaseId != null && complaint.ProductId != null && externalIdToProduct.containsKey(complaint.ProductId)){
                Product2 product = externalIdToProduct.get(complaint.ProductId);
                if(caseIdToProductIdToComplaintItem.containsKey(complaint.CaseId) && caseIdToProductIdToComplaintItem.get(complaint.CaseId).containsKey(product.Id)){
                    ComplaintItem__c itemToUpdate = caseIdToProductIdToComplaintItem.get(complaint.CaseId).get(product.Id);
                    itemToUpdate.Status__c = complaint.Status;
                    itemToUpdate.RefundType__c = complaint.RefundType;
                    itemToUpdate.RefundAmount__c = complaint.RefundAmount;
                    itemsToUpdate.add(itemToUpdate);
                }
            }
        }
        if(!itemsToUpdate.isEmpty()){
            List<Database.SaveResult> saveResults = Database.update(itemsToUpdate, false);
            for(Database.SaveResult saveResult : saveResults){
                if(!saveResult.isSuccess()){
                    System.debug('Error updating complaint item: ' + saveResult.getErrors());
                }
            }
        }

    }

    private class ComplaintBody{
        String CaseId;
        String ProductId;
        String Status;
        String RefundType;
        Decimal RefundAmount;
    }
}