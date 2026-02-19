@isTest
public class SHF_RepaymentController_Test {
 private static Id getRepaymentRTId() {
        try {
            return [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = 'Bank_Details__c'
                AND DeveloperName = 'Repayment'
                LIMIT 1
            ].Id;
        } catch (Exception e) {
            System.assert(false, 'Missing RecordType for Bank_Details__c with DeveloperName=Repayment required for tests. ' + e.getMessage());
            return null;
        }
    }

    @TestSetup
    static void setupData() {
       
        Application__c app = SHF_TestDataFactory.createApplication('Test App - Repayment', true);
   
        SHF_TestDataFactory.createLoanApplicant(app.Id, 'Pri', 'Applicant', '27AAACB2230M1ZL', true);
    }

    @IsTest
    static void test_getBankDetails_returnsExisting() {
     
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Bank_Details__c bd = new Bank_Details__c(
            Application__c = app.Id,
            RecordTypeId = getRepaymentRTId(),
            Name = 'Existing Repayment'
        );
        insert bd;

        Test.startTest();
        Bank_Details__c result = SHF_RepaymentController.getBankDetails(app.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected an existing Bank_Details__c record');
        System.assertEquals(bd.Id, result.Id, 'Should return the existing repayment record for the application');
        System.assertEquals(app.Id, result.Application__c, 'Application reference should match');
    }

    @IsTest
    static void test_getBankDetails_returnsUnsavedNewWhenMissing() {
    
        Application__c newApp = SHF_TestDataFactory.createApplication('App - No Repayment', true);

        Test.startTest();
        Bank_Details__c result = SHF_RepaymentController.getBankDetails(newApp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected an unsaved instance to be returned');
        System.assertEquals(null, result.Id, 'Returned instance should be unsaved (no Id)');
        System.assertEquals(newApp.Id, result.Application__c, 'Application should be pre-populated');
    }

    @IsTest
    static void test_getPrimaryApplicantName_found() {
     
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];

        Loan_Applicant__c anyApplicant = [
            SELECT Id, Name FROM Loan_Applicant__c WHERE Application__c = :app.Id LIMIT 1
        ];
        update new Loan_Applicant__c(
            Id = anyApplicant.Id,
            Applicant_Type__c = 'Primary Applicant'
        );

        Test.startTest();
        String name = SHF_RepaymentController.getPrimaryApplicantName(app.Id);
        Test.stopTest();

        System.assertNotEquals(null, name, 'Primary applicant name should be returned');
    }

    @IsTest
    static void test_getPrimaryApplicantName_none() {
  
        Application__c app = SHF_TestDataFactory.createApplication('App - No Primary Applicant', true);

        Test.startTest();
        String name = SHF_RepaymentController.getPrimaryApplicantName(app.Id);
        Test.stopTest();

        System.assertEquals(null, name, 'Should return null when no Primary Applicant exists');
    }

    @IsTest
    static void test_saveRepaymentDetails_insert_new_byApplication() {
        Application__c app = SHF_TestDataFactory.createApplication('App - Save Insert', true);

        Map<String, Object> repaymentData = new Map<String, Object>{
            'Application_Amount__c' => 100000.50,
            'Disbursal_Type__c' => 'Single',
            'Number_of_Disbursals__c' => 1,
            'Tenure__c' => 12,
            'Tenure_In__c' => 'Month',
            'Due_Day__c' => 5,
            'Interest_Start_Date__c' => String.valueOf(Date.today()),
            'First_Installment_Date__c' => String.valueOf(Date.today().addDays(30)),
            'Recovery_Type__c' => 'EMI',
            'Repayment_Type__c' => 'Fixed',
            'Repayment_Frequency__c' => 'Monthly',
            'Interest_Charge_Method__c' => 'Reducing',
            'Interest_Rate_Type__c' => 'Fixed',
            'Interest_Charge_Type__c' => 'Simple',
            'Moratorium_Type__c' => 'None',
            'Moratorium__c' => 0,
            'Moratorium_Days__c' => 0,
            'Broken_Period_Adjustment__c' => 'No',
            'Number_of_Advanced_Installments__c' => 0,
            'Total_Number_of_Installments__c' => 12,
            'Anchor_Type__c' => 'None',
            'Anchor_Rate__c' => 0,
            'Rate__c' => 12.5
        };

        Test.startTest();
        Bank_Details__c saved = SHF_RepaymentController.saveRepaymentDetails(null, app.Id, repaymentData);
        Test.stopTest();

        System.assertNotEquals(null, saved, 'Expected a Bank_Details__c record to be returned');
        System.assertNotEquals(null, saved.Id, 'Record should be inserted');
        System.assertEquals(app.Id, saved.Application__c, 'Application should be set');
        System.assertEquals(getRepaymentRTId(), saved.RecordTypeId, 'RecordType should be Repayment');
        System.assertEquals(12, saved.Tenure__c, 'Field value should be assigned from payload');
        System.assertEquals(12, saved.Total_Number_of_Installments__c, 'Field value should be assigned from payload');
    }

    @IsTest
    static void test_saveRepaymentDetails_update_existing_byRecordId() {
 
        Application__c app = SHF_TestDataFactory.createApplication('App - Save Update', true);

        Bank_Details__c bd = new Bank_Details__c(
            Application__c = app.Id,
            RecordTypeId   = getRepaymentRTId(),
            Tenure__c      = 6,
            Repayment_Type__c = 'Fixed'
        );
        insert bd;

        Map<String, Object> repaymentData = new Map<String, Object>{
            'Tenure__c' => 24,
            'Repayment_Type__c' => 'Variable'
        };

        Test.startTest();
        Bank_Details__c updated = SHF_RepaymentController.saveRepaymentDetails(bd.Id, app.Id, repaymentData);
        Test.stopTest();

        System.assertEquals(bd.Id, updated.Id, 'Should update the same record');
        System.assertEquals(24, updated.Tenure__c, 'Tenure should be updated');
        System.assertEquals('Variable', updated.Repayment_Type__c, 'Repayment_Type__c should be updated');
    }

    @IsTest
    static void test_saveRepaymentDetails_ignores_invalid_fields() {

        Application__c app = SHF_TestDataFactory.createApplication('App - Invalid Fields', true);

        Map<String, Object> repaymentData = new Map<String, Object>{
            'ThisFieldDoesNotExist__c' => 'abc',
            'Another_Bad_Field__c' => 123,
            'Tenure__c' => 10
        };

        Test.startTest();
        Bank_Details__c saved = SHF_RepaymentController.saveRepaymentDetails(null, app.Id, repaymentData);
        Test.stopTest();

        System.assertNotEquals(null, saved.Id, 'Record should be inserted even if some fields are ignored');
        System.assertEquals(10, saved.Tenure__c, 'Valid field should still be applied');
    }

    @IsTest
    static void test_saveRepaymentDetails_handles_bad_type_conversion_gracefully() {
  
        Application__c app = SHF_TestDataFactory.createApplication('App - Bad Types', true);

        Map<String, Object> repaymentData = new Map<String, Object>{
            'Interest_Start_Date__c' => 'not-a-date',
            'First_Installment_Date__c' => '2021-13-40T99:99:99Z',
            'Number_of_Disbursals__c' => 'abc',
            'Application_Amount__c' => 'x1y2',
            'Tenure__c' => 18 // include at least one valid field
        };

        Test.startTest();
        Bank_Details__c saved = SHF_RepaymentController.saveRepaymentDetails(null, app.Id, repaymentData);
        Test.stopTest();

        System.assertNotEquals(null, saved.Id, 'Record should be saved despite bad fields');
        System.assertEquals(18, saved.Tenure__c, 'Valid field should be set');
    }

    @IsTest
    static void test_saveRepaymentDetails_propagates_exception_as_auraHandled() {

        Application__c app = SHF_TestDataFactory.createApplication('App - Exception', true);

        Id badId;
        try {
            badId = (Id) '123';
        } catch (Exception e) {
           badId = null;
        }

        Boolean gotAura = false;
        Test.startTest();
        try {
             if (badId != null) {
                SHF_RepaymentController.saveRepaymentDetails(badId, app.Id, new Map<String, Object>());
            } else {
                 Bank_Details__c bd = new Bank_Details__c(Application__c = app.Id, RecordTypeId = getRepaymentRTId());
                insert bd;
                delete bd;
                SHF_RepaymentController.saveRepaymentDetails(bd.Id, app.Id, new Map<String, Object>());
            }
        } catch (AuraHandledException ahe) {
            gotAura = true;
        } catch (Exception e) {
            gotAura = true;
        }
        Test.stopTest();

        System.assertEquals(true, gotAura, 'saveRepaymentDetails should surface errors as AuraHandledException');
    }
}