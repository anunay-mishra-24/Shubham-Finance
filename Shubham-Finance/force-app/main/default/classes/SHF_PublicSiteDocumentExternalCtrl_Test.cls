@IsTest
public class SHF_PublicSiteDocumentExternalCtrl_Test {
 
    @testSetup
    static void setupTestData() {
        
        RecordType qdeRt = [
            SELECT Id FROM RecordType 
            WHERE SobjectType = 'Application__c' 
            AND DeveloperName = 'QDE' LIMIT 1
        ];
        
        RecordType creditRt = [
            SELECT Id FROM RecordType 
            WHERE SobjectType = 'Application__c' 
            AND DeveloperName = 'Credit_Evaluation' LIMIT 1
        ];
        
        // Active QDE Application
                Application__c qdeApp = new Application__c(Name = 'Test App',RecordTypeId = qdeRt.Id, Public_Site_Upload_SMS_Link_Time__c = System.now() + 1);

        
        insert qdeApp;
        
        // Non Allowed RecordType Application
               Application__c creditApp = new Application__c(Name = 'Test App2',RecordTypeId = creditRt.Id, Public_Site_Upload_SMS_Link_Time__c = System.now() + 1);

        
        insert creditApp;

        Loan_Applicant__c applicant1 = SHF_TestDataFactory.createLoanApplicant(
            qdeApp.Id,'John','Doe','27AAAAA0000A1Z5', false
        );
        insert applicant1;
        
        Loan_Applicant__c applicant2 = SHF_TestDataFactory.createLoanApplicant(
            creditApp.Id,'Jane','Doe','27AAAAA0000A1Z5', false
        );
        insert applicant2;

        Document__c doc = SHF_TestDataFactory.createDocument(
            qdeApp.Id,
            applicant1.Id,
            'Income Proof',
            'Income Proof',
            'QDE',
            'Not Uploaded',
            false
        );
        doc.Selected_for_Public_Site_Upload__c = true;
        insert doc;
    }

    // ---------------------------------------------------------
    // Test getDocumentsForApplicant
    // ---------------------------------------------------------
    @IsTest
    static void testGetDocuments() {
        
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c LIMIT 1];
        
        Test.startTest();
        SHF_PublicSiteDocumentExternalController.ResponseWrapper res =
            SHF_PublicSiteDocumentExternalController.getDocumentsForApplicant(applicant.Id);
        Test.stopTest();
        
        System.assertEquals(true, res.isSuccess);
        System.assert(res.totalRecords > 0);
    }

    // ---------------------------------------------------------
    // Test Valid QDE Link (NOT Expired)
    // ---------------------------------------------------------
    @IsTest
    static void testLinkNotExpired() {
        
        Loan_Applicant__c applicant = [
            SELECT Id FROM Loan_Applicant__c 
            WHERE Application__r.RecordType.DeveloperName = 'QDE'
            LIMIT 1
        ];
        
        Test.setCurrentPage(new PageReference('/apex/TestPage'));
        ApexPages.currentPage().getParameters().put('applicantId', applicant.Id);
        
        Test.startTest();
        SHF_PublicSiteDocumentExternalController controller =
            new SHF_PublicSiteDocumentExternalController();
        controller.onPageLoad();
        Test.stopTest();
        
        System.assertEquals(false, controller.isExpired);
    }

    // ---------------------------------------------------------
    // Test Invalid RecordType (Should Expire)
    // ---------------------------------------------------------
    @IsTest
    static void testInvalidRecordTypeExpired() {
        
        Loan_Applicant__c applicant = [
            SELECT Id FROM Loan_Applicant__c 
            WHERE Application__r.RecordType.DeveloperName = 'Credit_Evaluation'
            LIMIT 1
        ];
        
        Test.setCurrentPage(new PageReference('/apex/TestPage'));
        ApexPages.currentPage().getParameters().put('applicantId', applicant.Id);
        
        Test.startTest();
        SHF_PublicSiteDocumentExternalController controller =
            new SHF_PublicSiteDocumentExternalController();
        controller.onPageLoad();
        Test.stopTest();
        
        System.assertEquals(true, controller.isExpired);
    }

    // ---------------------------------------------------------
    // Test Invalid Applicant Id
    // ---------------------------------------------------------
    @IsTest
    static void testInvalidApplicantId() {
        
        Test.setCurrentPage(new PageReference('/apex/TestPage'));
        ApexPages.currentPage().getParameters().put('applicantId', '001000000000001AAA');
        
        Test.startTest();
        SHF_PublicSiteDocumentExternalController controller =
            new SHF_PublicSiteDocumentExternalController();
        controller.onPageLoad();
        Test.stopTest();
        
        System.assertEquals(true, controller.isExpired);
    }

    // ---------------------------------------------------------
    // Test afterExpiredUpdateDocuments
    // ---------------------------------------------------------
    @IsTest
    static void testAfterExpiredUpdateDocuments() {
        
        Loan_Applicant__c applicant = [
            SELECT Id FROM Loan_Applicant__c 
            WHERE Application__r.RecordType.DeveloperName = 'QDE'
            LIMIT 1
        ];
        
        Test.setCurrentPage(new PageReference('/apex/TestPage'));
        ApexPages.currentPage().getParameters().put('applicantId', applicant.Id);
        
        SHF_PublicSiteDocumentExternalController controller =
            new SHF_PublicSiteDocumentExternalController();
        
        controller.actualApplicantId = applicant.Id;
        
        Test.startTest();
        SHF_PublicSiteDocumentExternalController.ResponseWrapper res =
            controller.afterExpiredUpdateDocuments();
        Test.stopTest();
        
        System.assertEquals(true, res.isSuccess);
    }
}