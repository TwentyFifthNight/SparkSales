public with sharing class OrganizationInfoController {
    public class UserWrapper {
        public User user { get; private set; }
        public String device { get; private set; }

        public UserWrapper(User user, String device) {
            this.user = user;
            this.device = device;
        }
    }
    
	public List<UserWrapper> usersWrappers { get; private set; }
    public Map<String, Integer> availableLicenseCounts { get; private set; }
    public Integer apexClassCount { get; private set; }
    public Integer visualforcePageCount { get; private set; }
    public String sessionId { get; private set; }
    public String selectedId { get; set; }

    public OrganizationInfoController() {
        initializeUserWrappers();
        apexClassCount = [SELECT COUNT() FROM ApexClass];
        visualforcePageCount = [SELECT COUNT() FROM ApexPage];
        initializeavailableLicenseCount();
        sessionId = UserInfo.getSessionId();
    }
    
    private void initializeUserWrappers() {
        List<User> users = [SELECT Username, Email, IsActive FROM User];
       
        Map<Id, String> userDeviceMap = new Map<Id, String>();
        for (AggregateResult ar : [
            SELECT UserId, Platform, MAX(LoginTime) lastLogin
            FROM LoginHistory
            WHERE UserId IN :users
            GROUP BY UserId, Platform
        ]) {
            userDeviceMap.put((Id)ar.get('UserId'), (String)ar.get('Platform'));
        }
        
        usersWrappers = new List<UserWrapper>();
        for (User user : users) {
            String device = userDeviceMap.containsKey(user.Id) ? userDeviceMap.get(user.Id) : 'N/A';
            usersWrappers.add(new UserWrapper(user, device));
        }
    }
    
    private void initializeavailableLicenseCount() {
        availableLicenseCounts = new Map<String, Integer>();
        for (UserLicense userLicense : [
            SELECT Name, TotalLicenses, UsedLicenses
            FROM UserLicense
        ]) {
            availableLicenseCounts.put(userLicense.Name, userLicense.TotalLicenses - userLicense.UsedLicenses);
        }
    }

    public PageReference viewUser() {
        return new PageReference('/' + selectedId);
    }
}