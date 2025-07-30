public class OrderInvoiceService {
    @future(callout=true)
    public static void handleActivatedOrders(List<Id> orderIds){
        if (orderIds.size() > 0) {
            List<Order> orders = [SELECT Id, OrderNumber, isSigned__c FROM Order WHERE Id IN :orderIds];
            createPDFAttachements(orders);
        }
    }

    private static void createPDFAttachements(List<Order> orders) {
        List<ContentVersion> pdfFiles = new List<ContentVersion>();
        String currentDate = Datetime.now().format('yyyy_MM_dd_HH_mm_ss');
        for(Order order : orders) {
            PageReference pdfPage = Page.OrderInvoice;
            pdfPage.getParameters().put('id', order.Id);

            Blob pdfBlob; 
            if(Test.isRunningTest()){
                pdfBlob = Blob.valueOf('Unit.Test');
            } else{
                pdfBlob = pdfPage.getContentAsPDF();
            }
            
            String title = 'Invoice_' + order.OrderNumber + '_' + currentDate;
            ContentVersion pdf = new ContentVersion();
            pdf.Title = title;
            pdf.PathOnClient = title + '.pdf';
            pdf.VersionData = pdfBlob;
            pdf.FirstPublishLocationId = order.Id;
            pdfFiles.add(pdf);
            order.isSigned__c = false;
        }
        insert pdfFiles;
    }
}