@IsTest
public class SHF_CaseRoundRobinSubTypeAssiRule_Test {

    /* ---------------- Test Data Setup ---------------- */
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
        List<Round_Robin__c> rrUsers = SHF_TestDataFactory.createRoundRobinUsers(2, 'CRM SUB-TYPE');
        
        List<SHF_CaseRoundRobinSubTypeAssignmentRule.CaseWrapper> wrappers = new List<SHF_CaseRoundRobinSubTypeAssignmentRule.CaseWrapper>();
        for (Case c : cases) {
            SHF_CaseRoundRobinSubTypeAssignmentRule.CaseWrapper w = new SHF_CaseRoundRobinSubTypeAssignmentRule.CaseWrapper();
            w.caseId = c.Id;
            wrappers.add(w);
        }
        
        Test.startTest();
        SHF_CaseRoundRobinSubTypeAssignmentRule.caseOwnerAssignment(wrappers);
        Test.stopTest();
        
        List<Case> updatedCases = [SELECT Id, OwnerId FROM Case WHERE Id IN :cases];
        System.assertEquals(3, updatedCases.size(), 'All cases should be processed');
        Set<Id> ownerIds = new Set<Id>();
        for (Case c : updatedCases) {
            System.assertNotEquals(null, c.OwnerId, 'Owner must be assigned');
            ownerIds.add(c.OwnerId);
        }
        
    }
}