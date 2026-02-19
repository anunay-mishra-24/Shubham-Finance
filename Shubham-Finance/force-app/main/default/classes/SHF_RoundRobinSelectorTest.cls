/**
* @File Name          : SHF_RoundRobinSelectorTest.cls
* @Author             : Kunal Soni
* @Created On         : 20-08-2025
* @Last Modified By   : Kunal Soni
* @Description        : Test class for SHF_RoundRobinSelector
* ================================================================================================
* Update Ver   Date           Author        Modification
* ================================================================================================
* 1.0          20-08-2025     Kunal Soni    Initial Version
*/
@isTest
private class SHF_RoundRobinSelectorTest {

    @testSetup
    static void setupTestData() {
        // Create test Users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        List<User> users = SHF_TestDataFactory.createUserList(
            2, 'RR', 'User', null, null, p.Id, true, '1111111111', '2222222222', true
        );

        // Create Branch
        Branch_Master__c branch = SHF_TestDataFactory.createBranchMaster('Mumbai', 'BR123', true);

        // Create active Round Robin records for LOB = "CRM"
        SHF_TestDataFactory.createRoundRobinList(2, 'CRM', true, users, branch);

        // Create inactive Round Robin records (should not be fetched)
        SHF_TestDataFactory.createRoundRobinList(1, 'LOS', false, users, branch);

        // Create active Round Robin records for another LOB
        SHF_TestDataFactory.createRoundRobinList(1, 'LOS', true, users, branch);
    }

    @isTest
    static void testSelectRoundRobinRecords() {
        Test.startTest();
        List<Round_Robin__c> results = new SHF_RoundRobinSelector().selectRoundRobinRecords();
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return active Round Robin records');
        System.assertNotEquals(null, results[0].User__r.Name, 
            'User lookup should be populated');
        System.assertNotEquals(null, results[0].Branch_Name__r.Name, 
            'Branch lookup should be populated');
    }

    @isTest
    static void testSelectRoundRobinByName_MatchingLOB() {
        Test.startTest();
        List<Round_Robin__c> results = new SHF_RoundRobinSelector().selectRoundRobinByName('CRM');
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 active CRM records');
        System.assertEquals('CRM', results[0].LOB__c, 'LOB should match filter');
    }

}