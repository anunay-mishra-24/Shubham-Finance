/**
 * @description       : 
 * @author            : Gaurav Kumar
 * @group             : 
 * @last modified on  : 02-12-2026
 * @last modified by  : Gaurav Kumar
**/
public with sharing class SHF_DisbursementMoveToNextController {
    @AuraEnabled
    public static String moveToNextStage(Id recordId) { 
        List<SObject> updateRecords = new List<SObject>();
        List<String> errorMessages = new List<String>();
        Application__c app;
        String nextStage;
        String resultMsg = '';
        try{
            Disbursement__c disbursementData = [SELECT Id, Status__c,Name,Application__c FROM Disbursement__c WHERE Id = :recordId];
            if(disbursementData != null) {
                if(disbursementData.Application__c != null) {
                    app = [SELECT Id, Application_Stage__c,Name FROM Application__c 
                           WHERE Id = :disbursementData.Application__c LIMIT 1];
                }
                switch on disbursementData.Status__c   {
                    when 'Tranche Request Initiation' {
                        System.debug('Disbursement Status'+disbursementData.Status__c);
                    }
                    when 'Tranche Approval' {
                        System.debug('Disbursement Status'+disbursementData.Status__c);
                        nextStage = 'Tranche Disbursement';
                    }
                    when 'Tranche Disbursement' {
                        System.debug('Disbursement Status'+disbursementData.Status__c);
                    }
                    when else {
                        // default logic
                    }
                }
                if(!errorMessages.isEmpty()){
                    return 'ERROR: ' + String.join(errorMessages, '\n');
                }else {
                    Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('NEXT_STAGE_SUCCESS');
                    if(app.Application_Stage__c == 'Disbursement Maker'){
                        List<Group> queues = [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pending_Tranche_Records' LIMIT 1];
                        app.Application_Stage__c = 'Disbursement Checker';
                        updateRecords.add(app);
                        disbursementData.Status__c = nextStage;
                        disbursementData.OwnerId = queues[0].Id;
                        updateRecords.add(disbursementData);
                        System.debug('updateRecords :'+updateRecords);
                        if(!updateRecords.isEmpty()){
                            update updateRecords;
                        }
                        resultMsg = 'SUCCESS' + ': ' + msg.get('Message') + ' → ' + 'Disbursement Checker';
                        
                    }
                    
                }
            }
        }
        catch(Exception ex){
            throw new AuraHandledException('Error occurred while moving to next stage: ' + ex.getMessage());
        }
        return resultMsg;
    }
}