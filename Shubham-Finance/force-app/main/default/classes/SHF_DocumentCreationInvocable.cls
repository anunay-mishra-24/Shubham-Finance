/**
* @File Name          : SHF_DocumentCreationInvocable.cls
* @Description        : Invocable class to create documents for Loan Application & Applicants
* @Author             : Akshi Sharma
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         17-07-2025              Akshi Sharma            Initial Version
* 2.0         22-09-2025              Akshi Sharma            Refactored: Single entry point from Application
* 3.0         05-10-2025              Akshi Sharma            Refactored again for restoring to initial version
*/
public class SHF_DocumentCreationInvocable {

    public class InputWrapper {
        @InvocableVariable
        public Id applicationId;

        @InvocableVariable
        public Id applicantId;

        @InvocableVariable
        public Boolean isApplicationContext = false;
    }

    @InvocableMethod(label='Create Documents (Application or Applicant)')
    public static void createDocuments(List<InputWrapper> inputs) {
        System.debug('>>> SHF_DocumentCreationInvocable: Starting document creation for ' + inputs.size() + ' inputs');

        Set<Id> applicationIds = new Set<Id>();
        Set<Id> applicantIds = new Set<Id>();

        // Collect IDs
        for (InputWrapper input : inputs) {
            System.debug('>>> Input received: AppId = ' + input.applicationId + ', ApplicantId = ' + input.applicantId + ', isApplicationContext = ' + input.isApplicationContext);

            if (input.applicationId != null) {
                applicationIds.add(input.applicationId);
            }

            if (!input.isApplicationContext && input.applicantId != null) {
                applicantIds.add(input.applicantId);
            }
        }

        // Query Applications
        Map<Id, Application__c> appMap = new Map<Id, Application__c>();
        if (!applicationIds.isEmpty()) {
            System.debug('>>> Querying Application__c records for IDs: ' + applicationIds);
            appMap = new Map<Id, Application__c>(
                [SELECT Id, OwnerId, RecordTypeId, RecordType.Name, RecordType.DeveloperName 
 				 FROM Application__c  WHERE Id IN :applicationIds]
            );
            System.debug('>>> Retrieved Application__c records: ' + appMap.keySet());
        }

        // Query Applicants
        Map<Id, Loan_Applicant__c> applicantMap = new Map<Id, Loan_Applicant__c>();
        if (!applicantIds.isEmpty()) {
            System.debug('>>> Querying Loan_Applicant__c records for IDs: ' + applicantIds);
            applicantMap = new Map<Id, Loan_Applicant__c>(
                [SELECT Id, Customer_Profile__c, Application__c FROM Loan_Applicant__c WHERE Id IN :applicantIds]
            );
            System.debug('>>> Retrieved Loan_Applicant__c records: ' + applicantMap.keySet());
        }

        // Process each input
        for (InputWrapper input : inputs) {
            if (input.isApplicationContext) {
                Application__c app = appMap.get(input.applicationId);
                if (app != null) {
                    System.debug('>>> Creating documents for Application: ' + app.Id);
                    SHF_DocumentCreationService.createDocumentsForApplication(app);
                } else {
                    System.debug('!!! Application not found for ID: ' + input.applicationId);
                }
            } else if (input.applicantId != null) {
                Loan_Applicant__c applicant = applicantMap.get(input.applicantId);
                Application__c app = appMap.get(applicant != null ? applicant.Application__c : null);

                if (app != null && applicant != null) {
                    System.debug('>>> Creating documents for Applicant: ' + applicant.Id + ' under Application: ' + app.Id);
                    SHF_DocumentCreationService.createDocumentsForApplicant(applicant, app);
                } else {
                    if (applicant == null) {
                        System.debug('!!! Applicant not found for ID: ' + input.applicantId);
                    }
                    if (app == null) {
                        System.debug('!!! Application not found for Applicant ID: ' + input.applicantId);
                    }
                }
            }
        }

        System.debug('>>> SHF_DocumentCreationInvocable: Document creation completed.');
    }
}