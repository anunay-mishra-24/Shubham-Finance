@IsTest
public class SHF_LoanApplicantsSelector_Test {

    // Helper method to create Application
    private static Application__c createApplication() {
        Application__c app = new Application__c(
            Name = 'Test Application',
            Application_Stage__c = 'Credit Assessment'
        );
        insert app;
        return app;
    }

    // Helper method to create Loan Applicant
    private static Loan_Applicant__c createLoanApplicant(Id applicationId) {
        Loan_Applicant__c applicant = new Loan_Applicant__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990,1,1),
            Mobile_Number__c = '9999999999',
            Pan_Number__c = 'ABCDE1234F',
            Applicant_Type__c = 'Primary Applicant',
            Application__c = applicationId
        );
        insert applicant;
        return applicant;
    }

    @IsTest
    static void testSelectByIdWithLoanApplication() {
        Application__c app = createApplication();
        Loan_Applicant__c applicant = createLoanApplicant(app.Id);
        
        Test.startTest();
        SHF_LoanApplicantsSelector selector = new SHF_LoanApplicantsSelector();
        List<Loan_Applicant__c> results = selector.selectByIdWithLoanApplication(new Set<Id>{app.Id});
        Test.stopTest();
        
        System.assertNotEquals(0, results.size(), 'Should return applicant linked to application');
        System.assertEquals(applicant.Id, results[0].Id, 'Returned applicant Id should match');
    }

    @IsTest
    static void testSelectByApplicantId() {
        Application__c app = createApplication();
        Loan_Applicant__c applicant = createLoanApplicant(app.Id);
        
        Test.startTest();
        SHF_LoanApplicantsSelector selector = new SHF_LoanApplicantsSelector();
        List<Loan_Applicant__c> results = selector.selectByApplicantId(new Set<Id>{applicant.Id});
        Test.stopTest();
        
        System.assertNotEquals(0, results.size(), 'Should return applicant for given Id');
        System.assertEquals(applicant.Id, results[0].Id, 'Returned applicant Id should match');
    }

    @IsTest
    static void testSelectById() {
        Application__c app = createApplication();
        Loan_Applicant__c applicant = createLoanApplicant(app.Id);

        Test.startTest();
        SHF_LoanApplicantsSelector selector = new SHF_LoanApplicantsSelector();
        List<Loan_Applicant__c> results = selector.selectById(new Set<Id>{applicant.Id});
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return applicant by Id');
        System.assertEquals(applicant.Id, results[0].Id, 'Returned applicant Id should match');
    }

    @IsTest
    static void testSelectLoanApplicantForCIBIL() {
        Application__c app = createApplication();
        Loan_Applicant__c applicant = createLoanApplicant(app.Id);

        Test.startTest();
        SHF_LoanApplicantsSelector selector = new SHF_LoanApplicantsSelector();
        Loan_Applicant__c result = selector.selectLoanApplicantForCIBIL(applicant.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a loan applicant');
        System.assertEquals(applicant.Id, result.Id, 'Returned applicant Id should match');
    }

    @IsTest
    static void testSelectInsuranceApplicant() {
        Application__c app = createApplication();
        Loan_Applicant__c applicant = createLoanApplicant(app.Id);

        Test.startTest();
        SHF_LoanApplicantsSelector selector = new SHF_LoanApplicantsSelector();
        Loan_Applicant__c result = selector.selectInsuranceApplicant(applicant.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a loan applicant for insurance');
        System.assertEquals(applicant.Id, result.Id, 'Returned applicant Id should match');
    }
}