/**
* @File Name          : SHF_LeadRoundRobinAssignmentRule.cls
* @Author             : Kunal Soni
* @Last Modified By   : Kunal Soni
* @Last Modified On   : 19-06-2025
* @Description        : This class assigns lead owners using a round-robin algorithm,
*                       triggered from a Flow on lead insert/update.
* ================================================================================================
* Update Ver         Date           Author         Modification
* ================================================================================================
* 1.0                19-06-2025     Kunal Soni     Initial Version
*/
public class SHF_LeadRoundRobinAssignmentRule {
    
    /**
* Assigns owners to leads using round-robin logic based on their branch.
*
* @param leadList List of Lead__c records passed from Flow
*/
    @InvocableMethod(label = 'Round Robin Owner Assignment' description = 'Fetch lead owner based on assignment logic')
    public static void leadOwnerAssignment(List<Lead__c> leadList) {
        system.debug('SHF_LeadRoundRobinAssignmentRule');
        // Initialize Unit of Work for transactional consistency
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{ Lead__c.SObjectType, Round_Robin__c.SObjectType }
        );
        
        // Collections for processing
        List<Lead__c> leadsToUpdate = new List<Lead__c>();
        List<Round_Robin__c> assigneesToUpdate = new List<Round_Robin__c>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Map<String, List<Round_Robin__c>> mapOfBranchWithRoundRobins = new Map<String, List<Round_Robin__c>>();
        Map<String, Integer> lastAssignedIndex = new Map<String, Integer>();
        Map<String,String> mapOwnerDetails = new Map<String,String>();
        List<Apex_Sharing__e> eventsToPublish = new List<Apex_Sharing__e>();
        List<Message_Service__e> msgServicelist = new List<Message_Service__e>();
        Set<Id> setOfOwners = new Set<Id>();
        
