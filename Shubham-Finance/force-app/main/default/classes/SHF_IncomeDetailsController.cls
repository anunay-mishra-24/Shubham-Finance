/**
 * @File Name : SHF_IncomeDetailsController.cls
 * @Description : Controller for Income Details LWC. Manages 'Income_Details' Record Type records.
 * @Author : Karan Keswani
 * @Last Modified On : December 29, 2025
 **/

public with sharing class SHF_IncomeDetailsController {

    private static final String RECORD_TYPE_DEV_NAME = 'Income_Details';

    @AuraEnabled
    public static List<Income_Details__c> getIncomeDetails(String loanApplicantId) {
        // Added Total_Income_Monthly__c to the query
        return [
            SELECT Id, Income_Head__c, Income_Source__c, Frequency__c, 
                   Amount__c, Percentage__c, Net_Amount_Annual__c, 
                   Total_Income_Monthly__c
            FROM Income_Details__c 
            WHERE Loan_Applicant__c = :loanApplicantId
            AND RecordType.DeveloperName = :RECORD_TYPE_DEV_NAME
        ];
    }

    @AuraEnabled
    public static void saveIncomeDetails(List<Income_Details__c> recordsToSave, List<String> recordIdsToDelete, String loanApplicantId) {
        try {
            // A. Delete removed rows
            if (recordIdsToDelete != null && !recordIdsToDelete.isEmpty()) {
                delete [SELECT Id FROM Income_Details__c WHERE Id IN :recordIdsToDelete];
            }

            // B. Prepare new/updated records
            if (!recordsToSave.isEmpty()) {
                Id incomeRTId = Schema.SObjectType.Income_Details__c
                                .getRecordTypeInfosByDeveloperName()
                                .get(RECORD_TYPE_DEV_NAME)
                                .getRecordTypeId();

                for (Income_Details__c inc : recordsToSave) {
                    if (String.isBlank(inc.Loan_Applicant__c)) {
                        inc.Loan_Applicant__c = loanApplicantId;
                    }
                    if (inc.RecordTypeId == null) {
                        inc.RecordTypeId = incomeRTId;
                    }
                }

                // Standard upsert handles all fields passed from LWC (including Total_Income_Monthly__c)
                upsert recordsToSave;

                SHF_AppraisedIncomeHelper.updateAppraisedIncome(new Set<Id>{(Id)loanApplicantId});

                // Clear the sendback flag since income details have been re-saved
                Loan_Applicant__c la = new Loan_Applicant__c(
                    Id = (Id)loanApplicantId,
                    Financial_Calculator_Changed_After_SB__c = false
                );
                update la;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error saving income details: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistConfig() {
        Map<String, List<String>> picklistData = new Map<String, List<String>>();
        
        picklistData.put('Income_Head__c', new List<String>{'Monthly Gross Income', 'Basic'});
        picklistData.put('Income_source__c', getPicklists('Income_Details__c', 'Income_source__c'));
        picklistData.put('Frequency__c', getPicklists('Income_Details__c', 'Frequency__c'));
        
        return picklistData;
    }

    private static List<String> getPicklists(String objectName, String fieldName) {
        List<String> values = new List<String>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName);
        if (s == null) return values;

        Schema.DescribeSObjectResult r = s.getDescribe();
        Map<String, Schema.SObjectField> fields = r.fields.getMap();
        
        if (fields.containsKey(fieldName)) {
            Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : ple) {
                if (pickListVal.isActive()) {
                    values.add(pickListVal.getLabel());
                }
            }
        }
        return values;
    }
}