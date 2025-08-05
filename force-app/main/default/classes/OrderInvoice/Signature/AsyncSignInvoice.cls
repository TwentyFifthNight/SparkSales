public class AsyncSignInvoice implements Queueable, Database.AllowsCallouts {
    private String orderId;
    private String signatureId;
    
    public AsyncSignInvoice(String orderId, String signatureId){
        this.orderId = orderId;
        this.signatureId = signatureId;
    }
    
    public void execute(QueueableContext context) {
        updatePdfSignature(orderId, signatureId);
    }

    public static void updatePdfSignature(String orderId, String signatureId){
        List<Order> order = [SELECT Id, OrderNumber, isSigned__c FROM Order WHERE Id = :orderId];
        if(order.size() < 1) {
            return;
        }

        PageReference pdfPage = Page.OrderInvoice;
        pdfPage.getParameters().put('id', orderId);

        Blob pdfBlob;
        if(Test.isRunningTest()){
            pdfBlob = Blob.valueOf('Unit.Test');
        }else{
            pdfBlob = pdfPage.getContentAsPDF();
        }

        String title = 'Invoice_' + order[0].OrderNumber + '%';
        try {
            List<ContentVersion> pdfFiles = [SELECT ContentDocumentId, PathOnClient, Title  FROM ContentVersion WHERE FirstPublishLocationId = :orderId AND Title LIKE :title ORDER BY LastModifiedDate DESC LIMIT 1];
            if (pdfFiles.size() > 0) {
                ContentVersion pdf = new ContentVersion();
                pdf.Title = pdfFiles[0].Title;
                pdf.PathOnClient = pdfFiles[0].PathOnClient;
                pdf.VersionData = pdfBlob;
                pdf.ContentDocumentId = pdfFiles[0].ContentDocumentId;
                insert pdf;
                order[0].isSigned__c = true;
                update order[0];
            }
        } finally{
            deleteAttachedSigantures(orderId, signatureId);
        }
    }

    private static void deleteAttachedSigantures(String orderId, String signatureId){
        List<ContentDocument> signatureToDelete = [
            SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :signatureId
        ];
        delete signatureToDelete;
    }
}