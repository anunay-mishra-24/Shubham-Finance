/**
* @File Name          : SHF_CollateralApplicationSelector.cls
* @Description        : This class is used to fetch/query Collateral_Application__c  records based on conditions.
* @Author             : Mansur
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         15-12-2025             Mansur  
*/
public class SHF_CollateralApplicationSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            	Collateral_Application__c.Id,
                Collateral_Application__c.Name,
                Collateral_Application__c.Collateral__c ,
                Collateral_Application__c.Application__c
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Collateral_Application__c.SObjectType; 
    }
    
    public List<Collateral_Application__c > selectByApplicationIds(Set<Id> applicationId) {
        fflib_QueryFactory query = newQueryFactory();
		//getting all related collaterls records
		 fflib_SObjectSelector collRecords = new SHF_CollateralSelector();
        collRecords.configureQueryFactoryFields(query, 'Collateral__r');
        query.selectField('Name'); // Add other fields you need
        query.setCondition('Application__c IN :applicationId');
        return (List<Collateral_Application__c >) Database.query(query.toSOQL());
    }
     public List<Collateral_Application__c > selectByAppIds(Set<Id> applicationId) {
        fflib_QueryFactory query = newQueryFactory();
		//getting all related collaterls records
		 fflib_SObjectSelector collRecords = new SHF_CollateralSelector();
        //collRecords.configureQueryFactoryFields(query, 'Collateral__r');
       // query.selectField('Name'); // Add other fields you need
       String NO ='No';
       String YES ='Yes';
        query.setCondition('Application__c IN :applicationId AND Collateral__r.Property_Identification__c =:YES AND isActive__c = true');
        return (List<Collateral_Application__c >) Database.query(query.toSOQL());
    }
   
}