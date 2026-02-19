@IsTest
public class SHF_BusinessRuleEngine_Test {

    @IsTest
    static void testExecuteBRE_FullFlow() {

        // Create Base Data
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Branch_Master__c branch = SHF_TestDataFactory.createBranchMaster('Delhi', '0001', true);
        app.Branch__c = branch.Id;
        update app;

        Product_Master__c parentProd = new Product_Master__c(Name='Parent');
        insert parentProd;
        
        Product_Master__c childProd = SHF_TestDataFactory.createProduct(parentProd.Id,true);
        app.Product__c = parentProd.Id;
        update app;

        // Create Applicants
        Loan_Applicant__c primaryApplicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, true);

        // Create Collateral
        Collateral__c coll = SHF_TestDataFactory.createCollateral(primaryApplicant.Id,true);

        Collateral_Application__c collApp = new Collateral_Application__c(Application__c = app.Id, Collateral__c = coll.Id);
        insert collApp;

        Test.startTest();

        String result = SHF_BusinessRuleEngine.executeBRE(app.Id);

        Test.stopTest();

        System.assertEquals('Success', result);

        // Validate deviation records created
        List<Deviation_and_Sanction_Condition__c> devList = [SELECT Id FROM Deviation_and_Sanction_Condition__c WHERE Loan_Application__c = :app.Id];

