/**
* @File Name          :  SHF_CaseCategoriesMatrixSelector.cls
* @Author             :  Harshita Rathod
* @Last Modified By   :  Harshita Rathod
* @Last Modified On   :  03-07-2025 
* @Description        :  this class is used for fatching the Case Categories Matrix records
*================================================================================================
* Update Ver         Date                     Author                 Modification                    
*================================================================================================
* 1.0             03-07-2025               Harshita Rathod             	Initial Version            
*/

public class SHF_CaseCategoriesMatrixSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        
        return new List<Schema.SObjectField>{
            Case_Categories_Matrix__c.Id,
                Case_Categories_Matrix__c.Ticket_Type__c,
                Case_Categories_Matrix__c.Request_Type__c,
                Case_Categories_Matrix__c.Ticket_Sub_Type__c
                };
                    }
    
    public  Schema.SObjectType getSObjectType() {
        return Case_Categories_Matrix__c.SObjectType;
    }
    public List<Case_Categories_Matrix__c> selectByIdsWithSendNotification() {
        String query = newQueryFactory()
            .selectField('Turnaround_Time__c')
            .selectField('Send_Notification_InDays__c')
            .toSOQL();
        
        return (List<Case_Categories_Matrix__c>) Database.query(query);
    }
    
    
    
    
}