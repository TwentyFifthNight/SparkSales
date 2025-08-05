public class SignatureController {
    
    @AuraEnabled
    public static void saveSignature(String signElement,Id recId){
        ContentVersion siganture = new ContentVersion();
        siganture.Title = 'signature';
        siganture.PathOnClient = 'signature.png';
        siganture.VersionData = EncodingUtil.base64Decode(signElement);
        siganture.FirstPublishLocationId = recId;
        insert siganture;
        System.enqueueJob(new AsyncSignInvoice(recId, siganture.Id));
    }
}