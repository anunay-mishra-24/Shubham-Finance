@isTest
public class SHF_KfsControllerTest {
    
 @testSetup
    static void setupData() {
		Product_Master__c prod = new Product_Master__c(Name='test', Product_Type__c='Home Loan');
        Insert prod;
        // Application
        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);
		app.Product__c = prod.Id; 
        app.Sanction_Amount__c = 1000000;
        app.Revised_Rate__c = 15;
        app.Rate_of_Interest__c = 15;
        app.Tenure__c = 120;
        update app;
        // Verification
        Verification__c verification = SHF_TestDataFactory.createVerification(app.Id,UserInfo.getUserId(), 'Sampled','Document', null,true);

        // Verification Activity
        Verification_Activity__c va = SHF_TestDataFactory.createVerificationActivity( verification.Id, UserInfo.getUserId(), true);
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Merged Report';
        cv.PathOnClient = 'TestReport.pdf';
        cv.VersionData = Blob.valueOf('Test PDF Content');
        cv.IsMajorVersion = true;
        insert cv;
        
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = va.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.ShareType = 'V';
        insert cdl;
        
        Id repaymentRecTypeId = SObjectType.Bank_Details__c.getRecordTypeInfosByDeveloperName().get('Repayment').getRecordTypeId();
        Bank_Details__c bankDetail = new Bank_Details__c(Name = 'test', Due_Day__c ='4', Interest_Rate_Type__c='Floating', Installment_Type__c='',Repayment_Frequency__c='Monthly',First_Installment_Date__c=System.Today(), Disbursal_Type__c='Single', Application__c=app.Id, RecordTypeId = repaymentRecTypeId);
        Insert bankDetail;
        
        Anchor_Master__c anchor = new Anchor_Master__c(
            Anchor_Type__c = 'PLR',
            Anchor_Rate__c = 18.5,
            Is_Active__c = true
        );
        insert anchor;
        Charge_Master__c charge = new Charge_Master__c(
            Product_Type__c = 'Home Loan',
            Lower_Range__c = 0,
            Upper_Range__c = 5000000,
            Type_of_Charge__c = 'Login Fees',
            Login_Fee__c = 500
        );
        insert charge;
    }
    
    @isTest
    static void testControllerInitialization() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        
        PageReference pageRef = Page.SHF_Kfs_English;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', app.Id);

        Test.startTest();
        SHF_KfsController controller = new SHF_KfsController();
        Test.stopTest();

        System.assertNotEquals(null, controller.kfs, 'Wrapper should be initialized');
    }
}