@IsTest
private class SHF_addressControllerTest {

    private class AddressesSelector {
        @TestVisible
        List<Address__c> allAddressByApplicantIds(Set<Id> applicantIds) {
            return [SELECT Id, Loan_Applicant__c FROM Address__c WHERE Loan_Applicant__c IN :applicantIds];
        }
        @TestVisible
        List<Address__c> selectByIdsApplicantName(Set<Id> addrIds) {
            return [SELECT Id,
                           Loan_Applicant__c,
                           Loan_Applicant__r.Application__c,
                           Loan_Applicant__r.Application__r.Branch__c,
                           Address_Location__Latitude__s,
                           Address_Location__Longitude__s,
                           Distance_From_Branch__c,
                           OGL__c,
                           ODV__c
                      FROM Address__c
                     WHERE Id IN :addrIds];
        }
    }

    public class SHF_BranchSelector {
        @TestVisible
        List<Branch_Master__c> getBranchById(Set<Id> ids) {
            return [SELECT Id, Branch_Location__Latitude__s, Branch_Location__Longitude__s
                      FROM Branch_Master__c
                     WHERE Id IN :ids];
        }
    }

    public class SHF_pincodeSelector {
        @TestVisible
        List<Pincode_Master__c> selectByIds(Set<Id> ids) {
            return [SELECT Id, Name FROM Pincode_Master__c WHERE Id IN :ids];
        }
    }

    @TestSetup
    static void setupData() {

        Application__c app = SHF_TestDataFactory.createApplication('App - Address Ctrl', true);
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'John', 'Doe', '27AAACB2230M1ZL', true);

        Branch_Master__c branch = SHF_TestDataFactory.createBranchMaster('Delhi', 'BR123', true);
        app = [SELECT Id, Branch__c FROM Application__c WHERE Id = :app.Id LIMIT 1];
        app.Branch__c = branch.Id;
        update app;

