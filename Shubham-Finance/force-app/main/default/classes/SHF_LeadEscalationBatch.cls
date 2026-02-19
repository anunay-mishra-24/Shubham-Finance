/**
* @File Name          : SHF_LeadEscalationBatch.cls
* @Author             : Riteek Tiwari
* @Last Modified On   : 09-07-2025
* @Description        : This batch is use for trigger bell and whatsapp notification to L2,L3 and L4 users for lead escalation
* ================================================================================================
* Update Ver         Date           Author         Modification
* ================================================================================================
* 1.0                09-07-2025     Riteek Tiwari     Initial Version
*/
global class SHF_LeadEscalationBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Lead_Status__c, Send_Notification__c, OwnerId, Owner.Name,CreatedDate,LastModifiedDate,Full_Name__c,Contact_No1__c,Branch__c,Branch__r.Name,Lead_Stage__c,
            L2_Escalation__c, L3_Escalation__c, L4_Escalation__c FROM Lead__c
            WHERE Send_Notification__c = true AND Lead_Status__c = :SHF_ConstantsUtil.ACTIVE_STATUS
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Lead__c> leadList) {
        system.debug('leadList '+leadList);
        try{
            if (leadList.isEmpty()) {
                return;
            }
            // Containers for messages and emails
            List<Message_Service__e> msgServicelist = new List<Message_Service__e>();
            Map<String, Notification_Template__mdt> templateMap = Notification_Template__mdt.getAll();
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Lead__c.SObjectType });
            Set<Id> hoMarketingUserIds = new Set<Id>();
            // Fetch active business hours and store in map for quick access
            Map<String, Id> bhMap = new Map<String, Id>();
            for (BusinessHours bh : [SELECT Id, Name FROM BusinessHours WHERE IsActive = true]) {
                bhMap.put(bh.Name.toLowerCase(), bh.Id);
            }
            Logger.info('Fetched active business hours'+ bhMap.size());
            
            
            // Fetch all active Sales users and their managers
            List<User> userList = new SHF_UsersSelector().selectActiveCustomerServiceUsers(SHF_ConstantsUtil.SALES_PROFILE);
            
            Map<String, String> userMap = new Map<String, String>();
            for (User usr : userList) {
                if (usr.ManagerId != null ) {
                    
                    userMap.put(usr.Id, usr.ManagerId + '#' + usr.Manager.Email + '#' + usr.Manager.Name + '#' + usr.Manager.Phone);
                    if(usr.UserRole.DeveloperName == SHF_ConstantsUtil.HO_MARKETING_ROLE){
                       hoMarketingUserIds.add(usr.Id); 
                    }
                }
            }
            system.debug('iserMap '+userMap);
            Logger.info('Prepared userMap'+userMap.size());
            
            // Iterate through each lead and check escalation conditions
            for (Lead__c ld : leadList) {
                Long actualDiffTimeL2 = ld.L2_Escalation__c != null ? SHF_CommonUtil.calculateHours(ld.L2_Escalation__c, System.now()) : 0;
                Long actualDiffTimeL3 = ld.L3_Escalation__c != null ? SHF_CommonUtil.calculateHours(ld.L3_Escalation__c, System.now()) : 0;
                Long actualDiffTimeL4 = ld.L3_Escalation__c != null ? SHF_CommonUtil.calculateHours(ld.L4_Escalation__c, System.now()) : 0;
                
                if (userMap.containsKey(ld.OwnerId)) {
                    List<String> managerDetails = userMap.get(ld.OwnerId).split('#');
                    String L4ManagerId = '';
                    
                    // =============== L2 Escalation ====================
                    // Notify direct manager of Lead Owner
                    if (actualDiffTimeL2 >= 1 && actualDiffTimeL2 <= 60 && templateMap.containsKey(SHF_ConstantsUtil.LEAD_ESCALTE_TO_MANAGERS)) {
                        Logger.info('L2 escalation'+ ld.Id);
                        // Prepare bell notification
                        String template = templateMap.get(SHF_ConstantsUtil.LEAD_ESCALTE_TO_MANAGERS).Bell_Notification__c
                            .replace('<LeadOwnerName>', (ld.Owner.Name != null) ? ld.Owner.Name : '')
                            .replace('<LeadId>', (ld.Name != null) ? ld.Name : '');
                        
                        SHF_CommonUtil.notifyUsersByNotification(new Set<String>{managerDetails[0]}, ld.Id, Label.Lead_Escalation_Reminder, template, System.Label.Send_Notification_To_User );
                        
                        // Send escalation email
                        if (String.isNotBlank(managerDetails[1])) {
                            emails.addAll(SHF_CommonUtil.notifyUsersByEmail(new List<String>{ managerDetails[1] },
                                                                            templateMap.get(SHF_ConstantsUtil.LEAD_ESCALTE_TO_MANAGERS).Email_Template__c
                                                                            .replace('<recipientName>', managerDetails[2])
                                                                            .replace('<leadName>', (ld.Name != null) ? ld.Name : '')
                                                                            .replace('<leadOwnerName>', (ld.Owner.Name != null) ? ld.Owner.Name : '')
                                                                            .replace('<leadStage>', (ld.Lead_Stage__c != null) ? ld.Lead_Stage__c : ''),
                                                                            SHF_ConstantsUtil.LEAD_Escalation + ' - ' + ld.Name,
                                                                            SHF_ConstantsUtil.CASE_DISPLAY_NAME
                                                                           ));
                        }
                        
                        // Send WhatsApp escalation
                        if (String.isNotBlank(managerDetails[3])) {
                            Logger.info('Manager phone L2 ' +String.isNotBlank(managerDetails[3]));
                            msgServicelist.add(new Message_Service__e(
                                Receiver__c = managerDetails[3],
                                Message_Template__c = SHF_ConstantsUtil.ESCALATION_REMINDER,
                                WhatsApp_Placeholders__c = new List<String>{(managerDetails[2] != null) ? managerDetails[2] : '', ld.Owner.Name,
                                    ld.Name, String.valueOf(ld.CreatedDate), String.valueOf(ld.LastModifiedDate), (ld.Branch__r != null) ? ld.Branch__r.Name : '',
                                        ld.Full_Name__c , ld.Contact_No1__c}.toString()
                            ));
                        }
                        
                        // Update Lead record with new L2 escalation time
                        if (ld.Branch__c != null && ld.Branch__r.Name != null && hoMarketingUserIds.contains(ld.OwnerId)) {
                            String bhName = 'SHDFC ' + ld.Branch__r.Name + ' Business Hours';
                            
                            if (bhMap.containsKey(bhName.toLowerCase())) {
                                Id bhId = bhMap.get(bhName.toLowerCase());
                                Datetime previousEscalationDate = ld.L2_Escalation__c != null ? ld.L2_Escalation__c : System.now(); 
                                
                                Lead__c lds = new Lead__c(Id = ld.Id);
                                lds.L2_Escalation__c = BusinessHours.addGmt(bhId, previousEscalationDate, Integer.valueOf(Label.Business_9_5_Hours));
                                Logger.info(' lds.L2_Escalation__c L4 '+  lds.L2_Escalation__c);
                                uow.registerDirty(lds);
                            }
                        }
                    }
                    
                    // =============== L3 Escalation ====================
                    // Notify manager’s manager (L3)
                    if (userMap.containsKey(managerDetails[0]) && !hoMarketingUserIds.contains(ld.OwnerId)) {
                        Logger.info('L3 escalation'+ ld.Id);
                        L4ManagerId = userMap.get(managerDetails[0]).split('#')[0];
                        
                        if (actualDiffTimeL3 >= 1 && actualDiffTimeL3 <= 60 && templateMap.containsKey(SHF_ConstantsUtil.LEAD_ESCALTE_TO_MANAGERS)) {
                            // Prepare bell notification
                            String template = templateMap.get(SHF_ConstantsUtil.LEAD_ESCALTE_TO_MANAGERS).Bell_Notification__c
                                .replace('<LeadOwnerName>', (ld.Owner.Name != null) ? ld.Owner.Name : '')
                                .replace('<LeadId>', (ld.Name != null) ? ld.Name : '');
                            
                            SHF_CommonUtil.notifyUsersByNotification(new Set<String>{userMap.get(managerDetails[0]).split('#')[0]}, ld.Id, Label.Lead_Escalation_Reminder, template, System.Label.Send_Notification_To_User );
                            
                            // Send escalation email
                            if (String.isNotBlank(userMap.get(managerDetails[0]).split('#')[1])) {
                                emails.addAll(SHF_CommonUtil.notifyUsersByEmail(
                                    new List<String>{ userMap.get(managerDetails[0]).split('#')[1]},
                                    templateMap.get(SHF_ConstantsUtil.LEAD_ESCALTE_TO_MANAGERS).Email_Template__c
                                    .replace('<recipientName>', userMap.get(managerDetails[0]).split('#')[2])
                                    .replace('<leadName>', (ld.Name != null) ? ld.Name : '')
                                    .replace('<leadOwnerName>', (ld.Owner.Name != null) ? ld.Owner.Name : '')
                                    .replace('<leadStage>', (ld.Lead_Stage__c != null) ? ld.Lead_Stage__c : ''),
                                    SHF_ConstantsUtil.LEAD_Escalation + ' - ' + ld.Name,
                                    SHF_ConstantsUtil.CASE_DISPLAY_NAME
                                ));
                            }
                            
                            // Send WhatsApp escalation
                            if (String.isNotBlank(userMap.get(managerDetails[0]).split('#')[3])) {
                                Logger.info('Manager phone L3 ' +String.isNotBlank(userMap.get(managerDetails[0]).split('#')[3]));
                                msgServicelist.add(new Message_Service__e(
                                    Receiver__c = userMap.get(managerDetails[0]).split('#')[3],
                                    Message_Template__c = SHF_ConstantsUtil.ESCALATION_REMINDER,
                                    WhatsApp_Placeholders__c = new List<String>{(userMap.get(managerDetails[0]).split('#')[2] != null) ? userMap.get(managerDetails[0]).split('#')[2] : '', ld.Owner.Name,
                                        ld.Name, String.valueOf(ld.CreatedDate), String.valueOf(ld.LastModifiedDate), (ld.Branch__r != null) ? ld.Branch__r.Name : '',
                                            ld.Full_Name__c , ld.Contact_No1__c}.toString()
                                ));
                            }
                        }
                    }
                    
                    // =============== L4 Escalation ====================
                    //  Notify top-level manager (L4)
                    if (String.isNotBlank(L4ManagerId) && actualDiffTimeL4 >= 1 && actualDiffTimeL4 <= 60 &&
                        templateMap.containsKey(SHF_ConstantsUtil.LEAD_ESCALTE_TO_MANAGERS) && !hoMarketingUserIds.contains(ld.OwnerId)) {
                           Logger.info('L4 escalation'+ ld.Id); 
                            // Send bell notification to L4
                            String template = templateMap.get(SHF_ConstantsUtil.LEAD_ESCALTE_TO_MANAGERS).Bell_Notification__c
                                .replace('<LeadOwnerName>', (ld.Owner.Name != null) ? ld.Owner.Name : '')
                                .replace('<LeadId>', (ld.Name != null) ? ld.Name : '');
                            
                            SHF_CommonUtil.notifyUsersByNotification(new Set<String>{userMap.get(L4ManagerId).split('#')[0]}, ld.Id, Label.Lead_Escalation_Reminder, template, System.Label.Send_Notification_To_User );
                            
                            // Send escalation email
                            if (String.isNotBlank(userMap.get(L4ManagerId).split('#')[1])) {
                                emails.addAll(SHF_CommonUtil.notifyUsersByEmail(
                                    new List<String>{ userMap.get(L4ManagerId).split('#')[1]},
                                    templateMap.get(SHF_ConstantsUtil.LEAD_ESCALTE_TO_MANAGERS).Email_Template__c
                                    .replace('<recipientName>', userMap.get(L4ManagerId).split('#')[2])
                                    .replace('<leadName>', (ld.Name != null) ? ld.Name : '')
                                    .replace('<leadOwnerName>', (ld.Owner.Name != null) ? ld.Owner.Name : '')
                                    .replace('<leadStage>', (ld.Lead_Stage__c != null) ? ld.Lead_Stage__c : ''),
                                    SHF_ConstantsUtil.LEAD_Escalation + ' - ' + ld.Name,
                                    SHF_ConstantsUtil.CASE_DISPLAY_NAME
                                ));
                            }
                            // Send WhatsApp escalation to L4
                            if (String.isNotBlank(userMap.get(L4ManagerId).split('#')[3])) {
                                Logger.info('Manager phone L4 '+ String.isNotBlank(userMap.get(L4ManagerId).split('#')[3]));
                                Logger.info('Manager phone L4 Number '+ userMap.get(L4ManagerId).split('#')[3]);
                                msgServicelist.add(new Message_Service__e(
                                    Receiver__c = userMap.get(L4ManagerId).split('#')[3],
                                    Message_Template__c = SHF_ConstantsUtil.ESCALATION_REMINDER,
                                    WhatsApp_Placeholders__c = new List<String>{(userMap.get(L4ManagerId).split('#')[2] != null) ? userMap.get(L4ManagerId).split('#')[2] : '', ld.Owner.Name,
                                        ld.Name, String.valueOf(ld.CreatedDate), String.valueOf(ld.LastModifiedDate), (ld.Branch__r != null) ? ld.Branch__r.Name : '',
                                            ld.Full_Name__c , ld.Contact_No1__c}.toString()
                                ));
                            }
                            
                            // Update Lead record with new L4 escalation time
                            if (ld.Branch__c != null && ld.Branch__r.Name != null) {
                                String bhName = 'SHDFC ' + ld.Branch__r.Name + ' Business Hours';
                                
                                if (bhMap.containsKey(bhName.toLowerCase())) {
                                    Id bhId = bhMap.get(bhName.toLowerCase());
                                    Datetime previousEscalationDate = ld.L4_Escalation__c != null ? ld.L4_Escalation__c : System.now(); 
                                    
                                    Lead__c lds = new Lead__c(Id = ld.Id);
                                    lds.L4_Escalation__c = BusinessHours.addGmt(bhId, previousEscalationDate, Integer.valueOf(Label.Business_9_5_Hours));
                                    Logger.info(' lds.L4_Escalation__c L4 '+  lds.L4_Escalation__c);
                                    uow.registerDirty(lds);
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
            // Send email notifications
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
                Logger.info('Sent escalation Lead emails'+ new Map<String,Object>{ 'Count' => emails.size() });
            }
            // Commit all Lead updates registered in UnitOfWork
            uow.commitWork();
        }catch (Exception e) {
            Logger.error('Error in Lead Escalation Calculation: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('DEBUG: finish() invoked - SHF_LeadEscalationBatch completed.');
    }
    
    // Schedulable interface implementation
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SHF_LeadEscalationBatch(), 200);
    }
}