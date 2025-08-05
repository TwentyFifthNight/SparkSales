public class SignatureController {
    
    @AuraEnabled
    public static void saveSignature(String signElement,Id recId){
        SignatureService.saveSignature(signElement, recId);
    }
}