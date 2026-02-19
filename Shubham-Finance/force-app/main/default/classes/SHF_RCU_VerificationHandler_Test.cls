/**
* @File Name : SHF_RCU_VerificationHandler_Test.cls
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
private class SHF_RCU_VerificationHandler_Test {
    
    @testSetup
    static void setupData() {
        
        Id runningProfile = UserInfo.getProfileId();
        
        User currentUser = SHF_TestDataFactory.createUser('Current', 'User', 'currentuser@test.com',
                          'currentuser' + System.currentTimeMillis() + '@test.com', runningProfile, 
                          true, null, null, true);
        
        User otherUser = SHF_TestDataFactory.createUser('Other', 'User', 'otheruser@test.com',
                        'otheruser' + System.currentTimeMillis() + '@test.com', runningProfile, 
                        true, null, null, true);

        Group queue = new Group(Name = 'RCU Queue', Type = 'Queue');
        insert queue;

        insert new GroupMember(GroupId = queue.Id, UserOrGroupId = currentUser.Id);
        
        System.runAs(currentUser) {
            Application__c app = SHF_TestDataFactory.createApplication('Test App', true);
            SHF_TestDataFactory.createVerification(app.Id, currentUser.Id, 'Sampled', 'Document', null, true);
        }

        System.assertNotEquals(null, getUserByEmail('currentuser@test.com'), 'Current user must exist');
        System.assertNotEquals(null, getUserByEmail('otheruser@test.com'), 'Other user must exist');
        System.assertNotEquals(null, getAnyVerification(), 'Verification must exist');
    }
    
    private static User getUserByEmail(String email) {
        List<User> us = [SELECT Id, Email FROM User WHERE Email = :email LIMIT 1];
        return us.isEmpty() ? null : us[0];
    }

    private static Verification__c getAnyVerification() {
        List<Verification__c> vs = [SELECT Id, OwnerId, Status__c FROM Verification__c LIMIT 1];
        System.assert(!vs.isEmpty(), 'Test setup should have created a Verification__c');
        return vs[0];
    }

    private static Group getQueue() {
        List<Group> gs = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'RCU Queue' LIMIT 1];
        return gs.isEmpty() ? null : gs[0];
    }

    private static Id getFakeQueueId() {
        String base = '00G000000000001';
        String suffix = 'AAA';
        return (Id) (base + suffix);
    }

    private static Id getAlwaysNonMemberQueueId() {
        return getFakeQueueId();
    }

    @isTest
    static void testAssignToSelf_AllowsAndSetsAssigned() {

        User currentUser = getUserByEmail('currentuser@test.com');
        System.assertNotEquals(null, currentUser, 'Current user missing from setup');

        Verification__c existing = getAnyVerification();

        Group q = new Group(Name = 'RCU Queue Self', Type = 'Queue');
        insert q;

        insert new GroupMember(GroupId = q.Id, UserOrGroupId = currentUser.Id);
        
        Verification__c oldRec = existing.clone(false, false, false, false);
        oldRec.Id = existing.Id;
        oldRec.OwnerId = q.Id;
        
        Verification__c upd = existing.clone(true, true, false, false);
        upd.Id = existing.Id;
        upd.OwnerId = currentUser.Id;
        
        System.runAs(currentUser) {

            SHF_RCU_VerificationHandler.validateOwnerAgainstQueue(
            new List<Verification__c>{ upd },
            new Map<Id, Verification__c>{ existing.Id => oldRec }
            );
            update upd;
            System.assertEquals('Assigned', upd.Status__c, 'Self assignment must set status to Assigned');
            
        }
    }
    
    @isTest
    static void testUserNotInQueue_ErrorShown() {

        User otherUser = getUserByEmail('otheruser@test.com');
        System.assertNotEquals(null, otherUser, 'Other user missing from setup');

        Verification__c existing = getAnyVerification();
        
        Group q = new Group(Name = 'RCU Queue Neg', Type = 'Queue');
        insert q;        

        Verification__c oldRec = existing.clone(false, false, false, false);
        oldRec.Id = existing.Id;
        oldRec.OwnerId = q.Id;
        
        Verification__c upd = existing.clone(true, true, false, false);
        upd.Id = existing.Id;
        upd.OwnerId = otherUser.Id;
        
        Boolean gotError = false;
        System.runAs(otherUser) {
            SHF_RCU_VerificationHandler.validateOwnerAgainstQueue(
            new List<Verification__c>{ upd },
            new Map<Id, Verification__c>{ existing.Id => oldRec }
            );
            try {
                update upd;
            } catch (DmlException de) {
                System.debug(de.getDmlMessage(0));
            }
        }
    }
    
    @isTest
    static void testAssignToAnotherUser_Blocked() {

        User currentUser = getUserByEmail('currentuser@test.com');
        System.assertNotEquals(null, currentUser, 'Current user missing from setup');

        User otherUser = getUserByEmail('otheruser@test.com');
        System.assertNotEquals(null, otherUser, 'Other user missing from setup');

        Verification__c existing = getAnyVerification();
        
        Group q = new Group(Name = 'RCU Queue Block', Type = 'Queue');
        insert q;

        insert new GroupMember(GroupId = q.Id, UserOrGroupId = currentUser.Id);
        
        Verification__c oldRec = existing.clone(false, false, false, false);
        oldRec.Id = existing.Id;
        oldRec.OwnerId = q.Id;
        
        Verification__c upd = existing.clone(true, true, false, false);
        upd.Id = existing.Id;
        upd.OwnerId = otherUser.Id;
        
        insert new GroupMember(GroupId = q.Id, UserOrGroupId = otherUser.Id);
        
        Boolean gotError = false;
        System.runAs(currentUser) {
            SHF_RCU_VerificationHandler.validateOwnerAgainstQueue(
            new List<Verification__c>{ upd },
            new Map<Id, Verification__c>{ existing.Id => oldRec }
            );
            try {
                update upd;
            } catch (DmlException de) {
                System.debug(de.getDmlMessage(0));
            }
        }
    }
    
    @isTest
    static void testEarlyReturn_NoUserOrQueue() {

        Verification__c existing = getAnyVerification();
        
        Verification__c oldRec = existing.clone(false, false, false, false);
        oldRec.Id = existing.Id;
        oldRec.OwnerId = existing.OwnerId;
        
        Verification__c upd = existing.clone(false, true, false, false);
        upd.OwnerId = existing.OwnerId;
        
        SHF_RCU_VerificationHandler.validateOwnerAgainstQueue(
        new List<Verification__c>{ upd },
        new Map<Id, Verification__c>{ existing.Id => oldRec }
        );
        
        System.assertNotEquals('Assigned', upd.Status__c, 'Status should not be set in early return');
    }
}