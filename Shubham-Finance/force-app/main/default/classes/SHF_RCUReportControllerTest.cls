@isTest
public class SHF_RCUReportControllerTest {

    @testSetup
    static void setupData() {

        // Application
        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);

        // Verification
        Verification__c verification = SHF_TestDataFactory.createVerification(app.Id,UserInfo.getUserId(), 'Sampled','Document', null,true);

        // Verification Activity
        Verification_Activity__c va = SHF_TestDataFactory.createVerificationActivity( verification.Id, UserInfo.getUserId(), true);

        // Loan Applicants
        SHF_TestDataFactory.createLoanApplicantwithType( app.Id,'Primary','Applicant', null,'Primary Applicant', 'Yes', true);

        SHF_TestDataFactory.createLoanApplicantwithType(app.Id,'Co','Applicant',null,'Co-Applicant','No',true);

        // Document
        Document__c doc = SHF_TestDataFactory.createDocument(app.Id,null, 'Income Proof','Salary Slip', 'QDE', 'Uploaded', true);

        // Document Activity
        insert new Document_Activity__c(Verification__c = verification.Id, Document__c = doc.Id);
    }

    @isTest
    static void testRCUReportController() {

        Verification_Activity__c va = [SELECT Id FROM Verification_Activity__c LIMIT 1];

        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.StandardController(va);

        SHF_RCUReportController controller = new SHF_RCUReportController(sc);

        Test.stopTest();

        System.assertNotEquals(null, controller.verificationRec);
        System.assertNotEquals(null, controller.reportDate);
        System.assertNotEquals(null, controller.displayTimestamp);

        
        // Documents
        System.assertNotEquals(null, controller.documentActivities);
        System.assert(controller.totalDocCount >= 1);
        System.assertNotEquals(null, controller.rcuStatusSummary);
    }
}