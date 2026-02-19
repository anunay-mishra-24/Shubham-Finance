/**
 * @File Name          : SHF_LitigationAdvanceReport_Batch.cls
 * @Description        : 
 * @Author             : Vikas Soni
 * @Test Class         :
 *==============================================================================
 * Ver          Date            Author            Modification
 *==============================================================================
 * 1.0       12-01-2026      Vikas Soni       Initial Version
 */
global with sharing class SHF_LitigationAdvanceReport_Batch implements Schedulable,Database.Batchable<sObject>, Database.stateful, Database.AllowsCallouts{
    global SHF_LitigationAdvanceReport_Batch() {
        
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        Datetime twoDaysAgo = System.now().addDays(-2);
        
        return Database.getQueryLocator([
            SELECT Id, Litigation_Verify_Id__c,Litigation_Advance_API_Timestamp__c,Status__c
            FROM E_Verification__c
            WHERE Litigation_Advance_API_Timestamp__c <= :twoDaysAgo
            AND Litigation_Verify_Id__c != NULL AND Status__c = 'In Progress'
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<E_Verification__c> scope) {
        
        String result = '';
        if(scope.size()!=null && !scope.isEmpty()) {
            system.debug('Scope - '+scope);
            system.debug('Scope size - '+scope.size());
            for(E_Verification__c eVerify : scope){
                String verifyId = eVerify.Litigation_Verify_Id__c;
                system.debug('verifyId - '+verifyId);
                if(String.isNotBlank(verifyId)){
                    result = SHF_LitigationAdvance_Service.getLitiagationAdvanceReport(verifyId,eVerify.Id);
                    System.debug('result - '+result);
                }
            }
        }
    }
    
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new SHF_LitigationAdvanceReport_Batch(), 1);
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('EVerification Batch Finished');
    }
}