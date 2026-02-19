/**
* @File Name          : SHF_LeadOwnerAssignmentBatch.cls
* @Author             : Kunal Soni
* @Last Modified By   : Kunal Soni
* @Last Modified On   : 01-07-2025
* @Description        : This class is used to perform round robin assignment for bulk imported leads.
*
* ================================================================================================
* Update Ver         Date           Author         Modification
* ================================================================================================
* 1.0              01-07-2025     Kunal Soni     Initial Version
*/
global class SHF_LeadOwnerAssignmentBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        return Database.getQueryLocator([SELECT Id,Branch__c,First_Name__c,Name,Full_Name__C,Contact_No1__c,Branch__r.Name,Lead_Source__c
                                         FROM Lead__c
                                         WHERE IsImported__c = True
                                         AND CreatedDate = Today]); 
    }
    
    global void execute(Database.BatchableContext bc, List<Lead__c> listOfLeads) {
        
        List<Lead_Round_Robin_Assignment_Event__e> eventsToPublish = new List<Lead_Round_Robin_Assignment_Event__e>();
        List<Lead__c> leadsToUpdate = new List<Lead__c>();
        system.debug('listOfLeads--> '+listOfLeads);
        
        // Initialize Unit of Work for transactional consistency
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{ Lead__c.SObjectType }
        );
        
        try {
            if (!listOfLeads.isEmpty()) {
                For(Lead__c lead : listOfLeads){
                    Lead_Round_Robin_Assignment_Event__e myEvent = new Lead_Round_Robin_Assignment_Event__e();
                    myEvent.Lead_ID__c = lead.Id;
                    myEvent.Send_SMS__c = false;
                    eventsToPublish.add(myEvent);
                    leadsToUpdate.add(new Lead__c(Id = lead.Id, IsImported__c = false));
                    system.debug('leadsToUpdate--> '+leadsToUpdate);
                }
                if(!eventsToPublish.isEmpty()){
                    Logger.info('eventsToPublish',eventsToPublish);
                    Database.SaveResult[] results = EventBus.publish(eventsToPublish);
                    Logger.info('results',results);
                }
                // Register changes with UOW
                if (!leadsToUpdate.isEmpty()) {
                    Logger.info('leadsToUpdate ',leadsToUpdate);
                    uow.registerDirty(leadsToUpdate);
                }
                
                // Commit transaction
                uow.commitWork();
                
            }
        }catch (Exception e) {
            // Log the exception for visibility
            Logger.error('Error in LeadRoundRobinAssignmentRule: ' + e.getMessage());
        }finally{
            Logger.saveLog();
        }    
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('FINISH method called: LeadOwnerAssignmentBatch Batch completed.');
    }
    
}