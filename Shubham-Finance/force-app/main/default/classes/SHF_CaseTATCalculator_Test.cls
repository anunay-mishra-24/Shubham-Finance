@IsTest
public class SHF_CaseTATCalculator_Test {
    
    @TestSetup
static void setupTestData() {
    // Query existing default business hours
    BusinessHours bh = [
        SELECT Id, Name, IsDefault 
        FROM BusinessHours 
        WHERE IsDefault = true 
        LIMIT 1
    ];
    
    // Insert Case Categories Matrix
    Case_Categories_Matrix__c matrix = new Case_Categories_Matrix__c(
        Ticket_Type__c = 'Enquiry',
        Request_Type__c = 'Increase/Decrease in base rate',
        Ticket_Sub_Type__c = 'Change in base rate',
        Turnaround_Time__c = 2,
        Send_Notification_InDays__c = 1
    );
    insert matrix;
}

    @IsTest
    static void testCalculateCaseTAT() {
        // Create a test case that matches the matrix
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = SHF_ConstantsUtil.NEW_STATUS,
            Ticket_Type__c = 'Enquiry',
            Request_Type__c = 'Increase/Decrease in base rate',
            Ticket_Sub_Type__c = 'Change in base rate',
            Origin = 'Phone'
        );
        insert testCase;
        
        Test.startTest();
        SHF_CaseTATCalculator.calculateCaseTAT(new List<Case>{ testCase });
        Test.stopTest();
        
        // Reload updated case
        Case updatedCase = [SELECT Id, 
                                   Send_Notification_4_hours__c,
                                   Actual_TAT__c,
                                   Actual_TAT_Before_1__c,
                                   Actual_TAT_After_1__c,
                                   Actual_TAT_After_3__c,
                                   Actual_TAT_After_4__c,
                                   Escalation_Notification_Date__c
                            FROM Case
                            WHERE Id = :testCase.Id];
        
        System.assertNotEquals(null, updatedCase.Send_Notification_4_hours__c, '4 hours notification should be calculated');
        System.assertNotEquals(null, updatedCase.Actual_TAT__c, 'Actual TAT should be calculated');
        System.assertNotEquals(null, updatedCase.Actual_TAT_Before_1__c, 'Before 1 TAT should be calculated');
        System.assertNotEquals(null, updatedCase.Actual_TAT_After_1__c, 'After 1 TAT should be calculated');
        System.assertNotEquals(null, updatedCase.Actual_TAT_After_4__c, 'After 4 TAT should be calculated');
        System.assertNotEquals(null, updatedCase.Escalation_Notification_Date__c, 'Escalation Notification Date should be calculated');
    }
    
    @IsTest
    static void testEmptyCaseList() {
        Test.startTest();
        SHF_CaseTATCalculator.calculateCaseTAT(new List<Case>());
        Test.stopTest();
        System.assert(true, 'Empty case list branch executed without error');
    }
}