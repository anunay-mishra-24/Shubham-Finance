@isTest
private class SHF_SendNotificationForTAT_Test {
    
    // ====== TEST DATA SETUP ======
    @testSetup
    static void setupData() {
        // --- Roles (setup objects) ---
        UserRole hodRole = new UserRole(Name = 'Head of Department');
        insert hodRole;
        UserRole agmRole = new UserRole(Name = 'Assistant General Manager');
        insert agmRole;
        UserRole mgrRole = new UserRole(Name = 'Manager');
        insert mgrRole;
        // --- Users (setup objects) ---
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        User hodUser   = createUser('tatHOD', hodRole.Id, p.Id, null);
        User agmUser   = createUser('tatAGM', agmRole.Id, p.Id, hodUser.Id);
        User mgrUser   = createUser('tatMGR', mgrRole.Id, p.Id, agmUser.Id);
        User ownerUser = createUser('tatOwner', null, p.Id, mgrUser.Id);
        
        // --- Now runAs(ownerUser) to insert non-setup objects ---
        System.runAs(ownerUser) {
            // Insert bypass custom setting
            insert new Bypass_Validations__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                Bypass_Validation__c = true
            );
            
            // --- Matrix Rows ---
            insert new Case_Categories_Matrix__c(
                Ticket_Type__c = 'Complaint',
                Request_Type__c = 'Change in Personal Details',
                Ticket_Sub_Type__c = 'Change in Personal Details',
                Turnaround_Time__c = 2,
                Send_Notification_InDays__c = 1
            );
            insert new Case_Categories_Matrix__c(
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'Balance confirmation certificate',
                Ticket_Sub_Type__c = SHF_ConstantsUtil.STATEMENTS_TICKET_SUB_TYPE,
                Turnaround_Time__c = 2,
                Send_Notification_InDays__c = 1
            ); 
            // --- Cases ---
            insert new Case(
                Status = SHF_ConstantsUtil.NEW_STATUS,
                Ticket_Type__c = 'Complaint',
                Request_Type__c = 'Change in Personal Details',
                Ticket_Sub_Type__c = 'Change in Personal Details',
                OwnerId = ownerUser.Id,
                Origin = SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE,
                Sub_Source__c = 'Regulator\'s Emails'
            );
            
            insert new Case(
                Status = SHF_ConstantsUtil.NEW_STATUS,
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'Balance confirmation certificate',
                Ticket_Sub_Type__c = SHF_ConstantsUtil.STATEMENTS_TICKET_SUB_TYPE,
                OwnerId = ownerUser.Id,
                Origin = 'Letter',
                Sub_Source__c = 'Letter'
            );
            
            // --- Mock Notification Template ---
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.caseNotMovedToWIPforManager);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.preTATforTeamLead);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.postTATforTeamLead);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.responseAwaitedClosureSMS);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.caseNotMovedToWIPOwner);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.caseNotMovedToWIPforManager);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.caseNotMovedToWIPforAGM);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.periodicEscalationforTeamLead);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.periodicEscalationforHOD);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.periodicEscalationforAGM);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.preTATforHOD);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.preTATforAGM);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.preTATforManager);    
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.postTATforHOD);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.postTATforAGM);
            SHF_TestDataFactory.mockNotificationTemplate(SHF_ConstantsUtil.postTATforManager);
        }
    }
    // ====== HELPER: CREATE USER ======
    private static User createUser(String alias, Id roleId, Id profileId, Id managerId) {
        User u = new User(
            FirstName = alias,
            LastName  = 'Test',
            Alias     = alias.left(8),
            Email     = alias + '@test.com',
            Username  = alias + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey      = 'en_US',
            TimeZoneSidKey    = 'GMT',
            ProfileId         = profileId,
            UserRoleId        = roleId,
            ManagerId         = managerId
        );
        insert u;
        return u;
    }
    // ====== TESTS ======
    @isTest
    static void testBatchExecute_NewStatusCase1() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        //  Create AGM user
        User agmUser = createUser('agm', null, p.Id, null);
        //  Create Team Lead (reports to AGM)
        User teamLeadUser = createUser('teamLead', null, p.Id, agmUser.Id);
        //  Create Manager (reports to Team Lead)
        User mgrUser = createUser('mgr', null, p.Id, teamLeadUser.Id);
        // Create Case Owner (reports to Manager)
        User ownerUser = createUser('owner', null, p.Id, mgrUser.Id);
        // User mgrUser = [SELECT Id, ManagerId FROM User WHERE isActive = true LIMIT 1];
        System.runAs(mgrUser) {
            // Create a Case owned by user
            Case cs = new Case(
                Status = SHF_ConstantsUtil.NEW_STATUS,
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'Balance confirmation certificate',
                Ticket_Sub_Type__c = SHF_ConstantsUtil.STATEMENTS_TICKET_SUB_TYPE,
                Origin = SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE,
                OwnerId = ownerUser.Id,
                Sub_Source__c = 'Regulator\'s Emails',
                Subject = 'Case NEW - statements',
                Send_Notification_4_hours__c = System.now().addMinutes(30),
                Actual_TAT_After_1__c = System.now().addMinutes(45),
                Actual_TAT_Before_1__c = System.now().addMinutes(50),
                Escalation_Notification_Date__c = System.now().addMinutes(40),
                Actual_TAT_After_3__c = System.now().addMinutes(35),
                Actual_TAT_After_4__c = System.now().addMinutes(55)
            );
            insert cs;
            
            //  Populate templateMap  (mock Custom Metadata)
            Map<String, Notification_Template__mdt> templateMap = new Map<String, Notification_Template__mdt>();
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforManager,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for Manager <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for Manager <ManagerName> <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for TeamLead <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for TeamLead <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforAGM,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>'));
            Test.startTest();
            Database.executeBatch(new SHF_SendNotificationForTATsEscalation(), 50);
            Test.stopTest();
        }
    }
    @isTest
    static void testBatchExecute_NewStatusCase2() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        //  Create AGM user
        User agmUser = createUser('agm', null, p.Id, null);
        //  Create Team Lead (reports to AGM)
        User teamLeadUser = createUser('teamLead', null, p.Id, agmUser.Id);
        //  Create Manager (reports to Team Lead)
        User mgrUser = createUser('mgr', null, p.Id, teamLeadUser.Id);
        //  Create Case Owner (reports to Manager)
        User ownerUser = createUser('owner', null, p.Id, mgrUser.Id);
        System.runAs(mgrUser) {
            // Create a Case owned by user
            Case cs = new Case(
                Status = SHF_ConstantsUtil.NEW_STATUS,
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'EMI payment',
                Ticket_Sub_Type__c = 'Payments',
                Origin = SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE,
                OwnerId = ownerUser.Id,
                Sub_Source__c = 'Regulator\'s Emails',
                Subject = 'Case NEW - non statements',
                Send_Notification_4_hours__c = System.now().addMinutes(30),
                Actual_TAT_After_1__c = System.now().addMinutes(45),
                Actual_TAT_Before_1__c = System.now().addMinutes(50),
                Escalation_Notification_Date__c = System.now().addMinutes(40),
                Actual_TAT_After_3__c = System.now().addMinutes(35),
                Actual_TAT__c   = System.now().addMinutes(35),
                Actual_TAT_After_4__c = System.now().addMinutes(55)
            );
            insert cs;
            //  Populate templateMap in test context (mock Custom Metadata)
            Map<String, Notification_Template__mdt> templateMap = new Map<String, Notification_Template__mdt>();
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforManager,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for Manager <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for Manager <ManagerName> <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for TeamLead <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for TeamLead <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforAGM,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>'));
            Test.startTest();
            Database.executeBatch(new SHF_SendNotificationForTATsEscalation(), 50);
            Test.stopTest();
        }
    }
    
    @isTest
    static void testBatchExecute_NewStatusCase3() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        // Create AGM user
        User agmUser = createUser('agm', null, p.Id, null);
        //  Create Team Lead (reports to AGM)
        User teamLeadUser = createUser('teamLead', null, p.Id, agmUser.Id);
        //  Create Manager (reports to Team Lead)
        User mgrUser = createUser('mgr', null, p.Id, teamLeadUser.Id);
        //  Create Case Owner (reports to Manager)
        User ownerUser = createUser('owner', null, p.Id, mgrUser.Id);
        System.runAs(mgrUser) {
            // Create a Case owned by user
            Case cs = new Case(
                Status = SHF_ConstantsUtil.NEW_STATUS,
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'Balance confirmation certificate',
                Ticket_Sub_Type__c = SHF_ConstantsUtil.STATEMENTS_TICKET_SUB_TYPE,
                Origin = SHF_ConstantsUtil.EMAILS_SOURCE,
                OwnerId = ownerUser.Id,
                Sub_Source__c = 'Direct Email',
                Subject = 'Case NEW - statements',
                Send_Notification_4_hours__c = System.now().addMinutes(30),
                Actual_TAT_After_1__c = System.now().addMinutes(45),
                Actual_TAT_Before_1__c = System.now().addMinutes(50),
                Escalation_Notification_Date__c = System.now().addMinutes(40),
                Actual_TAT_After_3__c = System.now().addMinutes(35),
                Actual_TAT__c   = System.now().addMinutes(35),
                Actual_TAT_After_4__c = System.now().addMinutes(55)
            );
            insert cs;
            
            // Populate templateMap in test context (mock Custom Metadata)
            Map<String, Notification_Template__mdt> templateMap = new Map<String, Notification_Template__mdt>();
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforManager,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for Manager <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for Manager <ManagerName> <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for TeamLead <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for TeamLead <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforAGM,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>'));
            //  Assign AGM name (so String.isNotBlank(nameAGM) passes)
            String nameAGM = agmUser.FirstName;    
            Test.startTest();
            Database.executeBatch(new SHF_SendNotificationForTATsEscalation(), 50);
            Test.stopTest();
        }
    }
    @isTest
    static void testBatchExecute_NewStatusCase4() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        //  Create AGM user
        User agmUser = createUser('agm', null, p.Id, null);
        //  Create Team Lead (reports to AGM)
        User teamLeadUser = createUser('teamLead', null, p.Id, agmUser.Id);
        // Create Manager (reports to Team Lead)
        User mgrUser = createUser('mgr', null, p.Id, teamLeadUser.Id);
        //  Create Case Owner (reports to Manager)
        User ownerUser = createUser('owner', null, p.Id, mgrUser.Id);
        System.runAs(mgrUser) {
            // Create a Case owned by  user
            Case cs = new Case(
                Status = SHF_ConstantsUtil.NEW_STATUS,
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'EMI payment',
                Ticket_Sub_Type__c = 'Payments',
                Origin = SHF_ConstantsUtil.EMAILS_SOURCE,
                OwnerId = ownerUser.Id,
                Sub_Source__c = 'Direct Email',
                Subject = 'Case NEW - statements',
                Send_Notification_4_hours__c = System.now().addMinutes(30),
                Actual_TAT_After_1__c = System.now().addMinutes(45),
                Actual_TAT_Before_1__c = System.now().addMinutes(50),
                Escalation_Notification_Date__c = System.now().addMinutes(40),
                Actual_TAT_After_3__c = System.now().addMinutes(35),
                Actual_TAT__c   = System.now().addMinutes(56),
                Actual_TAT_After_4__c = System.now().addMinutes(55)
            );
            insert cs;
            
            //  Populate templateMap in test context (mock Custom Metadata)
            Map<String, Notification_Template__mdt> templateMap = new Map<String, Notification_Template__mdt>();
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforManager,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for Manager <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for Manager <ManagerName> <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for TeamLead <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for TeamLead <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforAGM,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>'));
            
            Test.startTest();
            Database.executeBatch(new SHF_SendNotificationForTATsEscalation(), 50);
            Test.stopTest();
        }
    }
    
    @isTest
    static void testBatchExecute_WIPStatusCase1() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        // Create AGM user
        User agmUser = createUser('agm', null, p.Id, null);
        // Create Team Lead (reports to AGM)
        User teamLeadUser = createUser('teamLead', null, p.Id, agmUser.Id);
        //  Create Manager (reports to Team Lead)
        User mgrUser = createUser('mgr', null, p.Id, teamLeadUser.Id);
        //  Create Case Owner (reports to Manager)
        User ownerUser = createUser('owner', null, p.Id, mgrUser.Id);
        System.runAs(mgrUser) {
            // Create a Case owned by user
            Case cs = new Case(
                Status = SHF_ConstantsUtil.WIP_STATUS,
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'EMI payment',
                Ticket_Sub_Type__c = 'Payments',
                Origin = SHF_ConstantsUtil.EMAILS_SOURCE,
                OwnerId = ownerUser.Id,
                Sub_Source__c = 'Direct Email',
                Subject = 'Case NEW - statements',
                Send_Notification_4_hours__c = System.now().addMinutes(30),
                Actual_TAT_After_1__c = System.now().addMinutes(45),
                Actual_TAT_Before_1__c = System.now().addMinutes(50),
                Escalation_Notification_Date__c = System.now().addMinutes(40),
                Actual_TAT_After_3__c = System.now().addMinutes(35),
                Actual_TAT__c   = System.now().addMinutes(43),
                Actual_TAT_After_4__c = System.now().addMinutes(55)
            );
            insert cs;
            
            // Populate templateMap in test context (mock Custom Metadata)
            Map<String, Notification_Template__mdt> templateMap = new Map<String, Notification_Template__mdt>();
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforManager,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for Manager <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for Manager <ManagerName> <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for TeamLead <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for TeamLead <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforAGM,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>'));
            
            Test.startTest();
            Database.executeBatch(new SHF_SendNotificationForTATsEscalation(), 50);
            Test.stopTest();
        }
    }
    
    @isTest
    static void testBatchExecute_WIPStatusCase2() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        //  Create AGM user
        User agmUser = createUser('agm', null, p.Id, null);
        //  Create Team Lead (reports to AGM)
        User teamLeadUser = createUser('teamLead', null, p.Id, agmUser.Id);
        //  Create Manager (reports to Team Lead)
        User mgrUser = createUser('mgr', null, p.Id, teamLeadUser.Id);
        //  Create Case Owner (reports to Manager)
        User ownerUser = createUser('owner', null, p.Id, mgrUser.Id);
        System.runAs(mgrUser) {
            // Create a Case owned by user
            Case cs = new Case(
                Status = SHF_ConstantsUtil.WIP_STATUS,
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'EMI payment',
                Ticket_Sub_Type__c = 'Payments',
                Origin = SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE,
                OwnerId = ownerUser.Id,
                Sub_Source__c = 'Regulator\'s Emails',
                Subject = 'Case WIP - Regulator',
                Send_Notification_4_hours__c = System.now().addMinutes(30),
                Actual_TAT_After_1__c = System.now().addMinutes(45),
                Actual_TAT_Before_1__c = System.now().addMinutes(50),
                Escalation_Notification_Date__c = System.now().addMinutes(40),
                Actual_TAT_After_3__c = System.now().addMinutes(35),
                Actual_TAT__c   = System.now().addMinutes(43),
                Actual_TAT_After_4__c = System.now().addMinutes(55)
            );
            insert cs;
            
            // Populate templateMap in test context (mock Custom Metadata)
            Map<String, Notification_Template__mdt> templateMap = new Map<String, Notification_Template__mdt>();
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforManager,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for Manager <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for Manager <ManagerName> <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for TeamLead <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for TeamLead <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.caseNotMovedToWIPforAGM,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>'));    
            
            Test.startTest();
            Database.executeBatch(new SHF_SendNotificationForTATsEscalation(), 50);
            Test.stopTest();
        }
    }    
    
    @isTest
    static void testBatchExecute_WIPStatusCase3() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        //  Create AGM user
        User agmUser = createUser('agm', null, p.Id, null);
        //  Create Team Lead (reports to AGM)
        User teamLeadUser = createUser('teamLead', null, p.Id, agmUser.Id);
        //  Create Manager (reports to Team Lead)
        User mgrUser = createUser('mgr', null, p.Id, teamLeadUser.Id);
        //  Create Case Owner (reports to Manager)
        User ownerUser = createUser('owner', null, p.Id, mgrUser.Id);
        System.runAs(mgrUser) {
            // Create a Case owned by user
            Case cs = new Case(
                Status = SHF_ConstantsUtil.WIP_STATUS,
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'EMI payment',
                Ticket_Sub_Type__c = 'Payments',
                Origin = SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE,
                OwnerId = ownerUser.Id,
                Sub_Source__c = 'Regulator\'s Emails',
                Subject = 'Case WIP - Regulator',
                Send_Notification_4_hours__c = System.now().addMinutes(30),
                Actual_TAT_After_1__c = System.now().addMinutes(45),
                Actual_TAT_Before_1__c = System.now().addMinutes(50),
                Escalation_Notification_Date__c = System.now().addMinutes(-30),
                Actual_TAT_After_3__c = System.now().addMinutes(35),
                Actual_TAT__c   = System.now().addMinutes(43),
                Actual_TAT_After_4__c = System.now().addMinutes(55)
            );
            insert cs;
            //  Populate templateMap in test context (mock Custom Metadata)
            Map<String, Notification_Template__mdt> templateMap = new Map<String, Notification_Template__mdt>();
            templateMap.put(SHF_ConstantsUtil.preTATforManager,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for Manager <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for Manager <ManagerName> <TeamLead> <caseNo>'));
            templateMap.put('Query_Approaching_TAT_Pre_TAT_Reminder',
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for TeamLead <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for TeamLead <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.preTATforAGM,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>'));
            
            // HOD
            templateMap.put(SHF_ConstantsUtil.preTATforHOD,
                            new Notification_Template__mdt(
                                Bell_Notification__c = 'Bell for HOD <HODName> <ManagerName> <TeamLead> <caseNo>',
                                Email_Template__c    = 'Email for HOD <HODName> <ManagerName> <TeamLead> <caseNo>'
                            )
                           );
            Test.startTest();
            Database.executeBatch(new SHF_SendNotificationForTATsEscalation(), 50);
            Test.stopTest();
        }
    }
    
    @isTest
    static void testBatchExecute_EsclatedStatusCase1() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        // Create AGM user
        User agmUser = createUser('agm', null, p.Id, null);
        //  Create Team Lead (reports to AGM)
        User teamLeadUser = createUser('teamLead', null, p.Id, agmUser.Id);
        //  Create Manager (reports to Team Lead)
        User mgrUser = createUser('mgr', null, p.Id, teamLeadUser.Id);
        //  Create Case Owner (reports to Manager)
        User ownerUser = createUser('owner', null, p.Id, mgrUser.Id);
        System.runAs(mgrUser) {
            Bypass_Validations__c bypass = 
                [SELECT Id, Bypass_Validation__c FROM Bypass_Validations__c 
                 WHERE SetupOwnerId = :UserInfo.getOrganizationId() LIMIT 1];
            
            bypass.Bypass_Validation__c = true;
            update bypass;
            // Create a Case owned by user
            Case cs = new Case(
                Status = SHF_ConstantsUtil.ESCALATED_STATUS,
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'EMI payment',
                Ticket_Sub_Type__c = 'Payments',
                Origin = SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE,
                OwnerId = ownerUser.Id,
                Sub_Source__c = 'Regulator\'s Emails',
                Subject = 'Case Escalated - Regulator',
                Send_Notification_4_hours__c = System.now().addMinutes(30),
                Actual_TAT_After_1__c = System.now().addMinutes(45),
                Actual_TAT_Before_1__c = System.now().addMinutes(50),
                Escalation_Notification_Date__c = System.now().addMinutes(-30),
                Actual_TAT_After_3__c = System.now().addMinutes(35),
                Actual_TAT__c   = System.now().addMinutes(43),
                Actual_TAT_After_4__c = System.now().addMinutes(55)
            );
            insert cs;
            Map<String, Notification_Template__mdt> templateMap = new Map<String, Notification_Template__mdt>();
            templateMap.put(SHF_ConstantsUtil.postTATforManager,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for Manager <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for Manager <ManagerName> <TeamLead> <caseNo>'));
            templateMap.put('Query_Out_of_TAT_Urgent_Escalation_Ale',
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for TeamLead <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for TeamLead <TeamLead> <caseNo>'));
            templateMap.put(SHF_ConstantsUtil.postTATforAGM,
                            new Notification_Template__mdt(Bell_Notification__c = 'Bell for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>', 
                                                           Email_Template__c = 'Email for AGM <AGMName> <ManagerName> <TeamLead> <caseNo>'));
            
            // HOD
            templateMap.put(SHF_ConstantsUtil.postTATforHOD,
                            new Notification_Template__mdt(
                                Bell_Notification__c = 'Bell for HOD <HODName> <ManagerName> <TeamLead> <caseNo>',
                                Email_Template__c    = 'Email for HOD <HODName> <ManagerName> <TeamLead> <caseNo>'
                            )
                           );
            Test.startTest();
            Database.executeBatch(new SHF_SendNotificationForTATsEscalation(), 50);
            Test.stopTest();
        }
    }
    @isTest
    static void testBatchExecute_ResponseAwaitedStatusCase1() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];
        //  Create AGM user
        User agmUser = createUser('agm', null, p.Id, null);
        //  Create Team Lead (reports to AGM)
        User teamLeadUser = createUser('teamLead', null, p.Id, agmUser.Id);
        //  Create Manager (reports to Team Lead)
        User mgrUser = createUser('mgr', null, p.Id, teamLeadUser.Id);
        //  Create Case Owner (reports to Manager)
        User ownerUser = createUser('owner', null, p.Id, mgrUser.Id);
        System.runAs(mgrUser) {
            // Create a Case owned by that user
            Case cs = new Case(
                Status = SHF_ConstantsUtil.RESPONSE_AWAITED_STATUS,
                Ticket_Type__c = 'Enquiry',
                Request_Type__c = 'EMI payment',
                Ticket_Sub_Type__c = 'Payments',
                Origin = SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE,
                OwnerId = ownerUser.Id,
                Sub_Source__c = 'Regulator\'s Emails',
                Subject = 'Case Escalated - Regulator',
                Send_Notification_4_hours__c = System.now().addMinutes(30),
                Actual_TAT_After_1__c = System.now().addMinutes(45),
                Actual_TAT_Before_1__c = System.now().addMinutes(50),
                Escalation_Notification_Date__c = System.now().addMinutes(-30),
                Actual_TAT_After_3__c = System.now().addMinutes(35),
                Actual_TAT__c   = System.now().addMinutes(43),
                Actual_TAT_After_4__c = System.now().addMinutes(55)
            );
            insert cs;
            //  Populate templateMap in test context (mock Custom Metadata)
            Map<String, Notification_Template__mdt> templateMap = new Map<String, Notification_Template__mdt>();
            templateMap.put('ResponseAwaited_from_Customer_ClosureSMS',
                            new Notification_Template__mdt(SMS_Notification__c = 'Bell for Manager <ManagerName> <TeamLead> <caseNo>'));
            
            // Assign AGM name (so String.isNotBlank(nameAGM) passes)
            String nameAGM = agmUser.FirstName;    
            Test.startTest();
            Database.executeBatch(new SHF_SendNotificationForTATsEscalation(), 50);
            Test.stopTest();
        }
    }
    // ====== HELPER: CREATE RESPONSE AWAITED CASE ======
    private static Case createResponseAwaitedCase(Boolean isDayOne) {
        Case cs = new Case(
            Status = SHF_ConstantsUtil.RESPONSE_AWAITED_STATUS,
            Ticket_Type__c = 'Complaint',
            Request_Type__c = 'Change in Personal Details',
            Ticket_Sub_Type__c = 'Change in Personal Details',
            OwnerId = UserInfo.getUserId()
        );
        insert cs;
        if (isDayOne) {
            Test.setCreatedDate(cs.Id, System.now().addDays(-1));
        } else {
            Test.setCreatedDate(cs.Id, System.now().addDays(-4));
        }
        return cs;
    }
}