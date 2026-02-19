/**
* @File Name          : SHF_SendNotificationForTATsEscalation.cls
* @Author             : Harshita Rathod
* @Last Modified By   : Harshita Rathod
* @Last Modified On   : 20-08-2025
* @Description        : 
* ================================================================================================
* Update Ver         Date           Author         Modification
* ================================================================================================
* 1.0               20-08-2025     Harshita Rathod   
*/
global class SHF_SendNotificationForTATsEscalation implements Database.Batchable<SObject>{
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        List<String> statusList = new List<String>{
            SHF_ConstantsUtil.NEW_STATUS,
                SHF_ConstantsUtil.WIP_STATUS,
                SHF_ConstantsUtil.ESCALATED_STATUS,
                SHF_ConstantsUtil.RESPONSE_AWAITED_STATUS
                };
                    
                    return Database.getQueryLocator([
                        SELECT Id, OwnerId, Actual_TAT__c, Owner.Name, CaseNumber, Subject, 
                        Send_Notification__c, Status, Contact_No_1__c, Customer_Name__c, Case_Owner_Name__c, SuppliedEmail, CreatedDate, 
                        Escalation_Notification_Date__c, Actual_TAT_After_1__c, Actual_TAT_After_4__c,
                        Actual_TAT_Before_1__c, Ticket_Sub_Type__c, Origin, Send_Notification_4_hours__c,  
                        Owner.UserRole.DeveloperName, AccountId, Account.PersonEmail 
                        FROM Case 
                        WHERE Status IN :statusList 
                        AND Send_Notification__c = true
                    ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Case> caseList) {
        
        List<Message_Service__e> msgServicelist = new List<Message_Service__e>();
        
        // Fetch all metadata records
        Map<String, Notification_Template__mdt> templateMap = Notification_Template__mdt.getAll();
        
        // Email template for apology
        EmailTemplate caseApologyemail = [
            SELECT Id, Body 
            FROM EmailTemplate 
            WHERE DeveloperName = :SHF_ConstantsUtil.apologyMessageEmail
            LIMIT 1
        ]; 
        Notification_Template__mdt caseAfterTATSms = [
            SELECT Id, DeveloperName, SMS_Notification__c
            FROM Notification_Template__mdt
            WHERE DeveloperName = :SHF_ConstantsUtil.apologySMS
        ];
        
        Notification_Template__mdt responseAwaitedClosureSMS = [
            SELECT Id, DeveloperName, SMS_Notification__c
            FROM Notification_Template__mdt
            WHERE DeveloperName = :SHF_ConstantsUtil.responseAwaitedClosureSMS
        ];
        
        Map<Id, String> mapOfManagerWithOwner = new Map<Id, String>();
        Id roleAGMId;
        String roleAGMEmail;
        Id roleHODId;
        String roleHODEmail;
        String nameHOD;
        String nameAGM;
        
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{ Case.SObjectType }
        );
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Case> updateCaseStatus = new List<Case>();
        
        try{
            List<User> listOfUsers = new SHF_UsersSelector()
                .selectActiveCustomerServiceUsers(SHF_ConstantsUtil.CUSTOMER_SERVICEPROFILE);
            Logger.info('listOfUsers size : ' + listOfUsers);
            //Fetch list of active users 
            if (!listOfUsers.isEmpty()) {
                for (User user : listOfUsers) {
                    if(user.ManagerId!=null){
                        mapOfManagerWithOwner.put(user.Id, user.ManagerId + '#' + user.Manager.Email + '#' + user.Manager.Name+ '#' + user.Phone + '#' + user.Email);
                    }
                    if(user.UserRole.DeveloperName == SHF_ConstantsUtil.AGM_ROLE){
                        roleAGMId = user.Id;
                        roleAGMEmail = user.Email;
                        nameAGM = user.Name;
                    }
                    if(user.UserRole.DeveloperName == SHF_ConstantsUtil.HOD_ROLE){
                        roleHODId = user.Id;
                        roleHODEmail = user.Email;
                        nameHOD = user.Name;
                    }
                }      
            }
            for (Case cs : caseList) {
                if (mapOfManagerWithOwner.containsKey(cs.OwnerId)) {
                    List<String> managerDetails = mapOfManagerWithOwner.get(cs.OwnerId).split('#');
                    List<Set<String>> sendNotificationTo = new List<Set<String>>();
                    List<String> managerEmail = new List<String>();
                    List<String> managerName= new List<String>();
                    String ownerEmail;
                    
                    //Added logic for TAT 4 hours
                    if (cs.Status == SHF_ConstantsUtil.NEW_STATUS) {
                        Long actualDiffTime = SHF_CommonUtil.calculateHours(cs.Send_Notification_4_hours__c, System.now());
                        Logger.info('Difference between TAT 4 hours and current time : '+ actualDiffTime);
                        
                        if(actualDiffTime >=1 && actualDiffTime  <=60){
                            Logger.info('Inside condition for TAT 4 hours logic for case number : ' + cs.CaseNumber);
                            sendNotificationTo.add(new Set<String>{managerDetails[0]}); // User's TeamLead notification Id
                            ownerEmail = managerDetails[4]; // Owner email for sending email to case owner
                            managerEmail.add(managerDetails[1]);  // User's Manager email
                            managerName.add(managerDetails[2]);
                            if(mapOfManagerWithOwner.containsKey(managerDetails[0])){
                                List<String> l2ManagerDetails = mapOfManagerWithOwner.get(managerDetails[0]).split('#');
                                 sendNotificationTo.add(new Set<String>{l2ManagerDetails[0]}); // User's Manager notification Id
                                    managerEmail.add(l2ManagerDetails[1]);   // User's TeamLead Email
                                	managerName.add(l2ManagerDetails[2]);    // User's TeamLead Name   
                            }
                            
                            if(cs.Ticket_Sub_Type__c == SHF_ConstantsUtil.STATEMENTS_TICKET_SUB_TYPE && cs.Origin == SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE){

                                if(!sendNotificationTo.isEmpty() && !managerEmail.isEmpty()){
                                    if(String.isNotBlank(managerName.get(0)) && String.isNotBlank(managerName.get(1)) && templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPforManager)  && !sendNotificationTo.get(1).contains(roleHODId) && !sendNotificationTo.get(1).contains(roleAGMId)){
                                        //Added Bell Notification logic for TAT 4 hours for Manager                          
                                        SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(1), cs.Id, Label.Reminder_Alert, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforManager).Bell_Notification__c
                                                                                 .replace('<ManagerName>', managerName.get(1))
                                                                                 .replace('<OwnerName>', cs.owner.name)
                                                                                 .replace('<caseNo>',cs.CaseNumber)
                                                                                 .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                        //Added Email logic for TAT 4 hours for Manager 
                                        emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(1)}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforManager).Email_Template__c
                                                                                        .replace('<ManagerName>', managerName.get(1))
                                                                                        .replace('<OwnerName>', cs.owner.name)
                                                                                        .replace('<caseNo>',cs.CaseNumber)
                                                                                        .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                        
                                    }
                                    if(String.isNotBlank(managerName.get(0)) && String.isNotBlank(managerName.get(1)) && templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead) && managerName.get(0) != managerName.get(1) && !sendNotificationTo.get(0).contains(roleHODId) && !sendNotificationTo.get(0).contains(roleAGMId)){
                                        //Added Bell Notification logic for TAT 4 hours for TeamLead and TeamLead name must be unique not same as manager name
                                        SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(0), cs.Id, Label.Reminder_Alert, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead).Bell_Notification__c
                                                                                 .replace('<ManagerName>', managerName.get(1))
                                                                                 .replace('<caseNo>',cs.CaseNumber)
                                                                                 .replace('<OwnerName>', cs.owner.name)
                                                                                 .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                        //Added Email logic for TAT 4 hours for TeamLead
                                        emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(0)}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead).Email_Template__c
                                                                                        .replace('<ManagerName>', managerName.get(1))
                                                                                        .replace('<caseNo>',cs.CaseNumber)
                                                                                        .replace('<OwnerName>', cs.owner.name)
                                                                                        .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                        
                                    }if(String.isNotBlank(managerName.get(0)) && String.isNotBlank(managerName.get(1)) && String.isNotBlank(nameAGM) && templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPforAGM)){
                                        //Added Bell Notification logic for TAT 4 hours for AGM
                                        SHF_CommonUtil.notifyUsersByNotification(new Set<String> {roleAGMId}, cs.Id, Label.Reminder_Alert, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforAGM).Bell_Notification__c
                                                                                 .replace('<AGMName>', nameAGM)
                                                                                 .replace('<caseNo>',cs.CaseNumber)
                                                                                 .replace('<OwnerName>', cs.owner.name)
                                                                                 .replace('<TeamLead>', managerName.get(0))
                                                                                 .replace('<ManagerName>',managerName.get(1)), System.Label.Send_Notification_To_User); 
                                        //Added Email logic for TAT 4 hours for AGM
                                        emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {roleAGMEmail}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforAGM).Email_Template__c
                                                                                        .replace('<AGMName>', nameAGM)
                                                                                        .replace('<caseNo>',cs.CaseNumber)
                                                                                        .replace('<OwnerName>', cs.owner.name)
                                                                                        .replace('<TeamLead>', managerName.get(0))
                                                                                        .replace('<ManagerName>',managerName.get(1)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                    }
                                }
                                
                            }else if(cs.Ticket_Sub_Type__c != SHF_ConstantsUtil.STATEMENTS_TICKET_SUB_TYPE && cs.Origin == SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE){
                               // if (managerEmail.contains(SHF_ConstantsUtil.HOD_EMAIL)) {
    							//managerEmail.remove(managerEmail.indexOf(SHF_ConstantsUtil.HOD_EMAIL));
							//}
                                if(templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPOwner) && cs.owner.name != managerName.get(0)){
                                    SHF_CommonUtil.notifyUsersByNotification(new Set<String>{cs.OwnerId}, cs.Id, Label.Reminder_Alert, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPOwner).Bell_Notification__c
                                                                             .replace('<SalesforceUserName>', cs.owner.name)
                                                                             .replace('<CaseNumber>',cs.CaseNumber), System.Label.Send_Notification_To_User);
                                    
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {ownerEmail}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPOwner).Email_Template__c
                                                                                    .replace('<SalesforceUserName>', cs.owner.name)
                                                                                    .replace('<CaseNumber>',cs.CaseNumber), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));    
                                }
                                
                                if(!sendNotificationTo.isEmpty() && !managerEmail.isEmpty()){
                              
                                    if(String.isNotBlank(managerName.get(0)) && String.isNotBlank(managerName.get(1)) && templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPforManager) && !sendNotificationTo.get(1).contains(roleHODId) && !sendNotificationTo.get(1).contains(roleAGMId)){
                                        //Added Bell Notification logic for TAT 4 hours for Manager
                                        SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(1), cs.Id, Label.Reminder_Alert, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforManager).Bell_Notification__c
                                                                                 .replace('<ManagerName>', managerName.get(1))
                                                                                 .replace('<OwnerName>', cs.owner.name)
                                                                                 .replace('<caseNo>',cs.CaseNumber)
                                                                                 .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                        //Added Email logic for TAT 4 hours for Manager 
                                        emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(1)}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforManager).Email_Template__c
                                                                                        .replace('<ManagerName>', managerName.get(1))
                                                                                        .replace('<OwnerName>', cs.owner.name)
                                                                                        .replace('<caseNo>',cs.CaseNumber)
                                                                                        .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                        
                                    }
                                    if(String.isNotBlank(managerName.get(0)) && String.isNotBlank(managerName.get(1)) && managerName.get(0) != managerName.get(1) && templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead) && !sendNotificationTo.get(0).contains(roleHODId) && !sendNotificationTo.get(0).contains(roleAGMId)){
                                        //Added Bell Notification logic for TAT 4 hours for TeamLead
                                        SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(0), cs.Id, Label.Reminder_Alert, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead).Bell_Notification__c
                                                                                 .replace('<ManagerName>', managerName.get(1))
                                                                                 .replace('<caseNo>',cs.CaseNumber)
                                                                                 .replace('<OwnerName>', cs.owner.name)
                                                                                 .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                        //Added Email logic for TAT 4 hours for TeamLead
                                        emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(0)}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead).Email_Template__c
                                                                                        .replace('<ManagerName>', managerName.get(1))
                                                                                        .replace('<caseNo>',cs.CaseNumber)
                                                                                        .replace('<OwnerName>', cs.owner.name)
                                                                                        .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                        
                                    }if(String.isNotBlank(managerName.get(0)) && String.isNotBlank(managerName.get(1)) && String.isNotBlank(nameAGM) && templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPforAGM)){
                                        //Added Bell Notification logic for TAT 4 hours for AGM
                                        SHF_CommonUtil.notifyUsersByNotification(new Set<String> {roleAGMId}, cs.Id, Label.Reminder_Alert, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforAGM).Bell_Notification__c
                                                                                 .replace('<AGMName>', nameAGM)
                                                                                 .replace('<caseNo>',cs.CaseNumber)
                                                                                 .replace('<OwnerName>', cs.owner.name)
                                                                                 .replace('<TeamLead>', managerName.get(0))
                                                                                 .replace('<ManagerName>',managerName.get(1)), System.Label.Send_Notification_To_User); 
                                        //Added Email logic for TAT 4 hours for AGM
                                        emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {roleAGMEmail}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforAGM).Email_Template__c
                                                                                        .replace('<AGMName>', nameAGM)
                                                                                        .replace('<caseNo>',cs.CaseNumber)
                                                                                        .replace('<OwnerName>', cs.owner.name)
                                                                                        .replace('<TeamLead>', managerName.get(0))
                                                                                        .replace('<ManagerName>',managerName.get(1)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                    }
                                }
                            }else if(cs.Ticket_Sub_Type__c == SHF_ConstantsUtil.STATEMENTS_TICKET_SUB_TYPE){

                                if(!sendNotificationTo.isEmpty() && !managerEmail.isEmpty()){
                                    if(String.isNotBlank(managerName.get(0)) && String.isNotBlank(managerName.get(1)) && templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPforManager) && !sendNotificationTo.get(1).contains(roleHODId)){
                                        //Added Bell Notification logic for TAT 4 hours for Manager
                                        SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(1), cs.Id, Label.Reminder_Alert, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforManager).Bell_Notification__c
                                                                                 .replace('<ManagerName>', managerName.get(1))
                                                                                 .replace('<OwnerName>', cs.owner.name)
                                                                                 .replace('<caseNo>',cs.CaseNumber)
                                                                                 .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                        //Added Email logic for TAT 4 hours for Manager 
                                        emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(1)}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforManager).Email_Template__c
                                                                                        .replace('<ManagerName>', managerName.get(1))
                                                                                        .replace('<OwnerName>', cs.owner.name)
                                                                                        .replace('<caseNo>',cs.CaseNumber)
                                                                                        .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                    }
                                    if(String.isNotBlank(managerName.get(0)) && String.isNotBlank(managerName.get(1)) && managerName.get(0) != managerName.get(1) && templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead) && !sendNotificationTo.get(0).contains(roleHODId) && !sendNotificationTo.get(0).contains(roleAGMId)){
                                        //Added Bell Notification logic for TAT 4 hours for TeamLead
                                        SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(0), cs.Id, Label.Reminder_Alert, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead).Bell_Notification__c
                                                                                 .replace('<ManagerName>', managerName.get(1))
                                                                                 .replace('<caseNo>',cs.CaseNumber)
                                                                                 .replace('<OwnerName>', cs.owner.name)
                                                                                 .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                        //Added Email logic for TAT 4 hours for TeamLead
                                        emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(0)}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead).Email_Template__c
                                                                                        .replace('<ManagerName>', managerName.get(1))
                                                                                        .replace('<caseNo>',cs.CaseNumber)
                                                                                        .replace('<OwnerName>', cs.owner.name)
                                                                                        .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                    }
                                }
                            }else{
                                if(templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPOwner) && cs.owner.name != managerName.get(0)){
                                     System.debug('INSIDE ELSE>>>');
                                    SHF_CommonUtil.notifyUsersByNotification(new Set<String>{cs.OwnerId}, cs.Id, Label.Reminder_Alert,  templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPOwner).Bell_Notification__c
                                                                             .replace('<SalesforceUserName>', cs.owner.name)
                                                                             .replace('<CaseNumber>',cs.CaseNumber), System.Label.Send_Notification_To_User);
                                     System.debug('Bell Notification>>>');
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {ownerEmail}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPOwner).Email_Template__c
                                                                                    .replace('<SalesforceUserName>', cs.owner.name)
                                                                                    .replace('<CaseNumber>',cs.CaseNumber), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                    
                                }
                                
                                if(String.isNotBlank(managerName.get(0)) && String.isNotBlank(managerName.get(1)) && templateMap.containsKey(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead) && !sendNotificationTo.get(0).contains(roleHODId)){
                                    //Added Bell Notification logic for TAT 4 hours for TeamLead
                                    //Change request for Team Lead - Reporting Manager AND Manager - Reporting Manager's Manager added on 04/10/25
                                    SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(0), cs.Id, Label.Reminder_Alert, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead).Bell_Notification__c
                                                                             .replace('<ManagerName>', managerName.get(1))
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                    System.debug('Send NotificationTo '+sendNotificationTo.get(0));
                                    //Added Email logic for TAT 4 hours for TeamLead
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(0)}, templateMap.get(SHF_ConstantsUtil.caseNotMovedToWIPforTeamLead).Email_Template__c
                                                                                    .replace('<ManagerName>', managerName.get(1))
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                           System.debug('manager email>>'+managerEmail);
                                    
                                }
                            }
                        }
                        
                    }else if (cs.Status == SHF_ConstantsUtil.WIP_STATUS) {
                        Long actualNotificationDiffTime = SHF_CommonUtil.calculateHours(cs.Escalation_Notification_Date__c,System.now());
                        Logger.info('Difference between notification date and current date : '+ actualNotificationDiffTime);
                        
                        Long actualTATBefore1DiffTime = SHF_CommonUtil.calculateHours(cs.Actual_TAT_Before_1__c,System.now());
                        Logger.info('Difference between TAT Before 1 day and current time : '+ actualTATBefore1DiffTime);
                        
                        if(actualNotificationDiffTime  >=1 && actualNotificationDiffTime  <=60 ){
                            Logger.info('Inside condition for Notification Date logic for case number : ' + cs.CaseNumber);
                            sendNotificationTo.add(new Set<String> {managerDetails[0]}); // User's Manager notification Id
                            managerEmail.add(managerDetails[1]);  // User's Manager email
                            managerName.add(managerDetails[2]);
                            
                            if(mapOfManagerWithOwner.containsKey(managerDetails[0])){
                                List<String> l2ManagerDetails = mapOfManagerWithOwner.get(managerDetails[0]).split('#');
                                sendNotificationTo.add(new Set<String>{l2ManagerDetails[0]}); // User's Manager Of Manger notification Id
                                managerEmail.add(l2ManagerDetails[1]);   // User's Manager Of Manger email
                                managerName.add(l2ManagerDetails[2]);
                            }  
                            
                            if(!sendNotificationTo.isEmpty()){
                                if(cs.Origin == SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE){
                                    if(String.isNotBlank(nameAGM)){
                                        //Added Bell Notification logic for Escalation Notification for AGM
                                        SHF_CommonUtil.notifyUsersByNotification(new Set<String> {roleAGMId}, cs.Id, Label.Periodic_Escalation_Reminder, templateMap.get(SHF_ConstantsUtil.periodicEscalationforAGM).Bell_Notification__c
                                                                                 .replace('<AGMName>', nameAGM)
                                                                                 .replace('<caseNo>',cs.CaseNumber)
                                                                                 .replace('<OwnerName>', cs.owner.name)
                                                                                 .replace('<TeamLead>', managerName.get(0))
                                                                                 .replace('<ManagerName>',managerName.get(1)), System.Label.Send_Notification_To_User); 
                                    
                                    }if(String.isNotBlank(nameHOD)){   
                                        //Added Bell Notification logic for Escalation Notification for HOD
                                        SHF_CommonUtil.notifyUsersByNotification(new Set<String> {roleHODId}, cs.Id, Label.Periodic_Escalation_Reminder, templateMap.get(SHF_ConstantsUtil.periodicEscalationforHOD).Bell_Notification__c
                                                                                 .replace('<HODName>', nameHOD)
                                                                                 .replace('<caseNo>',cs.CaseNumber)
                                                                                 .replace('<OwnerName>', cs.owner.name)
                                                                                 .replace('<TeamLead>', managerName.get(0))
                                                                                 .replace('<ManagerName>',managerName.get(1)), System.Label.Send_Notification_To_User); 
                                        
                                    }
                                if(String.isNotBlank(managerName.get(1)) && !sendNotificationTo.get(1).contains(roleHODId) && managerName.get(1) != nameAGM){
                                    //Added Bell Notification logic for Escalation Notification for Manager
                                    SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(1), cs.Id, Label.Periodic_Escalation_Reminder, templateMap.get(SHF_ConstantsUtil.periodicEscalationforManager).Bell_Notification__c
                                                                             .replace('<ManagerName>', managerName.get(1))
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                }
                                if(String.isNotBlank(managerName.get(0)) && managerName.get(1) != managerName.get(0) && !sendNotificationTo.get(0).contains(roleHODId) && managerName.get(0) != managerName.get(1)){
                                    //Added Bell Notification logic for Escalation Notification for Team Lead
                                    SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(0), cs.Id, Label.Periodic_Escalation_Reminder, templateMap.get(SHF_ConstantsUtil.periodicEscalationforTeamLead).Bell_Notification__c
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                    
                                }
                                }else{
                                    if(String.isNotBlank(managerName.get(1)) && !sendNotificationTo.get(1).contains(roleHODId)){
                                    //Added Bell Notification logic for Escalation Notification for Manager
                                    SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(1), cs.Id, Label.Periodic_Escalation_Reminder, templateMap.get(SHF_ConstantsUtil.periodicEscalationforManager).Bell_Notification__c
                                                                             .replace('<ManagerName>', managerName.get(1))
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                }
                                if(String.isNotBlank(managerName.get(0)) && managerName.get(1) != managerName.get(0) && !sendNotificationTo.get(0).contains(roleHODId)){
                                    //Added Bell Notification logic for Escalation Notification for Team Lead
                                    SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(0), cs.Id, Label.Periodic_Escalation_Reminder, templateMap.get(SHF_ConstantsUtil.periodicEscalationforTeamLead).Bell_Notification__c
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                    
                                }
                                }
                            }
                            
                            if(!managerEmail.isEmpty()){
                                if(cs.Origin == SHF_ConstantsUtil.REGULATORS_COMPLAINTS_SOURCE){
                                    if(String.isNotBlank(nameAGM)){
                                        //Added Email logic for Escalation Notification for AGM
                                        emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {roleAGMEmail}, templateMap.get(SHF_ConstantsUtil.periodicEscalationforAGM).Email_Template__c
                                                                                        .replace('<AGMName>', nameAGM)
                                                                                        .replace('<caseNo>',cs.CaseNumber)
                                                                                        .replace('<OwnerName>', cs.owner.name)
                                                                                        .replace('<TeamLead>', managerName.get(0))
                                                                                        .replace('<ManagerName>',managerName.get(1)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                    }
                                    if(String.isNotBlank(nameHOD)){
                                        //Added Email logic for Escalation Notification for HOD
                                        emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {roleHODEmail}, templateMap.get(SHF_ConstantsUtil.periodicEscalationforHOD).Email_Template__c
                                                                                        .replace('<HODName>', nameHOD)
                                                                                        .replace('<caseNo>',cs.CaseNumber)
                                                                                        .replace('<OwnerName>', cs.owner.name)
                                                                                        .replace('<TeamLead>', managerName.get(0))
                                                                                        .replace('<ManagerName>',managerName.get(1)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                    }
                                if(String.isNotBlank(managerName.get(1)) && !sendNotificationTo.get(1).contains(roleHODId) && managerName.get(1) != nameAGM){
                                    //Added Email logic for Escalation Notification for Manager
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(1)}, templateMap.get(SHF_ConstantsUtil.periodicEscalationforManager).Email_Template__c
                                                                                    .replace('<ManagerName>', managerName.get(1))
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                                if(String.isNotBlank(managerName.get(0)) && managerName.get(1) != managerName.get(0) && !sendNotificationTo.get(0).contains(roleHODId) && managerName.get(0) != nameAGM){
                                    //Added Email logic for Escalation Notification for TeamLead
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(0)}, templateMap.get(SHF_ConstantsUtil.periodicEscalationforTeamLead).Email_Template__c
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                                }else{
                                    if(String.isNotBlank(managerName.get(1)) && !sendNotificationTo.get(1).contains(roleHODId)){
                                    //Added Email logic for Escalation Notification for Manager
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(1)}, templateMap.get(SHF_ConstantsUtil.periodicEscalationforManager).Email_Template__c
                                                                                    .replace('<ManagerName>', managerName.get(1))
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                                    if(String.isNotBlank(managerName.get(0)) && managerName.get(1) != managerName.get(0) && !sendNotificationTo.get(0).contains(roleHODId)){
                                    //Added Email logic for Escalation Notification for TeamLead
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(0)}, templateMap.get(SHF_ConstantsUtil.periodicEscalationforTeamLead).Email_Template__c
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                                }
                            }   
                            
                        } else if(actualTATBefore1DiffTime  >=1 && actualTATBefore1DiffTime  <=60 ){  
                            Logger.info('Inside condition for TAT Before 1 Day logic for case number : ' + cs.CaseNumber);
                            sendNotificationTo.add(new Set<String> {managerDetails[0]}); // User's Manager notification Id
                            managerEmail.add(managerDetails[1]);  // User's Manager email
                            managerName.add(managerDetails[2]);
                            if(mapOfManagerWithOwner.containsKey(managerDetails[0])){
                                List<String> l2ManagerDetails = mapOfManagerWithOwner.get(managerDetails[0]).split('#');
                                sendNotificationTo.add(new Set<String> {l2ManagerDetails[0]}); // User's Manager Of Manger notification Id
                                managerEmail.add(l2ManagerDetails[1]);   // User's TeamLead email
                                managerName.add(l2ManagerDetails[2]);
                            }

                            if(!sendNotificationTo.isEmpty()){
                                if(String.isNotBlank(managerName.get(1)) && !sendNotificationTo.get(1).contains(roleHODId) && managerName.get(1) != nameAGM){
                                    //Added Bell Notification logic for Pre-TAT (TAT Before 1) for Manager
                                    SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(1), cs.Id, Label.Pre_TAT_Reminder, templateMap.get(SHF_ConstantsUtil.preTATforManager).Bell_Notification__c
                                                                             .replace('<ManagerName>', managerName.get(1))
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                             .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                }
                                if(String.isNotBlank(managerName.get(0)) && managerName.get(0) != managerName.get(1) && !sendNotificationTo.get(0).contains(roleHODId) && managerName.get(0) != managerName.get(1)){
                                    //Added Bell Notification logic for Pre-TAT (TAT Before 1) for TeamLead
                                    SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(0), cs.Id, Label.Pre_TAT_Reminder, templateMap.get(SHF_ConstantsUtil.preTATforTeamLead).Bell_Notification__c
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                             .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                    
                                }if(String.isNotBlank(nameAGM)){
                                    //Added Bell Notification logic for Pre-TAT (TAT Before 1) for AGM
                                    SHF_CommonUtil.notifyUsersByNotification(new Set<String> {roleAGMId}, cs.Id, Label.Pre_TAT_Reminder, templateMap.get(SHF_ConstantsUtil.preTATforAGM).Bell_Notification__c
                                                                             .replace('<AGMName>', nameAGM)
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                             .replace('<TeamLead>', managerName.get(0))
                                                                             .replace('<ManagerName>',managerName.get(1)), System.Label.Send_Notification_To_User); 
                                }if(String.isNotBlank(nameHOD)){   
                                    //Added Bell Notification logic for Pre-TAT (TAT Before 1) for HOD
                                    SHF_CommonUtil.notifyUsersByNotification(new Set<String> {roleHODId}, cs.Id, Label.Pre_TAT_Reminder, templateMap.get(SHF_ConstantsUtil.preTATforHOD).Bell_Notification__c
                                                                             .replace('<HODName>', nameHOD)
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                             .replace('<TeamLead>', managerName.get(0))
                                                                             .replace('<ManagerName>',managerName.get(1)), System.Label.Send_Notification_To_User); 
                                }
                            }
                            
                            if(!managerEmail.isEmpty()){
                                if(String.isNotBlank(managerName.get(1)) && !sendNotificationTo.get(1).contains(roleHODId) && managerName.get(1) != nameAGM){
                                    //Added Email logic for Pre-TAT (TAT Before 1) for Manager
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(1)}, templateMap.get(SHF_ConstantsUtil.preTATforManager).Email_Template__c
                                                                                    .replace('<ManagerName>', managerName.get(1))
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                                    .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                                if(String.isNotBlank(managerName.get(0)) && managerName.get(0) != managerName.get(1) && !sendNotificationTo.get(0).contains(roleHODId) && managerName.get(0) != nameAGM){
                                    //Added Email logic for Pre-TAT (TAT Before 1) for TeamLead
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(0)}, templateMap.get(SHF_ConstantsUtil.preTATforTeamLead).Email_Template__c
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                                    .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                                if(String.isNotBlank(nameAGM)){
                                    //Added Email logic for Pre-TAT (TAT Before 1) for AGM
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {roleAGMEmail}, templateMap.get(SHF_ConstantsUtil.preTATforAGM).Email_Template__c
                                                                                    .replace('<AGMName>', nameAGM)
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<TeamLead>', managerName.get(0))
                                                                                    .replace('<ManagerName>',managerName.get(1)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                                if(String.isNotBlank(nameHOD)){
                                    //Added Email logic for Pre-TAT (TAT Before 1) for HOD
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {roleHODEmail}, templateMap.get(SHF_ConstantsUtil.preTATforHOD).Email_Template__c
                                                                                    .replace('<HODName>', nameHOD)
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                                    .replace('<TeamLead>', managerName.get(0))
                                                                                    .replace('<ManagerName>',managerName.get(1)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                            }
                            
                            updateCaseStatus.add(new Case(Id = cs.Id, Status= SHF_ConstantsUtil.ESCALATED_STATUS));   
                        }                    
                    }else if (cs.Status == SHF_ConstantsUtil.ESCALATED_STATUS) {
                        
                        Long actualDiffTime = SHF_CommonUtil.calculateHours(cs.Actual_TAT_After_1__c, System.now());
                        Logger.info('Difference between TAT After 1 day and current time : '+ actualDiffTime);
                        
                        if(actualDiffTime  >=1 && actualDiffTime  <=60 ){ 
                            Logger.info('Inside condition for TAT After 1 Day logic for case number : ' + cs.CaseNumber);
                            String teamLeadName;
                            sendNotificationTo.add(new Set<String> {managerDetails[0]}); // User's Manager notification Id
                            managerEmail.add(managerDetails[1]);  // User's Manager email
                            managerName.add(managerDetails[2]);
                            
                            if(mapOfManagerWithOwner.containsKey(managerDetails[0])){
                                List<String> l2ManagerDetails = mapOfManagerWithOwner.get(managerDetails[0]).split('#');
                                sendNotificationTo.add(new Set<String> {l2ManagerDetails[0]}); // User's Manager Of Manger notification Id
                                managerEmail.add(l2ManagerDetails[1]);   // User's TeamLead email
                                teamLeadName = l2ManagerDetails[2]; // User's TeamLead name
                                managerName.add(l2ManagerDetails[2]);
                            }                 
                            
                            if(!sendNotificationTo.isEmpty()){
                                if(String.isNotBlank(managerName.get(1)) && !sendNotificationTo.get(1).contains(roleHODId) && managerName.get(1) != nameAGM){
                                    //Added Bell Notification logic for TAT After 1(TAT+1) for Manager
                                    SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(1), cs.Id, Label.Urgent_Escalation_Alert, templateMap.get(SHF_ConstantsUtil.postTATforManager).Bell_Notification__c
                                                                             .replace('<ManagerName>', managerName.get(1))
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                             .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                }
                                if(String.isNotBlank(managerName.get(0)) && managerName.get(0) != managerName.get(1) && !sendNotificationTo.get(0).contains(roleHODId) && managerName.get(0) != nameAGM){
                                    //Added Bell Notification logic for TAT After 1(TAT+1) for TeamLead
                                    SHF_CommonUtil.notifyUsersByNotification(sendNotificationTo.get(0), cs.Id, Label.Urgent_Escalation_Alert, templateMap.get(SHF_ConstantsUtil.postTATforTeamLead).Bell_Notification__c
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                             .replace('<TeamLead>', managerName.get(0)), System.Label.Send_Notification_To_User);
                                    
                                }if(String.isNotBlank(nameAGM)){
                                    //Added Bell Notification logic for TAT After 1(TAT+1) for AGM
                                    SHF_CommonUtil.notifyUsersByNotification(new Set<String> {roleAGMId}, cs.Id, Label.Urgent_Escalation_Alert, templateMap.get(SHF_ConstantsUtil.postTATforAGM).Bell_Notification__c
                                                                             .replace('<AGMName>', nameAGM)
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                             .replace('<TeamLead>', managerName.get(0))
                                                                             .replace('<ManagerName>',managerName.get(1)), System.Label.Send_Notification_To_User); 
                                }if(String.isNotBlank(nameHOD)){   
                                    //Added Bell Notification logic for TAT After 1(TAT+1) for HOD
                                    SHF_CommonUtil.notifyUsersByNotification(new Set<String> {roleHODId}, cs.Id, Label.Urgent_Escalation_Alert, templateMap.get(SHF_ConstantsUtil.postTATforHOD).Bell_Notification__c
                                                                             .replace('<HODName>', nameHOD)
                                                                             .replace('<caseNo>',cs.CaseNumber)
                                                                             .replace('<OwnerName>', cs.owner.name)
                                                                             .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                             .replace('<TeamLead>', managerName.get(0))
                                                                             .replace('<ManagerName>',managerName.get(1)), System.Label.Send_Notification_To_User); 
                                }
                            }
                            
                            if(!managerEmail.isEmpty()){
                                if(String.isNotBlank(managerName.get(1)) && !sendNotificationTo.get(1).contains(roleHODId) && managerName.get(1) != nameAGM){
                                    //Added Email logic for TAT After 1 (TAT+1) for Manager
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(1)}, templateMap.get(SHF_ConstantsUtil.postTATforManager).Email_Template__c
                                                                                    .replace('<ManagerName>', managerName.get(1))
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                                    .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                                if(String.isNotBlank(managerName.get(0)) && managerName.get(0) != managerName.get(1) && !sendNotificationTo.get(0).contains(roleHODId) && managerName.get(0) != nameAGM){
                                    //Added Email logic for TAT After 1 (TAT+1) for TeamLead
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {managerEmail.get(0)}, templateMap.get(SHF_ConstantsUtil.postTATforTeamLead).Email_Template__c
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                                    .replace('<TeamLead>', managerName.get(0)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                                if(String.isNotBlank(nameAGM)){
                                    //Added Email logic for TAT After 1 (TAT+1) for AGM
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {roleAGMEmail}, templateMap.get(SHF_ConstantsUtil.postTATforAGM).Email_Template__c
                                                                                    .replace('<AGMName>', nameAGM)
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<TeamLead>', managerName.get(0))
                                                                                    .replace('<ManagerName>',managerName.get(1)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                                if(String.isNotBlank(nameHOD)){
                                    //Added Email logic for TAT After 1 (TAT+1) for HOD
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String> {roleHODEmail}, templateMap.get(SHF_ConstantsUtil.postTATforHOD).Email_Template__c
                                                                                    .replace('<HODName>', nameHOD)
                                                                                    .replace('<caseNo>',cs.CaseNumber)
                                                                                    .replace('<OwnerName>', cs.owner.name)
                                                                                    .replace('<Date>',String.valueOf(cs.Actual_TAT__c.date()))
                                                                                    .replace('<TeamLead>', managerName.get(0))
                                                                                    .replace('<ManagerName>',managerName.get(1)), 'Case #'+ cs.CaseNumber +' - '+cs.Subject, SHF_ConstantsUtil.CASE_DISPLAY_NAME));
                                }
                            }
                            
                            if(String.isNotBlank(cs.SuppliedEmail) || (cs.AccountId != null && String.isNotBlank(cs.Account.PersonEmail))){
                                List<String> customerEmailList = new List<String>();
                                if(String.isNotBlank(cs.SuppliedEmail)){
                                    customerEmailList.add(cs.SuppliedEmail);
                                }else{
                                    customerEmailList.add(cs.Account.PersonEmail);
                                }
                                if(!customerEmailList.isEmpty()){
                                    emails.addAll(SHF_CommonUtil.notifyingUsersByEmail(customerEmailList, caseApologyemail.Id, cs.id));
                                }
                            }
                            
                            if(!String.isBlank(cs.Contact_No_1__c)){ 
                                msgServicelist.add(new Message_Service__e(
                                    Receiver__c	= cs.Contact_No_1__c,
                                    Message_Template__c = SHF_CommonUtil.formatSMSTemplate(caseAfterTATSms.SMS_Notification__c).replace('<customerName>', cs.Customer_Name__c)
                                    .replace('<casenumber>', cs.CaseNumber).replace('<contactno.>', managerDetails[3]).replace('<contactname>', cs.Case_Owner_Name__c)
                                ));
                                //Send whatsapp message
                                msgServicelist.add(new Message_Service__e(
                                    Receiver__c = cs.Contact_No_1__c,
                                    Message_Template__c = SHF_ConstantsUtil.apology_message_outoftat,
                                    WhatsApp_Placeholders__c = new List<String> {cs.Customer_Name__c, cs.CaseNumber, cs.Case_Owner_Name__c, managerDetails[3]}.toString()
                                )); 
                            }
                        }
                    }
                    // Check Actual TAT+4days for Response Awaited status
                    else if (cs.Status == SHF_ConstantsUtil.RESPONSE_AWAITED_STATUS) {
                        Long tatOver4Days = SHF_CommonUtil.calculateHours(cs.Actual_TAT_After_4__c, System.now());
                        Logger.info('Difference between TAT After 4 day and current time : '+ tatOver4Days);
                        
                        if(tatOver4Days  >=1 && tatOver4Days  <=60 ){
                            Logger.info('Inside condition for TAT After 4 Day logic for case number : ' + cs.CaseNumber);
                            if(!String.isBlank(cs.Contact_No_1__c)){
                                msgServicelist.add(new Message_Service__e(
                                    Receiver__c	= cs.Contact_No_1__c,
                                    Message_Template__c = SHF_CommonUtil.formatSMSTemplate(responseAwaitedClosureSMS.SMS_Notification__c).replace('<customerName>', cs.Customer_Name__c)
                                    .replace('<casenumber>', cs.CaseNumber)
                                ));
                                //Send whatsapp message
                                msgServicelist.add(new Message_Service__e(
                                    Receiver__c = cs.Contact_No_1__c,
                                    Message_Template__c = SHF_ConstantsUtil.rac_closure_sms,
                                    WhatsApp_Placeholders__c = new List<String> {cs.Customer_Name__c, cs.CaseNumber, cs.CaseNumber}.toString()
                                ));  
                            }
                            updateCaseStatus.add(new Case(Id = cs.Id, Status= SHF_ConstantsUtil.RESOLVED_STATUS));   
                        }
                    }            
                }
                
            }
            
            if (!updateCaseStatus.isEmpty()) {
                Logger.info('Updating ' + updateCaseStatus + ' case(s)');
                uow.registerDirty(updateCaseStatus);
            } 
            if (!msgServicelist.isEmpty()) {
                EventBus.publish(msgServicelist);
            }
            
            // Commit transaction
            uow.commitWork();
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
                Logger.info('Emails sent successfully');
            }
            
        }catch (Exception e) {
            Logger.error('Error in SHF_SendNotificationForTATsEscalation: ' + e.getMessage() + e.getLineNumber());
        }finally{
            Logger.saveLog();
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        Logger.info('FINISH method SHF_SendNotificationForTATsEscalation completed');
    }
}