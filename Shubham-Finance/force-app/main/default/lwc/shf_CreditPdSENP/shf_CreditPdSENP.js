import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import formFactorPropertyName from "@salesforce/client/formFactor";
import savePDRecords from '@salesforce/apex/SHF_PersonalDiscussionController.savePDRecords';
import getCustomerReferences from '@salesforce/apex/PDReferenceService.getCustomerReferences';
import getSuplierReferences from '@salesforce/apex/PDReferenceService.getSuplierReferences';
import deleteReference from '@salesforce/apex/PDReferenceService.deleteReference';
import getPDDetails from '@salesforce/apex/SHF_CreaditPDController.getPDDetails';
import saveDetails from '@salesforce/apex/SHF_CreaditPDController.saveDetails';
import getPdDynamic from '@salesforce/apex/SHF_PersonalDiscussionController.getPdDynamic';
import getApplicantDetails from '@salesforce/apex/SHF_CreaditPDController.getApplicantDetails';
import getBranchAddress from '@salesforce/apex/SHF_PersonalDiscussionController.getBranchAddress';
import checkDMSRequiredDoc from '@salesforce/apex/PDReferenceService.checkDMSRequiredDoc';
import fetchProfileWiseData from '@salesforce/apex/SHF_PersonalDiscussionController.fetchProfileWiseData';
import getPropertyDetails from '@salesforce/apex/SHF_CreaditPDController.getPropertyDetails';
export default class Shf_CreditPdSENP extends NavigationMixin(LightningElement) {
    @api recordId;
    @api applicationId;
    @api isReadOnly;
    @track pdRecordId;
    @track selectedProfile = true;
    @track isLocationEnabled = false;
    @track isMedical = false;
    @track isGaming = false;
    @track isAlternate = false;
    @track isDocument = false;
    @track isOwnership = false;
    @track isMand = false;
    @track isAsset_created_last_48_months__c = false;
    @track isBusDes = false;
    @track isOccupation = false;
    @track isRentedProperty = false;
    @track isRetail_JobWork = false;
    @track isService_Provider = false;
    @track isContractor = false;
    @track isOthersProfile = false;
    @track showConfirm = false;
    @track isRequired = false;
    @track selectedLabel = '';
    @track docName = 'Applicant Credit PD';
    @track deviceType;
    @track accessMode;
    @track isMobile = false;
    @track isDelete;
    @track calculateTotal = [];
    @track retailGrossMonthly = 0;
    @track retailgrossDaily = 0;
    @track serProGrossMonthly = 0;
    @track serProGrossDaily = 0;
    @track contractorGrossMonthly = 0;
    @track contractorgrossDaily = 0;
    latitude;
    longitude;
    locationSet = false;
    @track pdRec = {
        Name: '',
        RecordTypeId: '',
        Credit_PD_Mode__c: '',
        Application__c: '',
        Nature_of_Business__c: '',
        Industry__c: '',
        Remarks__c: '',
        PD_Activity_Status__c: '',
        Total_Expences__c: null,
        Loan_Applicant__c: '',
        Are_you_salaried_or_self_employed__c: '',
        Is_the_GST_Report_available__c: '',
        Is_BankStatement_avail_for_BankSurrogate__c: '',
        Can_Customer_Income_be_assessed__c: '',
        Is_the_last_2_month_salary_slip_availabl__c: '',
        Credit_PD_Locaton__Latitude__s: null,
        Credit_PD_Locaton__Longitude__s: null,
        Is_Form_16_available__c: '',
        Is_salary_credited_in_Bank_Account__c: '',
        IsDeleted__c: false,
        Residence_Status__c: '',
        Distance_from_Branch__c: null,
        Resi_Stability__c: null,
        Critical_Medical_History_Details__c: '',
        Involved_In_Speculative_Activities__c: '',
        Name_of_Successor_Alternate_Handler__c: '',
        application_no__c: '',
        other__c: null,
        rent__c: null,
        transport__c: null,
        telephone__c: null,
        total__c: null,
        entertainment__c: null,
        chits_pigmy__c: null,
        loan_amount_applied_in_rs_lacs__c: '',
        education__c: null,
        medical_expenditure__c: null,
        branch_name__c: '',
        name_of_applicant__c: '',
        sourcing_channel__c: '',
        clothing_expense__c: null,
        food_expense__c: null,
        insurance__c: null,
        cibil_crif_score__c: '',
        water_electricity__c: null,
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
        investment_value__c: null,
        estimate_value__c: null,
        property_owner_name__c: '',
        proof_of_document__c: '',
        property_address__c: '',
        end_use_of_loan__c: '',
        pd_snaps_video__c: '',
        Year_in_business__c: null,
        Prior_Occupaton_if_different_From_Curren__c: '',
        Business_Premises__c: '',
        Occupied_Since_When__c: '',
        Size_of_the_Premises__c: '',
        Type_of_Business_premises__c: '',
        Stock_Value_observed_during_PD_visit__c: '',
        No_of_family_members_in_the_family_with__c: '',
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
        no_of_coworkers_in_office__c: null,
        employer_name__c: '',
        is_company_operating_in_shifts__c: '',
        total_experience__c: '',
        office_inside_photo__c: '',
        salary_payment_mode__c: '',
        current_fixed_salary__c: null,
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
        house_keeping_expense__c: null,
        cost__c: null,
        gross_daily_income__c: null,
        site_details__c: '',
        item__c: '',
        margin_per_unit__c: null,
        commission_paid_external_parties__c: null,
        status__c: '',
        water_tea_expense__c: null,
        work_details__c: '',
        gross_monthly_income__c: null,
        sale_value_per_unit__c: null,
        other_fixed_expenses__c: null,
        total_cost_per_unit__c: null,
        saving_per_unit__c: null,
        period_of_service__c: '',
        fixed_salary_all_employees__c: null,
        daily_volume__c: null,
        contract_value__c: null,
        shop_rent_business_premises__c: null,
        stationery_expense__c: null,
        Avg_amount_of_Electricity_bill_of_last_3__c: null,
        PD_Type_Selection__c: '',
        Type_Of_Business__c: '',
        CRIF_Score__c: null,
        Alternate_Successor_Reason__c: '',
        Medical_Reason__c: '',
        Business_Description__c: '',
        Reason_for_Change_in_Occupation__c: '',
        Documents_Description__c: '',
        CIBIL_Score__c: null,
        Online_Gaming_Reason__c: '',
        Id: null,
        isSaveDisabled: false
    };
    householdFields = [
        'food_expense__c',
        'clothing_expense__c',
        'rent__c',
        'water_electricity__c',
        'telephone__c',
        'transport__c',
        'education__c',
        'medical_expenditure__c',
        'entertainment__c',
        'insurance__c',
        'chits_pigmy__c',
        'other__c'
    ];
    householdFields = [
        'food_expense__c',
        'clothing_expense__c',
        'rent__c',
        'water_electricity__c',
        'telephone__c',
        'transport__c',
        'education__c',
        'medical_expenditure__c',
        'entertainment__c',
        'insurance__c',
        'chits_pigmy__c',
        'other__c'
    ];
    rules = {
        PD_Visit_Remarks_Recommendation_Note__c: { min: 250, max: 10000 },
        investment_value__c: { type: 'number', minValue: 1, maxLength: 9 },
        Distance_from_Branch__c: { type: 'number', minValue: 1, maxLength: 9 },
        Resi_Stability__c: { type: 'number', minValue: 1, maxLength: 9 },

        Year_in_business__c: { type: 'number', minValue: 1, maxLength: 9 },

        value: { type: 'number', minValue: 1, maxLength: 9 },
        creditPeriod: { type: 'number', minValue: 1, maxLength: 9 },

        dailyVolume: { type: 'number', minValue: 1, maxLength: 9 },
        cost: { type: 'number', minValue: 1, maxLength: 9 },
        totalCost: { type: 'number', minValue: 1, maxLength: 9 },
        saleUnit: { type: 'number', minValue: 1, maxLength: 9 },
        savingUnit: { type: 'number', minValue: 1, maxLength: 9 },

        shop_rent_business_premises__c: { type: 'number', minValue: 1, maxLength: 9 },
        Avg_amount_of_Electricity_bill_of_last_3__c: { type: 'number', minValue: 1, maxLength: 9 },
        other_fixed_expenses__c: { type: 'number', minValue: 1, maxLength: 9 },
        water_tea_expense__c: { type: 'number', minValue: 1, maxLength: 9 },
        stationery_expense__c: { type: 'number', minValue: 1, maxLength: 9 },
        commission_paid_external_parties__c: { type: 'number', minValue: 1, maxLength: 9 },
        house_keeping_expense__c: { type: 'number', minValue: 1, maxLength: 9 },
        fixed_salary_all_employees__c: { type: 'number', minValue: 1, maxLength: 9 },

        food_expense__c: { type: 'number', minValue: 1, maxLength: 9 },
        clothing_expense__c: { type: 'number', minValue: 1, maxLength: 9 },
        rent__c: { type: 'number', minValue: 1, maxLength: 9 },
        water_electricity__c: { type: 'number', minValue: 1, maxLength: 9 },
        telephone__c: { type: 'number', minValue: 1, maxLength: 9 },
        transport__c: { type: 'number', minValue: 1, maxLength: 9 },
        education__c: { type: 'number', minValue: 1, maxLength: 9 },
        medical_expenditure__c: { type: 'number', minValue: 1, maxLength: 9 },
        entertainment__c: { type: 'number', minValue: 1, maxLength: 9 },
        insurance__c: { type: 'number', minValue: 1, maxLength: 9 },
        chits_pigmy__c: { type: 'number', minValue: 1, maxLength: 9 },
        total__c: { type: 'number', minValue: 1, maxLength: 9 }
    };

