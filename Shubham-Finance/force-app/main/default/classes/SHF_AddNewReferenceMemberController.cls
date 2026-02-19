/**
* @File Name : SHF_AddNewReferenceMemberController.cls
* @Description : Provides helper logic for Reference Member flow.Used to fetch Primary Applicant name based on selected applicant within the same Application.
* @Author : Preeti
* @Last Modified By : Preeti
* @Last Modified On : November 24, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 24, 2025 | Preeti  | Initial Version
* 1.0 | December 07, 2025 | Preeti  | modified Version
**/

public with sharing class SHF_AddNewReferenceMemberController {
    
    
    /**
* Returns the Primary Applicant name for a given applicant.
* If the provided applicant itself is Primary, its name is returned.
* Otherwise, Primary Applicant is fetched from the same Application.
*
* @param applicantId Id of the selected Loan Applicant
* @return String     Name of the Primary Applicant (if found)
*/
    
    @AuraEnabled(cacheable=true)
    public static String getPrimaryApplicantName(Id applicantId) {
        
        if (applicantId == null) {
            logger.error('Primary Applicant fetch failed: Applicant Id is missing');
            return null;
        }
        
        logger.info('Fetching Primary Applicant name for Applicant Id: ' + applicantId);
        
        // Fetch current applicant’s fields
        Loan_Applicant__c currentApp = [SELECT Id, Applicant_Type__c, Application__c, Account_Name__c FROM Loan_Applicant__c WHERE Id = :applicantId LIMIT 1];
        
        // If this applicant is Primary → return it
        if (currentApp.Applicant_Type__c == 'Primary Applicant') {
            logger.info('Applicant itself is Primary Applicant');
            return currentApp.Account_Name__c;
        }
        
        // Else find sibling Primary Applicant under same Application
        Loan_Applicant__c siblingPrimary = [SELECT Id, Account_Name__c FROM Loan_Applicant__c WHERE Application__c = :currentApp.Application__c AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        
        if (siblingPrimary == null) {
            logger.info('No Primary Applicant found for Application Id: ' + currentApp.Application__c);
            return null;
        }
        
        logger.info('Primary Applicant found successfully');
        return siblingPrimary.Account_Name__c;
    }
}