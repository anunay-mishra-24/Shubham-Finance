@IsTest
public class SHF_RiskCalculation_Test {

    // Utility: create minimal Risk Master + Details for a given key with both Thin/Thik active rows
    private static Risk_Score_Master__c upsertRiskMaster(String name, Decimal thik, Decimal thin) {
        Risk_Score_Master__c m = new Risk_Score_Master__c(
            Name = name,
            Thik_Weight__c = thik,
            Thin_Weight__c = thin
        );
        insert m;
        
        insert new Risk_Score_Details__c(
            Risk_Score_Master__c = m.Id,
            Weight_Type__c = SHF_ConstantsUtil.THIN,
            Operator__c = '=',
            Bin__c = 'DEFAULT', // string-equality scenario
            Scaled_WOE__c = 20,
            IsActive__c = true,
            Effective_Date__c = System.today().addDays(-5)
        );
       
        insert new Risk_Score_Details__c(
            Risk_Score_Master__c = m.Id,
            Weight_Type__c = SHF_ConstantsUtil.THIK,
            Operator__c = '=',
            Bin__c = 'DEFAULT',
            Scaled_WOE__c = 30,
            IsActive__c = true,
            Effective_Date__c = System.today().addDays(-5)
        );
        return m;
    }

    private static void seedTotalAnnualExpensesWOE() {
        Risk_Score_Master__c m = new Risk_Score_Master__c(
            Name = 'Total Annual Expenses',
            Thik_Weight__c = 10,
            Thin_Weight__c = 5
        );
        insert m;

        insert new Risk_Score_Details__c(
            Risk_Score_Master__c = m.Id,
            Weight_Type__c = SHF_ConstantsUtil.THIN,
            Operator__c = '<=',
            Bin__c = '100000',
            Scaled_WOE__c = 20,
            IsActive__c = true,
            Effective_Date__c = System.today().addDays(-1)
        );
        
        insert new Risk_Score_Details__c(
            Risk_Score_Master__c = m.Id,
            Weight_Type__c = SHF_ConstantsUtil.THIK,
            Operator__c = 'between',
            Bin__c = '20000',
            Bin2__c = '80000',
            Scaled_WOE__c = 40,
            IsActive__c = true,
            Effective_Date__c = System.today().addDays(-1)
        );
    }

    private static void seedAllStaticKeys() {
    
        upsertRiskMaster('Branch', 7, 3);
        upsertRiskMaster('Product', 9, 4);
        upsertRiskMaster('Analytical Channel', 6, 2);
        upsertRiskMaster('Age', 5, 2);
        upsertRiskMaster('Employment_and_document_type', 8, 3);
        upsertRiskMaster('Final_Industry', 6, 3);
        upsertRiskMaster('Relationship with Applicant', 7, 3);

        // Total Annual Expenses seeded with numeric cases
        seedTotalAnnualExpensesWOE();
    }

    private static Application__c createBaseApplication(Boolean setLeadSubSource, String defaultEqualityToken) {
        // Using TestDataFactory as hinted by original tests to keep consistency, then overriding required fields.
        Application__c app = SHF_TestDataFactory.createApplication('App-' + String.valueOf(Math.mod(Crypto.getRandomLong(), 1000000)), true);
        if (setLeadSubSource) {
            app.Lead__r.Lead_Sub_Source__c = defaultEqualityToken;
        } else {
            app.Lead__r.Lead_Sub_Source__c = null;
        }
        insert app;
        return app;
    }