    @track validField = false;
    @track rowsData = [];
    error;
    @track loanApplicantOptions = [];
    filterList = [];
    keyIndex = 0;
    @track suppliers = [];
    @track customers = [];
    @track retails = [];
    @track contractor = [];
    @track OthersProfile = [];
    @track serviceProvider = [];
    @track finalArray = [];
    @track finalArrayForProfile = [];
    @track businessExpenseRows = [];
    @track householdExpenseRows = [];
    @track finalArrayJson = '';
    counter = 0;
    rowId = 0;
    @api validateRequiredData() {
        let isFocused = false;
        let isValid = true;
        const senpProfileComp = this.template.querySelector('c-shf_-credit-p-d-senp-profile');
        console.log('senpProfileComp 111:', senpProfileComp);

        if (senpProfileComp && typeof senpProfileComp.validateRequiredData === 'function') {
            isValid = senpProfileComp.validateRequiredData();
            console.log('senpProfileComp 111:', isValid);
        }
        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea, lightning-record-picker'
        );

        inputs.forEach(element => {
            element.reportValidity();
            if (!element.checkValidity()) {
                isValid = false;
                if (!isFocused) {
                    if (typeof element.focus === 'function') {
                        element.focus();
                    }
                    isFocused = true;
                }
            }
        });

