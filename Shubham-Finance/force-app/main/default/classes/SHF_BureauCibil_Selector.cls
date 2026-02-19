/**
* @File Name          : SHF_E-SHF_BureauCibil_Selector.cls
* @Description        : This class used to fetch/query Bureau_BSA_Detail__c based on conditions.
* @Author             :Mansur
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0        22-09-2025             Mansur          Initial Version
*/
public class SHF_BureauCibil_Selector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{ 
            Bureau_BSA_Detail__c.Id,
                 Bureau_BSA_Detail__c.E_Verification__c,
                Bureau_BSA_Detail__c.Account_Type__c,
                 Bureau_BSA_Detail__c.Loan_Applicant__c,
                Bureau_BSA_Detail__c.DPD__c
                }; 
                    }
    /**
* @Description: Select required object. 
* @Return: Schema.SObjectType.
*/
        public Schema.SObjectType getSObjectType() { 
            return Bureau_BSA_Detail__c.SObjectType; 
        }
    
    // fetching details on the basis of recordtypeId
    public List<Bureau_BSA_Detail__c> selectByRecordTypeId(Set<Id> eVerifications){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('E_Verification__c IN : eVerifications');
        return (List<Bureau_BSA_Detail__c>) Database.query( query.toSOQL());
    }


}