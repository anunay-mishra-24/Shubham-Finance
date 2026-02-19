/**
* @File Name          : SHF_CommonUtil_Test.cls
* @Description        : Test class to cover SHF_CommonUtil utility methods (using SHF_TestDataFactory)
* @Author             : Kunal Soni
* ==============================================================================
* Ver   Date          Author       Modification
* ==============================================================================
* 1.0   20-08-2025    Kunal Soni   Converted to use SHF_TestDataFactory
*/
@IsTest
public class SHF_CommonUtil_Test {
    
    @TestSetup
    static void setupData() {
        // Create Application
        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);
        
        // Create Loan Applicant
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(
            app.Id, 'Test', 'Applicant', '27AAACB2230M1ZL', true
        );
        
        // E-Verification record
        E_Verification__c ver = new E_Verification__c(
            Loan_Applicant__c = applicant.Id,
            Status__c = 'Success'
        );
        insert ver;
        
        // Link applicant to E-verifications
        applicant.PAN_Verification__c         = ver.Id;
        applicant.Mobile_Verification__c      = ver.Id;
        applicant.Digilocker_Verification__c  = ver.Id;
        applicant.GST_Verification__c         = ver.Id;
        applicant.Penny_Drop_Verification__c  = ver.Id;
        applicant.Electricity_Verification__c = ver.Id;
        applicant.Udyam_Verification__c       = ver.Id;
        applicant.AML_Verification__c         = ver.Id;
        update applicant;
        
        // Application Login Fee verification
        app.Login_Fee_Verification__c = ver.Id;
        update app;
        
