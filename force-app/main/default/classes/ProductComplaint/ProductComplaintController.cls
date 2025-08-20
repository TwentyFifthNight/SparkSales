public class ProductComplaintController {

    @AuraEnabled(Cacheable=true)
    public static List<Product2> getProducts(String orderId) {
        return ProductComplaintService.getProducts(orderId);
    }

    @AuraEnabled(Cacheable=false)
    public static ComplaintResult submitComplaints(List<Id> productIds, String orderId){
        return ProductComplaintService.submitComplaints(productIds, orderId);
    }

    public class ComplaintResult {
        @AuraEnabled public String status;
        @AuraEnabled public String trackingId;
    }
}