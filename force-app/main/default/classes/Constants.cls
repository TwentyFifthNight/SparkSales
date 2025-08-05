public class Constants {
    public static Id STANDARD_PRICEBOOK_ID {
        get {
            if (STANDARD_PRICEBOOK_ID == null) {
                STANDARD_PRICEBOOK_ID = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
            }
            return STANDARD_PRICEBOOK_ID;
        }
        private set;
    }
}