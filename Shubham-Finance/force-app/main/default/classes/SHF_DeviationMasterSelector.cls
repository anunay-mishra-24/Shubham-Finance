/**
* @File Name          : SHF_DeviationMasterSelector.cls
* @Description        : This class is used to fetch/query User records based on conditions.
* @Author             : Mansur
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         15-09-2025              Mansur alam       
*/
public class SHF_DeviationMasterSelector extends fflib_SObjectSelector {

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
                Deviation_Master__c.Id,
                Deviation_Master__c.Active__c,
                Deviation_Master__c.Approving_Authority__c,
                Deviation_Master__c.Department__c,
                Deviation_Master__c.Deviation__c,
                Deviation_Master__c.Name,
                Deviation_Master__c.Deviation_Description__c,
                Deviation_Master__c.Product__c,
                Deviation_Master__c.Source__c,
                Deviation_Master__c.Type_Of_Deviation__c
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Deviation_Master__c.SObjectType; 
    }

    public List<Deviation_Master__c> selectByIds(Set<Id> deviationIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN :deviationIds');
        return (List<Deviation_Master__c>) Database.query(query.toSOQL());
    }

    public List<Deviation_Master__c> getAllDeviations() {
        fflib_QueryFactory query = newQueryFactory();
        return (List<Deviation_Master__c>) Database.query(query.toSOQL());
    }
    
}