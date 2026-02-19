/**
* @description       : Validate that every Loan Applicant under an Application has at least one
*                      Personal Discussion with Status = 'Completed' before allowing Application update.
* @author            : Gaurav Kumar
* @last modified on  : 12-02-2025
* @last modified by  : Gaurav Kumar
**/
public with sharing class SHF_ApplicationHandler {
    public static void validateApplicationStage(List<Application__c> newList, Map<Id, Application__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;
        Set<Id> applicantsWithCompletedPD = new Set<Id>();
        Set<Id> applicationIds = new Set<Id>();
        for (Application__c newRec : newList) {
            Application__c oldRec = oldMap != null ? oldMap.get(newRec.Id) : null;
            if (newRec.Application_Stage__c == 'Credit Assessment' && oldRec.Application_Stage__c =='DDE') {
                applicationIds.add(newRec.Id);
            }
        }
        if (applicationIds.isEmpty()) return;        
        List<Loan_Applicant__c> applicants = [SELECT Id, Name, Application__c FROM Loan_Applicant__c
            								  WHERE Application__c IN :applicationIds];
        if (applicants.isEmpty()) return;
        Set<Id> applicantIds = new Set<Id>();
        for (Loan_Applicant__c la : applicants) {
            applicantIds.add(la.Id);
        }
        
        if (applicantIds.isEmpty()) return;        
        for (AggregateResult ar : [SELECT Loan_Applicant__c laId FROM Personal_Discussion__c
            					   WHERE Loan_Applicant__c IN :applicantIds AND Status__c = 'Completed'
                                   GROUP BY Loan_Applicant__c]) {
            applicantsWithCompletedPD.add((Id) ar.get('laId'));
        }
        
        Map<Id, List<String>> appToMissingApplicantNames = new Map<Id, List<String>>();        
        for (Loan_Applicant__c la : applicants) {
            if (!applicantsWithCompletedPD.contains(la.Id)) {
                if (!appToMissingApplicantNames.containsKey(la.Application__c)) {
                    appToMissingApplicantNames.put(la.Application__c, new List<String>());
                }
                appToMissingApplicantNames.get(la.Application__c).add(la.Name != null ? la.Name : String.valueOf(la.Id));
            }
        }
                
        for (Application__c app : newList) {
            if (appToMissingApplicantNames.containsKey(app.Id)) {
                List<String> missingNames = appToMissingApplicantNames.get(app.Id);
                String details;
                if (missingNames == null || missingNames.isEmpty()) {
                    details = 'One or more Loan Applicants are missing a completed Personal Discussion.';
                } else {
                    List<String> shown = new List<String>();
                    Integer maxNames = Math.min(10, missingNames.size());                    
                    for (Integer i = 0; i < maxNames; i++) {
                        shown.add(missingNames[i]);
                    }
                    details = 'Personal Discussion for ' 
                        + String.join(shown, ', ') +' '+'must be completed before recommending the loan application.';
                    if (missingNames.size() > maxNames) {
                        details += ' (+' + String.valueOf(missingNames.size() - maxNames) + ' more)';
                    }
                }
                app.addError(details);
            }
        }
    } 
    
    
    // Handles Applications changed to 'Recommended' and triggers Hunter for related Individual applicants

    public static void handleRecommendedStatus(List<Application__c> newList, Map<Id, Application__c> oldMap) {
                System.debug('Trigger After handler Update fired. Records: ');

        Set<Id> appIds = new Set<Id>();
         
        for (Application__c app : newList) {
            if (app.Application_Status__c == 'Recommended' && oldMap.get(app.Id).Application_Status__c != 'Recommended' ) {
                appIds.add(app.Id);
            }
        }

        if (appIds.isEmpty()){
          return;  
        } 

        List<Loan_Applicant__c> applicants = [SELECT Id FROM Loan_Applicant__c WHERE Application__c IN :appIds AND RecordType.DeveloperName = 'Individual'];

        for (Loan_Applicant__c applicant : applicants) {
            SHF_Hunter_Future.callHunter(applicant.Id);
        }
    }

    public static void validateSelfAssignmentFromQueue(List<Application__c> newRecords,Map<Id, Application__c> oldRecordMap){
        if (newRecords == null || newRecords.isEmpty() || oldRecordMap == null) {
            return;
        }
        
        final String CHEQUE_PRINTING_STAGE = 'Cheque Printing';
        final Id currentUserId = UserInfo.getUserId();
        
        Set<Id> candidateUserIds  = new Set<Id>();
        Set<Id> sourceQueueIds    = new Set<Id>();
        for (Application__c newRec : newRecords) {
            Application__c oldRec = oldRecordMap.get(newRec.Id);
            if (oldRec == null) continue;
            
            if (CHEQUE_PRINTING_STAGE == newRec.Application_Stage__c && isUser(newRec.OwnerId) && isQueue(oldRec.OwnerId)) {
                candidateUserIds.add(newRec.OwnerId);
                sourceQueueIds.add(oldRec.OwnerId);
            }
        }
        
        if (candidateUserIds.isEmpty() || sourceQueueIds.isEmpty()) {
            return;
        }        
        
        Map<Id, Set<Id>> userToQueueMap = new Map<Id, Set<Id>>();
        
        for (GroupMember member : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE UserOrGroupId IN :candidateUserIds AND GroupId IN :sourceQueueIds]) {
            if (!userToQueueMap.containsKey(member.UserOrGroupId)) {
                userToQueueMap.put(member.UserOrGroupId, new Set<Id>());
            }
            userToQueueMap.get(member.UserOrGroupId).add(member.GroupId);
            
        }
        
        for (Application__c newRec : newRecords) {
            Application__c oldRec = oldRecordMap.get(newRec.Id);
            if (oldRec == null) continue;
            
            if (CHEQUE_PRINTING_STAGE == newRec.Application_Stage__c && isUser(newRec.OwnerId) && isQueue(oldRec.OwnerId)) {
                
                if (newRec.OwnerId != currentUserId) {
                    newRec.OwnerId.addError(
                        'You can assign the Application only to yourself.'
                    );
                    continue;
                }
                
                Set<Id> queues = userToQueueMap.get(newRec.OwnerId);
                if (queues == null || !queues.contains(oldRec.OwnerId)) {
                    newRec.OwnerId.addError(
                        'You are not a member of the assigned Queue.'
                    );
                }
            }
        }
    }
    
    private static Boolean isUser(Id ownerId) {
        return ownerId != null && String.valueOf(ownerId).startsWith('005');
    }
    
    private static Boolean isQueue(Id ownerId) {
        return ownerId != null && String.valueOf(ownerId).startsWith('00G');
    }


}