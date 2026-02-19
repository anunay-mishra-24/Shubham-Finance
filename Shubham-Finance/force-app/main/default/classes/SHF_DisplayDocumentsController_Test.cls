@isTest
private class SHF_DisplayDocumentsController_Test {
    
    @testSetup
    static void setupTestData() {
        // Create Application with RecordType
        RecordType appRt = [SELECT Id, Name, SobjectType FROM RecordType WHERE SobjectType = 'Application__c' LIMIT 1];
        Application__c app = new Application__c(
            Name = 'Test App',
            RecordTypeId = appRt.Id
        );
        insert app;

        // Create Loan Applicant
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'John', 'Doe', 'GST123', true);

        // Create Checklist for Application
        SHF_TestDataFactory.createDocumentChecklist('Income Proof', 'Income Proof', 'Loan', 'Non Mandatory', 'QDE', null, true);

        // Create Checklist for Applicant
        SHF_TestDataFactory.createDocumentChecklist('Income Proof', 'Income Proof', 'All Applicants', 'Non Mandatory', 'QDE', 'Cash Salaried', true);

        // Create Documents
        SHF_TestDataFactory.createDocument(app.Id, null, 'Income Proof', 'Income Proof', 'QDE', 'Not Uploaded', true); // Application doc
        SHF_TestDataFactory.createDocument(app.Id, applicant.Id, 'Income Proof', 'Income Proof', 'QDE', 'Not Uploaded', true); // Applicant doc
        
        // Create Verification + Verification Activity (ensures flow won't fail)
        Verification__c ver = SHF_TestDataFactory.createVerification(app.Id, null, 'Sampled', 'Documents', 'RCU', true);
        SHF_TestDataFactory.createVerificationActivity(ver.Id, null, true);
    }
    
    @isTest
    static void testGetLoanApplicantRecords() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        SHF_DisplayDocumentsController.ResponseWrapper res = SHF_DisplayDocumentsController.getLoanApplicantRecords(app.Id);
        System.assert(res.isSuccess, 'Expected success from getLoanApplicantRecords');
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
    }

    @isTest
    static void testGetApplicationDocumentsForApplication() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        SHF_DisplayDocumentsController.ResponseWrapper res = SHF_DisplayDocumentsController.getApplicationDocuments(app.Id, null);
        System.assert(res.isSuccess, 'Expected success for Application documents');
        System.assert(res.totalRecords > 0, 'Should return at least one document');
    }
    
    @isTest
    static void testGetApplicationDocumentsForApplicant() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c LIMIT 1];
        SHF_DisplayDocumentsController.ResponseWrapper res = SHF_DisplayDocumentsController.getApplicationDocuments(app.Id, applicant.Id);
        System.assert(res.isSuccess, 'Expected success for Applicant documents');
        System.assert(res.totalRecords > 0, 'Should return at least one document for applicant');
    }
    
    @istest
    static void testGetDocumentsForRecord() {
        // Query a document with Application__c field
        Document__c doc = [SELECT Id, Application__c FROM Document__c LIMIT 1];
        SHF_DisplayDocumentsController.ResponseWrapper res =
            SHF_DisplayDocumentsController.getDocumentsForRecord(doc.Application__c, 'Application__c');
        System.assert(res.isSuccess, 'Expected success from getDocumentsForRecord');
    }    
    @isTest
    static void testGetChecklistOptionsForApplication() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        List<Document_Checklist__c> results =
            SHF_DisplayDocumentsController.getChecklistOptions(app.Id, null, 'Application');
        System.assert(!results.isEmpty(), 'Checklist should be returned for Application context');
    }
    
    @istest
    static void testGetChecklistOptionsForApplicant() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Loan_Applicant__c applicant = [SELECT Id, Customer_Profile__c FROM Loan_Applicant__c LIMIT 1];
        applicant.Customer_Profile__c = 'Profile1'; // aligns with factory checklist
        update applicant;
        
        List<Document_Checklist__c> results =
            SHF_DisplayDocumentsController.getChecklistOptions(app.Id, applicant.Id, 'Applicant');
        System.assert(!results.isEmpty(), 'Checklist should be returned for Applicant context');
    }

    
    @isTest
    static void testCreateDocumentRecordForApplication() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        SHF_DisplayDocumentsController.ResponseWrapper res = SHF_DisplayDocumentsController.createDocumentRecord(
            app.Id, null, 'Application', 'Income Proof', 'Income Proof', 'Doc Name', null, null
        );
        System.assert(res.isSuccess, 'Document should be created successfully for Application');
        System.assertNotEquals(null, res.recordId, 'RecordId should be populated');
    }
    
    @isTest
    static void testCreateDocumentRecordForApplicant() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c LIMIT 1];
        SHF_DisplayDocumentsController.ResponseWrapper res = SHF_DisplayDocumentsController.createDocumentRecord(
            app.Id, applicant.Id, 'Applicant', 'Income Proof', 'Income Proof', 'Doc Name 2', null, null
        );
        System.assert(res.isSuccess, 'Document should be created successfully for Applicant');
        System.assertNotEquals(null, res.recordId, 'RecordId should be populated');
    }
    
    @isTest
    static void testGetAcknowledgementStatusOptions() {
        List<String> options = SHF_DisplayDocumentsController.getAcknowledgementStatusOptions();
        System.assert(!options.isEmpty(), 'Acknowledgement status options should not be empty');
    }
    
    @isTest
    static void testUpdateAcknowledgementStatus() {
        Document__c doc = [SELECT Id FROM Document__c LIMIT 1];
        Test.startTest();
        SHF_DisplayDocumentsController.updateAcknowledgementStatus(new List<Id>{doc.Id}, 'Received', 'Test Comment');
        Test.stopTest();
        
        Document__c updatedDoc = [SELECT Acknowledge_Status__c FROM Document__c WHERE Id = :doc.Id];
        System.assertEquals('Received', updatedDoc.Acknowledge_Status__c, 'Acknowledgement status should be updated');
    }
    
    @isTest
    static void testGetDocuments() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];

        Test.startTest();
        SHF_DisplayDocumentsController.ResponseWrapper resp =
            SHF_DisplayDocumentsController.getDocumentsForRecord(app.Id, 'Application__c');
        Test.stopTest();

        System.assert(resp.isSuccess, 'Expected success');
        System.assertNotEquals(null, resp.responseBody, 'Response body should not be null');
    }
}