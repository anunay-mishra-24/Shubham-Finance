trigger SHF_LeadTrigger on Lead__c (before update) {
    SHF_LeadHandler.handleBranchChange(Trigger.new, Trigger.oldMap);
}