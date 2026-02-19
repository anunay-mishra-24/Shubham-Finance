trigger SHF_ActivityHistoryForCommitteeTrigger on Activity_History__c (after update) {

    SHF_ActivityHistoryCommitteeHandler.handleAfterUpdate(Trigger.new,Trigger.oldMap);
}