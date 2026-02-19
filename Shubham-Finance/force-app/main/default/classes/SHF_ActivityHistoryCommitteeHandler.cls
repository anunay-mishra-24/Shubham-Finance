/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : SHF_ActivityHistoryCommitteeHandler
* Author          : Preeti
* Created Date    : Feb 01, 2026
* Last Modified By: Preeti
* Last Modified On: Feb 01, 2026
* Description     : This class implements for......
* Change History  :
*  Date          │   Author     │   Change
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*  Feb 01, 2026  │ Preeti   │ Initial version
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/


public class SHF_ActivityHistoryCommitteeHandler {
    
    public static void handleAfterUpdate(List<Activity_History__c> newList,Map<Id, Activity_History__c> oldMap) {
        
        Set<Id> deviationIds = new Set<Id>();
        
        for (Activity_History__c newRec : newList) {
            Activity_History__c oldRec = oldMap.get(newRec.Id);
            
            if (newRec.RecordTypeId == SHF_ConstantsUtil.ACTIVITY_HISTORY_FOR_COMMITTEE_RECORDTYPEID && newRec.Deviation__c != null && newRec.Committee_Approval_Status__c != oldRec.Committee_Approval_Status__c) {
                deviationIds.add(newRec.Deviation__c);
            }
        }
        
        if (deviationIds.isEmpty()) {
          return;
        }
        
        List<Activity_History__c> activities = [SELECT Id, Deviation__c, OwnerId, Committee_Approval_Status__c FROM Activity_History__c WHERE Deviation__c IN :deviationIds AND RecordTypeId = :SHF_ConstantsUtil.ACTIVITY_HISTORY_FOR_COMMITTEE_RECORDTYPEID ORDER BY CreatedDate ASC];
        
        Map<Id, List<Activity_History__c>> devToActivities = new Map<Id, List<Activity_History__c>>();
        
        for (Activity_History__c ah : activities) {
            if (!devToActivities.containsKey(ah.Deviation__c)) {
                devToActivities.put(ah.Deviation__c, new List<Activity_History__c>());
            }
            devToActivities.get(ah.Deviation__c).add(ah);
        }
        
        
        List<Deviation_and_Sanction_Condition__c> deviationsToUpdate = new List<Deviation_and_Sanction_Condition__c>();
        
        for (Id devId : devToActivities.keySet()) {
            
            Integer totalCount = devToActivities.get(devId).size();
            Integer rejectedCount = 0;
            Id lastRejectUserId;
            Boolean approvedFound = false;
            
            for (Activity_History__c ah : devToActivities.get(devId)) {
                
                if (ah.Committee_Approval_Status__c == 'Approved') {
                    deviationsToUpdate.add(
                        new Deviation_and_Sanction_Condition__c(
                            Id = devId,
                            Decision__c = 'Approved',
                            Decision_By__c = UserInfo.getUserId()
                            
                        )
                    );
                    approvedFound = true;
                    break;
                }
                
                if (ah.Committee_Approval_Status__c == 'Rejected') {
                    rejectedCount++;
                    lastRejectUserId = UserInfo.getUserId();
                    
                }
            }
            
            if (!approvedFound && rejectedCount == totalCount) {
                deviationsToUpdate.add(
                    new Deviation_and_Sanction_Condition__c(
                        Id = devId,
                        Decision__c = 'Rejected',
                        Decision_By__c = lastRejectUserId
                    )
                );
            }
        }
        
        if (!deviationsToUpdate.isEmpty()) {
            try{
            update deviationsToUpdate;
            }catch(DmlException e) {
                Logger.error('Error: ' + e.getMessage());
                Logger.error('error> ' + e.getMessage()+' Line:- '+ e.getlineNumber());
            }finally{
            Logger.saveLog();
        }
        }
    }
}