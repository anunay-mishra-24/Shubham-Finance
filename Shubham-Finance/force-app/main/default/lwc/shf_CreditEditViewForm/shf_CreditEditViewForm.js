import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import savePDRecords from '@salesforce/apex/SHF_PersonalDiscussionController.savePDRecords';
import getApplicantDetails from '@salesforce/apex/SHF_CreaditPDController.getApplicantDetails';
export default class Shf_CreditEditViewForm extends LightningElement {
   @api recordId = 'a04C100000110F7IAI';
    @track pdObject = {};
    @track selectedProfile = true;
    @track pdRec = {
        Name: '',
        RecordTypeId: '',
        Credit_PD_Mode__c: '',
        Application__c: '',
        Nature_of_Business__c: '',
        Industry__c: '',
        Remarks__c: '',
        PD_Activity_Status__c: '',
        Total_Expences__c: 0,
        Loan_Applicant__c: '',
        Are_you_salaried_or_self_employed__c: '',
        Is_the_GST_Report_available__c: '',
        Is_BankStatement_avail_for_BankSurrogate__c: '',
        Can_Customer_Income_be_assessed__c: '',
        Is_the_last_2_month_salary_slip_availabl__c: '',
        Is_Form_16_available__c: '',
        Is_salary_credited_in_Bank_Account__c: '',
        IsDeleted__c: false,
        Residence_Status__c: '',
        Distance_from_Branch__c: 0,
        Resi_Stability__c: 0,
        Critical_Medical_History_Details__c: '',
        Involved_In_Speculative_Activities__c: '',
        Name_of_Successor_Alternate_Handler__c: '',
        application_no__c: '',
        other__c: 0,
        rent__c: 0,
        transport__c: 0,
        telephone__c: 0,
        total__c: 0,
        entertainment__c: 0,
        chits_pigmy__c: 0,
        loan_amount_applied_in_rs_lacs__c: '',
        education__c: 0,
        medical_expenditure__c: 0,
        branch_name__c: '',
        name_of_applicant__c: '',
        sourcing_channel__c: '',
        clothing_expense__c: 0,
        food_expense__c: 0,
        insurance__c: 0,
        cibil_crif_score__c: '',
        water_electricity__c: 0,
        Name_of_the_Business__c: '',
        Person_Met__c: '',
        Relationship__c: '',
        KYC_Validated_At_Business_Place__c: '',
        Documents_Verified__c: '',
        Business_board_seen__c: '',
        Constitution_of_Business__c: '',
        Current_Office_Business_Address__c: '',
        Enter_Landmark_details__c: '',
        Business_Ownership_proof_if_available__c: '',
        Locality_of_Business_Premises_Shop__c: '',
        asset_created_last_48_months__c: '',
        date_of_purchase__c: null,
        type_of_asset_declared__c: '',
        asset_owner__c: '',
        description_of_assets__c: '',
        investment_value__c: 0,
        estimate_value__c: 0,
        property_owner_name__c: '',
        proof_of_document__c: '',
        property_address__c: '',
        end_use_of_loan__c: '',
        pd_snaps_video__c: '',
        Year_in_business__c: 0,
        Prior_Occupaton_if_different_From_Curren__c: '',
        Business_Premises__c: '',
        Occupied_Since_When__c: '',
        Size_of_the_Premises__c: '',
        Type_of_Business_premises__c: '',
        Stock_Value_observed_during_PD_visit__c: '',
        No_of_family_members_in_the_family_with__c: 0,
        Are_there_any_critical_medical_history_o__c: '',
        Any_Alternate_Successor_of_Family_Who_C__c: '',
        Whether_the_applicant_is_involved_in_onl__c: '',
        PD_Visit_Remarks_Recommendation_Note__c: null,
        office_timing__c: '',
        salary_date__c: null,
        SelfieCapturedWithReportingMa__c: '',
        employer_industry__c: '',
        SelectConditionOfEmployerSPremises__c: '',
        job_profile_of_borrower__c: '',
        week_off_day__c: '',
        nature_of_employers_business__c: '',
        incentive_received_monthly__c: '',
        office_outside_photo__c: '',
        type_of_employer_premises__c: '',
        previous_employer_name__c: '',
        employer_issued_id_card__c: '',
        no_of_coworkers_in_office__c: 0,
        employer_name__c: '',
        is_company_operating_in_shifts__c: '',
        total_experience__c: '',
        office_inside_photo__c: '',
        salary_payment_mode__c: '',
        current_fixed_salary__c: 0,
        employer_representative_met__c: '',
        date_of_joining_current_employer__c: null,
        office_name_board_photo__c: '',
        previous_employment_brief__c: '',
        salary_deducted_for_leaves__c: '',
        notes_from_credit_manager__c: null,
        employer_classification__c: '',
        DoesApplicantTakeAdvance__c: '',
        IsAnyAttendanceRecordMaintained__c: '',
        StartingSalaryOfBorrowerWithC__c: '',
        house_keeping_expense__c: 0,
        cost__c: 0,
        gross_daily_income__c: 0,
        site_details__c: '',
        item__c: '',
        margin_per_unit__c: 0,
        commission_paid_external_parties__c: 0,
        status__c: '',
        water_tea_expense__c: 0,
        work_details__c: '',
        gross_monthly_income__c: 0,
        sale_value_per_unit__c: 0,
        other_fixed_expenses__c: 0,
        total_cost_per_unit__c: 0,
        saving_per_unit__c: 0,
        period_of_service__c: '',
        fixed_salary_all_employees__c: 0,
        daily_volume__c: 0,
        contract_value__c: 0,
        shop_rent_business_premises__c: 0,
        stationery_expense__c: 0,
        Avg_amount_of_Electricity_bill_of_last_3__c: 0,
        PD_Type_Selection__c: ''
    };

