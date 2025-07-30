public class Constants {
    public static final Id STANDARD_PRICEBOOK_ID = [select Id from Pricebook2 where isStandard = true limit 1].Id;
}