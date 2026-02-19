@IsTest
private class SHF_LeadTATCalculator_Test {

    @TestSetup
    static void setupData() {
        // Create valid Branch Master using your test data factory
        Branch_Master__c branch = SHF_TestDataFactory.createBranchMaster('Delhi', '5186554', true);

        // Create valid Lead__c record with all required fields and linked branch
        Lead__c testLead = new Lead__c(
            Lead_Status__c = 'Active',
            Contact_No1__c = '9876543210',
            Loan_Product__c = 'Home Loan',            
            Requested_Loan_Amount__c = 100000,
            Sub_Product__c = 'Ready Property',               
            Branch__c = branch.Id
        );
        insert testLead;
    }

    @IsTest
    static void testCalculateEscalations() {
        Lead__c testLead = [SELECT Id, Lead_Status__c FROM Lead__c LIMIT 1];

        Test.startTest();
        SHF_LeadTATCalculator.calculateEscalations(new List<Lead__c>{ testLead });
        Test.stopTest();

        Lead__c updatedLead = [SELECT L2_Escalation__c, L3_Escalation__c, L4_Escalation__c FROM Lead__c WHERE Id = :testLead.Id];

        System.assertNotEquals(null, updatedLead.L2_Escalation__c, 'L2 Escalation should be populated');
        System.assertNotEquals(null, updatedLead.L3_Escalation__c, 'L3 Escalation should be populated');
        System.assertNotEquals(null, updatedLead.L4_Escalation__c, 'L4 Escalation should be populated');
    }
}