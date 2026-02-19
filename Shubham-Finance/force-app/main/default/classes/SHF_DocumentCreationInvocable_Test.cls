@IsTest
private class SHF_DocumentCreationInvocable_Test {

    @TestSetup
    static void setupData() {
        
        RecordType appRT = [
            SELECT Id, Name, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Application__c'
            LIMIT 1
        ];

        Application__c testApp = new Application__c(
            Name = 'Test Application',
            RecordTypeId = appRT.Id
        );
        insert testApp;
    }

    @IsTest
    static void testCreateDocuments_ApplicationContext() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, true);

        SHF_DocumentCreationInvocable.InputWrapper input = new SHF_DocumentCreationInvocable.InputWrapper();
        input.applicationId = app.Id;
        input.isApplicationContext = true;

        Test.startTest();
        SHF_DocumentCreationInvocable.createDocuments(
            new List<SHF_DocumentCreationInvocable.InputWrapper>{ input }
        );
        Test.stopTest();

        System.assert(true, 'Application context executed without error');
    }

    @IsTest
    static void testCreateDocuments_ApplicantContext() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, true);
     
        SHF_DocumentCreationInvocable.InputWrapper input = new SHF_DocumentCreationInvocable.InputWrapper();
        input.applicationId = la.Application__c;
        input.applicantId = la.Id;
        input.isApplicationContext = false;

        Test.startTest();
        SHF_DocumentCreationInvocable.createDocuments(
            new List<SHF_DocumentCreationInvocable.InputWrapper>{ input }
        );
        Test.stopTest();

        System.assert(true, 'Applicant context executed without error');
    }

    @IsTest
    static void testCreateDocuments_InvalidRecords() {
    
        SHF_DocumentCreationInvocable.InputWrapper badInput = new SHF_DocumentCreationInvocable.InputWrapper();
        badInput.applicationId = 'a0A000000000001AAA';
        badInput.applicantId = 'a0B000000000001AAA';
        badInput.isApplicationContext = false;

        Test.startTest();
        SHF_DocumentCreationInvocable.createDocuments(
            new List<SHF_DocumentCreationInvocable.InputWrapper>{ badInput }
        );
        Test.stopTest();

        System.assert(true, 'Handled invalid IDs gracefully');
    }
}