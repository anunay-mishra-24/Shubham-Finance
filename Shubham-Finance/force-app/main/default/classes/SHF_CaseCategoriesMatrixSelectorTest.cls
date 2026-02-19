@IsTest
private class SHF_CaseCategoriesMatrixSelectorTest {
    
    @TestSetup
    static void setupData() {
        // Create sample Case Categories Matrix records using your TestDataFactory
        SHF_TestDataFactory.createCaseCategoryMatrix(
            'Enquiry',
            'Increase/Decrease in base rate',
            'Change in base rate',
            2,   // Turnaround Time
            1,   // Send Notification Days
            true // doInsert
        );
    }
    
    @IsTest
    static void testGetSObjectFieldList() {
        SHF_CaseCategoriesMatrixSelector selector = new SHF_CaseCategoriesMatrixSelector();
        
        List<Schema.SObjectField> fields = selector.getSObjectFieldList();
        
        System.assertNotEquals(0, fields.size(), 'Expected fields to be returned');
        System.assert(fields.contains(Case_Categories_Matrix__c.Ticket_Type__c), 
                      'Expected Ticket_Type__c to be included in field list');
    }
    
    @IsTest
    static void testGetSObjectType() {
        SHF_CaseCategoriesMatrixSelector selector = new SHF_CaseCategoriesMatrixSelector();
        
        Schema.SObjectType sObjType = selector.getSObjectType();
        
        System.assertEquals(Case_Categories_Matrix__c.SObjectType, sObjType, 
                            'SObjectType should match Case_Categories_Matrix__c');
    }
    
    @IsTest
    static void testSelectByIdsWithSendNotification() {
        SHF_CaseCategoriesMatrixSelector selector = new SHF_CaseCategoriesMatrixSelector();
        
        Test.startTest();
        List<Case_Categories_Matrix__c> results = selector.selectByIdsWithSendNotification();
        Test.stopTest();
        
        System.assert(!results.isEmpty(), 'Expected at least one Case_Categories_Matrix__c record');
        System.assertNotEquals(null, results[0].Turnaround_Time__c, 'Turnaround_Time__c should be populated');
        System.assertNotEquals(null, results[0].Send_Notification_InDays__c, 'Send_Notification_InDays__c should be populated');
    }
}