        try {
            if (!leadList.isEmpty()) {
                Logger.info('leadRoundRobin',leadList);
                Round_Robin__c assignee;
                // Extract lead IDs
                Set<Id> leadIds = new Set<Id>();
                for (Lead__c lead : leadList) {
                    leadIds.add(lead.Id);
                }
                
                // Get notification template metadata
                Notification_Template__mdt notificationMTD = Notification_Template__mdt.getInstance(SHF_ConstantsUtil.LEAD_OWNER_ASSIGNMENT_NOTIFICATION);
                system.debug('notificationMTD-->'+notificationMTD.SMS_Notification__c);
                
                // Retrieve the email template
                EmailTemplate emailTemplate = [SELECT Id, Body 
                                               FROM EmailTemplate 
                                               WHERE DeveloperName =: SHF_ConstantsUtil.LEAD_OWNER_ASSIGNMENT_EMAIL_TEMP LIMIT 1];
                system.debug('Id Email'+emailTemplate);
                Logger.info('emailTemplate',emailTemplate);
                // Re-fetch leads with related Branch Name
                leadList = new SHF_LeadSelector().selectByIdsWithBranchName(leadIds);
                
                // Fetch all round robin user assignments
                List<Round_Robin__c> roundRobinList = new SHF_RoundRobinSelector().selectRoundRobinByName(SHF_ConstantsUtil.LOS_LOB);
                // Group round robin assignees by branch name
                for (Round_Robin__c roundRobin : roundRobinList) {
                    String branchName = roundRobin.Branch_Name__r.Name;
                    if (mapOfBranchWithRoundRobins.containsKey(branchName)) {
                        mapOfBranchWithRoundRobins.get(branchName).add(roundRobin);
                    } else {
                        mapOfBranchWithRoundRobins.put(branchName, new List<Round_Robin__c>{ roundRobin });
                    }
                    
                }
                
                // Loop through each lead and assign an owner
                for (Lead__c lead : leadList) {
                    String branchKey = lead.Branch__r.Name;
                    
                    if (String.isNotBlank(branchKey)) {
                        List<Round_Robin__c> assignees = mapOfBranchWithRoundRobins.get(branchKey);
                        
                        if (assignees != null && !assignees.isEmpty()) {
                            // Get next assignee using round-robin
                            Integer index = lastAssignedIndex.containsKey(branchKey)
                                ? lastAssignedIndex.get(branchKey)
                                : 0;
                            
                            assignee = assignees[Math.mod(index, assignees.size())];
                            lastAssignedIndex.put(branchKey, index + 1);
                            
                            if (assignee.User__c != null) {
                                // Set lead owner
                                leadsToUpdate.add(new Lead__c(Id = lead.Id, OwnerId = assignee.User__c, Lead_Stage__c = SHF_ConstantsUtil.ASSIGNEDD_LEAD_STAGE));
                                setOfOwners.add(assignee.User__c);
                            }                            
                            // Update last assigned timestamp for round-robin tracking
                            if (!assigneesToUpdate.contains(assignee)) {
                                assignee.Last_Assigned__c = System.now();
                                assigneesToUpdate.add(assignee);
                            }
                        }
                    }
                }
                // Fetch users with their managers
                List<User> userList = new SHF_UsersSelector().selectByIdsUserName(setOfOwners);
                for(User usr : userList){
                   mapOwnerDetails.put(usr.Id, usr.Name+'#'+usr.Phone);
                }
                
                // Register changes with UOW
                if (!leadsToUpdate.isEmpty()) {
                    Logger.info('leadsToUpdate',leadsToUpdate);
                    uow.registerDirty(leadsToUpdate);
                }
                if (!assigneesToUpdate.isEmpty()) {
                    Logger.info('assigneesToUpdate',assigneesToUpdate);
                    uow.registerDirty(assigneesToUpdate);
                }
                
                // Commit transaction
                uow.commitWork();
                
                for (Lead__c leads : leadList){
                    // Send email notification
                    system.debug('Channel__c '+leads.Channel__c);
                    if (emailTemplate != null && leads.Channel__c != SHF_ConstantsUtil.LEAD_MANUAL_CHANNEL) {
                        emails.addAll(SHF_CommonUtil.notifyingUsersByEmail(
                            new List<String>{ assignee.User_Email__c },
                            emailTemplate.Id,
                            leads.Id
                        )); 
                        Logger.info('Channel__c after');
                    } 
                    if(leads.IsImported__c|| leads.Channel__c != SHF_ConstantsUtil.LEAD_MANUAL_CHANNEL ){
                        Apex_Sharing__e myEvent = new Apex_Sharing__e();
                        myEvent.Lead_ID__c = leads.Id;
                        eventsToPublish.add(myEvent);
                        Logger.info('eventsToPublish',eventsToPublish);
                    }
                    system.debug('mapOwnerDetails'+mapOwnerDetails.containsKey(assignee.User__c));
                    if(mapOwnerDetails.containsKey(assignee.User__c) && leads.Channel__c != SHF_ConstantsUtil.LEAD_MANUAL_CHANNEL && !leads.IsImported__c){
                        //Send whatsapp message
                        Logger.info('whatsapp');
                        if(mapOwnerDetails.get(assignee.User__c).split('#')[1] != null){
                            //send whatsapp
                            msgServicelist.add(new Message_Service__e(
                                Receiver__c = mapOwnerDetails.get(assignee.User__c).split('#')[1],
                                Message_Template__c = 'lead_assignment',
                                WhatsApp_Placeholders__c = new List<String> {
                                    mapOwnerDetails.get(assignee.User__c).split('#')[0], 
                                        leads.Name, String.valueOf(leads.CreatedDate), leads.Full_Name__c,
                                        leads.Contact_No1__c, leads.Branch__r.Name
                                        }.toString()
                            )); 
                            // send sms
                            msgServicelist.add(new Message_Service__e(
                                    Receiver__c	= mapOwnerDetails.get(assignee.User__c).split('#')[1],
                                    Message_Template__c = SHF_CommonUtil.formatSMSTemplate(notificationMTD.SMS_Notification__c).replace('<OwnerName>', mapOwnerDetails.get(assignee.User__c).split('#')[0])
                                    .replace('<fName>', leads.Full_Name__c).replace('<contact>', leads.Contact_No1__c)
                                ));
                        }
                    }
                    
                }
                if (!msgServicelist.isEmpty()) {
                    Logger.info('msgServicelist',msgServicelist);
                    Database.SaveResult[] results = EventBus.publish(msgServicelist);
                    Logger.info('results',results);
                }
                if(!eventsToPublish.isEmpty()){
                    Database.SaveResult[] results = EventBus.publish(eventsToPublish);
                    Logger.info('results',results);
                }
                
                // Send all accumulated emails
                if (!emails.isEmpty()) {
                    Messaging.sendEmail(emails);
                    system.debug('Email Send');
                }
                
                // call apex sharing event.
            }
        } catch (Exception e) {
            // Log the exception for visibility
            Logger.error('Error in LeadRoundRobinAssignmentRule: ' + e.getMessage() +' '+ e.getLineNumber());
        }finally{
            Logger.saveLog();
        }
    }
}