/**
* @File Name : SHF_BureauAndBSASelector.cls
* @Description :
* @Author : Mansur
* @Last Modified By :
* @Last Modified On : November 4, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 4, 2025 |   | Initial Version
**/

public class SHF_BureauAndBSASelector extends fflib_SObjectSelector {
	 public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Bureau_BSA_Detail__c.Id,
                Bureau_BSA_Detail__c.Loan_Applicant__c,
				Bureau_BSA_Detail__c.E_Verification__c,
				Bureau_BSA_Detail__c.Total_CRD_Tradelines_in_Last_12_Months__c,
				Bureau_BSA_Detail__c.Average_utilization_for_NBF_in_last_24_m__c,
                Bureau_BSA_Detail__c.Primary_number_of_Accounts__c,
			Bureau_BSA_Detail__c.New_Accounts_in_last_six_months__c,
				Bureau_BSA_Detail__c.DPD__c,
				Bureau_BSA_Detail__c.Maximum_DPD_in_CRIF_for_last_15_months__c,
				Bureau_BSA_Detail__c.Number_of_enquires_by_Main_applicant__c,
				Bureau_BSA_Detail__c.Average_Current_balance_in_last_18_month__c,
				Bureau_BSA_Detail__c.Total_PLN_Tradelines_in_last_6_months__c,
				Bureau_BSA_Detail__c.Main_applicant_s_credit_score__c

                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Bureau_BSA_Detail__c.sObjectType;
    }
     
   /* public List<Bureau_BSA_Detail__c> selectPdByLoanApplicantId(Set<Id> applicantId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Applicant__c IN : applicantId');
        return (List<Personal_DBureau_BSA_Detail__cscussion__c>) Database.query( query.toSOQL() );
    }*/
}