/**
 * @File Name : SHF_BankDetails_Selector.cls
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
public with sharing class SHF_BankDetails_Selector {
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Bank_Details__c.Id,
            Bank_Details__c.Name
        };
    }
    
    public Schema.SObjectType getSObjectType() {
        return Bank_Details__c.SObjectType;
    }
    
    public List<Bank_Details__c> selectByIds(Id applicantId) {
        fflib_QueryFactory query = new fflib_QueryFactory(Bank_Details__c.sObjectType);
        query.selectField('Id');
        query.selectField('Name');
        query.selectField('Account_No__c');
        query.selectField('Type_of_Account__c');
        query.selectField('Branch_Name__c');
        query.selectField('IFSC_Code__c');
        query.selectField('Loan_Applicant__c');
        query.selectField('Loan_Applicant__r.Name');
        query.setCondition('Loan_Applicant__c =: applicantId');
        return (List<Bank_Details__c>) Database.query(query.toSOQL());
    }
}