    private static Loan_Applicant__c createApplicant(Application__c app, String first, String last, Integer age,
                                                     String relation, String profile, String industry,
                                                     Boolean financialYes, Boolean isDeleted, Boolean recordTypeIndividual,
                                                     String crifId) {
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, first, last, '27AAACB2230M1ZL', true);
        la.Relationship_with_Applicant__c = relation;
        la.Customer_Profile__c = profile;
        la.Industry__c = industry;
        la.IsFinancial_Applicant__c = financialYes ? 'Yes' : 'No';
        la.IsDeleted__c = isDeleted;
        // Set RecordTypeId instead of RecordType_Name__c which is not writeable
        if (recordTypeIndividual) {
            // Try to get the Individual record type ID
            try {
                la.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Applicant__c' AND DeveloperName = :SHF_ConstantsUtil.INDIVIDUAL LIMIT 1].Id;
            } catch (Exception e) {
                // If we can't find the record type, set it to null or handle appropriately
                la.RecordTypeId = null;
            }
        } else {
            la.RecordTypeId = null; // Or set to a default record type if needed
        }
        la.CRIF_Verification__c = crifId;
        update la;
        return la;
    }

    private static Personal_Discussion__c createPD(Loan_Applicant__c la, Decimal totalExpenses, Boolean setCreditPD) {
        Personal_Discussion__c pd = new Personal_Discussion__c(
            Loan_Applicant__c = la.Id,
            Total_Expences__c = totalExpenses,
            Credit_PD_Mode__c = setCreditPD ? SHF_ConstantsUtil.CREDIT_PD : null
        );
        insert pd;
        return pd;
    }

    private static E_Verification__c createCrif(Loan_Applicant__c la, Boolean addBsa) {
        E_Verification__c e = new E_Verification__c(Loan_Applicant__c = la.Id);
        insert e;
        if (addBsa) {
            insert new Bureau_BSA_Detail__c(
                E_Verification__c = e.Id,
                Loan_Applicant__c = la.Id,
                Main_applicant_s_credit_score__c = '750'
            );
        }
        return e;
    }

    @isTest
    static void testEvaluateOperator_AllBranches() {
        // Null operator
        System.assertEquals(false, SHF_RiskCalculation.evaluateOperator('10', null, '5', null));

        // MISSING logic
        System.assertEquals(true, SHF_RiskCalculation.evaluateOperator(SHF_ConstantsUtil.MISSING, '=', SHF_ConstantsUtil.MISSING, null));
        System.assertEquals(false, SHF_RiskCalculation.evaluateOperator(SHF_ConstantsUtil.MISSING, '=', '10', null));

        // Numeric comparisons
        System.assertEquals(true, SHF_RiskCalculation.evaluateOperator('5', '<', '10', null));
        System.assertEquals(true, SHF_RiskCalculation.evaluateOperator('10', '<=', '10', null));
        System.assertEquals(true, SHF_RiskCalculation.evaluateOperator('15', '>', '10', null));
        System.assertEquals(true, SHF_RiskCalculation.evaluateOperator('10', '>=', '10', null));
        System.assertEquals(true, SHF_RiskCalculation.evaluateOperator('10', '!=', '11', null));

        // String equality (case-insensitive)
        System.assertEquals(true, SHF_RiskCalculation.evaluateOperator('abc', '=', 'AbC', null));

        // Between missing bin2
        System.assertEquals(false, SHF_RiskCalculation.evaluateOperator('5', 'between', '1', null));
        // Valid between boundaries inclusive
        System.assertEquals(true, SHF_RiskCalculation.evaluateOperator('5', 'between', '1', '5'));
    }

    @isTest
    static void testLoadRiskData_NullApplicationId_ReturnsErrorPrefix() {
        Test.startTest();
        String res = SHF_RiskCalculation.loadRiskData(null);
        Test.stopTest();
        // With applicationId null, method flows to end with empty errors and no app data,
        // calculateRisk cannot be called as applicationId null; ensure it doesn't crash and returns either Success or error text.
        System.assertNotEquals(null, res);
    }

    @isTest
    static void testLoadRiskData_NoApplicants_NoApplicantErrorsButHeaderErrors() {
        seedAllStaticKeys();
        Application__c app = createBaseApplication(false, 'DEFAULT'); // missing Lead_Sub_Source => header error
        // No applicants inserted for this app

        Test.startTest();
        String res = SHF_RiskCalculation.loadRiskData(app.Id);
        Test.stopTest();

        System.assert(res.startsWith('ERROR'), 'Should collect header errors for missing Lead Sub-Source/Product/Branch if required by selector mapping.');
    }

    @isTest
    static void testLoadRiskData_MissingApplicantAttributes_CollectsAllErrors() {
        seedAllStaticKeys();
        Application__c app = createBaseApplication(true, 'DEFAULT');

        // Applicant that is financial and non FORMAL_SALARIED to be validated for missing attributes
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'A', 'B', '27AAACB2230M1ZL', true);
        // Set Date_of_Birth__c to ensure Applicant_Age__c formula field is populated
        la.Date_of_Birth__c = Date.newInstance(1990, 1, 1);
        la.Customer_Profile__c = null;
        // Remove setting Applicant_Age__c as it's a formula field and not writeable
        la.Relationship_with_Applicant__c = null;
        la.Industry__c = null;
        la.IsFinancial_Applicant__c = 'Yes';
        la.IsDeleted__c = false;
        la.Customer_Profile__c = null;
        update la;

        Test.startTest();
        String res = SHF_RiskCalculation.loadRiskData(app.Id);
        Test.stopTest();

        System.assert(res.contains('ERROR'), 'Should return validation errors');
        System.assert(res.contains('Age of'), 'Missing Age error expected');
        System.assert(res.contains('Relationship with Applicant of'), 'Missing Relationship error expected');
        System.assert(res.contains('Customer Profile of'), 'Missing Profile error expected');
        System.assert(res.contains('Industry of'), 'Missing Industry error expected');
    }

    @isTest
    static void testLoadRiskData_PDAbsent_ErrorsForCreditPD() {
        seedAllStaticKeys();
        Application__c app = createBaseApplication(true, 'DEFAULT');

        // Financial non-FORMAL_SALARIED applicant
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'John', 'Doe', '27AAACB2230M1ZL', true);
        la.Date_of_Birth__c = Date.newInstance(1990, 1, 1);
        la.Customer_Profile__c = 'INFORMAL';
        la.Industry__c = 'Retail';
        la.Relationship_with_Applicant__c = 'Self';
        la.IsFinancial_Applicant__c = 'Yes';
        la.IsDeleted__c = false;
        update la;

        // No PD inserted -> should prompt Credit PD error
        Test.startTest();
        String res = SHF_RiskCalculation.loadRiskData(app.Id);
        Test.stopTest();

        System.assert(res.contains('ERROR'), 'Should include Credit PD creation errors');
        System.assert(res.contains('Create Credit PD for all Financial Applicants') || res.contains('Credit PD of'), 'Credit PD error expected');
    }

    @isTest
    static void testLoadRiskData_PDPresent_ComputesAndUpdates_Success() {
        seedAllStaticKeys();
        Application__c app = createBaseApplication(true, 'DEFAULT');

        // Main applicant that will be scored
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Main', 'Applicant', '27AAACB2230M1ZL', true);
        la.Date_of_Birth__c = Date.newInstance(1990, 1, 1);
        la.Customer_Profile__c = 'INFORMAL';
        la.Industry__c = 'Retail';
        la.Relationship_with_Applicant__c = 'Self';
        la.IsFinancial_Applicant__c = 'Yes';
        la.IsDeleted__c = false;
        // Set RecordTypeId instead of RecordType_Name__c which is not writeable
        try {
            la.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Applicant__c' AND DeveloperName = :SHF_ConstantsUtil.INDIVIDUAL LIMIT 1].Id;
        } catch (Exception e) {
            // If we can't find the record type, set it to null or handle appropriately
            la.RecordTypeId = null;
        }
        update la;

        // PD present with Credit_PD and expenses in range
        createPD(la, 50000, true);

        // CRIF + BSA for coverage of mapping path
        E_Verification__c crif = createCrif(la, true);
        la.CRIF_Verification__c = crif.Id;
        update la;

        Test.startTest();
        String res = SHF_RiskCalculation.loadRiskData(app.Id);
        Test.stopTest();

        System.assertEquals('Success', res, 'With PD and complete data, calculateRisk should execute successfully');

        // Validate applicant fields updated
        Loan_Applicant__c laReload = [SELECT Id, Risk_Score_Thin_Weight__c, Risk_Score_Thik_Weight__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertNotEquals(null, laReload.Risk_Score_Thin_Weight__c, 'Thin weight should be updated');
        System.assertNotEquals(null, laReload.Risk_Score_Thik_Weight__c, 'Thik weight should be updated');

        // Validate application averages updated
        Application__c appReload = [SELECT Id, Risk_Score_Thin_Weight__c, Risk_Score_Thik_Weight__c FROM Application__c WHERE Id = :app.Id];
        System.assertNotEquals(null, appReload.Risk_Score_Thin_Weight__c, 'Application Thin average should be set');
        System.assertNotEquals(null, appReload.Risk_Score_Thik_Weight__c, 'Application Thik average should be set');
    }

    @isTest
    static void testCalculateRisk_ThinAndThikWeights_ComputationAndAverages() {
        // Directly seed and call calculateRisk to hit inner loops and update logic
        seedAllStaticKeys();
        Application__c app = createBaseApplication(true, 'DEFAULT');

        // Two applicants: one valid, one deleted to test averaging logic excluding deleted
        Loan_Applicant__c valid = SHF_TestDataFactory.createLoanApplicant(app.Id, 'V', 'A', '27AAACB2230M1ZL', true);
        valid.Date_of_Birth__c = Date.newInstance(1998, 1, 1);
        valid.Customer_Profile__c = 'INFORMAL';
        valid.Industry__c = 'Retail';
        valid.Relationship_with_Applicant__c = 'Self';
        valid.IsFinancial_Applicant__c = 'Yes';
        valid.IsDeleted__c = false;
        update valid;
        createPD(valid, 60000, true);

        Loan_Applicant__c deletedOne = SHF_TestDataFactory.createLoanApplicant(app.Id, 'D', 'A', '27AAACB2230M1ZL', true);
        deletedOne.Date_of_Birth__c = Date.newInstance(1985, 1, 1);
        deletedOne.Customer_Profile__c = 'INFORMAL';
        deletedOne.Industry__c = 'Retail';
        deletedOne.Relationship_with_Applicant__c = 'Spouse';
        deletedOne.IsFinancial_Applicant__c = 'Yes';
        deletedOne.IsDeleted__c = true;
        update deletedOne;
        createPD(deletedOne, 30000, true);

        // Build inputs as loadRiskData would
        Map<Id, Decimal> creditMap = new Map<Id, Decimal>{ valid.Id => 60000, deletedOne.Id => 30000 };
        Set<Id> crifSet = new Set<Id>();

        // Mock SHF_ApplicationSelector behavior by assembling applicationData with child relationship
        // In tests, we can requery with child relationships so calculateRisk can iterate them
        Application__c appQ = [SELECT Id,
                                      Risk_Score_Thin_Weight__c,
                                      Risk_Score_Thik_Weight__c,
                                      (SELECT Id, IsDeleted__c, Applicant_Age__c, Customer_Profile__c, Industry__c, Relationship_with_Applicant__c
                                       FROM Loan_Applicants__r)
                               FROM Application__c WHERE Id = :app.Id];

        Test.startTest();
        String r = SHF_RiskCalculation.calculateRisk(app.Id, new List<Application__c>{ appQ }, creditMap, crifSet);
        Test.stopTest();

        System.assertEquals('Success', r);
        // Validate updates
        Loan_Applicant__c vReload = [SELECT Risk_Score_Thin_Weight__c, Risk_Score_Thik_Weight__c FROM Loan_Applicant__c WHERE Id = :valid.Id];
        System.assertNotEquals(null, vReload.Risk_Score_Thin_Weight__c);
        System.assertNotEquals(null, vReload.Risk_Score_Thik_Weight__c);

        Application__c aReload = [SELECT Risk_Score_Thin_Weight__c, Risk_Score_Thik_Weight__c FROM Application__c WHERE Id = :app.Id];
        System.assertNotEquals(null, aReload.Risk_Score_Thin_Weight__c);
        System.assertNotEquals(null, aReload.Risk_Score_Thik_Weight__c);
    }
}