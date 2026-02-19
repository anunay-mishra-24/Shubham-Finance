/**
* @File Name : SHF_VerificationReassignController_Test.cls
* @Description :
* @Author : Anand
* @Last Modified By :
* @Last Modified On : December 30, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 30, 2025 |   | Initial Version
**/

@isTest
private class SHF_VerificationReassignController_Test {
    
    @TestVisible
    private static Boolean notificationCalled = false;
    
    @TestVisible
    private static void notifyUsersByNotification(Set<String> recipients, Id recordId, String title, String body, String action){
        notificationCalled = true;
    }
    
    @testSetup
    static void setupTestData() {
        
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User adminUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        System.runAs(adminUser) {
            
            UserRole parentRole = new UserRole(Name = 'ManagerRole');
            insert parentRole;
            
            UserRole childRole = new UserRole(Name = 'OfficerRole', ParentRoleId = parentRole.Id);
            insert childRole;
            
            User parentUser = SHF_TestDataFactory.createUser(
                'Manager','User','m@test.com','m'+System.currentTimeMillis()+'@mail.com',
            stdProfile.Id,true,'9999999999','9999999999',false
                );
            parentUser.UserRoleId = parentRole.Id;
            insert parentUser;
            
            User childUser = SHF_TestDataFactory.createUser(
                'Officer','User','o@test.com','o'+System.currentTimeMillis()+'@mail.com',
            stdProfile.Id,true,'8888888888','8888888888',false
                );
            childUser.UserRoleId = childRole.Id;
            insert childUser;
        }
        
        Branch_Master__c branch = SHF_TestDataFactory.createBranchMaster('Mumbai', 'BR001', true);
        
        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);
        app.Branch__c = branch.Id;
        update app;
        
        User parent = [SELECT Id FROM User WHERE FirstName = 'Manager' LIMIT 1];
        SHF_TestDataFactory.createVerification(app.Id, parent.Id, 'Sampled', 'Document', null, true);
        
        User officer = [SELECT Id FROM User WHERE FirstName = 'Officer' LIMIT 1];
        
        insert new Branch_Mapping__c(
            Branch_Master__c = branch.Id,
        Internal_User__c = officer.Id
            );
    }
    
    @isTest
    static void test_GetBranchUsers_Valid() {
        Verification__c v = [SELECT Id FROM Verification__c LIMIT 1];
        Test.startTest();
        List<User> users = SHF_VerificationReassignController.getBranchUsers(v.Id);
        Test.stopTest();
        System.assert(!users.isEmpty(), 'Expected users for branch & role');
    }
    
    @isTest
    static void test_GetBranchUsers_Null() {
        Test.startTest();
        List<User> users = SHF_VerificationReassignController.getBranchUsers(null);
        Test.stopTest();
        System.assertEquals(0, users.size());
    }
    
    @isTest
    static void test_ReassignVerification_Success() {
        Verification__c v = [SELECT Id FROM Verification__c LIMIT 1];
        User officer = [SELECT Id FROM User WHERE FirstName = 'Officer' LIMIT 1];
        
        Test.startTest();
        try {
            SHF_VerificationReassignController.reassignVerification(v.Id, officer.Id, 'Reassigned');
        } catch (Exception e) {
            System.debug('Expected notification exception ignored: ' + e.getMessage());
        }
        Test.stopTest();
        
        Verification__c updated = [
        SELECT OwnerId, Is_Re_opened__c, Re_Assign_Comments__c 
        FROM Verification__c WHERE Id = :v.Id
    ];
        
        System.assertEquals(officer.Id, updated.OwnerId, 'Owner should update');
        System.assertEquals(true, updated.Is_Re_opened__c, 'Record should mark reopened');
        System.assertEquals('Reassigned', updated.Re_Assign_Comments__c, 'Comment should update');
    }
    
    
    @isTest
    static void test_ReassignVerification_NullParams() {
        Boolean didThrow = false;
        try {
            SHF_VerificationReassignController.reassignVerification(null, null, 'X');
        } catch (Exception e) {
            didThrow = true;
        }
        System.assert(didThrow, 'Exception must be thrown when IDs are null');
    }
    
    @isTest
    static void test_SendNotification_Success() {
        Verification__c v = [SELECT Id FROM Verification__c LIMIT 1];
        User officer = [SELECT Id FROM User WHERE FirstName = 'Officer' LIMIT 1];
        
        Test.startTest();
        SHF_VerificationReassignController.sendVerificationReassignNotification(v.Id, officer.Id);
        Test.stopTest();
        
        System.assertEquals(true, notificationCalled, 'Notification should fire');
    }
    
    @isTest
    static void test_SendNotification_Null() {
        Boolean thrown = false;
        try {
            SHF_VerificationReassignController.sendVerificationReassignNotification(null, null);
        } catch (Exception e) {
            thrown = true;
        }
        System.assert(thrown, 'Should throw exception for missing IDs');
    }
}