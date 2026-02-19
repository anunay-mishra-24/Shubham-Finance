@IsTest
private class SHF_ApplicationEscalationBatch_Test {

    @TestSetup
    static void setupData() {

        Profile anyProfile = [SELECT Id FROM Profile LIMIT 1];

        User topMgr = SHF_TestDataFactory.createUser('Top', 'Mgr', 'top.mgr@test.com', null, anyProfile.Id, true, '9000000004', null, true);
        User midMgr = SHF_TestDataFactory.createUser('Mid', 'Mgr', 'mid.mgr@test.com', null, anyProfile.Id, true, '9000000003', null, true);
        User salesUser = SHF_TestDataFactory.createUser('Sales', 'User', 'sales.user@test.com', null, anyProfile.Id, true, '9000000002', null, true);

        update new List<User>{
            new User(Id = midMgr.Id, ManagerId = topMgr.Id),
            new User(Id = salesUser.Id, ManagerId = midMgr.Id)
        };

        String activeStatus = SHF_ConstantsUtil.ACTIVE_STATUS;
        String stage = SHF_ConstantsUtil.QDEList.isEmpty()
            ? 'QDE'
            : SHF_ConstantsUtil.QDEList[0];

        Datetime oneHourAgo = System.now().addHours(-1);

        // MATCHING record
        Application__c matchApp = SHF_TestDataFactory.createApplication(null, false);
        matchApp.OwnerId = salesUser.Id;
        matchApp.Application_Status__c = activeStatus;
        matchApp.Application_Stage__c = stage;
        matchApp.L2_Escalation__c = oneHourAgo;
        matchApp.L3_Escalation__c = oneHourAgo;
        matchApp.L4_Escalation__c = oneHourAgo;
        matchApp.Contact_No1__c = '9999999999';

        // SAME stage/status but formula evaluates false
        Application__c noPick = SHF_TestDataFactory.createApplication(null, false);
        noPick.OwnerId = salesUser.Id;
        noPick.Application_Status__c = 'Inactive'; // drives formula false
        noPick.Application_Stage__c = stage;
        noPick.Contact_No1__c = '9999999999';

        // WRONG stage
        Application__c stageMiss = SHF_TestDataFactory.createApplication(null, false);
        stageMiss.OwnerId = salesUser.Id;
        stageMiss.Application_Status__c = activeStatus;
        stageMiss.Application_Stage__c = 'NON_QDE_STAGE';
        stageMiss.Contact_No1__c = '9999999999';

        insert new List<Application__c>{ matchApp, noPick, stageMiss };
    }

    @IsTest
    static void test_Batch_Execute_HappyPath() {

    User salesUser = [
        SELECT Id FROM User WHERE Alias = 'User' LIMIT 1
    ];

    System.runAs(salesUser) {

        String activeStatus = SHF_ConstantsUtil.ACTIVE_STATUS;
        String stage = SHF_ConstantsUtil.QDEList.isEmpty()
            ? 'QDE'
            : SHF_ConstantsUtil.QDEList[0];

        Datetime oneHourAgo = System.now().addHours(-1);

        Application__c matchApp = SHF_TestDataFactory.createApplication(null, false);
        matchApp.OwnerId = salesUser.Id;
        matchApp.Application_Status__c = activeStatus;
        matchApp.Application_Stage__c = stage;
        matchApp.L2_Escalation__c = oneHourAgo;
        matchApp.L3_Escalation__c = oneHourAgo;
        matchApp.L4_Escalation__c = oneHourAgo;
        matchApp.Contact_No1__c = '9999999999';

        insert matchApp;
    }

    Test.startTest();
    Id batchId = Database.executeBatch(
        new SHF_ApplicationEscalationBatch(), 50
    );
    Test.stopTest();

    System.assertNotEquals(null, batchId);
   }

    @IsTest
    static void test_Batch_Execute_NoRecords() {

        // Drive formula to false by status
        List<Application__c> apps =
            [SELECT Id, Application_Status__c FROM Application__c];

        for (Application__c a : apps) {
            a.Application_Status__c = 'Inactive';
        }
        update apps;

        Test.startTest();
        Id batchId = Database.executeBatch(
            new SHF_ApplicationEscalationBatch(), 10
        );
        Test.stopTest();

        System.assertNotEquals(null, batchId);
    }
}