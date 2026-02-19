/**
* @File Name          : SHF_CitySelector.cls
* @Author             : Riteek Tiwari
* @Last Modified By   : Riteek Tiwari
* @Last Modified On   : 15-07-2025
* @Description        : This class is used for fetching the City_Master__c records.
*================================================================================================
* Update Ver         Date                     Author                 Modification                    
*================================================================================================
* 1.0              15-07-2025              	Riteek Tiwari            Initial Version            
*/
public class SHF_CitySelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            City_Master__c.Id,
                City_Master__c.Name
                };
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return City_Master__c.SObjectType; 
    }
    
    public List<City_Master__c> selectByName(String name) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Name = :name');
        return (List<City_Master__c>) Database.query(query.toSOQL());
    }
}