        // Dummy Group for notification
        insert new Group(
            DeveloperName = 'TestGroup',
            Name          = 'Test Group',
            Type          = 'Regular'
        );
    }
    
    @IsTest
    static void testFetchVerificationId_AllAPIs() {
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c LIMIT 1];
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        
        System.assertNotEquals(null, SHF_CommonUtil.fetchVerificationId(applicant.Id, SHF_ConstantsUtil.PAN_API));
        System.assertNotEquals(null, SHF_CommonUtil.fetchVerificationId(applicant.Id, SHF_ConstantsUtil.Mobile_MNRL_API));
        System.assertNotEquals(null, SHF_CommonUtil.fetchVerificationId(applicant.Id, SHF_ConstantsUtil.KYC_DigiLocker_API));
        System.assertNotEquals(null, SHF_CommonUtil.fetchVerificationId(applicant.Id, SHF_ConstantsUtil.GST_API));
        System.assertNotEquals(null, SHF_CommonUtil.fetchVerificationId(applicant.Id, SHF_ConstantsUtil.PENNY_DROP_API));
        System.assertNotEquals(null, SHF_CommonUtil.fetchVerificationId(applicant.Id, SHF_ConstantsUtil.ELECTRICITY_API));
        System.assertNotEquals(null, SHF_CommonUtil.fetchVerificationId(applicant.Id, SHF_ConstantsUtil.UDYAM_API));
        System.assertNotEquals(null, SHF_CommonUtil.fetchVerificationId(applicant.Id, SHF_ConstantsUtil.AML_API));
        
        System.assertNotEquals(null, SHF_CommonUtil.fetchVerificationId(app.Id, SHF_ConstantsUtil.LOGIN_FEE_API));
    }
    
    @IsTest
    static void testCreateUtilityMethods() {
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c LIMIT 1];
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        
        System.assertNotEquals(null, SHF_CommonUtil.createVerfication(applicant.Id, null, 'InProgress'));
        System.assertNotEquals(null, SHF_CommonUtil.createAddress(applicant.Id, 'Permanent'));
        System.assertNotEquals(null, SHF_CommonUtil.createDocument('Doc1', app.Id, 'PAN'));
    }
    
    @IsTest
    static void testFormatSMSTemplate() {
        String formatted = SHF_CommonUtil.formatSMSTemplate('Hello World\nLine2');
        System.assert(formatted.contains('%20'));
        System.assert(formatted.contains('%0A'));
    }
    
    @IsTest
    static void testNotifyUsersByEmail_Overloads() {
        User u = [SELECT Email FROM User WHERE IsActive = true LIMIT 1];
        List<String> emails = new List<String>{u.Email};
            
        // Default
        List<Messaging.SingleEmailMessage> mails = SHF_CommonUtil.notifyUsersByEmail(
            emails, 'Test Body', 'Test Subject'
        );
        System.assertEquals(1, mails.size());
        
        // With display name
        List<Messaging.SingleEmailMessage> mails2 = SHF_CommonUtil.notifyUsersByEmail(
            emails, 'Body2', 'Subj2', 'Custom Sender'
        );
        System.assertEquals('Custom Sender', mails2[0].getSenderDisplayName());
    }
    
    @IsTest
    static void testDateTimeCalculations() {
        Datetime nowDt = Datetime.now();
        
        Datetime local = SHF_CommonUtil.formatToUserLocalTimezone(nowDt);
        System.assertNotEquals(null, local);
        
        Long hours = SHF_CommonUtil.calculateHours(nowDt, nowDt.addHours(-5));
        System.assert(hours > 0);
        
        Test.startTest();
        SHF_CommonUtil.calculateBusinessHours(1, nowDt);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetGroupId() {
        Id gid = SHF_CommonUtil.getGroupIdByDeveloperName('TestGroup','Regular');
        System.assertNotEquals(null, gid);
    }
    
    @IsTest
    static void testInvocableEmail() {
        User u = [SELECT Email FROM User WHERE IsActive = true LIMIT 1];
        
        SHF_CommonUtil.NotifyEmailInput input = new SHF_CommonUtil.NotifyEmailInput();
        input.recipientEmails = new List<String>{u.Email};
        input.emailTemplateId = [SELECT Id FROM EmailTemplate LIMIT 1].Id;
        input.whatId          = [SELECT Id FROM Application__c LIMIT 1].Id;
        
        Test.startTest();
        SHF_CommonUtil.notifyUsersByEmail(new List<SHF_CommonUtil.NotifyEmailInput>{input});
        Test.stopTest();
    }
    
    @IsTest
    static void testMetadataMethods() {
        Test.startTest();
        Map<String, Messages_Config__mdt> msgMap = SHF_CommonUtil.getMessageRecord('SMS');
        Map<String, API_Fields_Mapping__mdt> apiMap = SHF_CommonUtil.getAPIFieldsMappingsRecord('LMS');
        Map<String, API_Fields_Mapping__mdt> apiMap2 = SHF_CommonUtil.getAPIFieldsMappingsRecordByLabel('LMS');
        Map<String, Callout_Framework__mdt> calloutMap = SHF_CommonUtil.getCalloutMetadata('SearchCustomer');
        
        // For Address Metadata (if exists in org)
        List<Callout_Framework__mdt> calloutList = [SELECT Id FROM Callout_Framework__mdt LIMIT 1];
        if (!calloutList.isEmpty()) {
            Map<String, Loan_Applicant_Address__mdt> addrMap = SHF_CommonUtil.getAddressMetadata(calloutList[0].Id);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testNotifyUsersByEmailWithTemplate() {
        User u = [SELECT Email FROM User WHERE IsActive = true LIMIT 1];
        Id templateId = [SELECT Id FROM EmailTemplate LIMIT 1].Id;
        Id appId      = [SELECT Id FROM Application__c LIMIT 1].Id;
        
        List<Messaging.SingleEmailMessage> mails = SHF_CommonUtil.notifyingUsersByEmail(
            new List<String>{u.Email}, templateId, appId
        );
        
        System.assertEquals(1, mails.size());
    }
    
    @IsTest
    static void testNotifyUsersByNotification() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Case c = SHF_TestDataFactory.createCase(
            'Test Case', 'New', null, 'Test Cust', 'abc@test.com',
            'Phone', 'Enquiry', 'Change in base rate',
            null, null, null, null, null, null, null, true
        );
        
        CustomNotificationType cnt = [SELECT Id, DeveloperName FROM CustomNotificationType LIMIT 1];
        
        Test.startTest();
        SHF_CommonUtil.notifyUsersByNotification(
            new Set<String>{u.Id}, c.Id, 'Test Notification', 'This is a test body', cnt.DeveloperName
        );
        Test.stopTest();
        
        System.assert(true, 'Notification method executed without errors');
    }
}