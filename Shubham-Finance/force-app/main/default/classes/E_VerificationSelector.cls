/**
* @File Name          : E-VerificationSelector.cls
* @Description        : This class used to fetch/query E_verification based on conditions.
* @Author             : Riteek Tiwari
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         27-06-2025              Riteek Tiwari            Initial Version
*/
public class E_VerificationSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{ 
            E_Verification__c.Id,
                E_Verification__c.Date_of_Birth__c,
                E_Verification__c.Transaction_Id__c,
                E_Verification__c.Status__c,
                E_Verification__c.Loan_Applicant__c,
                E_Verification__c.Description__c,
                E_Verification__c.Failed_Reason__c,
                E_Verification__c.Mobile_IsFound__c
                }; 
                    }
    /**
* @Description: Select required object.  Id, Status__c, Description__c, Failed_Reason__c, Mobile_IsFound__c
* @Return: Schema.SObjectType.
*/
    public Schema.SObjectType getSObjectType() { 
        return E_Verification__c.SObjectType; 
    }

    public List<E_Verification__c> selectById(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory();
        //query.selectField('E_Verification__c.Status__c');
        query.selectField('Loan_Applicant__r.Id');
        query.selectField('Loan_Applicant__r.Application__c');
        query.setCondition('Id IN :recordIds AND IsDeleted__c = false');
        return (List<E_Verification__c>) Database.query(query.toSOQL());
    }
    
    public List<E_Verification__c> selectByIdsApplicantName(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory();
        //query.selectField('E_Verification__c.Status__c');
        query.selectField('Loan_Applicant__r.Id');
        query.selectField('Loan_Applicant__r.Mobile_Number__c');
        query.selectField('Loan_Applicant__r.Alternate_Mobile_Number__c');
        query.selectField('Loan_Applicant__r.Mobile_Verification__r.Status__c');
        query.selectField('Loan_Applicant__r.Alternate_Mobile_Verification__r.Status__c');
        query.setCondition('Id IN :recordIds');
        return (List<E_Verification__c>) Database.query(query.toSOQL());
    }
}