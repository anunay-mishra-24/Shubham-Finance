/**
* @File Name          : SHF_CaseRoundRobinSubTypeAssignmentRule.cls
* @Author             : kunal soni
* @Last Modified By   : kunal soni
* @Last Modified On   : 12-01-2026 
* @Description        : This class assigns Case owners using a round-robin,
*                       triggered from a Flow on Case insert
* ================================================================================================
* Update Ver         Date           Author         Modification
* ================================================================================================
* 1.0                12-01-2026     kunal soni    Initial Version
*/
public class SHF_CaseRoundRobinSubTypeAssignmentRule {

    /**
     * Wrapper class to receive Case Ids from Flow
     */
    public class CaseWrapper {
        @InvocableVariable(required = true)
        public Id caseId;
    }

    /**
     * Invocable method used by Flow
     * Assigns Case Owner using Round Robin logic
     * when Case Sub-Type is not Statement
     */
    @InvocableMethod(
        label = 'Round Robin Owner Assignment for Sub-Type Cases'
        description = 'Assigns Case owner using round robin logic when sub type is not statement'
    )
    public static void caseOwnerAssignment(List<CaseWrapper> caseWrappers) {

        /* ---------------- Collect Case Ids ---------------- */
        List<Id> caseIds = new List<Id>();
        for (CaseWrapper wrapper : caseWrappers) {
            caseIds.add(wrapper.caseId);
        }

        /* ---------------- Fetch Cases using Selector ---------------- */
        List<Case> caseList = new SHF_CaseSelector()
                                .selectCasesByIds(new Set<Id>(caseIds));

        /* ---------------- Initialize Unit Of Work ---------------- */
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> {
                Case.SObjectType,
                Round_Robin__c.SObjectType
            }
        );

        List<Case> casesToUpdate = new List<Case>();
        List<Round_Robin__c> assigneesToUpdate = new List<Round_Robin__c>();

        try {

            if (!caseList.isEmpty()) {

                /* ---------------- Fetch Round Robin Assignees ---------------- */
                List<Round_Robin__c> roundRobinList =
                    new SHF_RoundRobinSelector()
                        .selectRoundRobinByName(SHF_ConstantsUtil.CRM_SUBTYPE_LOB);

                if (roundRobinList.isEmpty()) {
                    Logger.warn(
                        'No active Round Robin assignees found for label: '
                        + Label.Case_Round_Robin_Label
                    );
                    return;
                }

                /* ---------------- Round Robin Assignment Logic ---------------- */
                Integer index = 0;
                Integer totalAssignees = roundRobinList.size();

                for (Integer i = 0; i < caseList.size(); i++) {

                    Case c = caseList[i];

                    // Get assignee using modulo for circular assignment
                    Round_Robin__c assignee =
                        roundRobinList[Math.mod(index, totalAssignees)];

                    if (assignee.User__c != null) {

                        // Assign Case Owner
                        casesToUpdate.add(
                            new Case(
                                Id = c.Id,
                                OwnerId = assignee.User__c
                            )
                        );

                        // Update last assigned timestamp only once per assignee
                        if (!assigneesToUpdate.contains(assignee)) {
                            assignee.Last_Assigned__c = System.now();
                            assigneesToUpdate.add(assignee);
                        }

                        index++;
                    }
                }

                /* ---------------- Register Updates with UOW ---------------- */
                if (!casesToUpdate.isEmpty()) {
                    uow.registerDirty(casesToUpdate);
                }

                if (!assigneesToUpdate.isEmpty()) {
                    uow.registerDirty(assigneesToUpdate);
                }

                /* ---------------- Commit Transaction ---------------- */
                uow.commitWork();
            }

        } catch (Exception ex) {

            Logger.error(
                'Error during Case Round Robin Assignment: '
                + ex.getMessage()
            );

        } finally {
            Logger.saveLog();
        }
    }
}