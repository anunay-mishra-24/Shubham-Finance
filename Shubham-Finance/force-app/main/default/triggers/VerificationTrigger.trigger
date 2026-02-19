trigger VerificationTrigger on Verification__c (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        SHF_RCU_VerificationHandler.validateOwnerAgainstQueue(Trigger.new, Trigger.oldMap);
        SHF_RCU_VerificationHandler.validateRCUMNR(Trigger.new, Trigger.oldMap);
    }


}