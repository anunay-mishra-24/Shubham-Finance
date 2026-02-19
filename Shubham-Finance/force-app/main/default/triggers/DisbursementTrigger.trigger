trigger DisbursementTrigger on Disbursement__c (before update, after Update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        SHF_DisbursementTriggerHandler.validateSelfAssignmentFromQueue(Trigger.new, Trigger.oldMap);
    }
}