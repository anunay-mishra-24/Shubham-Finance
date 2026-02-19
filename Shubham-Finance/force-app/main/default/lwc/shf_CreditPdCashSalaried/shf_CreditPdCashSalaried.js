import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import formFactorPropertyName from "@salesforce/client/formFactor";
import savePDRecords from '@salesforce/apex/SHF_PersonalDiscussionController.savePDRecords';
import getPdDynamic from '@salesforce/apex/SHF_PersonalDiscussionController.getPdDynamic';
import getApplicantDetails from '@salesforce/apex/SHF_CreaditPDController.getApplicantDetails';
import getBranchAddress from '@salesforce/apex/SHF_PersonalDiscussionController.getBranchAddress';
import getPropertyDetails from '@salesforce/apex/SHF_CreaditPDController.getPropertyDetails';
export default class Shf_CreditPdCashSalaried extends NavigationMixin(LightningElement) {
    @api recordId;
    @api applicationId;
    @api isModalOpen;
    @api isReadOnly;
    @track validField = false;
    @track pdObject = {};
    @track isMedical = false;
    @track isGaming = false;
    @track isAlternate = false;
    @track isEmpClasification = false;
    @track isComOperate = false;
    @track isDocument = false;
    @track isOther_Prior_Occupatoin__c = false;
    @track isAsset_created_last_48_months__c = false;
    @track rowsData = [];
    error;
    @track deviceType;
    @track accessMode;
    @track isMobile = false;
    @track loanApplicantOptions = [];
    latitude;
    longitude;
    locationSet = false;
    @track pdRec = {
        Name: '',
        RecordTypeId: '',
        Credit_PD_Mode__c: '',
        Application__c: '',
        Company_Operating_Shifts__c: '',
        Employer_Classification_Description__c: '',
        Nature_of_Business__c: '',
        Industry__c: '',
        Remarks__c: '',
        PD_Activity_Status__c: '',
        Total_Expences__c: null,
        Loan_Applicant__c: '',
        Credit_PD_Locaton__Latitude__s: null,
        Credit_PD_Locaton__Longitude__s: null,
        Are_you_salaried_or_self_employed__c: '',
        Is_the_GST_Report_available__c: '',
        Is_BankStatement_avail_for_BankSurrogate__c: '',
        Can_Customer_Income_be_assessed__c: '',
        Is_the_last_2_month_salary_slip_availabl__c: '',
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
        No_of_family_members_in_the_family_with__c: null,
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
        Any_other_Prior_Occupatoin__c: null,
        Other_Prior_Occupatoin__c: null,
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
        KYC_validation_at_Visit_docs_seen_like__c: '',
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
    get todayDate() {
        return new Date().toISOString().split('T')[0];
    }
    get containerClass() {
        return this.isReadOnly ? 'read-only-container' : '';
    }
    rules = {
        PD_Visit_Remarks_Recommendation_Note__c: { min: 250, max: 10000 },
        investment_value__c: { type: 'number', minValue: 1, maxLength: 9 },
        loanAmountApplied: { type: 'number', minValue: 1, maxLength: 9 },

        Resi_Stability__c: { type: 'number', minValue: 1, maxLength: 9 },

        no_of_coworkers_in_office__c: { type: 'number', minValue: 1, maxLength: 9 },
        //Company_Operating_Shifts__c: { type: 'number', minValue: 1, maxLength: 9 },
        current_fixed_salary__c: { type: 'number', minValue: 1, maxLength: 9 },

        food_expense__c: { type: 'number', minValue: 1, maxLength: 9 },
        clothing_expense__c: { type: 'number', minValue: 1, maxLength: 9 },
        rent__c: { type: 'number', minValue: 1, maxLength: 9 },
        water_electricity__c: { type: 'number', minValue: 1, maxLength: 9 },
        telephone__c: { type: 'number', minValue: 1, maxLength: 10 },
        transport__c: { type: 'number', minValue: 1, maxLength: 9 },
        education__c: { type: 'number', minValue: 1, maxLength: 9 },
        medical_expenditure__c: { type: 'number', minValue: 1, maxLength: 9 },
        entertainment__c: { type: 'number', minValue: 1, maxLength: 9 },
        insurance__c: { type: 'number', minValue: 1, maxLength: 9 },
        chits_pigmy__c: { type: 'number', minValue: 1, maxLength: 9 },
        other__c: { type: 'number', minValue: 1, maxLength: 9 },
        //total__c: { type: 'number', minValue: 1, maxLength: 9 }
    };
    @api validateRequiredData() {
        let isFocused = false;
        let isValid = true;

        const senpProfileComp = this.template.querySelector('c-shf_-credit-p-d-senp-profile');
        console.log('senpProfileComp 111:', senpProfileComp);
        console.log('senpProfileComp 2222:', senpProfileComp.validateRequiredData());

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

    employerClassification = [
        { label: 'Service', value: 'Service' },
        { label: 'Trading', value: 'Trading' },
        { label: 'Manufacturing', value: 'Manufacturing' },
        { label: 'Others', value: 'Others' }
    ];
    employerRepresentative = [
        { label: 'Employer', value: 'Employer' },
        { label: 'Supervisor', value: 'Supervisor' },
        { label: 'Accountant', value: 'Accountant' },
        { label: 'Security Staff', value: 'Security Staff' }
    ];
    paymentModeOptions = [
        { label: 'Cash', value: 'Cash' },
        { label: 'IMPS', value: 'IMPS' },
        { label: 'UPI', value: 'UPI' },
        { label: 'Cheque', value: 'Cheque' },
        { label: 'Mixed', value: 'Mixed' }
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
    documentTypeOptions = [
        { label: 'PAN', value: 'PAN' },
        { label: 'Aadhar', value: 'Aadhar' },
        { label: 'Driving License', value: 'Driving License' },
        { label: 'Voter ID', value: 'Voter ID' },
        { label: 'Passport', value: 'Passport' },
        { label: 'NREGA Card', value: 'NREGA Card' },
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
    @wire(getApplicantDetails, { recordId: '$recordId' })
    wiredLoanApplicants({ data, error }) {
        if (data) {
            this.loanApplicantOptions = data;
            this.pdRec.employer_name__c = data.employeeName;
            this.pdRec.employer_industry__c = data.industry;
        } else if (error) {
            console.error('Error fetching loan applicants:', error);
        }
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
    get uploadUrl() {
        return `shubhamshf://docupload?recordId=${this.recordId}`;
    }

    async connectedCallback() {
        console.log('record Id child :', this.recordId);
        console.log('record Id child :', this.applicationId);
        console.log('record Id child :', this.isModalOpen);
        this.handleFormFactor();
        this.handleAppOrBrowser();
        this.getPdRecords();
        await this.getCurrentLocation();

        try {
            //this.getPdRecords();
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
                    this.pdRec = {
                        ...this.pdRec,
                        ...result
                    };
                    this.pdRecordId = result.Id;
                    if (this.pdRecordId) {
                        // this.pdRec = {
                        //     ...this.pdRec,
                        //     total__c: this.pdRec.total__c
                        // };
                        //this.calculateHouseholdTotal(this.pdRec);
                    }
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
                    if (this.pdRec.employer_classification__c === 'Others') {
                        this.isEmpClasification = true;
                    } else if (this.pdRec.employer_classification__c != 'Others') {
                        this.isEmpClasification = false;
                    }
                    if (this.pdRec.is_company_operating_in_shifts__c === 'Yes') {
                        this.isComOperate = true;
                    } else if (this.pdRec.is_company_operating_in_shifts__c === 'No') {
                        this.isComOperate = false;
                    }
                    if (this.pdRec.Documents_Verified__c === 'Others') {
                        this.isDocument = true;
                    } else if (this.pdRec.Documents_Verified__c != 'Others') {
                        this.isDocument = false;
                    }
                    else if (this.pdRec.Any_other_Prior_Occupatoin__c === 'Yes') {
                        this.isOther_Prior_Occupatoin__c = true;
                    } else if (this.pdRec.Any_other_Prior_Occupatoin__c === 'No') {
                        this.isOther_Prior_Occupatoin__c = false;
                    }
                    if (this.pdRec.asset_created_last_48_months__c === 'Yes') {
                        this.isAsset_created_last_48_months__c = true;
                    } else if (this.pdRec.asset_created_last_48_months__c === 'No') {
                        this.isAsset_created_last_48_months__c = false;
                    }
                    this.pdRec.total__c = result.total__c != null ? Number(result.total__c) : 0;
                    console.log('cash salaried Id=:', this.pdRec.total__c);
                    console.log('cash salaried Id:', (typeof this.pdRec.total__c));
                    this.dispatchPdEvent();
                    console.log('getPdDynamic Id:', this.pdRecordId);
                }
                console.log('this.pdRec:', this.pdRec);
            })
            .catch(error => {
                console.error('Error saving PD:', error);
                // e.g. show error toast
            });
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
                    this.locationSet = true;
                    getBranchAddress({ applicationId: this.applicationId, latitude: this.latitude, longitude: this.longitude })
                        .then(result => {
                            console.log('result location ', result);
                            this.pdRec.Distance_from_Branch__c = (result !== null && result !== undefined) ? result : 0;
                            this.pdRec.Credit_PD_Locaton__Latitude__s = this.latitude;
                            this.pdRec.Credit_PD_Locaton__Longitude__s = this.longitude;
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
        console.log('field  => ', field);
        console.log('value  => ', value);
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
        } else if (field === 'employer_classification__c' && value === 'Others') {
            this.isEmpClasification = true;
        } else if (field === 'employer_classification__c' && value != 'Others') {
            this.isEmpClasification = false;
        } else if (field === 'is_company_operating_in_shifts__c' && value === 'Yes') {
            this.isComOperate = true;
        } else if (field === 'is_company_operating_in_shifts__c' && value === 'No') {
            this.isComOperate = false;
        } else if (field === 'Documents_Verified__c' && value === 'Others') {
            this.isDocument = true;
        } else if (field === 'Documents_Verified__c' && value != 'Others') {
            this.isDocument = false;
        }
        else if (field === 'office_outside_photo__c' && value === 'Yes') {
            this.checkPhotoUploadToast();
        } else if (field === 'office_inside_photo__c' && value === 'Yes') {
            this.checkPhotoUploadToast();
        } else if (field === 'SelfieCapturedWithReportingMa__c' && value === 'Yes') {
            this.checkPhotoUploadToast();
        } else if (field === 'Any_other_Prior_Occupatoin__c' && value === 'Yes') {
            this.isOther_Prior_Occupatoin__c = true;
        } else if (field === 'Any_other_Prior_Occupatoin__c' && value === 'No') {
            this.isOther_Prior_Occupatoin__c = false;
        } else if (field === 'asset_created_last_48_months__c' && value === 'Yes') {
            this.isAsset_created_last_48_months__c = true;
        } else if (field === 'asset_created_last_48_months__c' && value === 'No') {
            this.isAsset_created_last_48_months__c = false;
        }
        if (this.householdFields.includes(field)) {
            const updatedRec = {
                ...this.pdRec,
                [field]: value
            };
            this.pdRec = updatedRec;
            this.calculateHouseholdTotal(updatedRec);
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
                else if (rule.minValue && num < rule.minValue && num != null && valueStr != '') {
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

    checkPhotoUploadToast() {

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Warning',
                message: 'Please upload the required photo(s) from the Documents tab.',
                variant: 'warning'
            })
        );
    }
    calculateHouseholdTotal(record) {
        let total = 0;
        this.householdFields.forEach(f => {
            total += Number(record[f]) || 0;
        });
        console.log('total 640', total);
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
    disconnectedCallback() {
        this.getPdRecords();
        console.log('Component removed from DOM');
    }

}