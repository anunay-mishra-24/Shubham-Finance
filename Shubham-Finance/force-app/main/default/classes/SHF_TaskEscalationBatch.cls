/**
* Batch Class Name      : SHF_TaskEscalationBatch
* Author                : Riteek Tiwari
* Created On            : 25-08-2025
* Description           : Sends escalations for Tasks via WhatsApp/SMS and notifications to managers L2/L3/L4 .
*/
global class SHF_TaskEscalationBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Subject, Status, Send_Notification__c, WhatId, OwnerId, ActivityDate, Owner.Name,
            L2_Escalation__c, L3_Escalation__c, L4_Escalation__c
            FROM Task WHERE Send_Notification__c = true AND ActivityDate != NULL AND WhatId != NULL AND Status =: SHF_ConstantsUtil.OPEN_STATUS
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Task> taskList) {
        try{
            if (taskList.isEmpty()) {
                return;
            }
            
            Map<String, Notification_Template__mdt> templateMap = Notification_Template__mdt.getAll();
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Task.SObjectType });
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            Set<Id> leadIdSet = new Set<Id>();
            
            // Fetch active business hours and store in map for quick access
            Map<String, Id> bhMap = new Map<String, Id>();
            for (BusinessHours bh : [SELECT Id, Name FROM BusinessHours WHERE IsActive = true]) {
                bhMap.put(bh.Name.toLowerCase(), bh.Id);
            }
            
            // Fetch users with their managers
            List<User> userList = new SHF_UsersSelector().selectActiveCustomerServiceUsers(SHF_ConstantsUtil.SALES_PROFILE);
            
            Map<String, String> userMap = new Map<String, String>();
            for (User usr : userList) {
                if (usr.ManagerId != null) {
                    userMap.put(usr.Id, usr.ManagerId + '#' + usr.Manager.Email + '#' + usr.Manager.Name + '#' + usr.Manager.Phone);
                }
            }
            // Collect all WhatIds from tasks
            for (Task tsk : taskList) {
                leadIdSet.add(tsk.WhatId);
            }
            // Fetch Leads with Branch and Owner details
            List<Lead__c> leadList = new SHF_LeadSelector().selectByIdsWithBranchName(leadIdSet);
            // Map: LeadId, Lead details (Name,OwnerName,BranchName,FullName,ContactNo)
            Map<String,String> mapOfLead = new Map<String,String>();
            if(leadList.size()>0){
                for(Lead__c leads : leadList ) {
                    if(String.IsNotBlank(leads.Lead_Status__c) &&  leads.Lead_Status__c == SHF_ConstantsUtil.ACTIVE_LEAD_STATUS){
                        mapOfLead.put(leads.Id, leads.Name + '#' + leads.Owner.Name + '#' + leads.Branch__r.Name + '#' + leads.Full_Name__c + '#' + leads.Contact_No1__c);
                    }
                }
            }
            // Iterate through each lead and check escalation conditions
            for (Task tsk : taskList) {
                if(mapOfLead.keySet().Size() > 0 && mapOfLead.ContainsKey(tsk.WhatId)){
                    Long actualDiffTimeL2 = tsk.L2_Escalation__c != null ? SHF_CommonUtil.calculateHours(tsk.L2_Escalation__c, System.now()) : 0;
                    Long actualDiffTimeL3 = tsk.L3_Escalation__c != null ? SHF_CommonUtil.calculateHours(tsk.L3_Escalation__c, System.now()) : 0;
                    Long actualDiffTimeL4 = tsk.L4_Escalation__c != null ? SHF_CommonUtil.calculateHours(tsk.L4_Escalation__c, System.now()) : 0;
                    
                    if (userMap.containsKey(tsk.OwnerId)) {
                        List<String> managerDetails = userMap.get(tsk.OwnerId).split('#');
                        String L4ManagerId = '';
                        
                        // =============== L2 Escalation ====================
                        // Notify direct manager of Lead Owner
                        if (actualDiffTimeL2 >= 1 && actualDiffTimeL2 <= 60 && templateMap.containsKey(SHF_ConstantsUtil.TASK_ESCALTE_TO_L1MANAGER)) {
                            // Prepare bell notification
                            String template = templateMap.get(SHF_ConstantsUtil.TASK_ESCALTE_TO_L1MANAGER).Bell_Notification__c
                                .replace('<TaskOwnerName>', (tsk.Owner.Name != null) ? tsk.Owner.Name : '');
                            
                            SHF_CommonUtil.notifyUsersByNotification(new Set<String>{managerDetails[0]}, tsk.Id, Label.Task_Escalation_Reminder, template, System.Label.Send_Notification_To_User );
                            // Send escalation email
                            if (String.isNotBlank(managerDetails[1])) {
                                System.debug('DEBUG: Sending Email for L2 escalation to ' + managerDetails[1]);
                                emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String>{ managerDetails[1] },
                                                                                templateMap.get(SHF_ConstantsUtil.TASK_ESCALTE_TO_L1MANAGER).Email_Template__c
                                                                                .replace('<recipientName>', managerDetails[2])
                                                                                .replace('<relatedToOwnerName>', (tsk.Owner.Name != null) ? tsk.Owner.Name : '')
                                                                                .replace('<leadName>', (mapOfLead.get(tsk.WhatId) != null) ?  mapOfLead.get(tsk.WhatId).split('#')[0] : '')
                                                                                .replace('<taskStatus>', (tsk.Status != null) ? tsk.Status : ''),
                                                                                SHF_ConstantsUtil.TASK_Escalation + ' - ' + tsk.Subject,
                                                                                SHF_ConstantsUtil.CASE_DISPLAY_NAME
                                                                               ));
                            }
                        }
                        
                        // =============== L3 Escalation ====================
                        // Notify manager’s manager (L3)
                        if (userMap.containsKey(managerDetails[0])) {
                            L4ManagerId = userMap.get(managerDetails[0]).split('#')[0];
                            // Prepare bell notification
                            if (actualDiffTimeL3 >= 1 && actualDiffTimeL3 <= 60 && templateMap.containsKey(SHF_ConstantsUtil.TASK_ESCALTE_TO_L1MANAGER)) {
                                
                                String template = templateMap.get(SHF_ConstantsUtil.TASK_ESCALTE_TO_L1MANAGER).Bell_Notification__c
                                    .replace('<TaskOwnerName>', (tsk.Owner.Name != null) ? tsk.Owner.Name : '');
                                
                                SHF_CommonUtil.notifyUsersByNotification(new Set<String>{userMap.get(managerDetails[0]).split('#')[0]}, tsk.Id, Label.Task_Escalation_Reminder, template, System.Label.Send_Notification_To_User );
                                // Send escalation email
                                if (String.isNotBlank(userMap.get(managerDetails[0]).split('#')[1])) {
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(
                                        new List<String>{ userMap.get(managerDetails[0]).split('#')[1]},
                                        templateMap.get(SHF_ConstantsUtil.TASK_ESCALTE_TO_L1MANAGER).Email_Template__c
                                        .replace('<recipientName>', userMap.get(managerDetails[0]).split('#')[2])
                                        .replace('<relatedToOwnerName>', (tsk.Owner.Name != null) ? tsk.Owner.Name : '')
                                        .replace('<leadName>', (mapOfLead.get(tsk.WhatId) != null) ?  mapOfLead.get(tsk.WhatId).split('#')[0] : '')
                                        .replace('<taskStatus>', (tsk.Status != null) ? tsk.Status : ''),
                                        SHF_ConstantsUtil.TASK_Escalation + ' - ' + tsk.Subject,
                                        SHF_ConstantsUtil.CASE_DISPLAY_NAME
                                    ));
                                }
                            }
                        }
                        
                        // =============== L4 Escalation ====================
                        // Notify top-level manager (L4)
                        if (String.isNotBlank(L4ManagerId) && actualDiffTimeL4 >= 1 && actualDiffTimeL4 <= 60 &&
                            templateMap.containsKey(SHF_ConstantsUtil.TASK_ESCALTE_TO_L1MANAGER)) {
                                
                                // Send bell notification to L4                                        
                                String template = templateMap.get(SHF_ConstantsUtil.TASK_ESCALTE_TO_L1MANAGER).Bell_Notification__c
                                    .replace('<TaskOwnerName>', (tsk.Owner.Name != null) ? tsk.Owner.Name : '');
                                
                                SHF_CommonUtil.notifyUsersByNotification(new Set<String>{userMap.get(L4ManagerId).split('#')[0]}, tsk.Id, Label.Task_Escalation_Reminder, template, System.Label.Send_Notification_To_User );
                                // Send escalation email
                                if (String.isNotBlank(userMap.get(L4ManagerId).split('#')[1])) {
                                    emails.addAll(SHF_CommonUtil.notifyUsersByEmail(
                                        new List<String>{ userMap.get(L4ManagerId).split('#')[1]},
                                        templateMap.get(SHF_ConstantsUtil.TASK_ESCALTE_TO_L1MANAGER).Email_Template__c
                                        .replace('<recipientName>', userMap.get(L4ManagerId).split('#')[2])
                                        .replace('<relatedToOwnerName>', (tsk.Owner.Name != null) ? tsk.Owner.Name : '')
                                        .replace('<leadName>', (mapOfLead.get(tsk.WhatId) != null) ?  mapOfLead.get(tsk.WhatId).split('#')[0] : '')
                                        .replace('<taskStatus>', (tsk.Status != null) ? tsk.Status : ''),
                                        SHF_ConstantsUtil.TASK_Escalation + ' - ' + tsk.Subject,
                                        SHF_ConstantsUtil.CASE_DISPLAY_NAME
                                    ));
                                }
                                
                                // Update Task record with new L4 escalation time
                                if( mapOfLead.get(tsk.WhatId).split('#')[2] != Null){
                                    String bhName = 'SHDFC ' +  mapOfLead.get(tsk.WhatId).split('#')[2] + ' Business Hours';
                                    
                                    if (bhMap.containsKey(bhName.toLowerCase())) {
                                        Id bhId = bhMap.get(bhName.toLowerCase());
                                        Datetime previousEscalationDate = tsk.L4_Escalation__c != null ? tsk.L4_Escalation__c : System.now(); 
                                        
                                        Task lds = new Task(Id = tsk.Id);
                                        lds.L4_Escalation__c = BusinessHours.addGmt(bhId, previousEscalationDate, Integer.valueOf(Label.Business_9_5_Hours));
                                        Logger.info(' lds.L4_Escalation__c L4 '+  lds.L4_Escalation__c);
                                        uow.registerDirty(lds);
                                    }
                                } 
                            }
                    }
                }
            }
            // Send email notifications
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
                Logger.info('Sent escalation Task emails'+ new Map<String,Object>{ 'Count' => emails.size() });
            }
            // Commit all Task updates registered in UnitOfWork
            uow.commitWork();
        }catch (Exception e) {
            Logger.error('Error in Lead Escalation Calculation: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('DEBUG: finish() invoked - SHF_TaskEscalationBatch completed.');
    }
    
    // Scheduler execute
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SHF_TaskEscalationBatch(), 200);
    }
}