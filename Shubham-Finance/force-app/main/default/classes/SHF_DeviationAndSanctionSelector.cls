/**
* @File Name          : SHF_UsersSelector.cls
* @Description        : This class is used to fetch/query User records based on conditions.
* @Author             : Riteek Tiwari
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         15-09-2025              Mansur alam       
*/
public class SHF_DeviationAndSanctionSelector extends fflib_SObjectSelector {

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
                Deviation_and_Sanction_Condition__c.Id,
                Deviation_and_Sanction_Condition__c.Name,
                Deviation_and_Sanction_Condition__c.Approver_Comments__c,
                Deviation_and_Sanction_Condition__c.Approving_Authority__c,
                Deviation_and_Sanction_Condition__c.CreatedById,
                Deviation_and_Sanction_Condition__c.Decision__c,
                Deviation_and_Sanction_Condition__c.Decision_By__c,
                Deviation_and_Sanction_Condition__c.Deviation_Description__c,
                Deviation_and_Sanction_Condition__c.Deviation_Name__c,
                 Deviation_and_Sanction_Condition__c.Loan_Applicant__c,
                Deviation_and_Sanction_Condition__c.Deviation_type__c,
                Deviation_and_Sanction_Condition__c.Deviations__c,
                Deviation_and_Sanction_Condition__c.Is_Delete__c,
                 Deviation_and_Sanction_Condition__c.Loan_Application__c,
                 Deviation_and_Sanction_Condition__c.OwnerId,
                 Deviation_and_Sanction_Condition__c.Mitigants__c,
                  Deviation_and_Sanction_Condition__c.External_Key__c,
                Deviation_and_Sanction_Condition__c.Type__c                
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Deviation_and_Sanction_Condition__c.SObjectType; 
    }

    public List<Deviation_and_Sanction_Condition__c> selectByIds(Set<Id> deviationIds) {
        fflib_QueryFactory query = newQueryFactory();
       query.selectField('Loan_Application__r.Credit_Manager__c');
       query.selectField('Loan_Application__r.OwnerId');
        query.setCondition('Id IN :deviationIds');
        return (List<Deviation_and_Sanction_Condition__c>) Database.query(query.toSOQL());
    }
    //get deviation by application Id
     public List<Deviation_and_Sanction_Condition__c> selestByApplicationId(Set<Id> applicationId) {
        fflib_QueryFactory query = newQueryFactory();
         query.selectField('Loan_Application__r.Credit_Manager__c');
       query.selectField('Loan_Application__r.OwnerId');
        query.setCondition('Loan_Application__c  IN :applicationId');
        return (List<Deviation_and_Sanction_Condition__c>) Database.query(query.toSOQL());
    }
     public List<Deviation_and_Sanction_Condition__c> selectByApplicationId(Set<Id> applicationId) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Deviations__r.Deviation__c');
        query.setCondition('Loan_Application__c  IN :applicationId AND Is_Delete__c = false AND Deviation_type__c =\'System\' AND Decision__c != \'Approved\'');
        return (List<Deviation_and_Sanction_Condition__c>) Database.query(query.toSOQL());
    }
    
}