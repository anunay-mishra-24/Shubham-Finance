/**
* @File Name          : SHF_CaseRoundRobinAssignmentRule.cls
* @Author             : Harshita Rathod
* @Last Modified By   : Harshita Rathod
* @Last Modified On   : 01-07-2025 
* @Description        : This class assigns Case owners using a round-robin,
*                       triggered from a Flow on Case insert
* ================================================================================================
* Update Ver         Date           Author         Modification
* ================================================================================================
* 1.0                01-07-2025     Harshita Rathod    Initial Version
*/
public class SHF_CaseRoundRobinAssignmentRule {
    
    //  to allow Flow to send Case Ids
    public class CaseWrapper {
        @InvocableVariable(required=true)
        public Id caseId;
    }
    
    @InvocableMethod(label = 'Round Robin Owner Assignment for Cases' description = 'Assigns Case owner using round robin logic')
    public static void caseOwnerAssignment(List<CaseWrapper> caseWrappers) {
        
        List<Id> caseIds = new List<Id>();
        for (CaseWrapper wrapper : caseWrappers) {
            caseIds.add(wrapper.caseId);
        }
         // Fetch Cases using Selector
                List<Case> caseList = new SHF_CaseSelector().selectCasesByIds(new Set<Id>(caseIds));
        //List<Case> caseList = [SELECT Id FROM Case WHERE Id IN :caseIds];
        
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> { Case.SObjectType, Round_Robin__c.SObjectType }
        );
        
        List<Case> casesToUpdate = new List<Case>();
        List<Round_Robin__c> assigneesToUpdate = new List<Round_Robin__c>();
        
        try {
            if (!caseList.isEmpty()) {
                
                List<Round_Robin__c> roundRobinList = new SHF_RoundRobinSelector().selectRoundRobinByName(SHF_ConstantsUtil.CRM_LOB);
                if (roundRobinList.isEmpty()) {
                    Logger.warn('No active Round Robin assignees found for label: ' + Label.Case_Round_Robin_Label);
                    return;
                }
                
                // Round-robin assignment 
                Integer index = 0;
                Integer totalAssignees = roundRobinList.size();
                
                for (Integer i = 0; i < caseList.size(); i++) {
                    Case c = caseList[i];
                    Round_Robin__c assignee = roundRobinList[Math.mod(index, totalAssignees)];
                    if (assignee.User__c != null) {
                        casesToUpdate.add(new Case(Id = c.Id, OwnerId = assignee.User__c));
                        // update last assigned timestamp for tracking
                        if (!assigneesToUpdate.contains(assignee)) {
                            System.debug('!assigneesToUpdate.contains(assignee)'+assignee);
                            assignee.Last_Assigned__c = System.now();
                            assigneesToUpdate.add(assignee);
                        }
                        
                        index++;
                    }
                }
                
                // Register changes with UOW
                if (!casesToUpdate.isEmpty()) {
                    uow.registerDirty(casesToUpdate);
                }
                
                if (!assigneesToUpdate.isEmpty()) {
                    uow.registerDirty(assigneesToUpdate);
                }
                
                uow.commitWork();
            }
        } catch (Exception ex) {
            Logger.error('Error during Case Round Robin Assignment: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }
    }
}