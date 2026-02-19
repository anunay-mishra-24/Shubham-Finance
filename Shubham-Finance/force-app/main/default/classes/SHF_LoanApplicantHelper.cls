/**
* @File Name : SHF_LoanApplicantHelper.cls
* @Description :
* @Author : Preeti
* @Last Modified By :
* @Last Modified On : September 30, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 30, 2025 |   | Initial Version
**/

public with sharing class SHF_LoanApplicantHelper {

    /**
     * Get all sibling Loan Applicants for a given Loan Applicant
     * @param loanApplicantId - Id of current Loan Applicant
     * @return List of sibling applicants under the same Application
     */
    @AuraEnabled(cacheable=true)
    public static List<Loan_Applicant__c> getSiblingApplicants(Id loanApplicantId) {
        if (loanApplicantId == null) return new List<Loan_Applicant__c>();

        SHF_LoanApplicantsSelector selector = new SHF_LoanApplicantsSelector();

        // Get the current applicant
        Loan_Applicant__c currentApplicant = selector.selectLoanApplicantForCIBIL(loanApplicantId);
        if (currentApplicant == null || currentApplicant.Application__c == null) {
            return new List<Loan_Applicant__c>();
        }

        // Get all applicants under the same Application 
        Set<Id> applicationIdSet = new Set<Id>{currentApplicant.Application__c};
        List<Loan_Applicant__c> siblings = selector.selectByIdWithLoanApplication(applicationIdSet);


        return siblings;
    }
    /**
     * Delete a Loan Applicant and soft delete its child records
     * @param loanApplicantId - Id of Loan Applicant to delete
     * @return Id of Parent Application (for navigation in LWC)
     */
    @AuraEnabled
    public static Id deleteApplicant(Id loanApplicantId) {
        if (loanApplicantId == null) throw new AuraHandledException('Invalid Loan Applicant Id');

        try {
          
            SHF_LoanApplicantsSelector applicantSelector = new SHF_LoanApplicantsSelector();

            // Fetch applicant along with child records (Documents, E_Verifications)
            List<Loan_Applicant__c> applicants = applicantSelector.selectByApplicantId(new Set<Id>{loanApplicantId});
            system.debug('applicants><>< ' + applicants);
            if (applicants.isEmpty()) throw new AuraHandledException('Applicant not found');

            Loan_Applicant__c applicant = applicants[0];
            Id parentAppId = applicant.Application__c;

            // Fetch child records
            List<E_Verification__c> everifications = applicant.E_Verifications__r != null ? applicant.E_Verifications__r : new List<E_Verification__c>();

            List<Document__c> documents = applicant.Documents__r != null ? applicant.Documents__r : new List<Document__c>();

            // Soft delete children
            for (E_Verification__c ev : everifications){
              ev.IsDeleted__c = true;
            } 
            for (Document__c doc : documents){
              doc.IsDeleted__c = true;
            } 

            if (!everifications.isEmpty()){
              update everifications;
            } 
            if (!documents.isEmpty()){
              update documents;
            } 
            // Soft delete applicant
            if (applicant != null) {
            applicant.IsDeleted__c = true;
            update applicant;
            }
            system.debug('parentAppIdparentAppId > ' + parentAppId);
            return parentAppId;

        } catch (Exception e) {
            throw new AuraHandledException('Error deleting applicant: ' + e.getMessage());
        }
    }
}