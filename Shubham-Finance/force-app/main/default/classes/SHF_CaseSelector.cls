/**
* @File Name          :  SHF_CaseSelector.cls
* @Author             :  Harshita Rathod
* @Last Modified By   :  Harshita Rathod
* @Last Modified On   :  01-07-2025 
* @Description        :  this class is used for fatching the Case records.
*================================================================================================
* Update Ver         Date                     Author                 Modification                    
*================================================================================================
* 1.0             01-07-2025               Harshita Rathod             	Initial Version            
*/

public  class SHF_CaseSelector extends fflib_SObjectSelector {
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{ 
            Case.Id, 
                Case.OwnerId,
                Case.CaseNumber,
                Case.Subject,
                Case.Send_Notification__c,
                Case.Status,
                Case.CreatedDate,
                Case.Escalation_Notification_Date__c,
                Case.Actual_TAT_After_1__c,
                Case.Actual_TAT_Before_1__c, 
                Case.Ticket_Sub_Type__c,
                Case.Origin	
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Case.SObjectType; 
    }
    
    public List<Case> selectCasesForTATEscalation(Set<Id> caseIds) {
        fflib_QueryFactory qf = newQueryFactory();
        qf.selectFields(getSObjectFieldList()); // Includes all fields
        qf.selectField('Owner.Name'); // Add Owner.Name 
        qf.selectField('Owner.UserRole.DeveloperName');    
        qf.setCondition('Send_Notification__c = false');
        return (List<Case>) Database.query(qf.toSOQL());
    }
    // METHOD for Round Robin Assignment
    public List<Case> selectCasesByIds(Set<Id> caseIds) {
        fflib_QueryFactory qf = newQueryFactory();
        qf.selectFields(getSObjectFieldList());
        qf.setCondition('Id IN :caseIds');
        return (List<Case>) Database.query(qf.toSOQL());
    }
    
}