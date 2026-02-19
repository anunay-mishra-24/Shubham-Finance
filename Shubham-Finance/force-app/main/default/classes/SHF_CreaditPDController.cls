/**
* @File Name : SHF_CreaditPDController.cls
* @Description :
* @Author : Gaurav Kumar
* @Last Modified By :
* @Last Modified On : December 1, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 1, 2025 |   | Initial Version
**/

public class SHF_CreaditPDController {


	@AuraEnabled(cacheable=true)
	public static Personal_Discussion__c getPDData(String recordId) {
    return [
        SELECT Id, OwnerId, IsDeleted, Name, RecordTypeId, CreatedDate, CreatedById, 
               LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, 
               LastViewedDate, LastReferencedDate, Credit_PD_Mode__c, Application__c, 
               Industry__c, Remarks__c, PD_Activity_Status__c, Total_Expences__c, 
               Loan_Applicant__c, Are_you_salaried_or_self_employed__c, 
               Is_the_GST_Report_available__c, Is_BankStatement_avail_for_BankSurrogate__c, 
               Can_Customer_Income_be_assessed__c, Is_the_last_2_month_salary_slip_availabl__c, 
               Is_Form_16_available__c, Is_salary_credited_in_Bank_Account__c, IsDeleted__c, 
               Residence_Status__c, Distance_from_Branch__c, Resi_Stability__c, 
               Critical_Medical_History_Details__c, Involved_In_Speculative_Activities__c, 
               Name_of_Successor_Alternate_Handler__c, application_no__c, other__c, rent__c, 
               transport__c, telephone__c, total__c, entertainment__c, chits_pigmy__c, 
               loan_amount_applied_in_rs_lacs__c, education__c, medical_expenditure__c, 
               branch_name__c, name_of_applicant__c, sourcing_channel__c, clothing_expense__c, 
               food_expense__c, insurance__c, cibil_crif_score__c, water_electricity__c, 
               Name_of_the_Business__c, Person_Met__c, Relationship__c, 
               KYC_Validated_At_Business_Place__c, Documents_Verified__c, 
               Business_board_seen__c, Constitution_of_Business__c, 
               Current_Office_Business_Address__c, Enter_Landmark_details__c, 
               Business_Ownership_proof_if_available__c, Locality_of_Business_Premises_Shop__c, 
               asset_created_last_48_months__c, date_of_purchase__c, type_of_asset_declared__c, 
               asset_owner__c, description_of_assets__c, investment_value__c, estimate_value__c, 
               property_owner_name__c, proof_of_document__c, property_address__c, 
               end_use_of_loan__c, pd_snaps_video__c, Year_in_business__c, 
               Prior_Occupaton_if_different_From_Curren__c, Business_Premises__c, 
               Occupied_Since_When__c, Size_of_the_Premises__c, Type_of_Business_premises__c, 
               Stock_Value_observed_during_PD_visit__c, 
               No_of_family_members_in_the_family_with__c, 
               Are_there_any_critical_medical_history_o__c, 
               Any_Alternate_Successor_of_Family_Who_C__c, 
               Whether_the_applicant_is_involved_in_onl__c, 
               PD_Visit_Remarks_Recommendation_Note__c, office_timing__c, salary_date__c, 
               SelfieCapturedWithReportingMa__c, employer_industry__c, 
               SelectConditionOfEmployerSPremises__c, job_profile_of_borrower__c, 
               week_off_day__c, nature_of_employers_business__c, incentive_received_monthly__c, 
               office_outside_photo__c, type_of_employer_premises__c, previous_employer_name__c, 
               employer_issued_id_card__c, no_of_coworkers_in_office__c, employer_name__c, 
               is_company_operating_in_shifts__c, total_experience__c, office_inside_photo__c, 
               salary_payment_mode__c, current_fixed_salary__c, employer_representative_met__c, 
               date_of_joining_current_employer__c, office_name_board_photo__c, 
               previous_employment_brief__c, salary_deducted_for_leaves__c, 
               notes_from_credit_manager__c, employer_classification__c, 
               DoesApplicantTakeAdvance__c, IsAnyAttendanceRecordMaintained__c, 
               StartingSalaryOfBorrowerWithC__c, house_keeping_expense__c, cost__c, 
               gross_daily_income__c, site_details__c, item__c, margin_per_unit__c, 
               commission_paid_external_parties__c, status__c, water_tea_expense__c, 
               work_details__c, gross_monthly_income__c, sale_value_per_unit__c, 
               other_fixed_expenses__c, total_cost_per_unit__c, saving_per_unit__c, 
               period_of_service__c, fixed_salary_all_employees__c, daily_volume__c, 
               contract_value__c, shop_rent_business_premises__c, stationery_expense__c, 
               Avg_amount_of_Electricity_bill_of_last_3__c, PD_Type_Selection__c, 
               Nature_of_Business__c, Any_other_Prior_Occupatoin__c, 
               KYC_validation_at_Visit_docs_seen_like__c
        FROM Personal_Discussion__c WHERE Id =:recordId
    ];
}


