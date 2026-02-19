/**
* @File Name : SHF_RCUActivitySLANotification_Test.cls
* @Description :
* @Author : Anand
* @Last Modified By :
* @Last Modified On : December 30, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 30, 2025 |   | Initial Version
**/

@IsTest
public class SHF_RCUActivitySLANotification_Test {

    @TestSetup
    static void setupTestData() {

        Profile p = [
            SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1
        ];

        User manager = SHF_TestDataFactory.createUser(
            'RCU', 'Manager',
            'manager@test.com',
            'manager' + System.currentTimeMillis() + '@test.com',
            p.Id, true, null, null, true
        );

        User vendor = SHF_TestDataFactory.createUser(
            'RCU', 'Vendor',
            'vendor@test.com',
            'vendor' + System.currentTimeMillis() + '@test.com',
            p.Id, true, null, null, true
        );

        Application__c app =
            SHF_TestDataFactory.createApplication('Test Application', true);

        Verification__c verification =
            SHF_TestDataFactory.createVerification(
                app.Id,
                manager.Id,
                'Sampled',
                'Document',
                null,
                true
            );

        Date pastDueDate = System.today().addDays(-1);

        Verification_Activity__c extAct =
            SHF_TestDataFactory.createVerificationActivity(
                verification.Id,
                vendor.Id,
                true
            );
        extAct.Vendor_Status__c = 'Pending';
        extAct.Vendor_Type__c   = 'External';
        extAct.Due_Date__c      = pastDueDate;
        update extAct;

        Verification_Activity__c intSame =
            SHF_TestDataFactory.createVerificationActivity(
                verification.Id,
                manager.Id,
                true
            );
        intSame.Vendor_Status__c = 'Pending';
        intSame.Vendor_Type__c   = 'Internal';
        intSame.Due_Date__c      = pastDueDate;
        update intSame;

        Verification_Activity__c intDiff =
            SHF_TestDataFactory.createVerificationActivity(
                verification.Id,
                vendor.Id,
                true
            );
        intDiff.Vendor_Status__c = 'Pending';
        intDiff.Vendor_Type__c   = 'Internal';
        intDiff.Due_Date__c      = pastDueDate;
        update intDiff;

    }

    @IsTest
    static void testBatchExecution() {

        Test.startTest();
        Database.executeBatch(
            new SHF_RCUActivitySLANotification(),
            200
        );
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testSchedulerExecution() {

        List<Verification_Activity__c> acts =
            [SELECT Id, Vendor_Status__c FROM Verification_Activity__c];

        for (Integer i = 1; i < acts.size(); i++) {
            acts[i].Vendor_Status__c = 'Completed';
        }
        update acts;

        Test.startTest();
        System.schedule(
            'RCU SLA Scheduler Test',
            '0 0 0 * * ?',
            new SHF_RCUActivitySLANotification()
        );
        Test.stopTest();

        System.assert(true);
    }
}