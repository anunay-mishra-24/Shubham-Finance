@IsTest
private class SHF_ApplicationSelector_Test {

    private static Application__c createTestApplication() {
        State_Master__c state = new State_Master__c(
            Name = 'Madhya Pradesh',
            State_Code__c = 'MP',
            Region__c = 'Central',
            Zone__c = 'West Region'
        );
        insert state;

        City_Master__c city = new City_Master__c(
            Name = 'Indore',
            State_Master__c = state.Id
        );
        insert city;

        Branch_Master__c branch = new Branch_Master__c(
            Name = 'Indore Main',
            Branch_Code__c = 'BR001',
            City__c = city.Id
        );
        insert branch;

        Application__c app = new Application__c(
            Name = 'APP-001',
            Applied_Loan_Amount__c = 500000,
            Branch__c = branch.Id,
            Tenure__c = 120,
            Login_Fee_Verification__c = UserInfo.getUserId(),
            Application_Stage__c = 'DDE'
        );
        insert app;

        Loan_Applicant__c applicant = new Loan_Applicant__c(
            Name = 'Primary Applicant',
            Application__c = app.Id
        );
        insert applicant;

        return app;
    }

    
    @IsTest
    static void test_selectApplicationForCIBIL() {
        Application__c app = createTestApplication();

        Test.startTest();
        SHF_ApplicationSelector selector = new SHF_ApplicationSelector();

        Application__c singleApp = selector.selectApplicationForCIBIL(app.Id);
        System.assertNotEquals(null, singleApp, 'CIBIL query should return record');
        System.assertEquals(app.Id, singleApp.Id);

        List<Application__c> appList = selector.listOfselectApplicationForCIBIL(app.Id);
        System.assertEquals(1, appList.size());
        System.assertEquals(app.Id, appList[0].Id);
        Test.stopTest();
    }

    @IsTest
    static void test_selectBranchCodeByApplicationId() {
        Application__c app = createTestApplication();

        Test.startTest();
        SHF_ApplicationSelector selector = new SHF_ApplicationSelector();
        List<Application__c> results = selector.selectBranchCodeByApplicationId(new Set<Id>{app.Id});
        System.assert(!results.isEmpty(), 'Branch code query should return results');
        System.assertEquals(app.Id, results[0].Id);
        Test.stopTest();
    }

    @IsTest
    static void test_selectApplicationForInsurance() {
        Application__c app = createTestApplication();

        Test.startTest();
        SHF_ApplicationSelector selector = new SHF_ApplicationSelector();
        Application__c insApp = selector.selectApplicationForInsurance(app.Id);
        System.assertNotEquals(null, insApp, 'Insurance query should return record');
        System.assertEquals(app.Id, insApp.Id);
        Test.stopTest();
    }

    @IsTest
    static void test_getSObjectTypeAndFieldList() {
        SHF_ApplicationSelector selector = new SHF_ApplicationSelector();

        System.assertEquals(Application__c.SObjectType, selector.getSObjectType());

        List<Schema.SObjectField> fields = selector.getSObjectFieldList();
        System.assert(fields.contains(Application__c.Id));
        System.assert(fields.contains(Application__c.Name));
    }
}