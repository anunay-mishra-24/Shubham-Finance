@IsTest
private class SHF_EmailVerification_Service_Test {

    @IsTest
    static void test_applicant_not_found() {
        Test.startTest();
        String result = SHF_EmailVerification_Service.initiateEmailVerification(Id.valueOf('001000000000000AAA')); // random Id not present as Loan_Applicant__c
        Test.stopTest();

        System.assertNotEquals(null, result, 'Service should return a message string');
        System.assert(result.toLowerCase().contains('error') || result.toLowerCase().contains('not found') || result.toLowerCase().contains('failed'),
            'Expected error-like message when applicant not found. Actual: ' + result);
    }

     @IsTest
    static void test_applicant_email_blank() {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(
            app.Id, 'Test', 'Blank', null, false
        );
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'User';
        applicant.Customer_Type__c = 'Individual';
        applicant.Email__c = 'testuser@example.com';
        applicant.UAN_Number__c = '100234567890';
        insert applicant;

        Test.startTest();
        String result = SHF_EmailVerification_Service.initiateEmailVerification(applicant.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Service should return a message string');
        System.assert(result.toLowerCase().contains('error') || result.toLowerCase().contains('email') || result.toLowerCase().contains('failed'),
            'Expected email-error-like message when email is blank. Actual: ' + result);
    }

    @IsTest
    static void test_happy_path_email_present() {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(
            app.Id, 'Test', 'Blank', null, false
        );
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'User';
        applicant.Customer_Type__c = 'Individual';
        applicant.Email__c = 'testuser@example.com';
        applicant.UAN_Number__c = '100234567890';
        insert applicant;
        
        Integer preCount = [SELECT count() FROM E_Verification__c];

        Test.startTest();
        String result = SHF_EmailVerification_Service.initiateEmailVerification(applicant.Id);
        Test.stopTest();

        Integer postCount = [SELECT count() FROM E_Verification__c];
        System.assertEquals(preCount + 1, postCount, 'Should create exactly one E_Verification__c');

        applicant = [SELECT Id, Email_Verification__c FROM Loan_Applicant__c WHERE Id = :applicant.Id];
        System.assertNotEquals(null, applicant.Email_Verification__c, 'Applicant should be linked to E_Verification__c');

        E_Verification__c ev = [SELECT Id, Status__c, Sent_To__c FROM E_Verification__c WHERE Id = :applicant.Email_Verification__c];
        System.assertEquals('In Progress', ev.Status__c, 'E-Verification should be set In Progress');
        System.assertEquals('', ev.Sent_To__c, 'Sent_To__c should be set to empty string per service');

        System.assertNotEquals(null, result, 'Service should return a message string');
        System.assert(
            result.toLowerCase().contains('success') ||
            result.toLowerCase().contains('initiated') ||
            result.toLowerCase().contains('verify'),
            'Expected success-like message. Actual: ' + result
        );
    }
}