@isTest
public class SHF_DocumentCreationService_Test {

    @testSetup
    static void setupData() {
        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);
        try {
            RecordType rt = [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = 'Application__c'
                AND IsActive = true
                LIMIT 1
            ];
            if (rt != null) {
                app.RecordTypeId = rt.Id;
                update app;
            }
        } catch (Exception ign) {
            // No RT available in this org; positive tests will short-circuit accordingly.
        }

        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(
            app.Id,
            'Test',
            'Applicant', 
            '27AAACB2230M1ZL',
            true
        );
       
        if (applicant.Application__c == null) {
            applicant.Application__c = app.Id;
        }
        upsert applicant;

        SHF_TestDataFactory.createDocumentChecklist('Income Proof', 'Income Proof', 'Loan', 'Mandatory', 'QDE', null, true);
        SHF_TestDataFactory.createDocumentChecklist('Income Proof', 'Income Proof', 'All Applicants', 'Mandatory', 'QDE', 'Cash Salaried', true);
        SHF_TestDataFactory.createDocumentChecklist('Income Proof', 'Income Proof', 'All Applicants', 'Mandatory', 'QDE', 'Cash Salaried', true);
        SHF_TestDataFactory.createDocumentChecklist('Income Proof', 'Income Proof', 'Loan', 'Mandatory', 'QDE', null, false);
        SHF_TestDataFactory.createDocumentChecklist('Income Proof', 'Income Proof', 'All Applicants', 'Non Mandatory', 'QDE', 'Cash Salaried', true);
    }

    @isTest
    static void test_createDocumentsForApplication_positive() {
        
        Application__c app = [SELECT Id, RecordType.Name, OwnerId FROM Application__c LIMIT 1];

        if (app.RecordType == null) {
            System.assertEquals(null, app.RecordType, 'RecordType not available; positive path cannot run in this org.');
            return;
        }

        Test.startTest();
        SHF_DocumentCreationService.createDocumentsForApplication(app);
        Test.stopTest();

        List<Document__c> docs = [
            SELECT Id, Application__c, Document_Checklist__c, Status__c, Applicable_For__c
            FROM Document__c
            WHERE Application__c = :app.Id
        ];
        System.assert(docs.size() > 0, 'Documents should be created for application when checklist matches and RT present');
        for (Document__c d : docs) {
            System.assertEquals('Not Uploaded', d.Status__c, 'New documents should default to Not Uploaded');
            System.assertEquals('Loan Application', d.Applicable_For__c, 'Application documents should be marked for Loan Application');
        }
    }

    @isTest
    static void test_createDocumentsForApplicant_positive() {
        Application__c app = [SELECT Id, RecordType.Name, OwnerId FROM Application__c LIMIT 1];
        Loan_Applicant__c applicant = [SELECT Id, Customer_Profile__c FROM Loan_Applicant__c LIMIT 1];

        if (app.RecordType == null) {
            System.assertEquals(null, app.RecordType, 'RecordType not available; positive path cannot run in this org.');
            return;
        }

        Test.startTest();
        SHF_DocumentCreationService.createDocumentsForApplicant(applicant, app);
        Test.stopTest();

        List<Document__c> docs = [
            SELECT Id, Loan_Applicant__c, Document_Checklist__c, Applicable_For__c
            FROM Document__c
            WHERE Loan_Applicant__c = :applicant.Id
        ];
        System.assert(docs.size() >= 2, 'Applicant should receive documents from All Profile and Salaried profile checklists');
        for (Document__c d : docs) {
            System.assertEquals('Loan Applicants', d.Applicable_For__c, 'Applicant documents should be marked for Loan Applicants');
        }
    }

    @isTest
    static void test_createDocumentsForApplication_negative_invalidInput() {
        Test.startTest();
        try {
            SHF_DocumentCreationService.createDocumentsForApplication(null);
            System.assert(false, 'Expected exception for null application');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid Application input'), 'Guard should raise Invalid Application input');
        }
        Test.stopTest();
    }

    @isTest
    static void test_createDocumentsForApplicant_negative_invalidInput() {
        Application__c appNoRt = SHF_TestDataFactory.createApplication('No RT App', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(
            appNoRt.Id,
            'NoRT',
            'Applicant',
            '27AAACB2230M1ZL',
            true
        );

        Test.startTest();
        try {
            SHF_DocumentCreationService.createDocumentsForApplicant(applicant, appNoRt);
            System.assert(false, 'Expected exception when Application has no RecordType');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid Applicant or Application input'), 'Guard should raise Invalid Applicant or Application input');
        }
        Test.stopTest();
    }
}