	@AuraEnabled(cacheable=true)
	public static ApplicantDetailsWrapper getApplicantDetails(String recordId){
		ApplicantDetailsWrapper wrapObj = new ApplicantDetailsWrapper();
        List<Address__c> addObj = [Select Id,Address_Line_1__c from Address__c Where Loan_Applicant__c =:recordId and Address_Line_1__c != null order by CreatedDate desc LIMIT 1];
		Loan_Applicant__c loanApplicant = [SELECT Id,Name,Application__r.Name,Application__r.Branch__r.Name,Application__r.Applied_Loan_Amount__c,CIBIL_Verification__r.Score__c,CRIF_Verification__r.Score__c, Industry__c,Business_Employer_Name__c,Application__r.Lead__r.Channel__c FROM Loan_Applicant__c where Id =:recordId];
        List<Employment__c> emplymntList = [Select ID,Industry__c, Business_Employer_Name__c,Loan_Applicant__r.Name from Employment__c WHERE Loan_Applicant__c=:recordId order by CreatedDate DESC LIMIT 1];
		wrapObj.Id                  = loanApplicant != null ? loanApplicant.Id : null;
		wrapObj.nameOfApplicant     = loanApplicant != null ? loanApplicant.Name : '';
		wrapObj.branchName          = loanApplicant != null && loanApplicant.Application__r != null && loanApplicant.Application__r.Branch__r != null ? loanApplicant.Application__r.Branch__r.Name : '';
		wrapObj.applicationNumber   = loanApplicant != null && loanApplicant.Application__r != null ? loanApplicant.Application__r.Name : '';
		wrapObj.sourcingChannel     = loanApplicant != null && loanApplicant.Application__r.Lead__r != null ? loanApplicant.Application__r.Lead__r.Channel__c : '';
		wrapObj.loanAmountApplied   = loanApplicant != null && loanApplicant.Application__r != null ? loanApplicant.Application__r.Applied_Loan_Amount__c : null;
		wrapObj.cibilScore          = loanApplicant != null && loanApplicant.CIBIL_Verification__r != null ? loanApplicant.CIBIL_Verification__r.Score__c : null;
        wrapObj.crifScore          = loanApplicant != null && loanApplicant.CRIF_Verification__r != null ? loanApplicant.CRIF_Verification__r.Score__c : null;
        wrapObj.employeeName        = emplymntList != null && emplymntList.size() > 0 && emplymntList[0].Business_Employer_Name__c != null ? emplymntList[0].Business_Employer_Name__c : null;
        wrapObj.industry            = emplymntList != null && emplymntList.size() > 0 && emplymntList[0].Industry__c != null ? emplymntList[0].Industry__c : null;
        wrapObj.address             = addObj != null && addObj.size() > 0 && addObj[0].Address_Line_1__c != null ? addObj[0].Address_Line_1__c: null;
		return wrapObj;


	}
    @AuraEnabled
    public static void saveDetails(String details,String recordId) {
        
        System.debug('DETAILS => ' + details);
        String profileRecordTypId = Schema.getGlobalDescribe().get('Personal_Discussion_Details__c').getDescribe().getRecordTypeInfosByName().get('Other').getRecordTypeId(); 
        List<DetailWrapper> warperData;
        try {
            warperData = (List<DetailWrapper>) JSON.deserialize(details, List<DetailWrapper>.class);
        } catch (Exception ex) {
            throw new AuraHandledException('Invalid JSON payload: ' + ex.getMessage());
        }        
        List<Personal_Discussion_Details__c> records =
            new List<Personal_Discussion_Details__c>();
            List<Personal_Discussion_Details__c> recordsToInsert =
            new List<Personal_Discussion_Details__c>();
        
        for (DetailWrapper d : warperData) {
            if(d.sfId != null){
                records.add(new Personal_Discussion_Details__c(
                Label__c   = d.label,
                Id= d.sfId,
                Value__c   = String.valueOf(d.value),
                Section__c = d.section,
                Order__c   = d.orderNo,
                Personal_Discussion__c = recordId,
                RecordTypeId = profileRecordTypId
            ));
            }else{
                recordsToInsert.add(new Personal_Discussion_Details__c(
                Label__c   = d.label,
                Value__c   = String.valueOf(d.value),
                Section__c = d.section,
                Order__c   = d.orderNo,
                Personal_Discussion__c = recordId,
                RecordTypeId = profileRecordTypId
                ));
            }
            
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
        if (!records.isEmpty()) {
            update records;
            
        }
        
    }
    @AuraEnabled
    public static List<DetailWrapper> getPDDetails(String parentRecordId) {
        List<DetailWrapper> results = new List<DetailWrapper>();
        if (parentRecordId == null) return results;

		List<Personal_Discussion_Details__c> pdList = [SELECT Id, Personal_Discussion__c, Order__c, Section__c, 
										Value__c, Label__c FROM Personal_Discussion_Details__c 
										WHERE Personal_Discussion__r.Loan_Applicant__c = :parentRecordId AND RecordType.Name = 'Other'];

        for (Personal_Discussion_Details__c r : pdList) {
            DetailWrapper w = new DetailWrapper();
            w.sfId = r.Id;
            w.orderNo = r.Order__c;
            w.section = r.Section__c;
            w.value = r.Value__c;
            w.label = r.Label__c;
            results.add(w);
        }
        System.debug('results :: '+results);
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<Loan_Applicant__c> getLoanApplicantCreditPd(Id loanApplicantId) {
        return [
            SELECT Id, Name,Account_Name__c, Employment_Type__c, Customer_Profile__c, Subcategory__c, RecordType_Name__c,Expense__c
            FROM Loan_Applicant__c 
            WHERE Id = :loanApplicantId AND IsDeleted__c = false 
        ];
    }
     @AuraEnabled
    public static String savePersonalDetails(Map<String, Object> pdRec) {
        System.debug('pdRec :'+pdRec);
        System.debug('pdRec pdRec :'+pdRec.get('Id'));
        String recordTypeId = Schema.SObjectType.Personal_Discussion__c
            .getRecordTypeInfosByName()
            .get('Credit PD')
            .getRecordTypeId();
        Personal_Discussion__c rec = new Personal_Discussion__c();
        if (pdRec.get('Id') != null) {
            rec.Id = (Id) pdRec.get('Id');
        }
        rec.Food_Expense__c = toDecimal(pdRec.get('food_expense__c'));
        rec.Clothing_Expense__c = toDecimal(pdRec.get('clothing_expense__c'));
        rec.Rent__c = toDecimal(pdRec.get('rent__c'));
        rec.Water_Electricity__c = toDecimal(pdRec.get('water_electricity__c'));
        rec.Telephone__c = toDecimal(pdRec.get('telephone__c'));
        rec.Transport__c = toDecimal(pdRec.get('transport__c'));
        rec.Education__c = toDecimal(pdRec.get('education__c'));
        rec.Medical_Expenditure__c = toDecimal(pdRec.get('medical_expenditure__c'));
        rec.Entertainment__c = toDecimal(pdRec.get('entertainment__c'));
        rec.Insurance__c = toDecimal(pdRec.get('insurance__c'));
        rec.Chits_Pigmy__c = toDecimal(pdRec.get('chits_pigmy__c'));

        rec.Total__c = toDecimal(pdRec.get('total__c'));
        rec.Loan_Applicant__c = (Id) pdRec.get('Loan_Applicant__c');
        rec.RecordTypeId = recordTypeId;

        upsert rec;
        return rec.Id;
    }
    private static Decimal toDecimal(Object val) {
    if (val == null) {
        return null;
    }

    String strVal = String.valueOf(val).trim();

    if (String.isBlank(strVal)) {
        return null;
    }

    return Decimal.valueOf(strVal);
}

    @AuraEnabled
    public static PDExpenseWrapper getPersonalDetails(Id loanApplicantId) {
        if (loanApplicantId == null) return null;

        List<Personal_Discussion__c> recList =[SELECT Id,Food_Expense__c, Clothing_Expense__c, Rent__c, Water_Electricity__c, Telephone__c, Transport__c, Education__c, Medical_Expenditure__c,
                                    Entertainment__c, Insurance__c, Chits_Pigmy__c, Total__c, Loan_Applicant__r.Expense__c,Loan_Applicant__r.Customer_Profile__c,other__c
                                    FROM Personal_Discussion__c
                                    WHERE Loan_Applicant__c = :loanApplicantId AND RecordType.Name = 'Credit PD' order by createdDate desc LIMIT 1];
        Loan_Applicant__c lonApp = [SELECT Id, Customer_Profile__c,Expense__c FROM Loan_Applicant__c WHERE Id = :loanApplicantId];

        PDExpenseWrapper w = new PDExpenseWrapper();

        if (lonApp.Customer_Profile__c != null) {
            w.customerProfile = lonApp.Customer_Profile__c;
            w.totalExpense = lonApp.Expense__c;
            w.expense = lonApp.Expense__c;
        }
        if (!recList.isEmpty()) {
        Personal_Discussion__c rec = recList[0];

        w.Id = rec.Id;
        w.foodExpense = rec.Food_Expense__c;
        w.clothingExpense = rec.Clothing_Expense__c;
        w.rent = rec.Rent__c;
        w.waterElectricity = rec.Water_Electricity__c;
        w.telephone = rec.Telephone__c;
        w.transport = rec.Transport__c;
        w.education = rec.Education__c;
        w.medicalExpenditure = rec.Medical_Expenditure__c;
        w.entertainment = rec.Entertainment__c;
        w.insurance = rec.Insurance__c;
        w.chitsPigmy = rec.Chits_Pigmy__c;
        w.total = rec.Total__c;
        w.other = rec.other__c;
        
        if (rec.Loan_Applicant__r != null) {
            w.totalExpense = rec.Loan_Applicant__r.Expense__c;
            w.expense = rec.Loan_Applicant__r.Expense__c > rec.Total__c ? rec.Loan_Applicant__r.Expense__c :rec.Total__c;

            w.customerProfile = rec.Loan_Applicant__r.Customer_Profile__c;
        }
    }
        
        return w;
    }
    @AuraEnabled(cacheable=true)
    public static List<PropertyWrapper> getPropertyDetails(String applicationId) {
        List<PropertyWrapper> result = new List<PropertyWrapper>();
        Set<Id> collIdSet = new Set<Id>();
        for(Collateral_Application__c colApp : [SELECT Id,Collateral__c,Collateral__r.Accepted_Valuation_INR__c FROM Collateral_Application__c WHERE Application__c =:applicationId]){
            if(colApp.Collateral__c != null){
                collIdSet.add(colApp.Collateral__c);
            }
        }
        List<Collateral_Seller_Owner__c> collSellerList = [SELECT Id,Name,Collateral__r.Accepted_Valuation_INR__c,Collateral__r.Full_Address__c FROM Collateral_Seller_Owner__c WHERE RecordType.Name='Owner'  AND Collateral__c IN :collIdSet];
        System.debug('collSellerList :: '+collSellerList);
        for(Collateral_Seller_Owner__c collOwner :collSellerList){
            result.add(new PropertyWrapper(
                collOwner.Name,
                collOwner.Collateral__r.Accepted_Valuation_INR__c,
                collOwner.Collateral__r.Full_Address__c
            ));
        }
        System.debug('PropertyWrapper :: '+result);
        return result;
    }
    
    public class DetailWrapper {
        @AuraEnabled public Id sfId;
        @AuraEnabled public String label;
        @AuraEnabled public String value;   
        @AuraEnabled public String section;
        @AuraEnabled public Decimal orderNo;
    }
	public class ApplicantDetailsWrapper {
		@AuraEnabled public String Id;
        @AuraEnabled public String nameOfApplicant;
        @AuraEnabled public String branchName;
        @AuraEnabled public String applicationNumber;
        @AuraEnabled public String sourcingChannel;
		@AuraEnabled public Decimal loanAmountApplied;
		@AuraEnabled public String cibilScore;
        @AuraEnabled public String crifScore;
        @AuraEnabled public String employeeName;
        @AuraEnabled public String industry;
        @AuraEnabled public String address;
    }
    public class PDExpenseWrapper {
        @AuraEnabled public Decimal foodExpense;
        @AuraEnabled public Decimal clothingExpense;
        @AuraEnabled public Decimal rent;
        @AuraEnabled public Decimal waterElectricity;
        @AuraEnabled public Decimal telephone;
        @AuraEnabled public Decimal transport;
        @AuraEnabled public Decimal education;
        @AuraEnabled public Decimal medicalExpenditure;
        @AuraEnabled public Decimal entertainment;
        @AuraEnabled public Decimal insurance;
        @AuraEnabled public Decimal chitsPigmy;
        @AuraEnabled public Decimal total;
        @AuraEnabled public Decimal expense;
        @AuraEnabled public Decimal totalExpense;
        @AuraEnabled public Decimal other;
        @AuraEnabled public String customerProfile;
        @AuraEnabled public String Id;
    }
    public class PropertyWrapper {
        @AuraEnabled public String ownerName;
        @AuraEnabled public Decimal estimateValue;
        @AuraEnabled public String propertyAddress;

    public PropertyWrapper(String ownerName, Decimal estimateValue, String propertyAddress) {
        this.ownerName = ownerName;
        this.estimateValue = estimateValue;
        this.propertyAddress = propertyAddress;
    }
}

}