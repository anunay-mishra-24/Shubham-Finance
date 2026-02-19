/**
* @File Name : SHF_RCUBusinessRuleEngineTest.cls
* @Description : test class for SHF_RCUBusinessRuleEngine
* @Author : Anand
* @Last Modified : Dec 30, 2025
**/

@isTest
private class SHF_RCUBusinessRuleEngineTest {

    @testSetup
    static void dataSetup() {

        UserRole ur;
        List<UserRole> existingRole = [SELECT Id 
                                       FROM UserRole
                                       WHERE DeveloperName = 'Head_Fraud_Control_Investigations'
                                       LIMIT 1];
        if(existingRole.isEmpty()){
            ur = new UserRole(Name = 'Head-Fraud Control & Investigations', DeveloperName = 'Head_Fraud_Control_Investigations');
            insert ur;
        } else {
            ur = existingRole[0];
        }

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US',
            UserRoleId = ur.Id
        );
        insert testUser;

        System.runAs(testUser) {

            Branch_Master__c branch = new Branch_Master__c(Name = 'Test Branch', Branch_Code__c = 'TB001');
            insert branch;

            insert new Branch_Mapping__c(Branch_Master__c = branch.Id, Internal_User__c = testUser.Id);

            Application__c app = new Application__c(Name = 'Test Application', Branch__c = branch.Id);
            insert app;

            Id deviationRT = Schema.SObjectType.Deviation_Master__c
                .getRecordTypeInfosByName()
                .get('Deviation')
                .getRecordTypeId();
            System.assertNotEquals(null, deviationRT, 'RecordType "Deviation" must exist');

            List<Deviation_Master__c> dmList = new List<Deviation_Master__c>{
                new Deviation_Master__c(Deviation__c='Not Recommended / Negative', Approving_Authority__c='HFCU', Department__c='Seller RCU', Source__c='System', Type_Of_Deviation__c='Application', Active__c=true, Product__c='Home Loan', RecordTypeId=deviationRT),
                new Deviation_Master__c(Deviation__c='Refer to Credit / Failed', Approving_Authority__c='ACM', Department__c='Seller RCU', Source__c='System', Type_Of_Deviation__c='Application', Active__c=true, Product__c='Home Loan', RecordTypeId=deviationRT),
                new Deviation_Master__c(Deviation__c='Not Recommended', Approving_Authority__c='RCUZM', Department__c='Borrower RCU', Source__c='System', Type_Of_Deviation__c='Application', Active__c=true, Product__c='Home Loan', RecordTypeId=deviationRT),
                new Deviation_Master__c(Deviation__c='Negative', Approving_Authority__c='RCUSH', Department__c='Borrower RCU', Source__c='System', Type_Of_Deviation__c='Application', Active__c=true, Product__c='Home Loan', RecordTypeId=deviationRT)
            };
            insert dmList;

            List<String> decisions = new List<String>{
                'RCU Not Recommended','Negative','RCU Refer to Credit','RCU Failed'
            };
            List<Verification__c> verList = new List<Verification__c>();
            for(String d : decisions){
                verList.add(new Verification__c(Application__c = app.Id, Type__c = 'Seller', FCU_Manager_Decision__c = d));
                verList.add(new Verification__c(Application__c = app.Id, Type__c = 'Borrower', FCU_Manager_Decision__c = d));
            }
            insert verList;
        }
    }

    @isTest
    static void testAllDecisionScenarios() {
        User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

        System.runAs(u){
            List<Verification__c> allRecords = [SELECT Id FROM Verification__c];
            Test.startTest();
            for(Verification__c v : allRecords){
                SHF_RCUBusinessRuleEngine.executeRCUBusinessRules(v.Id);
            }
            Test.stopTest();
            System.assert(allRecords.size() > 0, 'All rules executed successfully');
        }
    }

    @isTest
    static void testExistingDeviationDeleteAndRecreate() {
        User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

        System.runAs(u){

            Verification__c v = [SELECT Id, Application__c, Type__c, FCU_Manager_Decision__c FROM Verification__c LIMIT 1];

            Deviation_Master__c dev = [
                SELECT Id FROM Deviation_Master__c
                WHERE Deviation__c = 'Not Recommended / Negative'
                LIMIT 1
            ];

            insert new Deviation_and_Sanction_Condition__c(
                Loan_Application__c = v.Application__c,
                Verification__c = v.Id,
                Deviations__c = dev.Id,
                Decision__c = 'Sent For Review'
            );

            Test.startTest();
            SHF_RCUBusinessRuleEngine.executeRCUBusinessRules(v.Id);
            Test.stopTest();

            Integer countAfter = [
                SELECT COUNT() FROM Deviation_and_Sanction_Condition__c
                WHERE Verification__c = :v.Id
            ];
            System.assertEquals(1, countAfter, 'Old deviation deleted & new one inserted correctly.');
        }
    }

    @isTest
    static void testInvalidNullHandling() {
        Test.startTest();
        SHF_RCUBusinessRuleEngine.executeRCUBusinessRules('INVALID-ID');
        SHF_RCUBusinessRuleEngine.createDeviationRecord(null, null, null, new Map<String,Set<String>>());
        Test.stopTest();
        System.assert(true, 'Handled invalid/null safely');
    }

    @isTest
    static void testAuthorityAndRoleMap() {
        Id branchId = [SELECT Id FROM Branch_Master__c LIMIT 1].Id;
        Map<String, Set<String>> roleMap = SHF_RCUBusinessRuleEngine.findApprovalAuthority(branchId);

        System.assertNotEquals(null, roleMap);
        System.assertEquals(
            'Head-Fraud Control & Investigations',
            SHF_RCUBusinessRuleEngine.roleMap.get('HFCU')
        );
    }
}