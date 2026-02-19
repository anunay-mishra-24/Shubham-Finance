/**
* @File Name : SHF_SwapApplicantController.cls
* @Description : Handles Swap Applicant LWC logic
* @Author : Preeti
* @Last Modified By : Preeti
* @Last Modified On : November 25, 2025
* @Modification Log : because requirement got fully changed
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 27, 2025 | Preeti   | Initial Version
* 2.0 | November 25, 2025 | Preeti   | Modified Version
**/


public with sharing class SHF_SwapApplicantController {
    
    // ================================================
    // GET APPLICANTS 
    // ================================================
    
    /**
* Fetches all active applicants linked to a given Application.
* This method is cacheable and used to populate applicant selection
* in the Swap Applicant LWC.
*
* @param applicationId Id of the Application record
* @return List<Loan_Applicant__c> List of applicants for the application
*/
    @AuraEnabled(cacheable = true)
    public static List<Loan_Applicant__c> getApplicants(Id applicationId) {
        if (applicationId == null) {
            logger.error('Application Id is missing while fetching applicants');
            throw new AuraHandledException('Application Id is required.');
        }
        
        try {
            logger.info('Fetching applicants for Application Id: ' + applicationId);
            return [
                SELECT Id, Name,Account_Name__c, Applicant_Type__c
                FROM Loan_Applicant__c
                WHERE Application__c = :applicationId AND IsDeleted__c = false
                ORDER BY Account_Name__c
            ];
        } catch (Exception ex) {
            logger.error('Error while fetching applicants: ' + ex.getMessage());
            throw new AuraHandledException('Error while fetching applicants: ' + ex.getMessage());
        }
    }
    
    
    
    // ================================================
    // PERFORM SWAP
    // ================================================
    
    /**
* Swaps the Applicant Type between two selected applicants.
* Also captures swap reason and comments for audit/reference.
*
* @param applicantAId Id of first applicant
* @param applicantBId Id of second applicant
* @param reason       Reason for swapping applicants
* @param comments     Additional comments entered by user
*/
    @AuraEnabled
    public static void performSwap(Id applicantAId, Id applicantBId, String reason, String comments) {
        
        
        if (applicantAId == null || applicantBId == null) {
            logger.error('Swap failed: Applicant Ids are missing');
            throw new AuraHandledException('Both applicants must be selected.');
        }
        
        if (applicantAId == applicantBId) {
            logger.error('Swap failed: Same applicant selected for swap');
            throw new AuraHandledException('You cannot swap the same applicant.');
        }
        
        if (String.isBlank(reason)) {
            logger.error('Swap failed: Reason not provided');
            throw new AuraHandledException('Swap reason is required.');
        }
        
        logger.info('applicant swap. ApplicantA: ' + applicantAId + ', ApplicantB: ' + applicantBId);
        
        // -------------------------------
        // QUERY RECORDS 
        // -------------------------------
        List<Loan_Applicant__c> applicants = [
            SELECT Id, Applicant_Type__c
            FROM Loan_Applicant__c
            WHERE Id IN :new Set<Id>{ applicantAId, applicantBId }
            LIMIT 2
        ];
        
        if (applicants.size() != 2) {
            logger.error('One or both applicants not available for swapping');
            throw new AuraHandledException('One or both applicants could not be found.');
        }
        
        // -------------------------------
        // MAP 
        // -------------------------------
        Map<Id, Loan_Applicant__c> appMap = new Map<Id, Loan_Applicant__c>(applicants);
        
        Loan_Applicant__c a1 = appMap.get(applicantAId);
        Loan_Applicant__c a2 = appMap.get(applicantBId);
        
        if (a1 == null || a2 == null) {
            logger.error('Swap faile. Applicant records could not be mapped');
            throw new AuraHandledException('Error retrieving applicant details.');
        }
        
        // -------------------------------
        // SET BYPASS FLAG
        // -------------------------------
        a1.Swap_Bypass__c = true;
        a2.Swap_Bypass__c = true;
        
        
        // -------------------------------
        // SWAP TYPES
        // -------------------------------
        String tempType = a1.Applicant_Type__c;
        a1.Applicant_Type__c = a2.Applicant_Type__c;
        a2.Applicant_Type__c = tempType;
        
        logger.info('Applicant types swapped successfully');
        
        // -------------------------------
        // UPDATE SWAP DETAILS
        // -------------------------------
        a1.Swap_Reason__c = reason;
        a2.Swap_Reason__c = reason;
        
        a1.Swap_Comments__c = comments;
        a2.Swap_Comments__c = comments;
        
        
        // -------------------------------
        // BULK DML 
        // -------------------------------
        try {
            update new List<Loan_Applicant__c>{ a1, a2 };
                } catch (DmlException dmlEx) {
                    logger.info('Applicant swap completed successfully');
                    throw new AuraHandledException('Swap action failed: ' + dmlEx.getMessage());
                } catch (Exception ex) {
                    logger.error('Unexpected error during swap: ' + ex.getMessage());
                    throw new AuraHandledException('Unexpected error: ' + ex.getMessage());
                }
    }
}