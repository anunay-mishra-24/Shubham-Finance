/**
* @File Name : SHF_LoanApplicationHelper.cls
* @Description : Helper class for Application record type transitions.
* @Author :
* @Last Modified By :
* @Last Modified On : September 01, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 22, 2025 |   | Initial Version
**/

public with sharing class SHF_LoanApplicationHelper {

    @AuraEnabled
    public static void sendBackToQDE(Id applicationId) {
        if (applicationId == null) {
            throw new AuraHandledException('Application not found.');
        }

        try {
            logger.info('sendBackToQDE called for Application Id: ' + applicationId);

            // Get RecordType Ids 
            Map<String, Id> recordTypeMap = new Map<String, Id>();
            for (RecordType record : [SELECT Id, DeveloperName FROM RecordType  WHERE SObjectType = 'Application__c' AND DeveloperName IN ('QDE', 'Credit_Evaluation') ]) {
                recordTypeMap.put(record.DeveloperName, record.Id);
            }
            logger.info('RecordType Map: ' + recordTypeMap);

            Id qdeRecordTypeId = recordTypeMap.get('QDE');
            Id creditEvaluationRecordTypeId = recordTypeMap.get('Credit_Evaluation');

            // Query Application record
            Application__c applicationRecord = [SELECT Id, RecordTypeId,QDE_Last_Owner__c,OwnerId  FROM Application__c  WHERE Id = :applicationId LIMIT 1];
            logger.info('Fetched Application: ' + applicationRecord);

            if (applicationRecord.RecordTypeId != creditEvaluationRecordTypeId) {
                throw new AuraHandledException('Only Credit Evaluation records can be sent back to QDE.');
            }

            // Update RecordType
            applicationRecord.RecordTypeId = qdeRecordTypeId;
            applicationRecord.OwnerId = applicationRecord.QDE_Last_Owner__c;
            applicationRecord.Application_Stage__c = 'Application Form Generation';
            applicationRecord.DDE_Last_Owner__c = UserInfo.getUserId();
            update applicationRecord;
            logger.info('Application sent back to QDE successfully: ' + applicationRecord.Id);
        } catch (Exception e) {
            logger.error('Error in sendBackToQDE: ' + e.getMessage());
        } finally {
            logger.saveLog();
        }
    }


    @AuraEnabled
    public static String changeRecordType(Id recordId) {
        if (recordId == null) {
            return 'ERROR: Application Not Found.';
        }

        try {
            // Fetch the Application record with RecordType
            Application__c app = [SELECT Id, RecordTypeId, Application_Stage__c, RecordType.DeveloperName FROM Application__c WHERE Id = :recordId LIMIT 1];

            // Validate stage & record type
            if (app.RecordType.DeveloperName != 'QDE' || app.Application_Stage__c != 'Application Form Generation') {
                return 'INFO: Cannot move stage from ' + app.Application_Stage__c;
            }

            // Get Credit_Evaluation RecordTypeId
            RecordType recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Credit_Evaluation' AND SObjectType = 'Application__c' LIMIT 1];
            if (recordType == null) {
                return 'ERROR: Credit_Evaluation Record Type not found.';
            }

            // Update record type and stage
            app.RecordTypeId = recordType.Id;
            app.Application_Stage__c = 'DDE';
            update app;

            // Call E-Verification creation after successful update
            createEVerificationRecords(app.Id);

            return 'SUCCESS: Application moved to DDE stage successfully';

        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static void createEVerificationRecords(Id applicationId) {
        if (applicationId == null) return;

        // Fetch Insurance RecordType for E_Verification__c
        RecordType insuranceRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Insurance' AND SObjectType = 'E_Verification__c' LIMIT 1];
        if (insuranceRT == null) return;

        // Fetch Loan Applicants with null Insurance_Verification__c
        List<Loan_Applicant__c> applicants = [SELECT Id, Insurance_Verification__c FROM Loan_Applicant__c WHERE Application__c = :applicationId AND Insurance_Verification__c = null];
        if (applicants.isEmpty()) return;

        // Prepare E_Verification__c records
        List<E_Verification__c> verifications = new List<E_Verification__c>();
        for (Loan_Applicant__c la : applicants) {
            verifications.add(new E_Verification__c(
                RecordTypeId       = insuranceRT.Id,
                Loan_Application__c = applicationId,
                Loan_Applicant__c   = la.Id
            ));
        }

        // Insert and map back to Loan Applicants
        if (!verifications.isEmpty()) {
            insert verifications;

            List<Loan_Applicant__c> updateApplicants = new List<Loan_Applicant__c>();
            for (E_Verification__c ev : verifications) {
                updateApplicants.add(new Loan_Applicant__c(
                    Id = ev.Loan_Applicant__c,
                    Insurance_Verification__c = ev.Id
                ));
            }
            if (!updateApplicants.isEmpty()) {
             update updateApplicants;
            }
            
        }
    }
}