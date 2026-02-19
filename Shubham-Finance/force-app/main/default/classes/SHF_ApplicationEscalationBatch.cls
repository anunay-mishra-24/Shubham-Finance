global class SHF_ApplicationEscalationBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        return Database.getQueryLocator([
            SELECT Id,
            Name,
            OwnerId,
            Owner.Name,
            Application_Stage__c,
            Application_Status__c,
            CreatedDate,
            Send_Notification__c,
            L2_Escalation__c,
            L3_Escalation__c,
            L4_Escalation__c,
Contact_No1__c
            FROM Application__c
            WHERE Send_Notification__c = true AND Application_Status__c =  :SHF_ConstantsUtil.ACTIVE_STATUS
        ]);
    }
    
    
    global void execute(Database.BatchableContext bc, List<Application__c> appList) {
        if (appList.isEmpty()) {
            return;
        }
        
        try {
          //  List<Message_Service__e> msgEvents = new List<Message_Service__e>();
  List<Message_Service__e> msgServicelist = new List<Message_Service__e>();
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            Map<String, Notification_Template__mdt> templateMap =
                Notification_Template__mdt.getAll();
            
            fflib_SObjectUnitOfWork uow =
                new fflib_SObjectUnitOfWork(new List<SObjectType>{ Application__c.SObjectType });
            
            //Fetch Users & Managers 
           /* List<User> users =
                new SHF_UsersSelector().selectActiveCustomerServiceUsers(
                    SHF_ConstantsUtil.SALES_PROFILE,
                );*/
List<User> users =
    new SHF_UsersSelector().selectActiveCustomerServiceUsers(
        new Set<String>{
            SHF_ConstantsUtil.SALES_PROFILE,
            SHF_ConstantsUtil.CREDIT_PROFILE
        }
    );
            
            Map<String, String> userMap = new Map<String, String>();
            
            for (User u : users) {
                if (u.ManagerId != null) {
                    userMap.put(
                        u.Id,
                        u.ManagerId + '#' +
                        u.Manager.Email + '#' +
                        u.Manager.Name + '#' +
                        u.Manager.Phone
                    );
                }
            }
            for (Application__c app : appList) {
                
                Long diffL2 = app.L2_Escalation__c != null
                    ? SHF_CommonUtil.calculateHours(app.L2_Escalation__c, System.now())
                    : 0;
                
                Long diffL3 = app.L3_Escalation__c != null
                    ? SHF_CommonUtil.calculateHours(app.L3_Escalation__c, System.now())
                    : 0;
                
                Long diffL4 = app.L4_Escalation__c != null
                    ? SHF_CommonUtil.calculateHours(app.L4_Escalation__c, System.now())
                    : 0;
                
                if (!userMap.containsKey(app.OwnerId)) {
                    continue;
                }
                
                if(SHF_ConstantsUtil.QDEList.contains(app.Application_Stage__c)){
                    List<String> l2Details = userMap.get(app.OwnerId).split('#');
                    String l3ManagerId = '';
                    String l3ManagerEmail = '';
                    String l4ManagerId = '';
                    String l4ManagerEmail = '';
                    
                    // L2 Escalation
                    if (diffL2 >= 1 && diffL2 <= 60 &&
                        templateMap.containsKey('Application_Escalation_Notification')) {
                            String bellTemplate =
                                templateMap.get('Application_Escalation_Notification')
                                .Bell_Notification__c
                                .replace('<recipientName>', app.Owner.Name)
                                .replace('<ApplicationName>', app.Name)
                                .replace('<OwnerName>', app.Owner.Name)
                                .replace('<ApplicantionStage>', app.Application_Stage__c);
                            
                            SHF_CommonUtil.notifyUsersByNotification(
                                new Set<String>{ l2Details[0] },
                                app.Id,
                                Label.Application_Escalation_Reminder,
                                bellTemplate,
                                System.Label.Send_Notification_To_User
                            );
                            
                            if (String.isNotBlank(l2Details[1])) {
                                emails.addAll(
                                    SHF_CommonUtil.notifyUsersByEmailHTMLApplication(
                                        new List<String>{ l2Details[1] },
                                        templateMap.get('Application_Escalation_Notification')
                                        .Email_Template__c
                                        .replace('<recipientName>', l2Details[2])
                                        .replace('<ApplicationName>', app.Name)
                                        .replace('<OwnerName>', app.Owner.Name)
                                        .replace('<ApplicantionStage>', app.Application_Stage__c),
                                        //SHF_ConstantsUtil.APPLICATION_Escalation + ' (L1) - ' + app.Name,
SHF_ConstantsUtil.APPLICATION_Escalation,
                                        SHF_ConstantsUtil.CASE_DISPLAY_NAME
                                    ));                            
                            }
// -------- L2 WhatsApp Escalation --------
if (String.isNotBlank(l2Details[3])) {
    msgServicelist.add(
        new Message_Service__e(
            Receiver__c = l2Details[3],
            Message_Template__c = SHF_ConstantsUtil.ESCALATION_REMINDER,
            WhatsApp_Placeholders__c =
                new List<String>{
                    l2Details[2] != null ? l2Details[2] : '', // Manager Name
                    app.Owner.Name,
                    app.Name,
                    String.valueOf(app.CreatedDate),
                    String.valueOf(System.now()),
                    app.Contact_No1__c
                }.toString()
        )
    );
}

                        }
                    
                    // L3 Escalation
                    if (userMap.containsKey(l2Details[0])) {                    
                        List<String> l3Details = userMap.get(l2Details[0]).split('#');
                        l3ManagerId = l3Details[0];
                        l3ManagerEmail = l3Details[1];
                        
                        if (diffL3 >= 1 && diffL3 <= 60) {                        
                            String bellTemplate =
                                templateMap.get('Application_Escalation_Notification')
                                .Bell_Notification__c
                                .replace('<recipientName>', app.Owner.Name)
                                .replace('<ApplicationName>', app.Name)
                                .replace('<OwnerName>', app.Owner.Name)
                                .replace('<ApplicantionStage>', app.Application_Stage__c);
                            
                            SHF_CommonUtil.notifyUsersByNotification(
                                new Set<String>{ l3ManagerId },
                                app.Id,
                                Label.Application_Escalation_Reminder,
                                bellTemplate,
                                System.Label.Send_Notification_To_User
                            );
                            
                            if (String.isNotBlank(l3ManagerEmail)) {
                                emails.addAll(
                                    SHF_CommonUtil.notifyUsersByEmailHTMLApplication(
                                        new List<String>{ l3ManagerEmail },
                                        templateMap.get('Application_Escalation_Notification')
                                        .Email_Template__c
                                        .replace('<recipientName>', l3Details[2])
                                        .replace('<ApplicationName>', app.Name)
                                        .replace('<OwnerName>', app.Owner.Name)
                                        .replace('<ApplicantionStage>', app.Application_Stage__c),
                                       // SHF_ConstantsUtil.APPLICATION_Escalation + ' (L2) - ' + app.Name,
SHF_ConstantsUtil.APPLICATION_Escalation,
                                        SHF_ConstantsUtil.CASE_DISPLAY_NAME
                                    ));                            
                            }
// -------- L3 WhatsApp Escalation --------
if (String.isNotBlank(l3Details[3])) {
    msgServicelist.add(
        new Message_Service__e(
            Receiver__c = l3Details[3],
            Message_Template__c = SHF_ConstantsUtil.ESCALATION_REMINDER,
            WhatsApp_Placeholders__c =
                new List<String>{
                    l3Details[2] != null ? l3Details[2] : '', // L3 Manager Name
                    app.Owner.Name,
                    app.Name,
                    String.valueOf(app.CreatedDate),
                    String.valueOf(System.now()),
                    app.Contact_No1__c
                }.toString()
        )
    );
}

                        }
                    }
                    
                    // L4 Escalation 
                    if (String.isNotBlank(l3ManagerId) &&
                        userMap.containsKey(l3ManagerId)) {                        
                            List<String> l4Details = userMap.get(l3ManagerId).split('#');
                            l4ManagerId = l4Details[0];
                            l4ManagerEmail = l4Details[1];
 if (userMap.containsKey(l2Details[0])) {                    
                        List<String> l3Details = userMap.get(l2Details[0]).split('#');
                        l3ManagerId = l3Details[0];
                        l3ManagerEmail = l3Details[1];
                            
                            if (diffL4 >= 1 && diffL4 <= 60) {                            
                                String bellTemplate =
                                    templateMap.get('Application_Escalation_Notification')
                                    .Bell_Notification__c
                                    .replace('<recipientName>', app.Owner.Name)
                                    .replace('<ApplicationName>', app.Name)
                                    .replace('<OwnerName>', app.Owner.Name)
                                    .replace('<ApplicantionStage>', app.Application_Stage__c);
                                
                                SHF_CommonUtil.notifyUsersByNotification(
                                    new Set<String>{ l3ManagerId },
                                    app.Id,
                                    Label.Application_Escalation_Reminder,
                                    bellTemplate,
                                    System.Label.Send_Notification_To_User
                                );
                                
                                if (String.isNotBlank(l3ManagerEmail)) {
                                    emails.addAll(
                                        SHF_CommonUtil.notifyUsersByEmailHTMLApplication(
                                            new List<String>{ l3ManagerEmail },
                                            templateMap.get('Application_Escalation_Notification')
                                            .Email_Template__c
                                            .replace('<recipientName>', l3Details[2])
                                            .replace('<ApplicationName>', app.Name)
                                            .replace('<OwnerName>', app.Owner.Name)
                                            .replace('<ApplicantionStage>', app.Application_Stage__c),
                                           // SHF_ConstantsUtil.APPLICATION_Escalation + ' (L3) - ' + app.Name,
SHF_ConstantsUtil.APPLICATION_Escalation,
                                            SHF_ConstantsUtil.CASE_DISPLAY_NAME
                                        ));                            
                                }
// -------- L4 WhatsApp Escalation --------
if (String.isNotBlank(l4Details[3])) {
    msgServicelist.add(
        new Message_Service__e(
            Receiver__c = l4Details[3],
            Message_Template__c = SHF_ConstantsUtil.ESCALATION_REMINDER,
            WhatsApp_Placeholders__c =
                new List<String>{
                    l4Details[2] != null ? l4Details[2] : '', // L4 Manager Name
                    app.Owner.Name,
                    app.Name,
                    String.valueOf(app.CreatedDate),
                    String.valueOf(System.now()),
                    app.Contact_No1__c
                }.toString()
        )
    );
}

                            }
                        }
                } 
            }
            }
            
               // Publish platform events for WhatsApp
            if (!msgServicelist.isEmpty()) {
                EventBus.publish(msgServicelist);
                Logger.info('Published WhatsApp escalation events'+ new Map<String,Object>{ 'Count' => msgServicelist.size() });
            }
            
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
            
           /* if (!msgEvents.isEmpty()) {
                EventBus.publish(msgEvents);
            }*/
            
            uow.commitWork();
            
        } catch (Exception e) {
            Logger.error('Error in Application Escalation Batch: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('SHF_ApplicationEscalationBatch completed successfully.');
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SHF_ApplicationEscalationBatch(), 200);
    }
    
    
}