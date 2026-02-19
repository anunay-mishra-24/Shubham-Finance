/**
 * @description       : 
 * @author            : Gaurav Kumar
 * @group             : 
 * @last modified on  : 12-02-2025
 * @last modified by  : Gaurav Kumar
**/
trigger SHF_ApplicationTrigger on Application__c (before update, after Update) {
    /*if (Trigger.isBefore && Trigger.isUpdate) {
        SHF_ApplicationHandler.validateApplicationStage(Trigger.new, Trigger.oldMap);
    }*/
    if (Trigger.isAfter && Trigger.isUpdate) {
                System.debug('Trigger After Update fired. Records: ' + Trigger.new);
        SHF_ApplicationHandler.handleRecommendedStatus(Trigger.new,Trigger.oldMap
        );
    }
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        SHF_ApplicationHandler.validateSelfAssignmentFromQueue(Trigger.new, Trigger.oldMap);
    }
}