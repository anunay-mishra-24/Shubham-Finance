@IsTest
private class SHF_LeadEscalationBatch_Test {

    private static Id getStandardUserProfileId() {
        return [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
    }

    private static Map<String, User> createUserHierarchy() {

        Id stdProf = getStandardUserProfileId();

        User top = SHF_TestDataFactory.createUser('Top','Mgr','top@test.com',null,stdProf,true,'9000000000','9000000001',true);
        User mid = SHF_TestDataFactory.createUser('Mid','Mgr','mid@test.com',null,stdProf,true,'9000000002','9000000003',true);
        User own = SHF_TestDataFactory.createUser('Own','User','own@test.com',null,stdProf,true,'9000000004','9000000005',true);

        mid.ManagerId = top.Id;
        own.ManagerId = mid.Id;
        update new List<User>{ mid, own };

        return new Map<String, User>{
            'top' => top,
            'mid' => mid,
            'own' => own
        };
    }

    private static Notification_Template__mdt ensureEscalationTemplate() {
        return [
            SELECT Id
            FROM Notification_Template__mdt
            WHERE DeveloperName = :SHF_ConstantsUtil.LEAD_ESCALTE_TO_MANAGERS
            LIMIT 1
        ];
    }

    private static BusinessHours ensureBusinessHours() {
        return [
            SELECT Id
            FROM BusinessHours
            WHERE IsDefault = true
            LIMIT 1
        ];
    }

    private static Branch_Master__c ensureBranch() {
        return SHF_TestDataFactory.createBranchMaster('Test Branch', '0009', true);
    }

    private static Lead__c createEscalationLead(Id ownerId, Id branchId) {

        Datetime past = System.now().addHours(-2);

        Lead__c ld = new Lead__c(
            OwnerId = ownerId,
            Branch__c = branchId,
            Lead_Status__c = SHF_ConstantsUtil.ACTIVE_STATUS,
            L2_Escalation__c = past,
            L3_Escalation__c = past,
            L4_Escalation__c = past
        );
        insert ld;
        return ld;
    }

    @IsTest
    static void testBatchLeadEscalation_UpdatesEscalationDates() {

        Map<String, User> users = createUserHierarchy();
        Branch_Master__c branch = ensureBranch();
        ensureBusinessHours();
        ensureEscalationTemplate();

        System.runAs(users.get('own')) {

            Lead__c ld = createEscalationLead(users.get('own').Id, branch.Id);

            Test.startTest();
            Database.executeBatch(new SHF_LeadEscalationBatch(), 50);
            Test.stopTest();

            Lead__c updated = [
                SELECT L2_Escalation__c, L3_Escalation__c, L4_Escalation__c
                FROM Lead__c
                WHERE Id = :ld.Id
            ];

            System.assertNotEquals(null, updated.L2_Escalation__c);
            System.assertNotEquals(null, updated.L3_Escalation__c);
            System.assertNotEquals(null, updated.L4_Escalation__c);
        }
    }

    @IsTest
    static void testSchedulerRunsBatch() {

        Test.startTest();
        System.schedule(
            'LeadEscScheduler',
            '0 0 12 * * ?',
            new SHF_LeadEscalationBatch()
        );
        Test.stopTest();
    }
}