/**
* @File Name          : SHF_DocumentCreationService.cls
* @Description        : Class to create documents for Loan Application & Applicants
* @Author             : Akshi Sharma
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         17-07-2025              Akshi Sharma            Initial Version
* 2.0         22-09-2025              Akshi Sharma            Refactored for Change in Trigger Point
* 3.0         05-10-2025              Akshi Sharma            Refactored again for restoring to initial version
*/
public with sharing class SHF_DocumentCreationService {

    public static void createDocumentsForApplication(Application__c applicationRecord) {
        System.debug('>>> [Application] Starting document creation for application: ' + applicationRecord?.Id);

        if (applicationRecord == null || applicationRecord.Id == null || applicationRecord.RecordType == null) {
            System.debug('!!! [Application] Invalid input: Application record or RecordType missing');
            throw new AuraHandledException('Invalid Application input');
        }

        Savepoint sp = Database.setSavepoint();

        try {
            List<String> stages = new List<String>{ applicationRecord.RecordType.Name };
            System.debug('>>> [Application] Fetching checklists for stage: ' + stages);

            List<Document_Checklist__c> applicableChecklists = new SHF_DocumentCheckListSelector()
                .selectForContext(stages, 'Loan', null);

            System.debug('>>> [Application] Retrieved ' + applicableChecklists.size() + ' checklist items');

            List<Document__c> documentsToInsert = new List<Document__c>();

            for (Document_Checklist__c checklist : applicableChecklists) {
                Document__c doc = new Document__c(
                    Document_Checklist__c = checklist.Id,
                    Application__c        = applicationRecord.Id,
                    Document_Category__c  = checklist.Document_Category__c,
                    File_Name__c		  = checklist.Name,
                    Mandatory_Document__c = checklist.Mandatory_Optional__c == 'Mandatory',
                    Applicable_For__c 	  = 'Loan Application',
                    Document_Type__c      = checklist.Document_Type__c,
                    Stage__c              = checklist.Document_Stage__c,
                    OwnerId               = applicationRecord.OwnerId,
                    Status__c 			  = 'Not Uploaded'
                );
                documentsToInsert.add(doc);
                System.debug('>>> [Application] Prepared Document__c: ' + doc);
            }

            if (!documentsToInsert.isEmpty()) {
                System.debug('>>> [Application] Inserting ' + documentsToInsert.size() + ' documents');
                insert documentsToInsert;
            } else {
                System.debug('>>> [Application] No documents to insert.');
            }

        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('!!! [Application] Exception Line: ' + e.getLineNumber());
            System.debug('!!! [Application] Exception Message: ' + e.getMessage());
            System.debug('!!! [Application] Exception Details: ' + e);
        }
    }

    public static void createDocumentsForApplicant(Loan_Applicant__c applicantRecord, Application__c applicationRecord) {
        System.debug('>>> [Applicant] Starting document creation for applicant: ' + applicantRecord?.Id);

        if (applicantRecord == null || applicantRecord.Id == null || applicationRecord == null || applicationRecord.RecordType == null) {
            System.debug('!!! [Applicant] Invalid input: Applicant or Application record missing');
 	          throw new AuraHandledException('Invalid Applicant or Application input');      
        }
        Savepoint sp = Database.setSavepoint();

        try {
            List<String> stageLabels = getCumulativeStages(applicationRecord.RecordType.Name);
            System.debug('>>> [Applicant] Cumulative stages for ' + applicationRecord.RecordType.Name + ': ' + stageLabels);

            List<Document_Checklist__c> applicableChecklists = new SHF_DocumentCheckListSelector()
                .selectForContext(stageLabels, 'All Applicants', applicantRecord.Customer_Profile__c);

            System.debug('>>> [Applicant] Retrieved ' + applicableChecklists.size() + ' checklist items');

            List<Document__c> documentsToInsert = new List<Document__c>();

            for (Document_Checklist__c checklist : applicableChecklists) {
                Document__c doc = new Document__c(
                    Document_Checklist__c = checklist.Id,
                    Application__c        = applicationRecord.Id,
                    Loan_Applicant__c     = applicantRecord.Id,
                    Document_Category__c  = checklist.Document_Category__c,
                    File_Name__c		  = checklist.Name,
                    Mandatory_Document__c = checklist.Mandatory_Optional__c == 'Mandatory',
                    Applicable_For__c 	  = 'Loan Applicants',
                    Document_Type__c      = checklist.Document_Type__c,
                    Stage__c              = checklist.Document_Stage__c,
                    OwnerId               = applicationRecord.OwnerId,
                    Status__c 			  = 'Not Uploaded'
                );
                documentsToInsert.add(doc);
                System.debug('>>> [Applicant] Prepared Document__c: ' + doc);
            }

            if (!documentsToInsert.isEmpty()) {
                System.debug('>>> [Applicant] Inserting ' + documentsToInsert.size() + ' documents');
                insert documentsToInsert;
            } else {
                System.debug('>>> [Applicant] No documents to insert.');
            }

        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('!!! [Applicant] Exception Line: ' + e.getLineNumber());
            System.debug('!!! [Applicant] Exception Message: ' + e.getMessage());
            System.debug('!!! [Applicant] Exception Details: ' + e);
        }
    }

    private static List<String> getCumulativeStages(String currentStage) {
        System.debug('>>> [Stages] Computing cumulative stages for: ' + currentStage);

        List<String> allStages = new List<String>{ 'QDE', 'DDE', 'Credit', 'Sanction', 'Disbursement' };
        Integer idx = allStages.indexOf(currentStage);

        if (idx != -1) {
            List<String> cumulative = new List<String>();
            for (Integer i = 0; i <= idx; i++) {
                cumulative.add(allStages[i]);
            }
            System.debug('>>> [Stages] Cumulative stages: ' + cumulative);
            return cumulative;
        } else {
            System.debug('>>> [Stages] Stage not found in known list. Returning: ' + currentStage);
            return new List<String>{ currentStage };
        }
    }
}