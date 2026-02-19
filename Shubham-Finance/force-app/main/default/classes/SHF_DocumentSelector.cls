/**
* @File Name : SHF_DocumentSelector.cls
* @Description :
* @Author : Preeti 
* @Last Modified By :
* @Last Modified On : October 14, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 14, 2025 |   | Initial Version
**/

public with sharing class SHF_DocumentSelector extends fflib_SObjectSelector {

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Document__c.Id,
            Document__c.Name,
            Document__c.Loan_Applicant__c,
            Document__c.IsDeleted__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return Document__c.sObjectType;
    }
}