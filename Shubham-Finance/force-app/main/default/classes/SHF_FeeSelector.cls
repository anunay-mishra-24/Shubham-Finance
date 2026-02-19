/**
 * @File Name : SHF_FeeSelector.cls
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
public with sharing class SHF_FeeSelector {
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Fees__c.Id,
            Fees__c.Name,
             Fees__c.Fee_Type__c,
              Fees__c.Amount__c,
               Fees__c.Tax__c,
                Fees__c.Application__c 
        };
    }
    
    public Schema.SObjectType getSObjectType() {
        return Fees__c.SObjectType;
    }
    
    public List<Fees__c> selectByapplicationID(String applicationId) {
        
        fflib_QueryFactory query = new fflib_QueryFactory(Fees__c.sObjectType);
        query.selectField('Id');
        query.selectField('Receipt_Id__c');
        query.selectField('Status__c');
        query.selectField('Application__c');
        query.selectField('Charge_Master__r.Type_Of_Charge__c');
        query.setCondition('Application__c =: applicationId AND Charge_Master__r.Type_Of_Charge__c = \'Login Fees\'');
        return (List<Fees__c>) Database.query(query.toSOQL());
    }

    public Fees__c selectByIds(Set<String> feeIds) {
        fflib_QueryFactory query = new fflib_QueryFactory(Fees__c.sObjectType);
        query.selectField('Id');
        query.selectField('Receipt_Id__c');
        query.selectField('Status__c');
        query.selectField('Application__c');
        query.selectField('Charge_Master__r.Type_Of_Charge__c');
        query.setCondition('Id IN : feeIds');
        return (Fees__c) Database.query(query.toSOQL());
    }

    //added by mansur to get all fee recrod on the basis of applicationId
 public List<Fees__c> selectByapplicationRecodID(String applicationId) {
        fflib_QueryFactory query = new fflib_QueryFactory(Fees__c.sObjectType);
        query.selectField('Id');
        query.selectField('Tax__c');
        query.selectField('Amount__c');
        query.selectField('Application__c');
        query.selectField('Fee_Type__c');
        query.setCondition('Application__c =: applicationId');
        return (List<Fees__c>) Database.query(query.toSOQL());
    }
    
}