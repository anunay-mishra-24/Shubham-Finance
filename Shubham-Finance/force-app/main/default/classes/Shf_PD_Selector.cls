/**
* @File Name : Shf_PD_Selector.cls
* @Description :
* @Author : mansur
* @Last Modified By :
* @Last Modified On : October 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 27, 2025 |   | Initial Version
**/

public class Shf_PD_Selector extends fflib_SObjectSelector {
	 public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Personal_Discussion__c.Id,
                Personal_Discussion__c.Name,
				Personal_Discussion__c.Credit_PD_Mode__c,
				Personal_Discussion__c.Industry__c,
				Personal_Discussion__c.PD_Activity_Status__c,
                Personal_Discussion__c.Loan_Applicant__c,
			    Personal_Discussion__c.Remarks__c,
                Personal_Discussion__c.employer_issued_id_card__c,
				Personal_Discussion__c.Total_Expences__c
                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Personal_Discussion__c.sObjectType;
    }
     
    public List<Personal_Discussion__c> selectPdByLoanApplicantId(Set<Id> applicantId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Applicant__c IN : applicantId ' +  'AND Credit_PD_Mode__c = \'Credit PD\' ');
         query.setLimit(1);  
        return (List<Personal_Discussion__c>) Database.query( query.toSOQL() );
    }

//Added by mansur for BRE on 11/02/2026
     public List<Personal_Discussion__c> selectCreditPdByLoanApplicantId(Set<Id> applicantId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Applicant__c IN : applicantId ' +  'AND RecordType.Name = \'Credit PD\' ');
        return (List<Personal_Discussion__c>) Database.query( query.toSOQL() );
    }
}