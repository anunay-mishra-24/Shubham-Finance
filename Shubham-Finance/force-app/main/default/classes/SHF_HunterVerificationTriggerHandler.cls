/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_HunterVerificationTriggerHandler
 * Author          : Preeti
 * Created Date    : Jan 28, 2026
 * Last Modified By: Preeti
 * Last Modified On: Jan 28, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 28, 2026  │ Preeti │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */


public with sharing class SHF_HunterVerificationTriggerHandler {
    
    // Validates record owner changes before update
    // Enforces queue rules, Hunter Analyst restrictions, RCU & above, and new owner must be Hunter Analyst
    public static void beforeUpdate(List<Hunter_Verification__c> newList,Map<Id, Hunter_Verification__c> oldMap) {
        
        Set<Id> userIds  = new Set<Id>();
        Set<Id> queueIds = new Set<Id>();
        
        Id currentUserId = UserInfo.getUserId();
        userIds.add(currentUserId);
        
        
        for (Hunter_Verification__c hv : newList) {
            
            Hunter_Verification__c oldHv = oldMap.get(hv.Id);
            
            if (hv.OwnerId != oldHv.OwnerId) {
                
                if (isUser(oldHv.OwnerId)) {
                    userIds.add(oldHv.OwnerId);
                }
                
                if (isUser(hv.OwnerId)) {
                    userIds.add(hv.OwnerId);
                }
                
                if (isQueue(oldHv.OwnerId)) {
                    queueIds.add(oldHv.OwnerId);
                }
            }
        }
        
        if (userIds.isEmpty()) {
            return;
        }
        
        Map<Id, User> userMap = getUsers(userIds);
        Map<Id, Set<Id>> queueMembersMap = getQueueMembers(queueIds);
        User currentUser = userMap.get(currentUserId);
        String currentUserRole = currentUser.UserRole != null ? currentUser.UserRole.Name : '';
        
        for (Hunter_Verification__c hv : newList) {
            
            Hunter_Verification__c oldHv = oldMap.get(hv.Id);
            
            if (hv.OwnerId == oldHv.OwnerId) {
                continue;
            }
            
            Boolean oldOwnerIsQueue = isQueue(oldHv.OwnerId);
            
            if (oldOwnerIsQueue) {
                
                Set<Id> members = queueMembersMap.get(oldHv.OwnerId);
                
                // Queue membership check
                if (members == null || !members.contains(hv.OwnerId)) {
                    hv.addError('You are not the part of respective queue');
                    continue;
                }
                
                // Self assignment check
                if (hv.OwnerId != currentUserId) {
                    hv.addError('You can assign the activity to yourself only');
                    continue;
                }
                
                // Role check (must be Hunter Analyst)
                if (currentUserRole != 'Hunter Analyst') {
                    hv.addError('Only Hunter Analyst can take ownership from queue');
                    continue;
                }
                
                continue;
            }
            
            
            // OLD OWNER = USER
            
            // Hunter Analyst restriction
            if (currentUserRole == 'Hunter Analyst') {
                
                if (hv.OwnerId != currentUserId) {
                    hv.addError('Hunter Analyst is not authorized to assign this record to another user');
                }
                continue;
            }
            
            // RCU & above check
            User currentUsers = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            if (!isRCUOrAbove(currentUserId)) {
                hv.addError('You are not authorized to reassign this record');
                continue;
            }
            
            
            // New owner must be Hunter Analyst
            if (isUser(hv.OwnerId)) {
                
                User newOwner = userMap.get(hv.OwnerId);
                String newOwnerRole = newOwner.UserRole != null ? newOwner.UserRole.Name : '';
                
                if (newOwnerRole != 'Hunter Analyst') {
                    hv.addError('Records can be assigned only to Hunter Analysts');
                }
            }
        }
    }
    
     // Returns true if Id is a Salesforce User (starts with '005')
    
    private static Boolean isUser(Id idVal) {
        return String.valueOf(idVal).startsWith('005');
    }
    
     // Returns true if Id is a Salesforce Queue (starts with '00G')
    
    private static Boolean isQueue(Id idVal) {
        return String.valueOf(idVal).startsWith('00G');
    }
    
     // Returns a map of User Id to User record for given user Ids
    
    private static Map<Id, User> getUsers(Set<Id> userIds) {
        return new Map<Id, User>([SELECT Id, UserRole.Name FROM User WHERE Id IN :userIds]);
    }
    
    
     // Returns a map of Queue Id to set of User Ids (members of the queue)
    
    private static Map<Id, Set<Id>> getQueueMembers(Set<Id> queueIds) {
        
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        
        if (queueIds.isEmpty()) {
            return result;
        }
        
        for (GroupMember gm : [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :queueIds]) {
            if (!result.containsKey(gm.GroupId)) {
                result.put(gm.GroupId, new Set<Id>());
            }
            result.get(gm.GroupId).add(gm.UserOrGroupId);
        }
        return result;
    }
    
    // Returns true if user role is RCU_Area_Manager or above in hierarchy
 
    public static Boolean isRCUOrAbove(Id userId) {
        if (userId == null) return false;
        
        User u = [SELECT Id, UserRoleId FROM User WHERE Id = :userId LIMIT 1];
        if (u.UserRoleId == null) return false;
        
        Map<Id, UserRole> roleMap = new Map<Id, UserRole>([SELECT Id, DeveloperName, ParentRoleId FROM UserRole]);
        
        UserRole targetRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'RCU_Area_Manager' LIMIT 1];
        
        Id roleToCheck = targetRole.Id;
        while (roleToCheck != null) {
            if (roleToCheck == u.UserRoleId) {
                return true; // uss role is RCU_Area_Manager or above
            }
            UserRole ur = roleMap.get(roleToCheck);
            if (ur == null) break;
            roleToCheck = ur.ParentRoleId;
        }
        
        return false;
    }
    
    

    public static void handleAfterUpdate(List<Hunter_Verification__c> newList,Map<Id, Hunter_Verification__c> oldMap) {

        List<Id> applicantIds = new List<Id>();
        List<String> decisions = new List<String>();

        for (Hunter_Verification__c rec : newList) {

            Hunter_Verification__c oldRec = oldMap.get(rec.Id);

            // Status changed to Completed
            if (rec.Status__c == 'Completed' && oldRec.Status__c != 'Completed' && rec.Loan_Applicant__c != null && rec.Final_Decision__c != null) {

                applicantIds.add(rec.Loan_Applicant__c);
                decisions.add(rec.Final_Decision__c);
            }
        }

        if (!applicantIds.isEmpty()) {
            SHF_HunterFutureCallout.sendFinalDecision(applicantIds, decisions);
        }
    }


     
}