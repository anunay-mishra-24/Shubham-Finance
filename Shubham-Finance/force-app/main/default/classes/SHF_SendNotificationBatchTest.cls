@isTest
public class SHF_SendNotificationBatchTest {
    
    @testSetup
    static void setupData() {
        // Create test users
        Profile csProfile = [SELECT Id FROM Profile WHERE Name = :SHF_ConstantsUtil.CUSTOMER_SERVICEPROFILE LIMIT 1];
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        // Manager user
        User manager = new User(
            FirstName = 'Manager',
            LastName = 'Test',
            Email = 'manager@example.com',
            Username = 'manager' + Math.random() + '@example.com',
            Alias = 'mgr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = sysAdminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert manager;
        
        // Customer Service user with manager assigned
        User csUser = new User(
            FirstName = 'CS',
            LastName = 'User',
            Email = 'csuser@example.com',
            Username = 'csuser' + Math.random() + '@example.com',
            Alias = 'csu',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = csProfile.Id,
            LanguageLocaleKey = 'en_US',
            ManagerId = manager.Id
        );
        insert csUser;
        
        // Create cases that trigger notifications using the factory
        SHF_TestDataFactory.createCaseList(
            5,                            // count
            (String) null,                // subject
            (String) null,                // status
            (String) null,                // contactNo
            (String) null,                // customerName
            (String) null,                // suppliedEmail
            (String) null,                // origin
            (String) null,                // ticketType
            (String) null,                // ticketSubType
            (Datetime) null,              // actualTat
            (Datetime) null,              // actualTatAfter1
            (Datetime) null,              // actualTatAfter3
            (Datetime) null,              // actualTatAfter4
            (Datetime) null,              // actualTatBefore1
            (Datetime) null,              // sendNotification4Hrs
            (Datetime) null,              // escalationNotificationDate
            true                          // doInsert
        );
        
        
        List<Case> testCases = [SELECT Id FROM Case WHERE Subject LIKE 'Test Case%'];
        for (Case c : testCases) {
            c.OwnerId = csUser.Id;
        }
        update testCases;
        
        Datetime now = Datetime.now();
        List<Case> skipCases = new List<Case>();
        for (Integer i = 0; i < 2; i++) {
            skipCases.add(new Case(
                Subject = 'No Notify Case ' + i,
                Status = SHF_ConstantsUtil.NEW_STATUS,
                Contact_No_1__c = '999349567' + i,
                Customer_Name__c = 'Skip Customer ',
                SuppliedEmail = 'skip' + i + '@example.com',
                Origin = 'Email',
                Ticket_Type__c = 'Enquiry',
                Ticket_Sub_Type__c = 'Change in base rate',
                Actual_TAT_After_1__c = now.addHours(5),
                Actual_TAT_Before_1__c = now.addHours(5),
                Send_Notification_4_hours__c = now.addHours(5),
                Escalation_Notification_Date__c = now.addHours(5),
                Actual_TAT_After_3__c = now.addHours(5),
                Actual_TAT_After_4__c = now.addHours(5)
            ));
        }
        insert skipCases;
    }
    
    @isTest
    static void testCasesWithNotificationTrue() {
        List<Case> casesWithNotify = [
            SELECT Id, Send_Notification__c 
            FROM Case 
            WHERE Subject LIKE 'Test Case%'
        ];
        
        Test.startTest();
        System.schedule('Test Notify Job', '0 0 0 * * ?', new SHF_TATsEscalationScheduler());
        Test.stopTest();
        
        // Re-query after batch/scheduler
        casesWithNotify = [
            SELECT Id, Send_Notification__c 
            FROM Case 
            WHERE Subject LIKE 'Test Case%'
        ];
        
        System.assert(!casesWithNotify.isEmpty(), 'Expected cases with notification');
        for (Case c : casesWithNotify) {
            System.assertEquals(true, c.Send_Notification__c,
                                'Send_Notification__c should be TRUE for ' + c.Id);
        }
    }
    
    @isTest
    static void testCasesWithNotificationFalse() {
        List<Case> casesWithoutNotify = [
            SELECT Id, Send_Notification__c 
            FROM Case 
            WHERE Subject LIKE 'No Notify Case%'
        ];
        
        Test.startTest();
        System.schedule('Test Notify Job', '0 0 0 * * ?', new SHF_TATsEscalationScheduler());
        Test.stopTest();
        
    }
}