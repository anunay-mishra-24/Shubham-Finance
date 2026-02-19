/**
 * @File Name : SHF_APICodes_Selector.cls
 * @Description :
 * @Author : Vikas Soni
 * @Last Modified By :
 * @Last Modified On : Jan 21, 2026
 * @Modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | Jan 21, 2026 |   | Initial Version
 **/
public with sharing class SHF_APICodes_Selector {
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            API_codes__mdt.Id,
            API_codes__mdt.DeveloperName
        };
    }
    
    public Schema.SObjectType getSObjectType() {
        return API_codes__mdt.SObjectType;
    }
    
    public List<API_codes__mdt> selectByIds(Set<String> apiNames) {
        fflib_QueryFactory query = new fflib_QueryFactory(API_codes__mdt.sObjectType);
        query.selectField('API_Name__c');
        query.selectField('Codes__c');
        query.selectField('Label');
        query.selectField('Value__c');
        query.selectField('DeveloperName');
        query.setCondition('API_Name__c IN : apiNames');
        return (List<API_codes__mdt>) Database.query(query.toSOQL());
    }
}