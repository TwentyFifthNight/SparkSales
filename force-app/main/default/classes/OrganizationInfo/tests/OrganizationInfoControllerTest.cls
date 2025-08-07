@isTest
private class OrganizationInfoControllerTest {

    @isTest
    static void testOrganizationInfoData() {
        Test.setCurrentPage(Page.OrganizationInfo);

        Test.startTest();
        OrganizationInfoController controller = new OrganizationInfoController();

        Integer apexClassCount = [SELECT COUNT() FROM ApexClass];
        Integer visualForcePageCount = [SELECT COUNT() FROM ApexPage];
        String sessioId = UserInfo.getSessionId();
        UserLicense license = [
            SELECT Name, TotalLicenses, UsedLicenses
            FROM UserLicense
            WHERE Name = 'Salesforce'
            LIMIT 1
        ];
        Integer availaleLicenseCount = license.TotalLicenses - license.UsedLicenses;
        System.assertEquals(apexClassCount, controller.apexClassCount);
        System.AssertEquals(visualForcePageCount, controller.visualforcePageCount);
        System.AssertEquals(sessioId, controller.sessionId);
        System.AssertEquals(availaleLicenseCount, controller.availableLicenseCounts.get(license.Name));
        Test.stopTest();
    }
}