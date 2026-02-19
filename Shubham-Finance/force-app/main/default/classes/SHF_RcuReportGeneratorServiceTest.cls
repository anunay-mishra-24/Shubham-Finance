@isTest
public class SHF_RcuReportGeneratorServiceTest {

    @testSetup
    static void setupData() {

        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);

        Verification__c verification = SHF_TestDataFactory.createVerification( app.Id,UserInfo.getUserId(),'Sampled', 'Document', null,true);

        Verification_Activity__c va = SHF_TestDataFactory.createVerificationActivity( verification.Id, UserInfo.getUserId(), true);

        // Primary Applicant
        SHF_TestDataFactory.createLoanApplicantwithType( app.Id,'Primary', 'Applicant', null,'Primary Applicant', 'Yes',true);
    }

    // ---------------- generateRCUReport ----------------
    @isTest
    static void testGenerateRCUReport_success() {

        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Verification_Activity__c va = [SELECT Id FROM Verification_Activity__c LIMIT 1];

        Test.startTest();

        Map<String, Object> result =
            SHF_RcuReportGeneratorService.generateRCUReport(app.Id, va.Id,'DummyVFPage');

        Test.stopTest();

        System.assertEquals('success', result.get('status'));
        System.assertNotEquals(null, result.get('docId'));
        System.assertNotEquals(null, result.get('fileBase64'));

        // Document actually created
        Document__c doc = [SELECT Id, Public_View_Url__c FROM Document__c LIMIT 1];
        System.assertNotEquals(null, doc.Public_View_Url__c);
    }

    // ---------------- getPrimaryApplicant ----------------
    @isTest
    static void testGetPrimaryApplicant() {

        Application__c app = [SELECT Id FROM Application__c LIMIT 1];

        Test.startTest();
        Id applicantId =
            SHF_RcuReportGeneratorService.getPrimaryApplicant(app.Id);
        Test.stopTest();

        System.assertNotEquals(null, applicantId);
    }
}