    @track loanApplicantOptions = [];
    yesNoOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
    statusOptions = [
        { label: 'Completed', value: 'Completed' },
        { label: 'Running', value: 'Running' }
    ];

    relationshipOptions = [
        { label: 'Brother', value: 'Brother' },
        { label: 'Sister', value: 'Sister' },
        { label: 'Father', value: 'Father' },
        { label: 'Mother', value: 'Mother' },
        { label: 'Friend', value: 'Friend' },
        { label: 'Son', value: 'Son' },
        { label: 'Daughter', value: 'Daughter' },
        { label: 'Self', value: 'Self' },
        { label: 'Spouse', value: 'Spouse' }
    ];
    documentTypeOptions = [
        { label: 'PAN', value: 'PAN' },
        { label: 'Aadhar', value: 'Aadhar' },
        { label: 'Driving License', value: 'Driving_License' },
        { label: 'Voter ID', value: 'Voter_ID' },
        { label: 'Passport', value: 'Passport' },
        { label: 'NREGA Card', value: 'NREGA_Card' },
        { label: 'Others', value: 'Others' }
    ];
    businessTypeOptions = [
        { label: 'Private Limited', value: 'Private_Limited' },
        { label: 'Public', value: 'Public' },
        { label: 'Sole Proprietorship', value: 'Sole_Proprietorship' },
        { label: 'One Person Company', value: 'One_Person_Company' },
        { label: 'Partnership', value: 'Partnership' },
        { label: 'LLP', value: 'LLP' }
    ];
    areaTypeOptions = [
        { label: 'Urban', value: 'Urban' },
        { label: 'Rural', value: 'Rural' },
        { label: 'Mixed', value: 'Mixed' }
    ];
    residenceTypeOptions = [
        { label: 'Owned', value: 'Owned' },
        { label: 'Rented', value: 'Rented' }
    ];
    constructionTypeOptions = [
        { label: 'Kuccha', value: 'Kuccha' },
        { label: 'Pukka', value: 'Pukka' },
        { label: 'Tin Sheded', value: 'Tin_Sheded' }
    ];
    propertyTypeOptions = [
        { label: 'Commercial', value: 'Commercial' },
        { label: 'Residential', value: 'Residential' },
        { label: 'Industrial', value: 'Industrial' },
        { label: 'Others', value: 'Others' }
    ];
    residenceOptions = [
        { label: 'Owned', value: 'Owned' },
        { label: 'Rented', value: 'Rented' },
        { label: 'Other', value: 'Other' }
    ];
    purposeOptions = [
        { label: 'Purchase of House without Loan', value: 'Purchase_House_Without_Loan' },
        { label: 'Purchase of Land without Loan', value: 'Purchase_Land_Without_Loan' },
        { label: 'Purchase of House with Loan', value: 'Purchase_House_With_Loan' },
        { label: 'Purchase of Land with Loan', value: 'Purchase_Land_With_Loan' },
        { label: 'Purchase of any Vehicle without Loan', value: 'Purchase_Vehicle_Without_Loan' },
        { label: 'Purchase of Vehicle with Loan', value: 'Purchase_Vehicle_With_Loan' },
        { label: 'Purchase of Gold', value: 'Purchase_Gold' },
        { label: 'Purchase of Silver', value: 'Purchase_Silver' },
        { label: 'Purchase of Platinum', value: 'Purchase_Platinum' },
        { label: 'Purchase of Diamonds', value: 'Purchase_Diamonds' },
        { label: 'Pre-Closure of Home Loan', value: 'PreClosure_HomeLoan' },
        { label: 'Pre-Closure of LAP', value: 'PreClosure_LAP' },
        { label: 'Pre-Closure of PL / BL', value: 'PreClosure_PL_BL' },
        { label: 'Pre-Closure of AL', value: 'PreClosure_AL' },
        { label: 'Pre-Closure of Gold Loans', value: 'PreClosure_GoldLoans' },
        { label: 'Part-Payment of Home Loan', value: 'PartPayment_HomeLoan' },
        { label: 'Part-Payment of LAP', value: 'PartPayment_LAP' },
        { label: 'Part-Payment of PL / BL', value: 'PartPayment_PL_BL' },
        { label: 'Part-Payment of AL', value: 'PartPayment_AL' },
        { label: 'Margin Money or OC payment to the Proposed Property', value: 'MarginMoney_OC_Property' },
        { label: 'Investments in Shares / PPF / Mutual Funds', value: 'Investments_Shares_PPF_MF' }
    ];
    profileOptions = [
        { label: 'Retail / Job Work', value: 'Retail_JobWork' },
        { label: 'Service Provider', value: 'Service_Provider' },
        { label: 'Contractor', value: 'Contractor' },
        { label: 'Others', value: 'Others' }
    ];

    @wire(getApplicantDetails, { recordId: '$recordId' })
    wiredLoanApplicants({ data, error }) {
        if (data) {
            this.loanApplicantOptions = data;
        } else if (error) {
            console.error('Error fetching loan applicants:', error);
        }
    }
    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        console.log('field  => ', field);
        console.log('value  => ', value);
        this.pdRec = { ...this.pdRec, [field]: value };
    }
    async saveEVerification() {
        try {
            this.pdRec.Application__c = this.applicationId;
            this.pdRec.Loan_Applicant__c = this.recordId;;
            await savePDRecords({ pdRec: this.pdRec });

            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Personal Discussion record saved successfully.',
                variant: 'success'
            }));

            this.closeModal();
            window.location.reload();

        } catch (error) {
            console.error('Save error:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message || 'An unexpected error occurred.',
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }


}