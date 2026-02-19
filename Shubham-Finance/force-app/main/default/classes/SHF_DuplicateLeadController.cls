public with sharing class SHF_DuplicateLeadController {

    @AuraEnabled(cacheable=true)
    public static List<Lead__c> getDuplicateLeads(Id leadId) {
        if(leadId == null) return new List<Lead__c>();

        Lead__c currentLead = [
            SELECT Id, Contact_No1__c, Loan_Product__c, Sub_Product__c
            FROM Lead__c
            WHERE Id = :leadId
            LIMIT 1
        ];

        return [
            SELECT Id, Name, Full_Name__c, Lead_Status__c,
                   Loan_Product__c, Sub_Product__c, CreatedDate
            FROM Lead__c
            WHERE Contact_No1__c = :currentLead.Contact_No1__c
            AND Loan_Product__c = :currentLead.Loan_Product__c
            AND Sub_Product__c = :currentLead.Sub_Product__c
            AND Sub_Product__c != null
            AND Id != :leadId
            ORDER BY CreatedDate DESC
        ];
    }
}