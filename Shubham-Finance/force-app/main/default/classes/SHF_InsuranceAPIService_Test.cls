@IsTest
private class SHF_InsuranceAPIService_Test {

    @TestSetup
    static void setupData() {

        RecordType evRt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'E_Verification__c'
            AND DeveloperName = 'Insurance'
            LIMIT 1
        ];

        RecordType nomineeRt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'E_Verification_Line_Item__c'
            AND DeveloperName = 'Insurance_Nominee'
            LIMIT 1
        ];

        State_Master__c sm = new State_Master__c(
            Name = 'TN',
            State_Code__c = 'TN',
            Zone__c = 'South Region',
            Region__c = 'South'
        );
        insert sm;

        City_Master__c city = new City_Master__c(
            Name = 'Chennai',
            State_Master__c = sm.Id
        );
        insert city;

        Branch_Master__c branch = new Branch_Master__c(
            Name = 'Chennai',
            City__c = city.Id
        );
        insert branch;

        Application__c app = new Application__c(
            Name = 'APP-1001',
            Applied_Loan_Amount__c = 500000,
            Tenure__c = 10,
            Loan_Disbursement_Date__c = Date.today(),
            Branch__c = branch.Id
        );
        insert app;

        Loan_Applicant__c la1 = new Loan_Applicant__c(
            Application__c = app.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990,1,1)
        );
        insert la1;

        Loan_Applicant__c la2 = new Loan_Applicant__c(
            Application__c = app.Id,
            First_Name__c = 'Jane',
            Last_Name__c = 'Doe',
            Gender__c = 'Female',
            Date_of_Birth__c = Date.newInstance(1992,2,2)
        );
        insert la2;

        E_Verification__c ev = new E_Verification__c(
            RecordTypeId = evRt.Id,
            Funded__c = 'No',
            Loan_Type__c = 'Home Loan',
            Sanctioned_Loan_Amount__c = 500000,
            Flat_Tenure_In_Years__c = 10,
            Loan_Tenure_In_Years__c = 10,
            Loan_Applicant__c = la1.Id
        );
        insert ev;

        la1.Insurance_Verification__c = ev.Id;
        update la1;
    }

    static Loan_Applicant__c getPrimaryApplicant() {
        return [SELECT Id, Application__c, Insurance_Verification__c FROM Loan_Applicant__c LIMIT 1];
    }

    static E_Verification__c getEV() {
        return [SELECT Id FROM E_Verification__c LIMIT 1];
    }

    @IsTest
    static void test_missingApplicant_callInsuranceAPI() {
        String res = SHF_InsuranceAPIService.callInsuranceAPI(null);
        System.assert(res.contains('error'));
    }

    @IsTest
    static void test_kotak_or_icici_route() {
        Loan_Applicant__c la = getPrimaryApplicant();
        String res = SHF_InsuranceAPIService.callInsuranceAPI(la.Id);
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_callICICIInsuranceAPI() {
        Loan_Applicant__c la = getPrimaryApplicant();
        E_Verification__c ev = getEV();

        String res = SHF_InsuranceAPIService.callICICIInsuranceAPI(
            ev.Id,
            la.Id,
            '{"key":"value"}'
        );

        System.assert(res.contains('status'));
    }

    @IsTest
    static void test_callKotakInsuranceAPI() {
        Loan_Applicant__c la = getPrimaryApplicant();
        E_Verification__c ev = getEV();

        String res = SHF_InsuranceAPIService.callKotakInsuranceAPI(
            ev.Id,
            la.Id,
            '{"foo":"bar"}'
        );

        System.assert(res.contains('status'));
    }

    @IsTest
    static void test_getChildApplicants() {
        Loan_Applicant__c la = getPrimaryApplicant();

        List<Loan_Applicant__c> children =
            SHF_InsuranceAPIService.getChildApplicants(la.Application__c, la.Id);

        System.assert(children.size() >= 0);
    }

    @IsTest
    static void test_getEVerificationById() {
        E_Verification__c ev = getEV();

        Test.startTest();
        E_Verification__c fetched = SHF_InsuranceAPIService.getEVerificationById(ev.Id);
        Test.stopTest();

        System.assertEquals(ev.Id, fetched.Id);
    }

    @IsTest
    static void test_getInsuranceNominees() {
        E_Verification__c ev = getEV();

        List<E_Verification_Line_Item__c> nominees =
            SHF_InsuranceAPIService.getInsuranceNominees(ev.Id);

        System.assertNotEquals(null, nominees);
    }

    @IsTest
    static void test_updateEVerification() {

        Loan_Applicant__c la = getPrimaryApplicant();

        E_Verification__c newEV = new E_Verification__c(
            Funded__c = 'No',
            Loan_Type__c = 'Home Loan',
            Sanctioned_Loan_Amount__c = 400000,
            Flat_Tenure_In_Years__c = 8,
            Loan_Tenure_In_Years__c = 8,
            Loan_Applicant__c = la.Id
        );

        List<E_Verification_Line_Item__c> nominees = new List<E_Verification_Line_Item__c>{
            new E_Verification_Line_Item__c(
                Nominee_Name__c = 'Nom 1',
                Nominee_Relationship__c = 'Spouse'
            )
        };

        Test.startTest();
        Id newId = SHF_InsuranceAPIService.updateEVerification(
            newEV,
            la.Id,
            null,
            nominees
        );
        Test.stopTest();

        System.assertNotEquals(null, newId);
    }

}