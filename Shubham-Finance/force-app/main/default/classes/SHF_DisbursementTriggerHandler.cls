public class SHF_DisbursementTriggerHandler {
    public static void validateSelfAssignmentFromQueue(List<Disbursement__c> newRecords,Map<Id, Disbursement__c> oldRecordMap){
        if (newRecords == null || newRecords.isEmpty() || oldRecordMap == null) {
            return;
        }
        
        final String CHEQUE_PRINTING_STAGE = 'Tranche Request Initiation';
        final Id currentUserId = UserInfo.getUserId();
        
        Set<Id> candidateUserIds  = new Set<Id>();
        Set<Id> sourceQueueIds    = new Set<Id>();
        for (Disbursement__c newRec : newRecords) {
            Disbursement__c oldRec = oldRecordMap.get(newRec.Id);
            if (oldRec == null) continue;
            
            if (/*CHEQUE_PRINTING_STAGE == newRec.Status__c &&*/ isUser(newRec.OwnerId) && isQueue(oldRec.OwnerId)) {
                candidateUserIds.add(newRec.OwnerId);
                sourceQueueIds.add(oldRec.OwnerId);
            }
            else if (!isQueue(oldRec.OwnerId) && isUser(newRec.OwnerId) && newRec.OwnerId != oldRec.OwnerId) {

                if (newRec.OwnerId != currentUserId) {                    
                    newRec.OwnerId.addError('You can assign the Disbursement only to yourself.');
                }
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
        
        for (Disbursement__c newRec : newRecords) {
            Disbursement__c oldRec = oldRecordMap.get(newRec.Id);
            if (oldRec == null) continue;
            
            if (/*CHEQUE_PRINTING_STAGE == newRec.Status__c &&*/ isUser(newRec.OwnerId) && isQueue(oldRec.OwnerId)) {
                
                if (newRec.OwnerId != currentUserId) {
                    newRec.OwnerId.addError(
                        'You can assign the Disbursement only to yourself.'
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