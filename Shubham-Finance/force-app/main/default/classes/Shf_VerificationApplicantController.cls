/**
* @File Name : Shf_VerificationApplicantController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 21, 2025 |   | Initial Version
**/

public with sharing class Shf_VerificationApplicantController {

    public class ApplicantResponse {
        @AuraEnabled public String primaryApplicant;
        @AuraEnabled public List<String> coApplicants;

        public ApplicantResponse() {
            coApplicants = new List<String>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static ApplicantResponse fetchApplicants(Id applicationId) {

        Logger.info('fetchApplicants called with Application Id: ' + applicationId);

        ApplicantResponse response = new ApplicantResponse();

        if (applicationId == null) {
            Logger.info('Application Id is null');
            return response;
        }

        List<Loan_Applicant__c> applicants = [SELECT Name, Applicant_Type__c, Account_Name__c, IsDeleted__c FROM Loan_Applicant__c WHERE Application__c = :applicationId AND IsDeleted__c = FALSE];

        Logger.info('Total Loan Applicants found: ' + applicants.size());

        for (Loan_Applicant__c loanApplicant : applicants) {
            if (loanApplicant.Applicant_Type__c != null &&
                loanApplicant.Applicant_Type__c.contains('Primary Applicant')) {

                response.primaryApplicant = loanApplicant.Account_Name__c;
                Logger.info('Primary Applicant found: ' + response.primaryApplicant);
            } else {
                response.coApplicants.add(loanApplicant.Account_Name__c);
                Logger.info('Co-Applicant added: ' + loanApplicant.Account_Name__c);
            }
        }

        return response;
    }
}