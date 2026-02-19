/**
* @File Name          : SHF_UsersSelectorTest.cls
* @Author             : Preeti
* @Last Modified By   : Preeti
* @Last Modified On   : 18-08-2025
* @Description        : This test class verifies the functionality of SHF_UsersSelector.
*                        It creates sample users with different profiles and statuses
*                        and tests methods.
*================================================================================================
* Update Ver         Date                     Author                 Modification                    
*================================================================================================
* 1.0             18-08-2025               Preeti                  Initial Version            
*/


@IsTest
private class SHF_UsersSelectorTest {
    
    
    // Prepare test data once for all test methods
    @TestSetup
    static void setupTestData() {
        // Get Profiles for testing
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile customerServiceProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        
        // Create an active admin user
        SHF_TestDataFactory.createUser(
            'Active', 'Admin', 'activeadmin@test.com',
            'activeadmin' + System.currentTimeMillis() + '@test.com',
            sysAdminProfile.Id,
            true, '1111111111', '9999999999', true
        );
        
        // Create an active customer service user
        
        SHF_TestDataFactory.createUser(
            'Customer', 'Service', 'customerservice@test.com',
            'customerservice' + System.currentTimeMillis() + '@test.com',
            customerServiceProfile.Id,
            true, '2222222222', '8888888888', true
        );
        
        // Create an inactive user
        
        SHF_TestDataFactory.createUser(
            'Inactive', 'User', 'inactive@test.com',
            'inactive' + System.currentTimeMillis() + '@test.com',
            sysAdminProfile.Id,
            false, '3333333333', null, true
        );
    }
    
    // Test selecting a user by phone number
    @IsTest
    static void testSelectUserWithPhone() {
        SHF_UsersSelector selector = new SHF_UsersSelector();
        User u = selector.selectUserWithPhone('1111111111');
        System.assertNotEquals(null, u, 'User should be found by phone');
        System.assertEquals('Active Admin', u.Name);
    }
    
    // Test selecting users by a set of IDs
    @IsTest
    static void testSelectByIdsUserName() {
        List<User> allUsers = [SELECT Id FROM User LIMIT 3];
        Set<Id> userIds = new Set<Id>();
        for(User u : allUsers) userIds.add(u.Id);
        
        SHF_UsersSelector selector = new SHF_UsersSelector();
        List<User> users = selector.selectByIdsUserName(userIds);
        System.assertEquals(userIds.size(), users.size(), 'Should return all users by Id');
    }
    
    // Test selecting active users by their profile
    @IsTest
    static void testSelectActiveUsersByProfile() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Set<Id> profileIds = new Set<Id>{ p.Id };
            
            SHF_UsersSelector selector = new SHF_UsersSelector();
        List<User> users = selector.selectActiveUsersByProfile(profileIds);
        System.assert(!users.isEmpty(), 'Should return at least 1 active user');
        System.assert(users[0].IsActive, 'Returned user should be active');
    }
    
    // Test selecting active sales users
    @IsTest
    static void testSelectActiveSalesUsers() {
        // This method currently selects users with ManagerId != null
        // So we just test that it runs without exception
        SHF_UsersSelector selector = new SHF_UsersSelector();
        List<User> users = selector.selectActiveSalesUsers('Sales');
        System.assertNotEquals(null, users, 'Method should return a list (empty or not)');
    }
    
    
    // Test selecting active customer service users
    @IsTest
    static void testSelectActiveCustomerServiceUsers() {
        SHF_UsersSelector selector = new SHF_UsersSelector();
        List<User> users = selector.selectActiveCustomerServiceUsers('Customer Service');
        System.assert(!users.isEmpty(), 'Should return at least 1 customer service user');
        System.assertNotEquals(null, users[0].ProfileId, 'User should have a ProfileId');
    }
    // Manager hierarchy validation
    @IsTest
    static void testManagerHierarchy() {
        Profile csProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        
        // Create Lead (top-level manager)
        User leadUser = SHF_TestDataFactory.createUser(
            'tatLead', 'User', 'lead@test.com',
            'lead' + System.currentTimeMillis() + '@test.com',
            csProfile.Id, true, '7777777777', '9999999999', true
        );
        
        // Create Manager (reports to Lead)
        User mgrUser = new User(
            FirstName = 'tatMgr',
            LastName = 'User',
            Alias = 'tatmgr',
            Email = 'mgr@test.com',
            Username = 'mgr' + System.currentTimeMillis() + '@test.com',
            ProfileId = csProfile.Id,
            IsActive = true,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ManagerId = leadUser.Id
        );
        insert mgrUser;
        
        // Create Owner (reports to Manager)
        User ownerUser = new User(
            FirstName = 'tatOwner',
            LastName = 'User',
            Alias = 'tatowner',
            Email = 'owner@test.com',
            Username = 'owner' + System.currentTimeMillis() + '@test.com',
            ProfileId = csProfile.Id,
            IsActive = true,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ManagerId = mgrUser.Id
        );
        insert ownerUser;
        
        // Call selector
        SHF_UsersSelector selector = new SHF_UsersSelector();
        List<User> users = selector.selectActiveCustomerServiceUsers('Customer Service');
        
        System.assertNotEquals(0, users.size(), 'Expected users in result');
        
        // Validate hierarchy mapping
        Map<Id, String> hierarchyMap = new Map<Id, String>();
        for(User u : users){
            if(u.ManagerId != null){
                hierarchyMap.put(u.Id,
                                 u.ManagerId + '#' + u.Manager.Email + '#' + u.Manager.Name + '#' +
                                 u.MobilePhone + '#' + u.Email
                                );
            }
        }
        
        System.assertEquals(mgrUser.Id, ownerUser.ManagerId, 'Owner should report to Manager');
        System.assertEquals(leadUser.Id, mgrUser.ManagerId, 'Manager should report to Lead');
        System.assertEquals(true, hierarchyMap.containsKey(ownerUser.Id), 'Owner should be in hierarchyMap');
    }
    
   
}