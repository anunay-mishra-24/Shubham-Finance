/**
* @File Name : SHF_DocumentSamplingStatusController.cls
* @Description :  this class is used for maintaining status of Sampled Documents.
* @Author :  Kuldeep Sahu
* @Last Modified On : Dec 27, 2025
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | Dec 26, 2025 | Kuldeep Sahu  | Initial Version
**/

public without sharing class SHF_DocumentSamplingStatusController {
    @AuraEnabled
    public static List<Document_Activity__c> getSampledDocumentRecord(String recordId){
        try {
            List<Document_Activity__c> docActivities = [SELECT
                                                        Id, Document__c, Verification__c, Verification_Activity__c,
                                                        RCU_Verification_Status__c, Pick_up_Criteria__c, Decision__c,
                                                        Comments__c, Completion_Date_Time__c, Document__r.Status__c,
                                                        Document__r.Document_Category__c, Document__r.File_Name__c,
                                                        Document__r.RCU_Required__c, Referred_By__c
                                                        FROM Document_Activity__c
                                                        WHERE Verification_Activity__c =: recordId];
            return docActivities;                                                        
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string saveFCUDecision(String records){
        try {
            List<Document_Activity__c> documentActivities = new List<Document_Activity__c>();
            documentActivities =  (List<Document_Activity__c>) System.JSON.deserialize(records, List<Document_Activity__c>.class);
            UPSERT documentActivities;
            return 'SUCCESS';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}