        SHF_TestDataFactory.createAddress(la.Id, 'Line 1', 'Landmark', 'Delhi', '101', true);
    }

    private static Loan_Applicant__c getApplicant() {
        return [SELECT Id, Application__c FROM Loan_Applicant__c LIMIT 1];
    }
    private static Application__c getApplication() {
        return [SELECT Id, Branch__c FROM Application__c LIMIT 1];
    }
    private static Address__c getAnyAddress() {
        return [SELECT Id, Loan_Applicant__c,
                       Loan_Applicant__r.Application__c,
                       Loan_Applicant__r.Application__r.Branch__c,
                       Address_Location__Latitude__s, Address_Location__Longitude__s,
                       Distance_From_Branch__c, OGL__c, ODV__c
                  FROM Address__c LIMIT 1];
    }

    @IsTest static void test_getAddressData_success() {
        Address__c addr = getAnyAddress();

        Test.startTest();
        Address__c got = SHF_addressController.getAddressData(addr.Id);
        Test.stopTest();

        System.assertNotEquals(null, got, 'Should return a record');
        System.assertEquals(addr.Id, got.Id, 'Should return same id');
    }

    @IsTest static void test_getPinCodeDetails_guardAndSuccess() {

        Pincode_Master__c blankRes = SHF_addressController.getPinCodeDetails(null);
        System.assertEquals(null, blankRes.Id, 'Blank id should return new instance');

        Pincode_Master__c pm = new Pincode_Master__c(Name = '110001');
        insert pm;

        Test.startTest();
        Pincode_Master__c fetched = SHF_addressController.getPinCodeDetails(pm.Id);
        Test.stopTest();

        System.assertEquals(pm.Id, fetched.Id, 'Selector should return the same pin code record');
    }


    @IsTest static void test_getexistingAddresses_recordsExist() {
        Loan_Applicant__c la = getApplicant();

        List<Address__c> addrs = [SELECT Id FROM Address__c WHERE Loan_Applicant__c = :la.Id];
        System.assert(addrs.size() > 0, 'Expected at least one address from @TestSetup');

        Test.startTest();
        List<Address__c> res = SHF_addressController.getexistingAddresses(la.Id);
        Test.stopTest();

        System.assertNotEquals(0, res.size(), 'Should return existing addresses');
    }

    @IsTest static void test_getexistingAddresses_noRecords() {

        Application__c app = SHF_TestDataFactory.createApplication('No Addr App', true);
        Loan_Applicant__c la2 = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Zero', 'Addr', null, true);

        Test.startTest();
        List<Address__c> res = SHF_addressController.getexistingAddresses(la2.Id);
        Test.stopTest();

        System.assertEquals(0, res.size(), 'Should return empty list when no addresses exist');
    }


    @IsTest static void test_updateAddressLocation_withBranch_underThreshold() {

        Address__c addr = getAnyAddress();

        Application__c app = getApplication();
        Branch_Master__c branch = [SELECT Id FROM Branch_Master__c WHERE Id = :app.Branch__c LIMIT 1];

        branch.Branch_Location__Latitude__s = 0;
        branch.Branch_Location__Longitude__s = 0;
        update branch;

        Decimal lat = 0, lon = 0;

        Test.startTest();
        List<Address__c> updatedList = SHF_addressController.updateAddressLocation(addr.Id, lat, lon);
        Test.stopTest();

        System.assertEquals(1, updatedList.size(), 'Should return single element list');
        Address__c updated = [SELECT Id, Address_Location__Latitude__s, Address_Location__Longitude__s, Distance_From_Branch__c, OGL__c, ODV__c
                                FROM Address__c WHERE Id = :addr.Id];
        System.assertEquals(lat, updated.Address_Location__Latitude__s, 'Latitude updated');
        System.assertEquals(lon, updated.Address_Location__Longitude__s, 'Longitude updated');
        System.assertEquals(0, updated.Distance_From_Branch__c, 'Distance should be 0');
        System.assertEquals(false, updated.OGL__c, 'OGL should be false under threshold');
        System.assertEquals(false, updated.ODV__c, 'ODV forced to false');
    }

    @IsTest static void test_updateAddressLocation_withBranch_overThreshold() {

        Address__c addr = getAnyAddress();

        Application__c app = getApplication();
        Branch_Master__c branch = [SELECT Id FROM Branch_Master__c WHERE Id = :app.Branch__c LIMIT 1];

        branch.Branch_Location__Latitude__s = 50;
        branch.Branch_Location__Longitude__s = 50;
        update branch;

        Decimal lat = 0, lon = 0;

        Test.startTest();
        List<Address__c> updatedList = SHF_addressController.updateAddressLocation(addr.Id, lat, lon);
        Test.stopTest();

        Address__c updated = [SELECT Id, Distance_From_Branch__c, OGL__c FROM Address__c WHERE Id = :addr.Id];
        System.assertNotEquals(null, updated.Distance_From_Branch__c, 'Distance calculated');
        System.assert(updated.Distance_From_Branch__c >= 0, 'Distance non-negative');
        System.assertNotEquals(null, updated.OGL__c, 'OGL should be set by threshold logic');
    }

    @IsTest static void test_updateAddressLocation_noBranch() {
        Address__c addr = getAnyAddress();
        Application__c app = getApplication();
        app.Branch__c = null;
        update app;

        Test.startTest();
        List<Address__c> updatedList = SHF_addressController.updateAddressLocation(addr.Id, 11.11, 22.22);
        Test.stopTest();

        Address__c updated = [SELECT Address_Location__Latitude__s, Address_Location__Longitude__s, Distance_From_Branch__c, OGL__c
                                FROM Address__c WHERE Id = :addr.Id];
        System.assertEquals(11.11, updated.Address_Location__Latitude__s, 'Latitude set');
        System.assertEquals(22.22, updated.Address_Location__Longitude__s, 'Longitude set');
        System.assertNotEquals(null, updated.Distance_From_Branch__c, 'Distance computed even if branch missing');
    }

    @IsTest static void test_getPinCodeDetails_exceptionPath() {
        Pincode_Master__c pm = new Pincode_Master__c(Name = '999999');
        insert pm;
        delete pm;

        Test.startTest();
        Pincode_Master__c res = SHF_addressController.getPinCodeDetails(pm.Id);
        Test.stopTest();

        System.assertEquals(null, res.Id, 'When not found or exception, new instance without Id is returned');
    }
}