/*
* @File Name : SHF_RCU_VerificationHandler.cls
* @Author :  Preeti
* @Created Date : July 21, 2025
* @Description : .
* @Last Modified By :  Preeti
* @Last Modified On : July 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 21, 2025 | Preeti  | Initial Version
*/

public class SHF_RCU_VerificationHandler {
 
    public static void validateOwnerAgainstQueue(List<Verification__c> newList, Map<Id, Verification__c> oldMap) {
        Set<Id> newUserIds = new Set<Id>();
        Set<Id> queueIds = new Set<Id>();
        Id currentUserId = UserInfo.getUserId();

        
        for (Verification__c newRec : newList) {
            Verification__c oldRec = oldMap != null ? oldMap.get(newRec.Id) : null;
            Id oldOwnerId = oldRec != null ? oldRec.OwnerId : null;
            Id newOwnerId = newRec.OwnerId;
            
            if (newOwnerId != null && String.valueOf(newOwnerId).startsWith('005')) {
                if (oldOwnerId != null && String.valueOf(oldOwnerId).startsWith('00G')) {
                    newUserIds.add(newOwnerId);
                    queueIds.add(oldOwnerId);
                }
            }
        }
        
        if (newUserIds.isEmpty() || queueIds.isEmpty()) {
            return; 
        }
        
        Map<Id, Set<Id>> userToGroups = new Map<Id, Set<Id>>();
        for (GroupMember gm : [
            SELECT UserOrGroupId, GroupId
            FROM GroupMember
            WHERE UserOrGroupId IN :newUserIds AND GroupId IN :queueIds
        ]) {
            if (!userToGroups.containsKey(gm.UserOrGroupId)) {
                userToGroups.put(gm.UserOrGroupId, new Set<Id>());
            }
            userToGroups.get(gm.UserOrGroupId).add(gm.GroupId);
        }
        
        for (Verification__c newRec : newList) {
            Verification__c oldRec = oldMap != null ? oldMap.get(newRec.Id) : null;
            Id oldOwnerId = oldRec != null ? oldRec.OwnerId : null;
            Id newOwnerId = newRec.OwnerId;
            
            if (newOwnerId != null && String.valueOf(newOwnerId).startsWith('005')) {
                if (oldOwnerId != null && String.valueOf(oldOwnerId).startsWith('00G')) {
                    Set<Id> groups = userToGroups.containsKey(newOwnerId) ? userToGroups.get(newOwnerId) : new Set<Id>();
                    if (!groups.contains(oldOwnerId)) {
                        newRec.OwnerId.addError('User does not belong to respective Queue');
                    }
                    else if(newOwnerId != currentUserId) {
                        newRec.OwnerId.addError('You can assign verification only to yourself.');
                        continue;
                    }
                    else{
                        newRec.Status__c = 'Assigned';
                    }
                }
            }
        }
    }
    
    
    public static void validateRCUMNR(
    List<Verification__c> newList,
    Map<Id, Verification__c> oldMap
) {

    Set<Id> appIds = new Set<Id>();

    // Step 1: Collect Application Ids
    for (Verification__c v : newList) {

        Boolean closingNow =
            v.Completion_Date_Time__c != null &&
            (oldMap == null ||
             oldMap.get(v.Id) == null ||
             oldMap.get(v.Id).Completion_Date_Time__c == null);

        if (
            v.Type__c == 'Borrower' &&
            closingNow &&
            String.isBlank(v.RCU_Status_On_MNR__c) &&
            v.Application__c != null
        ) {
            appIds.add(v.Application__c);
        }
    }

    if (appIds.isEmpty()) return;

    // Step 2: Query once → store in list
    List<Loan_Applicant__c> loanApps = [
        SELECT Id, Application__c
        FROM Loan_Applicant__c
        WHERE Application__c IN :appIds
        AND Mobile_Verification__r.Mobile_IsFound__c = TRUE
    ];

    // Step 3: Convert to Set for fast lookup
    Set<Id> appsWithNegative = new Set<Id>();
    for (Loan_Applicant__c la : loanApps) {
        appsWithNegative.add(la.Application__c);
    }

    // Step 4: Add error
    for (Verification__c v : newList) {

        Boolean closingNow =
            v.Completion_Date_Time__c != null &&
            (oldMap == null ||
             oldMap.get(v.Id) == null ||
             oldMap.get(v.Id).Completion_Date_Time__c == null);

        if (
            v.Type__c == 'Borrower' &&
            closingNow &&
            String.isBlank(v.RCU_Status_On_MNR__c) &&
            appsWithNegative.contains(v.Application__c)
        ) {
            v.addError('Please fill RCU Status on MNR to close the activity');
        }
    }
}

     
}