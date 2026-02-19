/**
* @File Name          : SHF_CaseRoundRobinAssignmentRuleTest.cls
* @Author             : Kunal Soni
* @Created On         : 20-08-2025
* @Last Modified By   : Kunal Soni
* @Description        : Test class for SHF_CaseRoundRobinAssignmentRule
* ================================================================================================
* Update Ver   Date           Author        Modification
* ================================================================================================
* 1.0          20-08-2025     Kunal Soni    Initial Version
*/

@isTest
private class SHF_CaseRoundRobinAssignmentRuleTest {
    
    // Prepare test data for all test methods
    @TestSetup
    static void setupTestData() {
        SHF_TestDataFactory.createCaseList(3,
            'Test Case',              
            SHF_ConstantsUtil.NEW_STATUS, 
            '9999999999',
            'Test Customer',       
            'test@example.com',       
            'Phone',                  
            'Enquiry',                
            'Change in base rate',    
            null, null, null, null, null, null, null, 
            true                      
        );
    }
    
    @isTest
    static void testRoundRobinAssignment_Positive() {

        List<Case> cases = [SELECT Id FROM Case LIMIT 3];
        List<Round_Robin__c> rrUsers = SHF_TestDataFactory.createRoundRobinUsers(2, 'CRM');
        
        List<SHF_CaseRoundRobinAssignmentRule.CaseWrapper> wrappers = new List<SHF_CaseRoundRobinAssignmentRule.CaseWrapper>();
        for (Case c : cases) {
            SHF_CaseRoundRobinAssignmentRule.CaseWrapper w = new SHF_CaseRoundRobinAssignmentRule.CaseWrapper();
            w.caseId = c.Id;
            wrappers.add(w);
        }
        
        Test.startTest();
        SHF_CaseRoundRobinAssignmentRule.caseOwnerAssignment(wrappers);
        Test.stopTest();
        
        List<Case> updatedCases = [SELECT Id, OwnerId FROM Case WHERE Id IN :cases];
        System.assertEquals(3, updatedCases.size(), 'All cases should be processed');
        Set<Id> ownerIds = new Set<Id>();
        for (Case c : updatedCases) {
            System.assertNotEquals(null, c.OwnerId, 'Owner must be assigned');
            ownerIds.add(c.OwnerId);
        }
        System.assert(ownerIds.contains(rrUsers[0].User__c), 'Round robin user 1 should own cases');
        System.assert(ownerIds.contains(rrUsers[1].User__c), 'Round robin user 2 should own cases');
    }
    
}