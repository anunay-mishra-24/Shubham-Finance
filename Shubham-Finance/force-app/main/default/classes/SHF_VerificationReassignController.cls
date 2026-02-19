/**
* @File Name : SHF_VerificationReassignController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 23, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 23, 2025 |   | Initial Version
**/

public with sharing class SHF_VerificationReassignController {
    
    @AuraEnabled(cacheable=true)
    public static List<User> getBranchUsers(Id verificationId) {

        Set<Id> userIds = new Set<Id>();
        Set<Id> lowerRoleIds = new Set<Id>();
        List<User> filteredUsers;
        if (verificationId == null) {
            return new List<User>();
        }
        
        Verification__c verification = [SELECT Id, Application__r.Branch__c, OwnerId FROM Verification__c WHERE Id = :verificationId LIMIT 1 ];
        User ownerUser = [SELECT Id, UserRoleId FROM User WHERE Id = :verification.OwnerId LIMIT 1];
        
        
        if (verification.Application__r.Branch__c == null) {
            return new List<User>();
        }
        
        List<Branch_Mapping__c> mappings = [SELECT Internal_User__c, Internal_User__r.Name,Branch_Master__c FROM Branch_Mapping__c WHERE Branch_Master__c = :verification.Application__r.Branch__c];
        
        for (Branch_Mapping__c bm : mappings) {
            userIds.add(bm.Internal_User__c);
        }
        
        if(ownerUser.UserRoleId != null) {
            getLowerRoles(ownerUser.UserRoleId, lowerRoleIds);
        }
        
        if(lowerRoleIds.isEmpty()) {
            filteredUsers = new List<User>();
        } else {
            filteredUsers = [SELECT Id, Name FROM User WHERE Id IN :userIds AND UserRoleId IN :lowerRoleIds AND IsActive = true];
        }
        
        return filteredUsers;
        
    }
    
    @AuraEnabled
    public static void reassignVerification(Id verificationId, Id newOwnerId, String comments) {
        if (verificationId == null || newOwnerId == null) {
            throw new AuraHandledException('Invalid input. Please select a user.');
        }
        try {
            Verification__c verification = [SELECT Id, OwnerId, Is_Re_opened__c, Re_Assign_Comments__c FROM Verification__c WHERE Id = :verificationId];
            
            verification.OwnerId = newOwnerId;
            verification.Re_Assign_Comments__c = comments;
            if (verification.Is_Re_opened__c == false) {
                verification.Is_Re_opened__c = true;
            }
            
            update verification;
            
            SHF_VerificationReassignController.sendVerificationReassignNotification(verification.Id,newOwnerId);
            
        } catch (Exception e) {
            throw new AuraHandledException(
                'Reassignment failed: ' + e.getMessage()
            );
        }
    }
    
    
    private static void getLowerRoles(Id parentRoleId, Set<Id> allLowerRoleIds) {
        List<UserRole> childRoles = [SELECT Id FROM UserRole WHERE ParentRoleId = :parentRoleId];
        for(UserRole r : childRoles) {
            allLowerRoleIds.add(r.Id);
            getLowerRoles(r.Id, allLowerRoleIds);
        }
    }
    
    
    @AuraEnabled
    public static void sendVerificationReassignNotification(Id verificationId, Id assignedUserId) {
        
        if (verificationId == null || assignedUserId == null) {
            throw new AuraHandledException('Invalid input. Both Verification and User must be provided.');
        }
        
        try {
            Verification__c verification = [SELECT Id, Name  FROM Verification__c WHERE Id = :verificationId LIMIT 1];
            
            Set<String> recipients = new Set<String>{ assignedUserId };
                
                // Custom Labels
                String notificationTitle = Label.RCU_Verification_Re_Assign_Bell_NotificationTitle;
                String notificationBody  = Label.RCU_Verification_Re_Assign_Bell_Notification.replace('<Activity(ID)>', verification.Name);
            
            // Send notification using SHF_CommonUtil
            SHF_CommonUtil.notifyUsersByNotification(recipients, verification.Id, notificationTitle, notificationBody, 'Send_Notification_To_User');
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to send notification: ' + e.getMessage());
        }
    }
}