        this.validField = isValid;
        console.log('validField child :', this.validField);
        const sendValid = new CustomEvent('sendisvalid', {
            detail: {
                isValid: this.validField
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(sendValid);
    }
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
        { label: 'Driving License', value: 'Driving License' },
        { label: 'Voter ID', value: 'Voter ID' },
        { label: 'Passport', value: 'Passport' },
        { label: 'NREGA Card', value: 'NREGA Card' },
        { label: 'Others', value: 'Others' }
    ];
    businessTypeOptions = [
        { label: 'Private Limited', value: 'Private Limited' },
        { label: 'Public', value: 'Public' },
        { label: 'Sole Proprietorship', value: 'Sole Proprietorship' },
        { label: 'One Person Company', value: 'One Person Company' },
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
        { label: 'Tin Sheded', value: 'Tin Sheded' }
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
    typeOfBusOptions = [
        { label: 'GST', value: 'GST' },
        { label: 'MSME', value: 'MSME' },
        { label: 'Udyam Aadhar', value: 'Udyam Aadhar' },
        { label: 'Others', value: 'Others' }
    ];
    purposeOptions = [
        { label: 'Purchase of House without Loan', value: 'Purchase of House without Loan' },
        { label: 'Purchase of Land without Loan', value: 'Purchase of Land without Loan' },
        { label: 'Purchase of House with Loan', value: 'Purchase of House with Loan' },
        { label: 'Purchase of Land with Loan', value: 'Purchase of Land with Loan' },
        { label: 'Purchase of any Vehicle without Loan', value: 'Purchase of any Vehicle without Loan' },
        { label: 'Purchase of Vehicle with Loan', value: 'Purchase of Vehicle with Loan' },
        { label: 'Purchase of Gold', value: 'Purchase of Gold' },
        { label: 'Purchase of Silver', value: 'Purchase of Silver' },
        { label: 'Purchase of Platinum', value: 'Purchase of Platinum' },
        { label: 'Purchase of Diamonds', value: 'Purchase of Diamonds' },
        { label: 'Pre-Closure of Home Loan', value: 'Pre-Closure of Home Loan' },
        { label: 'Pre-Closure of LAP', value: 'Pre-Closure of LAP' },
        { label: 'Pre-Closure of PL / BL', value: 'Pre-Closure of PL / BL' },
        { label: 'Pre-Closure of AL', value: 'Pre-Closure of AL' },
        { label: 'Pre-Closure of Gold Loans', value: 'Pre-Closure of Gold Loans' },
        { label: 'Part-Payment of Home Loan', value: 'Part-Payment of Home Loan' },
        { label: 'Part-Payment of LAP', value: 'Part-Payment of LAP' },
        { label: 'Part-Payment of PL / BL', value: 'Part-Payment of PL / BL' },
        { label: 'Part-Payment of AL', value: 'Part-Payment of AL' },
        { label: 'Margin Money or OC payment to the Proposed Property', value: 'Margin Money or OC payment to the Proposed Property' },
        { label: 'Investments in Shares / PPF / Mutual Funds', value: 'Investments in Shares / PPF / Mutual Funds' }
    ];
    profileOptions = [
        { label: 'Retail / Job Work', value: 'Retail / Job Work' },
        { label: 'Service Provider', value: 'Service Provider' },
        { label: 'Contractor', value: 'Contractor' },
        { label: 'Others', value: 'Others' }
    ];
    profileStatusOptions = [
        { label: 'Running', value: 'Running' },
        { label: 'Completed', value: 'Completed' }
    ];

    get disableRemoveSupplier() {
        return !(this.suppliers && this.suppliers.length > 1);
    }
    get disableRemoveRetails() {
        return !(this.retails && this.retails.length > 1);
    }

    get disableRemoveCustomer() {
        return !(this.customers && this.customers.length > 1);
    }
    get disableRemoveContractor() {
        return !(this.contractor && this.contractor.length > 1);
    }
    get disableRemoveOthersProfile() {
        return !(this.OthersProfile && this.OthersProfile.length > 1);
    }

    get disableRemoveserviceProvider() {
        return !(this.serviceProvider && this.serviceProvider.length > 1);
    }

    get uploadUrl() {
        return `shubhamshf://docupload?recordId=${this.recordId}&docName=${this.docName}`;
    }
    get todayDate() {
        return new Date().toISOString().split('T')[0];
    }
    get containerClass() {
        return this.isReadOnly ? 'read-only-container' : '';
    }

    @wire(getPropertyDetails, { applicationId: '$applicationId' })
    wiredProperties({ data, error }) {
        if (data) {
            this.rowsData = data.map((item, index) => ({
                id: index,
                ownerName: item.ownerName,
                estimateValue: item.estimateValue,
                address: item.propertyAddress
            }));
        } else if (error) {
            this.error = error;
            console.error(error);
        }
    }

    @wire(getApplicantDetails, { recordId: '$recordId' })
    wiredLoanApplicants({ data, error }) {
        if (data) {
            console.log('Current_Office_Business_Address__c', data.address);
            this.loanApplicantOptions = data;
            this.pdRec.Current_Office_Business_Address__c = data.address;
        } else if (error) {
            console.error('Error fetching loan applicants:', error);
        }
    }

    async connectedCallback() {
        this.handleFormFactor();
        this.handleAppOrBrowser();
        this.suppliers = [this.newRow('Supplier')];
        this.customers = [this.newRow('Customer')];
        this.retails = [this.newRowForRetail('retails')];
        this.serviceProvider = [this.newRowForRetail('serviceProvider')];
        this.OthersProfile = [this.newRowForRetail('OthersProfile')];
        this.contractor = [this.newRowForRetail('Contractor')];
        try {
            this.getPdRecords();
            this.updateFinalArray();
            await this.getCurrentLocation();
            this.isLocationEnabled = true;
            console.log(' Location enabled — opening New Address modal.');
        } catch (error) {
            this.isLocationEnabled = false;
            console.warn('GPS not available:', error.message);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning',
                    message: 'GPS is OFF — address will save without location coordinates.',
                    variant: 'warning'
                })
            );
        }

    }

    handleFormFactor() {
        console.log('formFactorPropertyName', formFactorPropertyName);
        // if (FORM_FACTOR === 'Large') {
        //     this.deviceType = 'Desktop/Laptop';
        // } else if (FORM_FACTOR === 'Medium') {
        //     this.deviceType = 'Tablet';
        // } else {
        //     this.deviceType = 'Mobile';
        // }
    }
    handleAppOrBrowser() {
        const ua = navigator.userAgent;

        // Salesforce Mobile App user agent contains "Salesforce"
        if (/Salesforce/i.test(ua)) {
            this.accessMode = 'Salesforce Mobile App';
            this.isMobile = true;
        } else {
            this.accessMode = 'Browser';
        }
        console.log('this.accessMode :', this.accessMode);
    }

    getPdRecords() {
        getPdDynamic({ loanApplicantId: this.recordId })
            .then(result => {
                if (result) {
                    console.log('this.pdRec result :', result.total__c);
                    this.pdRec = {
                        ...this.pdRec,
                        ...result
                    };
                    //this.pdRec = Object.assign({}, this.pdRec, result);
                    this.pdRec.total__c = result.total__c != null ? Number(result.total__c) : 0;
                    if (this.pdRec.Current_Office_Business_Address__c == null) {
                        this.pdRec.Current_Office_Business_Address__c = result.Current_Office_Business_Address__c;
                    }
                    console.log('this.pdRec total__c :', this.pdRec.total__c);
                    this.pdRecordId = result.Id;
                    this.dispatchPdEvent();
                    if (this.pdRecordId) {
                        if (this.pdRec.Are_there_any_critical_medical_history_o__c === 'Yes') {
                            this.isMedical = true;
                        } else if (this.pdRec.Are_there_any_critical_medical_history_o__c === 'No') {
                            this.isMedical = false;
                        }
                        if (this.pdRec.Whether_the_applicant_is_involved_in_onl__c === 'Yes') {
                            this.isGaming = true;
                        } else if (this.pdRec.Whether_the_applicant_is_involved_in_onl__c === 'No') {
                            this.isGaming = false;
                        }
                        if (this.pdRec.Any_Alternate_Successor_of_Family_Who_C__c === 'Yes') {
                            this.isAlternate = true;
                        } else if (this.pdRec.Any_Alternate_Successor_of_Family_Who_C__c === 'No') {
                            this.isAlternate = false;
                        }
                        if (this.pdRec.Documents_Verified__c === 'Others') {
                            this.isDocument = true;
                        } else if (this.pdRec.Documents_Verified__c != 'Others') {
                            this.isDocument = false;
                        }
                        if (this.pdRec.Business_Ownership_proof_if_available__c === 'Yes') {
                            this.isOwnership = true;
                        } else if (this.pdRec.Business_Ownership_proof_if_available__c === 'No') {
                            this.isOwnership = false;
                        }
                        if (this.pdRec.Type_Of_Business__c === 'Others') {
                            this.isBusDes = true;
                        } else if (this.pdRec.Type_Of_Business__c != 'Others') {
                            this.isBusDes = false;
                        }
                        if (this.pdRec.Prior_Occupaton_if_different_From_Curren__c === 'Yes') {
                            this.isOccupation = true;
                        } else if (this.pdRec.Prior_Occupaton_if_different_From_Curren__c === 'No') {
                            this.isOccupation = false;
                        }
                        if (this.pdRec.asset_created_last_48_months__c === 'Yes') {
                            this.isAsset_created_last_48_months__c = true;
                        } else if (this.pdRec.asset_created_last_48_months__c === 'No') {
                            this.isAsset_created_last_48_months__c = false;
                        }
                        if (this.pdRec.Business_Premises__c === 'Rented') {
                            this.isRentedProperty = true;
                        } else if (this.pdRec.Business_Premises__c != 'Rented') {
                            this.isRentedProperty = false;
                        }
                        if (this.pdRec.KYC_Validated_At_Business_Place__c === 'Yes') {
                            this.isMand = true;
                        } else if (this.pdRec.KYC_Validated_At_Business_Place__c === 'No') {
                            this.isMand = false;
                        }
                        //this.calculateHouseholdTotal(this.pdRec);
                        this.loadCustomers();
                        this.loadSuppliers();
                        this.loadProfileData();
                        this.loadPDDetails();
                    }
                    console.log('getPdDynamic Id:', this.pdRecordId);
                }
                console.log('this.pdRec111111:', this.pdRec);

            })
            .catch(error => {
                console.error('Error saving PD:', error);
                // e.g. show error toast
            });
    }
    getCurrentLocation() {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Geolocation is not supported by your browser.'));
                return;
            }

            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.pdRec.Credit_PD_Locaton__Latitude__s = this.latitude;
                    this.pdRec.Credit_PD_Locaton__Longitude__s = this.longitude;
                    this.locationSet = true;
                    getBranchAddress({ applicationId: this.applicationId, latitude: this.latitude, longitude: this.longitude })
                        .then(result => {
                            console.log('result  ', result);
                            this.pdRec.Distance_from_Branch__c = (result !== null && result !== undefined) ? result : 0;
                        })
                        .catch(error => {
                            console.log('error  ', error);
                        });
                    resolve();
                },
                (error) => {
                    let message = '';
                    switch (error.code) {
                        case error.PERMISSION_DENIED:
                            message = 'Location permission denied.';
                            break;
                        case error.POSITION_UNAVAILABLE:
                            message = 'Location unavailable.';
                            break;
                        case error.TIMEOUT:
                            message = 'Location request timed out.';
                            break;
                        default:
                            message = error.message;
                    }
                    reject(new Error(message));
                },
                {
                    enableHighAccuracy: false,
                    timeout: 60000,
                    maximumAge: 60000
                }
            );
        });
    }
    handleChange(event) {


        const field = event.target.dataset.field;
        const value = event.target.value;
        const name = event.target.name;
        console.log('field  => ', field);
        console.log('value  => ', value);
        console.log('name  => ', name);
        if (field === 'Are_there_any_critical_medical_history_o__c' && value === 'Yes') {
            this.isMedical = true;
        } else if (field === 'Are_there_any_critical_medical_history_o__c' && value === 'No') {
            this.isMedical = false;
        } else if (field === 'Whether_the_applicant_is_involved_in_onl__c' && value === 'Yes') {
            this.isGaming = true;
        } else if (field === 'Whether_the_applicant_is_involved_in_onl__c' && value === 'No') {
            this.isGaming = false;
        } else if (field === 'Any_Alternate_Successor_of_Family_Who_C__c' && value === 'Yes') {
            this.isAlternate = true;
        } else if (field === 'Any_Alternate_Successor_of_Family_Who_C__c' && value === 'No') {
            this.isAlternate = false;
        } else if (field === 'Documents_Verified__c' && value === 'Others') {
            this.isDocument = true;
        } else if (field === 'Documents_Verified__c' && value != 'Others') {
            this.isDocument = false;
        } else if (field === 'Business_Ownership_proof_if_available__c' && value === 'Yes') {
            this.isOwnership = true;
        } else if (field === 'Business_Ownership_proof_if_available__c' && value === 'No') {
            this.isOwnership = false;
        } else if (field === 'Type_Of_Business__c' && value === 'Others') {
            this.isBusDes = true;
        } else if (field === 'Type_Of_Business__c' && value != 'Others') {
            this.isBusDes = false;
        } else if (field === 'Prior_Occupaton_if_different_From_Curren__c' && value === 'Yes') {
            this.isOccupation = true;
        } else if (field === 'Prior_Occupaton_if_different_From_Curren__c' && value === 'No') {
            this.isOccupation = false;
        } else if (field === 'asset_created_last_48_months__c' && value === 'Yes') {
            this.isAsset_created_last_48_months__c = true;
        } else if (field === 'asset_created_last_48_months__c' && value === 'No') {
            this.isAsset_created_last_48_months__c = false;
        }
        else if (field === 'Business_Premises__c' && value === 'Rented') {
            this.isRentedProperty = true;
        } else if (field === 'Business_Premises__c' && value != 'Rented') {
            this.isRentedProperty = false;
        } else if (name === 'profile' && value === 'Retail / Job Work') {
            this.selectedLabel = 'Retail / Job Work';
            this.isRetail_JobWork = true;
            this.isService_Provider = false;
            this.isContractor = false;
            this.isOthersProfile = false;
        } else if (name === 'profile' && value === 'Service Provider') {

            this.selectedLabel = 'Service Provider';
            this.isService_Provider = true;
            this.isContractor = false;
            this.isOthersProfile = false;
            this.isRetail_JobWork = false;
        } else if (name === 'profile' && value === 'Contractor') {

            this.selectedLabel = 'Contractor';
            this.isContractor = true;
            this.isService_Provider = false;
            this.isOthersProfile = false;
            this.isRetail_JobWork = false;
        } else if (name === 'profile' && value === 'Others') {
            this.selectedLabel = 'Others';
            this.isOthersProfile = true;
            this.isService_Provider = false;
            this.isContractor = false;
            this.isRetail_JobWork = false;
        }
        if (field === 'KYC_Validated_At_Business_Place__c' && value === 'Yes') {
            this.isMand = true;
        } else if (field === 'KYC_Validated_At_Business_Place__c' && value === 'No') {
            this.isMand = false;
        }

        event.target.setCustomValidity('');

        // Apply rule if exists
        if (this.rules[field]) {
            const rule = this.rules[field];
            const valueStr = value ? value.toString() : '';

            // TEXT validation
            if (!rule.type || rule.type === 'text') {
                const len = valueStr.length;

                if (rule.min && len < rule.min) {
                    event.target.setCustomValidity(
                        `Minimum ${rule.min} characters required. Current: ${len}`
                    );
                } else if (rule.max && len > rule.max) {
                    event.target.setCustomValidity(
                        `Maximum ${rule.max} characters allowed. Current: ${len}`
                    );
                }
            }

            // NUMBER validation
            if (rule.type === 'number') {
                const valueStr = String(value ?? '').trim();

                if (valueStr === '') {
                    this.pdRec = { ...this.pdRec, [field]: value };
                    const dataSend = new CustomEvent('changeevent', {
                        detail: {
                            field,
                            value,
                            pdRec: this.pdRec
                        },
                        bubbles: true,
                        composed: true
                    });
                    this.dispatchEvent(dataSend);
                    event.target.setCustomValidity('');
                    //return;
                }
                const num = Number(value);
                const len = valueStr.length;

                if (isNaN(num)) {
                    event.target.setCustomValidity('Only numbers are allowed.');
                }
                else if (rule.minValue && num < rule.minValue && valueStr != '') {
                    event.target.setCustomValidity(
                        `Value must be greater than or equal to ${rule.minValue}.`
                    );
                }
                else if (rule.maxLength && len > rule.maxLength) {
                    event.target.setCustomValidity(
                        `Maximum ${rule.maxLength} digits allowed. Current: ${len}`
                    );
                }
            }
        }

        // Show validation immediately
        event.target.reportValidity();

        if (this.householdFields.includes(field)) {
            const updatedRec = {
                ...this.pdRec,
                [field]: value
            };
            this.pdRec = updatedRec;
            this.calculateHouseholdTotal(updatedRec);
        }
        this.pdRec = { ...this.pdRec, [field]: value };
        this.pdRec.isSaveDisabled = true;
        const dataSend = new CustomEvent('changeevent', {
            detail: {
                field,
                value,
                pdRec: this.pdRec
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(dataSend);

    }

    dispatchPdEvent() {
        const dataSend = new CustomEvent('changeevent', {
            detail: {
                pdRec: this.pdRec
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(dataSend);
    }

    loadCustomers() {
        getCustomerReferences({ parentRecordId: this.pdRecordId })
            .then(data => {
                if (data) {
                    this.customers = data.map((r, i) => ({
                        sfId: r.sfId || null,
                        uid: r.uid || `customer-${i}`,
                        type: r.type || 'Customer',
                        contact: r.contact || '',
                        nature: r.nature || '',
                        value: r.value || '',
                        frequency: r.frequency || '',
                        doingSince: r.doingSince || '',
                        creditPeriod: r.creditPeriod || ''
                    }));
                    console.log('customrs ', data);
                    //this._savedCustomers = JSON.parse(JSON.stringify(this.customers));
                    this.updateFinalArray();
                }
            })
            .catch(error => {
                this.customers = [this.newRow('Customer')];
                // this._showToast(
                //     'Error',
                //     'Failed to load customers: ',
                //     'error'
                // );
            });
    }

    loadSuppliers() {
        getSuplierReferences({ parentRecordId: this.pdRecordId })
            .then(data => {
                if (data) {
                    this.suppliers = data.map((r, i) => ({
                        sfId: r.sfId || null,
                        uid: r.uid || `supplier-${i}`,
                        type: r.type || 'Supplier',
                        contact: r.contact || '',
                        nature: r.nature || '',
                        value: r.value || '',
                        frequency: r.frequency || '',
                        doingSince: r.doingSince || '',
                        creditPeriod: r.creditPeriod || ''
                    }));
                    console.log('supplier ', data);
                    //this._savedSuppliers = JSON.parse(JSON.stringify(this.suppliers));
                    this.updateFinalArray();
                }
            })
            .catch(error => {
                this.suppliers = [this.newRow('Supplier')];
                // this._showToast(
                //     'Error',
                //     'Failed to load suppliers: ',
                //     'error'
                // );
            });
    }

    loadProfileData() {
        fetchProfileWiseData({ recordId: this.pdRecordId })
            .then(res => {
                if (res) {
                    console.log('Data ::::', res);
                    const serviceProviderProfile = res?.serviceProviders?.[0]?.profile;
                    const contractorProfile = res?.contractors?.[0]?.profile;
                    const othersProfile = res?.othersProfiles?.[0]?.profile;
                    const retailProfile = res?.retails?.[0]?.profile;

                    // Reset all flags first
                    this.isService_Provider = false;
                    this.isContractor = false;
                    this.isOthersProfile = false;
                    this.isRetail_JobWork = false;

                    if (serviceProviderProfile === 'Service Provider') {
                        this.selectedLabel = 'Service Provider';
                        this.isService_Provider = true;
                        this.pdRec.Applicant__c = serviceProviderProfile;
                        const dataCopy = JSON.parse(JSON.stringify(res.serviceProviders));
                        const [grossDaily, monthlyIncome] = this.calculateTotalsGeneric(dataCopy);
                        this.serProGrossDaily = grossDaily;
                        this.serProGrossMonthly = monthlyIncome;

                    } else if (contractorProfile === 'Contractor') {
                        this.selectedLabel = 'Contractor';
                        this.isContractor = true;
                        this.pdRec.Applicant__c = contractorProfile;
                        const dataCopy = JSON.parse(JSON.stringify(res.contractors));
                        const [grossDaily, monthlyIncome] = this.calculateTotalsGeneric(dataCopy);
                        this.contractorGrossDaily = grossDaily;
                        this.contractorGrossMonthly = monthlyIncome;

                    } else if (othersProfile === 'Others') {
                        this.selectedLabel = 'Others';
                        this.isOthersProfile = true;
                        this.pdRec.Applicant__c = othersProfile;

                    } else if (retailProfile === 'Retail / Job Work') {
                        this.selectedLabel = 'Retail / Job Work';
                        this.isRetail_JobWork = true;
                        this.pdRec.Applicant__c = retailProfile;
                        const dataCopy = JSON.parse(JSON.stringify(res.retails));
                        const [grossDaily, monthlyIncome] = this.calculateTotalsGeneric(dataCopy);
                        this.retailgrossDaily = grossDaily;
                        this.retailGrossMonthly = monthlyIncome;
                    }
                    this.retails = res.retails?.length
                        ? res.retails
                        : [this.newRowForRetail('retails')];

                    this.serviceProvider = res.serviceProviders?.length
                        ? res.serviceProviders
                        : [this.newRowForRetail('serviceProvider')];

                    this.contractor = res.contractors?.length
                        ? res.contractors
                        : [this.newRowForRetail('Contractor')];

                    this.othersProfile = res.othersProfiles?.length
                        ? res.othersProfiles
                        : [this.newRowForRetail('OthersProfile')];
                    console.log('contractors ', this.contractor);
                }


            })
            .catch(err => {
                console.error(err);
            });

    }

    async loadPDDetails() {
        await getPDDetails({ parentRecordId: this.recordId })
            .then(data => {
                const rows = data.map(r => ({
                    sfId: r.sfId,
                    label: r.label,
                    value: r.value,
                    section: r.section,
                    orderNo: r.orderNo
                }));

                // split by section
                this.businessExpenseRows = rows.filter(
                    r => r.section === 'Business Expenses'
                );

                this.householdExpenseRows = rows.filter(
                    r => r.section === 'House Hold'
                );
                console.log('this.businessExpenseRows :', this.businessExpenseRows);
                console.log('this.householdExpenseRows :', this.householdExpenseRows);
            })
            .catch(error => {
                console.error(error);
            });
    }

    loadDmsRequired() {
        checkDMSRequiredDoc({ pdRecordId: this.pdRecordId })
            .then(data => {
                console.log('Data:', data);
                this.isRequired = data;
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }

    calculateHouseholdTotal(record) {
        let total = 0;
        this.householdFields.forEach(f => {
            total += Number(record[f]) || 0;
        });

        this.pdRec = { ...record, total__c: total };
    }


    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) {
            return;
        }
        const reader = new FileReader();
        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            console.log('BASE64 OUTPUT ===>', base64);

            const dataSend = new CustomEvent('sendfileevent', {
                detail: {
                    fileName: file.name,
                    fileSize: file.size,
                    fileType: file.type,
                    base64Data: base64,
                    fullDataUrl: reader.result,
                    fileObject: file
                },
                bubbles: true,
                composed: true
            });

            this.dispatchEvent(dataSend);
        };

        reader.readAsDataURL(file);
    }

    async saveEVerification() {
        try {
            this.pdRec.Application__c = this.applicationId;
            this.pdRec.Loan_Applicant__c = this.recordId;
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


    newRow(type) {
        this.counter += 1;
        return {
            uid: type + '-' + this.counter,
            sfId: null,
            type: type,
            contact: '',
            nature: '',
            value: '',
            frequency: '',
            doingSince: '',
            creditPeriod: ''
        };
    }
    newRowForRetail(type) {
        this.counter += 1;
        return {
            uid: type + '-' + this.counter,
            sfId: null,
            type: type,
            item: '',
            dailyVolume: '',
            cost: '',
            totalCost: '',
            saleUnit: '',
            savingUnit: '',
            workDetails: '',
            period_of_Service: '',
            remarks:''
        };
    }

    addRow(event) {
        const table = event.currentTarget.dataset.table;

        if (table === 'suppliers') {
            this.suppliers = [...this.suppliers, this.newRow('Supplier')];
        } else if (table === 'customers') {
            this.customers = [...this.customers, this.newRow('Customer')];
        } else if (table === 'retails') {
            this.retails = [...this.retails, this.newRowForRetail('retails')];
        } else if (table === 'serviceProvider') {
            this.serviceProvider = [...this.serviceProvider, this.newRowForRetail('serviceProvider')];
        } else if (table === 'OthersProfile') {
            this.OthersProfile = [...this.OthersProfile, this.newRowForRetail('OthersProfile')];
        } else if (table === 'Contractor') {
            this.contractor = [...this.contractor, this.newRowForRetail('Contractor')];
        }
        this.updateFinalArray();
    }

    removeRow(event) {
        const table = event.currentTarget.dataset.table;
        const index = Number(event.currentTarget.dataset.index);
        const sfId = event.currentTarget.dataset.id;
        const uid = event.currentTarget.dataset.uid;
        console.log('DELETE ICON CLICKED → Key:', uid);
        console.log('DELETE ICON CLICKED → Key:', sfId);
        if (table === 'suppliers') {
            let rows = [...this.suppliers];
            rows.splice(index, 1);
            this.suppliers = rows.length ? rows : [this.newRow('Supplier')];
        } else if (table === 'customers') {
            let rows = [...this.customers];
            rows.splice(index, 1);
            this.customers = rows.length ? rows : [this.newRow('Customer')];
        } else if (table === 'retails') {
            let rows = [...this.retails];
            rows.splice(index, 1);
            this.retails = rows.length ? rows : [this.newRowForRetail('retails')];
        } else if (table === 'OthersProfile') {
            let rows = [...this.OthersProfile];
            rows.splice(index, 1);
            this.OthersProfile = rows.length ? rows : [this.newRowForRetail('OthersProfile')];
        } else if (table === 'serviceProvider') {
            let rows = [...this.serviceProvider];
            rows.splice(index, 1);
            this.serviceProvider = rows.length ? rows : [this.newRowForRetail('serviceProvider')];
        } else if (table === 'Contractor') {
            let rows = [...this.contractor];
            rows.splice(index, 1);
            this.contractor = rows.length ? rows : [this.newRowForRetail('Contractor')];
        }
        this.updateFinalArray();
    }

    deleteRowRecord(event) {

        const sfId = event.currentTarget.dataset.id;
        const uid = event.currentTarget.dataset.uid;
        console.log('DELETE ICON CLICKED → Key:', uid);
        console.log('DELETE ICON CLICKED → Key:', sfId);
        if (sfId) {
            this.isDelete = sfId;
            this.showConfirm = true;
        }
        else {
            console.log("This record is not available in Salesforce CRM.!");
            // this.dispatchEvent(new ShowToastEvent({
            //     title: 'Warning',
            //     message: 'This record is not available in Salesforce CRM.',
            //     variant: 'Warning'
            // }));
            this.removeRow(event);
            console.log("This record is not available in Salesforce CRM.!");
        }
        const table = event.currentTarget.dataset.table;
        const index = Number(event.currentTarget.dataset.index);
        // Your remove logic continues...
    }
    handleConfirmNo() {
        this.showConfirm = false;
    }
    handleConfirmYes() {
        this.deleteRecord();
    }
    deleteRecord() {
        deleteReference({ sfId: this.isDelete })
            .then(result => {
                // success logic
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'PD Refrence Delete successfully.',
                    variant: 'success'
                }));
                this.showConfirm = false;
                console.log('savePDRefrenceRecords Id:', result);
                // e.g. show toast, navigate, etc.
            })
            .catch(error => {

                console.error('Error deleteReference:', error);
                this.showConfirm = false;
            });
    }

    handleInputChange(event) {
        const table = event.target.dataset.table;
        const index = Number(event.target.dataset.index);
        const field = event.target.dataset.field;
        const value = event.detail.value;
        const inputType = event.target.type;
        console.log('table :',table);
        console.log('index :',index);
        console.log('field :',field);
        console.log('value :',value);
        console.log('inputType :',inputType);
        if (inputType === 'number') {
            const numValue = Number(value);

            if (isNaN(numValue)) {
                event.target.setCustomValidity('Invalid number');
            } else if (numValue < 0) {
                event.target.setCustomValidity('Negative values not allowed');
            } else if (value.replace('.', '').length > 10) {
                event.target.setCustomValidity('Max 10 digits allowed');
            } else {
                event.target.setCustomValidity('');
            }

            event.target.reportValidity();
        }

        if (table === 'suppliers') {
            this.suppliers[index] = { ...this.suppliers[index], [field]: value };
            this.suppliers = [...this.suppliers];
        } else if (table === 'customers') {
            this.customers[index] = { ...this.customers[index], [field]: value };
            this.customers = [...this.customers];
        } else if (table === 'retails') {
            this.retails[index] = { ...this.retails[index], [field]: value };
            this.retails = [...this.retails];
            console.log('Retails Tables : ', this.retails);
        } else if (table === 'serviceProvider') {
            this.serviceProvider[index] = { ...this.serviceProvider[index], [field]: value };
            this.serviceProvider = [...this.serviceProvider];
            console.log('Service Provider Tables : ', this.serviceProvider);
        } else if (table === 'Contractor') {
            this.contractor[index] = { ...this.contractor[index], [field]: value };
            this.contractor = [...this.contractor];
            console.log('Contractor Tables : ', this.contractor);
        } else if (table === 'OthersProfile') {
            this.OthersProfile[index] = { ...this.OthersProfile[index], [field]: value };
            this.OthersProfile = [...this.OthersProfile];
            console.log('Others Profile Tables : ', this.OthersProfile);
        }
        this.updateFinalArray();
        if(inputType != 'text'){
            this.calculateGross(event);
        }
        
    }

    calculateGross(event) {
        const table = event.target.dataset.table;
        console.log('Table :', table);
        if (table === 'retails') {
            const dataCopy = JSON.parse(JSON.stringify(this.retails));
            const [grossDaily, monthlyIncome] = this.calculateTotalsGeneric(dataCopy);
            this.retailgrossDaily = grossDaily;
            this.retailGrossMonthly = monthlyIncome;
            console.log('this.retailGrossMonthly : ', this.retailGrossMonthly);
        } else if (table === 'serviceProvider') {
            const dataCopy = JSON.parse(JSON.stringify(this.serviceProvider));
            const [grossDaily, monthlyIncome] = this.calculateTotalsGeneric(dataCopy);
            this.serProGrossDaily = grossDaily;
            this.serProGrossMonthly = monthlyIncome;
            console.log('this.serProGrossDaily : ', this.serProGrossDaily);
            console.log('this.serProGrossMonthly : ', this.serProGrossMonthly);
        } else if (table === 'Contractor') {
            const dataCopy = JSON.parse(JSON.stringify(this.contractor));
            const [grossDaily, monthlyIncome] = this.calculateTotalsGeneric(dataCopy);
            this.contractorGrossDaily = grossDaily;
            this.contractorGrossMonthly = monthlyIncome;
            console.log('this.contractorGrossDaily : ', this.contractorGrossDaily);
            console.log('this.contractorGrossMonthly : ', this.contractorGrossMonthly);
        }


    }
calculateTotalsGeneric(list) {
    if (!Array.isArray(list)) {
        return [0, 0];
    }

    const SKIP_FIELD = 'item';

    const dynamicTotal = list.reduce((totalAcc, row) => {
        if (!row || typeof row !== 'object') {
            return totalAcc;
        }

        const rowTotal = Object.entries(row).reduce((rowAcc, [key, val]) => {
            if (key === SKIP_FIELD) {
                return rowAcc;
            }

            const num = Number(val);
            return Number.isFinite(num) ? rowAcc + num : rowAcc;
        }, 0);

        return totalAcc + rowTotal;
    }, 0);

    const staticTotal =
        (Number(this.itemValue) || 0) +
        (Number(this.incomeValue) || 0);

    const dailyTotal = dynamicTotal + staticTotal;

    const daysInMonth = new Date(
        new Date().getFullYear(),
        new Date().getMonth() + 1,
        0
    ).getDate();

    return [dailyTotal, dailyTotal * daysInMonth];
}




    updateFinalArray() {

        this.finalArray = [...this.suppliers, ...this.customers];
        this.finalArrayForProfile = [...this.retails, ...this.serviceProvider, ...this.contractor, ...this.OthersProfile];

        this.dispatchEvent(
            new CustomEvent('businessdatachange', {
                detail: {
                    list: this.finalArray,
                    profileList: this.finalArrayForProfile,
                    selectedProfile: this.selectedLabel
                },
                bubbles: true,
                composed: true
            })
        );
    }

    _showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
    disconnectedCallback() {
        //this.getPdRecords();
        console.log('Component removed from DOM');
    }
}