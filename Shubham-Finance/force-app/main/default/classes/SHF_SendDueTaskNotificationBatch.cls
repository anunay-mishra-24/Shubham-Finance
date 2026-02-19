/**
* @File Name          : SHF_SendDueTaskNotificationBatch.cls
* @Author             : Kunal Soni
* @Last Modified By   : Kunal Soni
* @Last Modified On   : 01-07-2025
* @Description        : This class is used to send notificatons on task due date to task owner.
**/
global class SHF_SendDueTaskNotificationBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        return Database.getQueryLocator([SELECT Id,OwnerId,Status,WhatId,ActivityDate
                                         FROM Task
                                         WHERE Status =: SHF_ConstantsUtil.OPEN_LEAD_STATUS 
                                         AND ActivityDate = :Date.today() 
                                         AND WhatId != null]);
        
    }
    
    global void execute(Database.BatchableContext bc, List<Task> listOfTasks) {
        
        Set<Id> leadIds = new Set<Id>();
        List<Lead__c> listOfLead = new List<Lead__c>();
        Map<Id,String> mapOfNotification = new map <Id,String>();
        List<Message_Service__e> msgServicelist = new List<Message_Service__e>();
        Map<String,String> mapOfLead = new Map<String,String>();
        Set<Id> setOfOwners = new Set<Id>();
        Map<String,String> mapOwnerDetails = new Map<String,String>();
        
        try{
            // Get notification template metadata
            Notification_Template__mdt notificationMTD = Notification_Template__mdt.getInstance('Task_Due_Notification');
            logger.info('notificationMTD',notificationMTD);
            For(Task tsk : listOfTasks){
                leadIds.add(tsk.WhatId);
                setOfOwners.add(tsk.OwnerId);
            }
            
            // Fetch users with their managers
            List<User> userList = new SHF_UsersSelector().selectByIdsUserName(setOfOwners);
            for(User usr : userList){
                mapOwnerDetails.put(usr.Id, usr.Phone);
            }
            if(leadIds.size() > 0){
                listOfLead = new SHF_LeadSelector().selectByIdsWithBranchName(leadIds);
                logger.info('Lead List',listOfLead);
                for(Lead__c leads : listOfLead){
                    mapOfLead.put(leads.Id, leads.Name + '#' + leads.Owner.Name + '#' + leads.Branch__r.Name + '#' + leads.Full_Name__c + '#' + leads.Contact_No1__c);
                }
                
                For(Task tsks : listOfTasks){
                    if (notificationMTD.Bell_Notification__c != null && mapOfLead.containsKey(tsks.WhatId)) {
                        mapOfNotification.put(tsks.WhatId, notificationMTD.Bell_Notification__c.replace('<LeadName>',mapOfLead.get(tsks.WhatId).split('#')[0]));
                    }
                    if(mapOfLead.containsKey(tsks.WhatId) ){
                        //Send whatsapp message
                        if(mapOwnerDetails.containsKey(tsks.OwnerId)){
                            if(mapOwnerDetails.get(tsks.OwnerId).split('#')[0] != null){
                                msgServicelist.add(new Message_Service__e(
                                    Receiver__c = mapOwnerDetails.get(tsks.OwnerId).split('#')[0],
                                    Message_Template__c = SHF_ConstantsUtil.on_the_due_date_of_follow_up_lead,
                                    WhatsApp_Placeholders__c = new List<String> {mapOfLead.get(tsks.WhatId).split('#')[1], mapOfLead.get(tsks.WhatId).split('#')[0], String.valueOf(tsks.ActivityDate) , mapOfLead.get(tsks.WhatId).split('#')[2] , mapOfLead.get(tsks.WhatId).split('#')[3], mapOfLead.get(tsks.WhatId).split('#')[4]}.toString()
                                )); 
                            }
                        }
                    }
                }
                
            }
            for(Task tasks : listOfTasks){
                SHF_CommonUtil.notifyUsersByNotification(
                    new Set<String>{tasks.OwnerId},
                    tasks.Id,
                    Label.Task_Reminder,
                    mapOfNotification.get(tasks.WhatId),
                    system.Label.Send_Notification_To_User
                );
            }
            
            if (!msgServicelist.isEmpty()) {
                EventBus.publish(msgServicelist);
            }
            
        }catch (Exception e) {
            // Log the exception for visibility
            Logger.error('Error in SendTaskDueDateNotificationBatch: ' + e.getMessage());
        }finally{
            Logger.saveLog();
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('FINISH method called: SHF_SendDueTaskNotificationBatch Batch completed.');
    }
    
    // Scheduler class
    global class SendDueTaskNotificationScheduler implements Schedulable {
        global void execute(SchedulableContext sc) {
            Database.executeBatch(new SHF_SendDueTaskNotificationBatch(), 200);
        }
    }
}