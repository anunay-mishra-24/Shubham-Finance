/**
* @File Name : SHF_pincodeSelector.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 12, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 12, 2025 |   | Initial Version
**/

public class SHF_pincodeSelector {
	 public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            Pincode_Master__c.Id,
                Pincode_Master__c.Name,
                Pincode_Master__c.State__c
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Pincode_Master__c.SObjectType; 
    }

	 public List<Pincode_Master__c> selectByIds(Set<Id> recordIds) {    
        fflib_QueryFactory query = new fflib_QueryFactory(Pincode_Master__c.sObjectType);
        query.selectField('City_Master__r.Name'); 
		 query.selectField('State__c'); 
         query.selectField('City_Master__r.Country__c'); 
        query.setCondition('Id IN : recordIds');
        return (List<Pincode_Master__c>) Database.query(query.toSOQL());
    }
    
    public Id selectPincodeIdByName(String pincodeName) {
        if (String.isBlank(pincodeName)) return null;

        fflib_QueryFactory query = new fflib_QueryFactory(Pincode_Master__c.sObjectType);
        query.selectField('Id');
        query.selectField('Name');
        query.setCondition('Name = :pincodeName');
        query.setLimit(1);

        List<Pincode_Master__c> results = (List<Pincode_Master__c>) Database.query(query.toSOQL());
        return results.isEmpty() ? null : results[0].Id;
    }
}