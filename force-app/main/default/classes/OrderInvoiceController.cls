public class OrderInvoiceController {
    public List<OrderItem> OrderItems { get; set; }
    public Decimal SubTotal { get; set; }
    public Decimal Tax { get; set; }
    public Decimal TotalAmount { get; set; }
    public String Signature {get;set;}
    public String FormatedIssuedDate { get; set; }

    private final Order order;


    public OrderInvoiceController(ApexPages.StandardController stdCtrl) {
        this.order = (Order)stdCtrl.getRecord();
        Order tempOrder = [SELECT EffectiveDate FROM Order WHERE Id = :this.order.Id];
        Tax = 23;
        FormatedIssuedDate = tempOrder.EffectiveDate.format();
        loadOrderItems();
        loadSignature();
    }

    private void loadOrderItems() {
        OrderItems = [
            SELECT Id, Quantity, UnitPrice, TotalPrice,
                   PricebookEntry.Name
            FROM OrderItem
            WHERE OrderId = :order.Id
        ];
        
        SubTotal = 0;
        for (OrderItem item : OrderItems) {
            SubTotal += item.TotalPrice;
        }
        TotalAmount = SubTotal + SubTotal * Tax / 100;
    }

    private void loadSignature(){
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, ContentDocument.FileExtension, 
                ContentDocument.LatestPublishedVersionId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :order.Id AND ContentDocument.FileExtension = 'png'
                AND ContentDocument.Title LIKE 'signature%'
        ];
        
        for( ContentDocumentLink link : links){
            if (link.ContentDocument.FileExtension == 'png') {
                String version = link.ContentDocument.LatestPublishedVersionId;
                Signature = '/sfc/servlet.shepherd/version/download/' + version;
                break;
            }
        }

    }
}