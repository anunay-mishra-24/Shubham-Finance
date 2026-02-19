/**
* @File Name          : SHF_E-VerificationSelector.cls
* @Description        : This class used to fetch/query E_verification based on conditions.
* @Author             : Riteek Tiwari
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         27-06-2025              Riteek Tiwari            Initial Version
*/
public class SHF_E_VerificationSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{ 
            E_Verification__c.Id,
                E_Verification__c.Date_of_Birth__c,
                E_Verification__c.Transaction_Id__c,
                E_Verification__c.Status__c,
                E_Verification__c.OTP_Sent_to_Customer__c,
                E_Verification__c.No_of_Attempt__c,
                 E_Verification__c.CreatedDate,
                E_Verification__c.Sent_To__c,
                E_Verification__c.Loan_Applicant__c,
                 E_Verification__c.Score__c,
                  E_Verification__c.RecordTypeId,
                E_Verification__c.Average_utilization_for_NBF_in_last_24_m__c,
                E_Verification__c.Average_Current_balance_in_last_18_month__c,
                E_Verification__c.Main_applicant_s_credit_score__c,
                E_Verification__c.New_Accounts_in_last_six_months__c,
                E_Verification__c.Maximum_DPD_in_CRIF_for_last_15_months__c,
                E_Verification__c.Number_of_enquires_by_Main_applicant__c,
                E_Verification__c.Primary_number_of_Accounts__c,
                E_Verification__c.Total_PLN_Tradelines_in_last_6_months__c,
                E_Verification__c.Credit_Bureau_Exception__c,
                E_Verification__c.Credit_Bureau_Deviations__c,
                E_Verification__c.Total_CRD_Tradelines_in_Last_12_Months__c,
                E_Verification__c.Hunter_Total_Match_Score__c,
                E_Verification__c.Hunter_Summary_Match__c,

                E_Verification__c.Negotiation_Insurance_Premium__c,
                E_Verification__c.Negotiation_Insurance_Tenure__c,
                E_Verification__c.Negotiation_Insured_Amount__c,
                E_Verification__c.Original_Insurance_Premium__c,
                E_Verification__c.Original_Insurance_Tenure__c,
                E_Verification__c.Original_Insured_Amount__c,
                E_Verification__c.Insurance_Provider__c ,
                E_Verification__c.Outstanding_Loan_Tenure__c  ,
                E_Verification__c.Loan_Tenure_In_Years__c  ,
                 E_Verification__c.Insured_Amount__c   ,
                  E_Verification__c.Premium_Amount__c   ,
                
                E_Verification__c.Hunter_Status__c
                }; 
                    }
    /**
* @Description: Select required object. 
* @Return: Schema.SObjectType.
*/
        public Schema.SObjectType getSObjectType() { 
            return E_Verification__c.SObjectType; 
        }
    
    public List<E_Verification__c> selectByIdsApplicantName(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory();
        //query.selectField('E_Verification__c.Status__c');
        query.selectField('Loan_Applicant__r.Is_SMS_Consent_Given__c');
        query.selectField('Loan_Applicant__r.SMS_Consent__c');
        query.setCondition('Id IN :recordIds');
        return (List<E_Verification__c>) Database.query(query.toSOQL());
    }
    // fetching details on the basis of recordtypeId
    public List<E_Verification__c> selectByRecordTypeId(String loanApplicationId, String recordTypeId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Application__c  =: loanApplicationId AND RecordTypeId =: recordTypeId');
        return (List<E_Verification__c>) Database.query( query.toSOQL());
    }
//getting record on the basis of applicantId
 public List<E_Verification__c> selectByrecordId(Set<Id> verificationId) {
    fflib_QueryFactory query = newQueryFactory();

    // getting all bureau and BSA record
   // fflib_SObjectSelector bureauAndBSA = new SHF_BureauAndBSASelector();
   // bureauAndBSA.addQueryFactorySubselect(query, 'Bureau_BSA_Details__r');

    // Set filter condition
    query.setCondition('Id IN :verificationId');

    // Add ordering
   // query.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);

    // Execute query
    return (List<E_Verification__c>) Database.query(query.toSOQL());
}


}