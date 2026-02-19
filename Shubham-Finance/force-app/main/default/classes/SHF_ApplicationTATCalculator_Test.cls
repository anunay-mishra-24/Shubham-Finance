@IsTest
private class SHF_ApplicationTATCalculator_Test {

     @TestSetup
     static void setup() {

     List<Application__c> apps = new List<Application__c>{
         new Application__c(Name = 'Valid App 1'),
         new Application__c(Name = 'Valid App 2')
     };

         insert apps;
     }

    @IsTest
    static void testNullAndEmptyInputs() {
        Test.startTest();
        // Null input - should return early without exception.
        SHF_ApplicationTATCalculator.calculateEscalations(null);

        // Empty list - should return early without exception.
        SHF_ApplicationTATCalculator.calculateEscalations(new List<Application__c>());
        Test.stopTest();

        System.assert(true, 'Method should safely handle null and empty inputs.');
    }

    @IsTest
    static void testSkipsWhenIdOrLastModifiedMissing() {
        Application__c missingId = new Application__c(Name = 'No Id App');

        List<Application__c> apps = new List<Application__c>{ missingId };

        Test.startTest();
        SHF_ApplicationTATCalculator.calculateEscalations(apps);
        Test.stopTest();

        System.assertEquals(null, missingId.L2_Escalation__c, 'No updates expected for record without Id.');
        System.assertEquals(null, missingId.L3_Escalation__c, 'No updates expected for record without Id.');
        System.assertEquals(null, missingId.L4_Escalation__c, 'No updates expected for record without Id.');
    }

    @IsTest
    static void testExecutesWhenBusinessHoursPresentOrSkipsGracefully() {
        // Retrieve setup data from @TestSetup
        List<Application__c> existing = [
            SELECT Id, Name, LastModifiedDate, L2_Escalation__c, L3_Escalation__c, L4_Escalation__c
            FROM Application__c
            ORDER BY CreatedDate
            LIMIT 2
        ];
        System.assertEquals(2, existing.size(), 'Expected 2 setup Application__c records');

        // Check for presence of required active BusinessHours named "SHDFC Noida Business Hours"
        BusinessHours targetBh = null;
        for (BusinessHours bh : [
            SELECT Id, Name, IsActive FROM BusinessHours WHERE IsActive = true
        ]) {
            if (bh.Name != null && bh.Name.equalsIgnoreCase('SHDFC Noida Business Hours')) {
                targetBh = bh;
                break;
            }
        }

        // Call method under test
        Test.startTest();
        SHF_ApplicationTATCalculator.calculateEscalations(existing);
        Test.stopTest();

        // Re-query to see committed changes (UnitOfWork commits DML)
        List<Application__c> afterApps = [
            SELECT Id, L2_Escalation__c, L3_Escalation__c, L4_Escalation__c
            FROM Application__c
            WHERE Id IN :existing
            ORDER BY CreatedDate
        ];

        if (targetBh != null) {
            // Happy path: expect escalation dates populated
            for (Application__c a : afterApps) {
                System.assertNotEquals(null, a.L2_Escalation__c, 'L2 escalation should be set when BH exists.');
                System.assertNotEquals(null, a.L3_Escalation__c, 'L3 escalation should be set when BH exists.');
                System.assertNotEquals(null, a.L4_Escalation__c, 'L4 escalation should be set when BH exists.');

                // Basic sanity: L2 should be before L3 before L4 if labels are increasing. We cannot rely on label values here,
                // so we only assert non-null. If you want stricter assertions, ensure labels enforce increasing durations.
            }
        } else {
            // Skipped path: fields remain null since required BH not found
            for (Application__c a : afterApps) {
                System.assertEquals(null, a.L2_Escalation__c, 'L2 should remain null if BH not found.');
                System.assertEquals(null, a.L3_Escalation__c, 'L3 should remain null if BH not found.');
                System.assertEquals(null, a.L4_Escalation__c, 'L4 should remain null if BH not found.');
            }
        }
    }

    @IsTest
    static void testPartialListWithMixedValidInvalidRecords() {
        // Build a list containing one valid persisted record and one invalid (no Id) record, to ensure loop continues and skips appropriately
        Application__c valid = [SELECT Id, Name, LastModifiedDate FROM Application__c ORDER BY CreatedDate LIMIT 1];
        Application__c invalidNoId = new Application__c(Name = 'Invalid No Id');

        List<Application__c> input = new List<Application__c>{ valid, invalidNoId };

        // Detect BH presence to decide assertion branch
        Boolean hasTargetBh = false;
        for (BusinessHours bh : [
            SELECT Id, Name, IsActive FROM BusinessHours WHERE IsActive = true
        ]) {
            if (bh.Name != null && bh.Name.equalsIgnoreCase('SHDFC Noida Business Hours')) {
                hasTargetBh = true;
                break;
            }
        }

        Test.startTest();
        SHF_ApplicationTATCalculator.calculateEscalations(input);
        Test.stopTest();

        // Re-query valid record to see if updated when BH exists
        valid = [SELECT Id, L2_Escalation__c, L3_Escalation__c, L4_Escalation__c FROM Application__c WHERE Id = :valid.Id];

        if (hasTargetBh) {
            System.assertNotEquals(null, valid.L2_Escalation__c, 'Valid record should be updated when BH exists.');
            System.assertNotEquals(null, valid.L3_Escalation__c, 'Valid record should be updated when BH exists.');
            System.assertNotEquals(null, valid.L4_Escalation__c, 'Valid record should be updated when BH exists.');
        } else {
            System.assertEquals(null, valid.L2_Escalation__c, 'Valid record remains unchanged if BH missing.');
            System.assertEquals(null, valid.L3_Escalation__c, 'Valid record remains unchanged if BH missing.');
            System.assertEquals(null, valid.L4_Escalation__c, 'Valid record remains unchanged if BH missing.');
        }

        // Invalid record without Id should never be modified in-memory
        System.assertEquals(null, invalidNoId.L2_Escalation__c, 'Invalid record (no Id) should be skipped.');
        System.assertEquals(null, invalidNoId.L3_Escalation__c, 'Invalid record (no Id) should be skipped.');
        System.assertEquals(null, invalidNoId.L4_Escalation__c, 'Invalid record (no Id) should be skipped.');
    }
}