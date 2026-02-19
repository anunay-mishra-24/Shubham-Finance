/**
 * @File Name : SHF_OtherIncomeDetailsController.cls
 * @Description : Controller for Other Income Details LWC, pointing to Income_Details__c with 'Other_Income_Details' Record Type.
 * @Author : Karan Keswani
 * @Last Modified On : December 29, 2025
 **/

public with sharing class SHF_OtherIncomeDetailsController {

    private static final String RECORD_TYPE_DEV_NAME = 'Other_Income_Details';

    @AuraEnabled
    public static List<Income_Details__c> getOtherIncomeDetails(String loanApplicantId) {
        // Added Total_Income_Monthly__c to the query
        return [
            SELECT Id, Income_Head__c, Income_source__c, Frequency__c, 
                   Amount__c, Percentage__c, Net_Amount_Annual__c,
                   Total_Income_Monthly__c
            FROM Income_Details__c 
            WHERE Loan_Applicant__c = :loanApplicantId
            AND RecordType.DeveloperName = :RECORD_TYPE_DEV_NAME
        ];
    }

    @AuraEnabled
    public static void saveOtherIncomeDetails(List<Income_Details__c> recordsToSave, List<String> recordIdsToDelete, String loanApplicantId) {
        try {
            if (recordIdsToDelete != null && !recordIdsToDelete.isEmpty()) {
                delete [SELECT Id FROM Income_Details__c WHERE Id IN :recordIdsToDelete];
            }

            if (!recordsToSave.isEmpty()) {
                Id otherIncomeRTId = Schema.SObjectType.Income_Details__c
                                    .getRecordTypeInfosByDeveloperName()
                                    .get(RECORD_TYPE_DEV_NAME)
                                    .getRecordTypeId();

                for (Income_Details__c inc : recordsToSave) {
                    if (String.isBlank(inc.Loan_Applicant__c)) {
                        inc.Loan_Applicant__c = loanApplicantId;
                    }
                    if (inc.RecordTypeId == null) {
                        inc.RecordTypeId = otherIncomeRTId;
                    }
                }

                // upsert will handle Total_Income_Monthly__c automatically as it is in the list
                upsert recordsToSave;

                SHF_AppraisedIncomeHelper.updateAppraisedIncome(new Set<Id>{(Id)loanApplicantId});
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error saving other income details: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistConfig() {
        Map<String, List<String>> picklistData = new Map<String, List<String>>();
        
        picklistData.put('Income_Head__c', new List<String>{'Rental income'});
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