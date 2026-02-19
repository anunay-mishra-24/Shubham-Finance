public with sharing class SHF_CreditPD_VF_Controller {

	public CreditPDWrapper creditPDWrapper {get; set;}
    public Id loanApplicantId;
    public Id applicationId;

    public SHF_CreditPD_VF_Controller() {

		creditPDWrapper = new CreditPDWrapper();
        loanApplicantId = ApexPages.currentPage().getParameters().get('id');
		loanApplicantId = 'a04C1000001HP6IIAW';
		
        if (loanApplicantId != null) {

			Loan_Applicant__c loanApplicant = [SELECT Id, Name, Application__r.Branch__r.Name, Application__r.Name, 
			Application__r.Lead__r.Channel__c, Application__r.Applied_Loan_Amount__c, CIBIL_Verification__r.Score__c,
			Application__c 
			FROM Loan_Applicant__c 
			WHERE Id =: loanApplicantId];
            
			creditPDWrapper.loanApplicant = loanApplicant;
			applicationId = loanApplicant.Application__c;

			Personal_Discussion__c personalDiscussion = [SELECT Id, Name, No_of_family_members_in_the_family_with__c, 
			Residence_Status__c, Distance_from_Branch__c, Resi_Stability__c, Are_there_any_critical_medical_history_o__c, 
			Whether_the_applicant_is_involved_in_onl__c, Any_Alternate_Successor_of_Family_Who_C__c, Name_of_the_Business__c,
			Person_Met__c, Relationship__c, KYC_Validated_At_Business_Place__c, Documents_Verified__c, Business_board_seen__c,
			Constitution_of_Business__c, Current_Office_Business_Address__c, Enter_Landmark_details__c, Business_Ownership_proof_if_available__c,
			Locality_of_Business_Premises_Shop__c, Year_in_business__c, Prior_Occupaton_if_different_From_Curren__c, Business_Premises__c,
			Occupied_Since_When__c, Size_of_the_Premises__c, SelectConditionOfEmployerSPremises__c, Type_of_Business_premises__c,
			Stock_Value_observed_during_PD_visit__c, Nature_of_Business__c, site_details__c, status__c, period_of_service__c,
			work_details__c, contract_value__c, Remarks__c, gross_monthly_income__c, shop_rent_business_premises__c, 
			Avg_amount_of_Electricity_bill_of_last_3__c, other_fixed_expenses__c, water_tea_expense__c, stationery_expense__c,
			commission_paid_external_parties__c, house_keeping_expense__c, fixed_salary_all_employees__c, other__c, food_expense__c,
			clothing_expense__c, rent__c, water_electricity__c, telephone__c, transport__c, education__c, medical_expenditure__c,
			entertainment__c, insurance__c, chits_pigmy__c, total__c, asset_created_last_48_months__c, type_of_asset_declared__c,
			description_of_assets__c, asset_owner__c, date_of_purchase__c, proof_of_document__c, investment_value__c, property_owner_name__c,
			estimate_value__c, property_address__c, PD_Visit_Remarks_Recommendation_Note__c, end_use_of_loan__c
			FROM Personal_Discussion__c 
			WHERE Loan_Applicant__c  =: loanApplicantId and Application__c =: applicationId LIMIT 1];

			creditPDWrapper.personalDiscussion = personalDiscussion;

        }
    }

	public class CreditPDWrapper {
		public Personal_Discussion__c personalDiscussion {get; set;}
		public Loan_Applicant__c loanApplicant {get; set;}

	}

	
}