        System.assert(devList.size() > 0);
    }

    @IsTest
    static void testCalculateExactAge() {

        Date dob = Date.today().addYears(-30);

        Decimal age = SHF_BusinessRuleEngine.calculateExactAge(dob);

        System.assert(age > 29);
    }

    @IsTest
    static void testIsNumber() {

        System.assertEquals(true, SHF_BusinessRuleEngine.isNumber('123'));

        System.assertEquals(false, SHF_BusinessRuleEngine.isNumber('abc'));
    }

    @IsTest
    static void testDistanceCalculation() {

        Double distance = SHF_BusinessRuleEngine.calculateDistance(Double.valueOf(12.9716),Double.valueOf(77.5946),
        Double.valueOf(13.0827),Double.valueOf(80.2707));

        System.assert(distance > 0);
    }

    @IsTest
    static void testApprovingAuthorityMapping() {

        SHF_BusinessRuleEngine bre =
            new SHF_BusinessRuleEngine();

        String result = bre.configureApprovingAuth('ACM');

        System.assertNotEquals('', result);
    }

    @IsTest
    static void testApprovingAuthorityUnmatchedReturnsEmpty() {
        SHF_BusinessRuleEngine bre = new SHF_BusinessRuleEngine();
        String result = bre.configureApprovingAuth('UNKNOWN');
        System.assertEquals('', result, 'Unmatched authority should return empty string');
    }

    @IsTest
    static void testGetChildProductRecord_MatchAndNoMatch() {
        // Parent and two child products with different profiles
        Product_Master__c parent = new Product_Master__c(Name='Parent For Child Lookup');
        insert parent;

        Product_Master__c childA = SHF_TestDataFactory.createProduct(parent.Id, true);
        childA.Customer_Profile__c = 'PROFILE_A;PROFILE_COMMON';
        update childA;

        Product_Master__c childB = SHF_TestDataFactory.createProduct(parent.Id, true);
        childB.Customer_Profile__c = 'PROFILE_B';
        update childB;

        SHF_BusinessRuleEngine bre = new SHF_BusinessRuleEngine();

        // Match
        Product_Master__c found = bre.getChildProductRecord(parent.Id, 'PROFILE_A');
        System.assertNotEquals(null, found, 'Should find matching child product');

        // No Match
        Product_Master__c notFound = bre.getChildProductRecord(parent.Id, 'PROFILE_X');
        System.assertEquals(null, notFound, 'Should return null if no child matches');

        // Null guard
        System.assertEquals(null, bre.getChildProductRecord(null, 'PROFILE_A'));
        System.assertEquals(null, bre.getChildProductRecord(parent.Id, null));
    }

    @IsTest
    static void testCreateDeviationRecord_NoMaster_NoAdd() {
        // Build engine with empty deviation master map via constructor init
        SHF_BusinessRuleEngine bre = new SHF_BusinessRuleEngine();
        // Ensure key not present to force guard path
        System.assertEquals(false, bre.deviationMasterMap.containsKey('NON_EXISTENT'));

        Integer beforeSize = bre.deviationList.size();
        bre.createDeviationRecord('someAppId', 'NON_EXISTENT', null);
        Integer afterSize = bre.deviationList.size();
        System.assertEquals(beforeSize, afterSize, 'List should not change when deviation master missing');
    }

    @IsTest
    static void testMinimumAndMaximumAgeBranches() {
        // App + product with strict age thresholds
        Application__c app = SHF_TestDataFactory.createApplication('Age App', true);
        Product_Master__c parent = new Product_Master__c(Name='Parent Age');
        insert parent;
        Product_Master__c child = SHF_TestDataFactory.createProduct(parent.Id, true);
        child.Minimum_Co_Applicant_Age__c = '21';
        child.Max_Income_contributor_Age_At_Maturity__c = 40;
        child.Maximum_Age_Non_Finacial_Borrowers_At_Ma__c = 35;
        child.Maximum_Age_Property_Owner_At_Maturity__c = 45;
        child.Minimum_Tenure_in_months__c = 120;
        child.Minimum_Loan_Amount__c = 500000;
        child.LTV__c = 70;
        child.Plot_LTV__c = 60;
        child.Policy_FOIR__c = 40;
        child.IIR__c = 1;
        child.LVR_LCER__c = 50;
        child.IAR__c = 1;
        update child;

        app.Product__c = parent.Id;
        app.Tenure__c = 24; // 2 years
        app.FOIR_DBR__c = 35;
        app.Applied_Loan_Amount__c = 400000;
        app.LTV__c = 75;
        app.IIR__c = 2;
        app.LVR__c = 60;
        app.IAR__c = 2;
        update app;

        // Branch for distances used in borrower/non-service and OGL
        Branch_Master__c branch = SHF_TestDataFactory.createBranchMaster('Mumbai', '0002', true);
        app.Branch__c = branch.Id;
        update app;

        // Primary (financial) with DOB yielding young age to trigger min-age
        Loan_Applicant__c primary = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Prim', 'Fin', null, true);
        primary.Applicant_Type__c = 'Primary Applicant';
        primary.IsFinancial_Applicant__c = 'Yes';
        primary.Date_of_Birth__c = Date.today().addYears(-22);
        primary.Customer_Profile__c = 'PROFILE_A';
        primary.Total_Income__c = 100000;
        primary.Total_Working_Experience__c = 0;
        update primary;

        // Co-applicant (non-financial) to hit min-age co-app path
        Loan_Applicant__c co = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Co', 'NonFin', null, false);
        co.Applicant_Type__c = 'Co-Applicant';
        co.IsFinancial_Applicant__c = 'No';
        update co;

        // Collateral and collateral application
        Collateral__c coll = SHF_TestDataFactory.createCollateral(primary.Id, true);
        Collateral_Application__c collApp = new Collateral_Application__c(Application__c = app.Id, Collateral__c = coll.Id);
        insert collApp;

        // Income document missing scenario to traverse incomeDocsDeviation code (document list empty)
        // Also ensures minimumTenureDeviation and minimumLoanAmountDeviation paths are evaluated

        Test.startTest();
        String res = SHF_BusinessRuleEngine.executeBRE(app.Id);
        Test.stopTest();
        System.assertEquals('Success', res);
    }

    @IsTest
    static void testMinimumCibilCrifDeviationBranches() {
        // Prepare app + product + higher income contributor with CRIF/CIBIL below threshold
        Application__c app = SHF_TestDataFactory.createApplication('Score App', true);
        Product_Master__c parent = new Product_Master__c(Name='Parent Score');
        insert parent;
        Product_Master__c child = SHF_TestDataFactory.createProduct(parent.Id, true);
        child.Crif_Score__c = '750';
        child.Crif_Cibil_Score__c = '720';
        update child;

        app.Product__c = parent.Id;
        update app;

        // Higher income contributor (financial)
        Loan_Applicant__c higher = SHF_TestDataFactory.createLoanApplicant(app.Id, 'High', 'Income', null, true);
        higher.IsFinancial_Applicant__c = 'Yes';
        higher.Customer_Profile__c = 'PROFILE_A';
        higher.Total_Income__c = 999999;
        update higher;

        // E_Verification records mocked via TestDataFactory, if factory exposes relation E_Verifications__r
        // Create CRIF and CIBIL with low scores for the applicant
        E_Verification__c crif = new E_Verification__c(Loan_Applicant__c = higher.Id, score__c = '700', RecordTypeId = SHF_ConstantsUtil.CRIF_RECORDTYPE_ID);
        E_Verification__c cibil = new E_Verification__c(Loan_Applicant__c = higher.Id, score__c = '700', RecordTypeId = SHF_ConstantsUtil.CIBIL_RECORDTYPE_ID);
        insert new List<E_Verification__c>{crif, cibil};

        Test.startTest();
        String res = SHF_BusinessRuleEngine.executeBRE(app.Id);
        Test.stopTest();
        System.assertEquals('Success', res);
    }

    @IsTest
    static void testExecuteBRE_ExceptionPathGraceful() {
        // Force an exception by calling with null Id
        Test.startTest();
        String result = SHF_BusinessRuleEngine.executeBRE(null);
        Test.stopTest();
        System.assert(result != null, 'Should return a non-null message even on exception');
    }
}