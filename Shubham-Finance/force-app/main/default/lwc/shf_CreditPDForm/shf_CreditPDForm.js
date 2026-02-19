import { LightningElement, wire, api, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import PersonalDiscussion_OBJECT from '@salesforce/schema/Personal_Discussion__c';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import formFactorPropertyName from "@salesforce/client/formFactor";
import savePDRecords from '@salesforce/apex/SHF_PersonalDiscussionController.savePDRecords';
import getAttachmentRecord from '@salesforce/apex/SHF_PersonalDiscussionController.getAttachmentRecord';
import saveDetails from '@salesforce/apex/SHF_CreaditPDController.saveDetails';
import savePDRefrenceRecords from '@salesforce/apex/SHF_PersonalDiscussionController.savePDRefrenceRecords';
import saveRetailsProfileRelRecords from '@salesforce/apex/SHF_PersonalDiscussionController.saveRetailsProfileRelRecords';
import getLoanApplicantCreditPd from '@salesforce/apex/SHF_PersonalDiscussionController.getLoanApplicantCreditPd';
import getBranchCode from '@salesforce/apex/SHF_PersonalDiscussionController.getBranchCode';
import getPdDynamic from '@salesforce/apex/SHF_PersonalDiscussionController.getPdDynamic';
import getBranchMapping from '@salesforce/apex/SHF_PersonalDiscussionController.getBranchMapping';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPDRecordDetails from '@salesforce/apex/SHF_PersonalDiscussionController.getPDRecordDetails';
import getAllTemplates from '@salesforce/apex/SHF_PersonalDiscussionController.getAllTemplates';

const FIELDS = [
    'Credit_Pd_Template_Configuration__mdt.Label',
    'Credit_Pd_Template_Configuration__mdt.Profile__c',
    'Credit_Pd_Template_Configuration__mdt.PD_Template__c'
];
export default class Shf_CreditPDForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @track selectedTemplateName = 'CM-PD';
    @track pdRecordId;
    @track loanAplicantData;
    @track branchMappingData;
    @track customerTemplateName = '';
    @track templates;
    @track userProfileName;
    @track branchCode;
    @track payload;
    @track payloadBuseness;
    @track finalArray;
    @track bJSON;
    @track attchmentBase64;
    @track profileJSONRecords;
    @track previousGrossDaily;
    @track accessMode;
    @track isChildDisabled = false;
    @track isMobile = false;
    @track formalTemplate = false;
    @track isUploading = false;
    @track isSaveDisabled = true;
    @track sendDMS = false;
    @track cashTemplate = false;
    @track senpTemplate = false;
    @track isSaving = false;
    @track forApplicant = 'Applicant';
    @track selectedProfile;

    get columns() {
    return [
        {
            label: "Name", fieldName: "recordLink", wrapText: true, initialWidth: 350, type: "url", typeAttributes: {
                label: { fieldName: "Name" },
                target: "_self"
                //tooltip: { fieldName: "Name" }
            }
        },
        { label: "Record Type", fieldName: "RecordType_Name__c", wrapText: true, initialWidth: 300, type: "text" },
        { label: "Employment Type", fieldName: "Employment_Type__c", wrapText: true, initialWidth: 350, type: "text" },
        { label: "Subcategory", fieldName: "Subcategory__c", wrapText: true, initialWidth: 350, type: "text" },
        { label: "Customer Profile", fieldName: "Customer_Profile__c", wrapText: true, initialWidth: 320, type: "text" },
        {
            label: "Action",
            type: "action",
            fixedWidth: 120,
            typeAttributes: {
                rowActions: this.getRowActions.bind(this)
            }
        }
    ]
    }
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
        PD_Type_Selection__c: '',
        isSaveDisabled: false
    };
    requiredFields = [
        'Distance_from_Branch__c'
    ];

    applicantDataMap = {};
    @track loanApplicantOptions = [];
    @track branchMappingOptions = [];
    @track recordTypeOptions = [];
    @track selectedEmploymentType = '';
    @track selectedRecordTypeId;
    @track selectedLoanApplicantId;
    @track selectedVendor;
    @track documentData;
    @track showSelfEmpSection = false;
    @track showSalSection = false;
    @track showQ2 = false;
    @track showQ3 = false;
    @track showQ4 = false;
    @track isLoading = false;
    @track isModalOpen = false;
    @track isViewDetailOpen = false;
    @track isAplicant = false;
    @track isVendor = false;
    @track pdDetailRec;

    creditPDRecordTypeId;
    salesPDRecordTypeId;

    yesNoOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    employmentOptions = [
        { label: 'Self-Employed', value: 'Self-Employed' },
        { label: 'Salaried', value: 'Salaried' }
    ];
    vendorOptions = [
        { label: 'CM PD', value: 'CM-PD' },
        { label: 'Vendor PD', value: 'Vendor-PD' }
    ];
    
    getRowActions(row, doneCallback) {
    const actions = [];

    // Credit user → full access
    if (this.userProfileName === 'Credit' || this.userProfileName === 'System Administrator') {
        actions.push(
            { label: 'Initiate Credit PD', name: 'initiateCreditPD' },
            { label: 'View PD', name: 'viewPD' }
        );
    }
    else {
        // actions.push(
        //     { label: 'View PD', name: 'viewPD' }
        // );
    }

    doneCallback(actions);
}
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [PROFILE_NAME]
    })
    wiredUser({ data }) {
        if (data) {
            console.log('profile',data);
            this.userProfileName = data.fields.Profile.displayValue;
        }
    }
    @wire(getObjectInfo, { objectApiName: PersonalDiscussion_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) {
            const rtInfo = data.recordTypeInfos;
            this.creditPDRecordTypeId = Object.keys(rtInfo).find(rtId => rtInfo[rtId].name === 'Credit PD');
            this.salesPDRecordTypeId = Object.keys(rtInfo).find(rtId => rtInfo[rtId].name === 'Sales PD');

            console.log('Credit RT:', this.creditPDRecordTypeId);
            console.log('Sales RT:', this.salesPDRecordTypeId);
            this.recordTypeOptions = Object.keys(rtInfo)
                .filter(rtId => {
                    const rt = rtInfo[rtId];
                    return (
                        !rt.master && (rt.name === 'Credit PD' || rt.name === 'Sales PD')
                    );
                })
                .map(rtId => ({
                    label: rtInfo[rtId].name,
                    value: rtId
                }));

            console.log('Record Type options => ', JSON.stringify(this.recordTypeOptions));
        }
        if (error) {
            console.error(error);
        }
    }
    @wire(getLoanApplicantCreditPd, { applicationId: '$recordId' })
    wiredLoanApplicants({ data, error }) {
        if (data) {
            console.log('loanApplicantMap', data);
            // this.loanAplicantData = data.map(item => ({
            //     ...item,
            //     //Name: item.Id   // ⭐ create link to the record
            // }));
            let updatedData = JSON.parse(JSON.stringify(data));

            updatedData.forEach(res => {
                res.recordLink = '/' + res.Id; // URL
                // res.Name stays as Name
            });

            this.loanAplicantData = updatedData;
            this.loanApplicantOptions = data.map(app => {
                return {
                    label: app.Name,
                    value: app.Id
                };
            });
            //console.log('loanApplicantMap', this.loanApplicantMap);
        } else if (error) {
            console.error('Error fetching loan applicants:', error);
        }
    }
    @wire(getAllTemplates)
    wiredTemplates({ error, data }) {
        if (data) {
            console.log('template ', data);
            this.templates = data
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(CurrentPageReference)
    getLAFId(currentPageReference) {
        if (currentPageReference.state.recordId) {
            this.recordId = currentPageReference.state.recordId;
            //this.parentRecordId = currentPageReference.state.recordId;
        } else if (currentPageReference.attributes.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
            //this.parentRecordId = currentPageReference.state.recordId;
        }
        console.log('recordId-> ', this.recordId);
    }
    @wire(getBranchCode, { applicationId: '$recordId' })
    wireBranchCode({ data, error }) {
        if (data) {
            this.branchCode = data;
        } else if (error) {
            console.error('Error fetching loan applicants:', error);
        }
    }
    get hasData() {
        return this.loanAplicantData && this.loanAplicantData.length > 0;
    }

    get hasError() {
        return this.errorMessage !== "";
    }

    async connectedCallback() {
        this.handleFormFactor();
        this.handleAppOrBrowser();

    }
    getPdRecords() {
        getPdDynamic({ loanApplicantId: this.selectedLoanApplicantId })
            .then(result => {
                if (result) {
                    this.pdRecordId = result.Id;
                    this.openPD();
                    console.log('getPdDynamic Id123:', this.pdRecordId);
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Personal Discussion Record ID is not available..',
                        variant: 'Error'
                    }));
                }
                console.log('this.pdRec:', this.pdRec);
            })
            .catch(error => {
                console.error('Error saving PD:', error);
                // e.g. show error toast
            });
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


    async handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        console.log('selectedRecordId :', row.Id);
        this.selectedLoanApplicantId = row.Id;
        //this.getAttchmentRecord();
        if (action === "initiateCreditPD") {
            this.creditPdScreenSelection();
            this.isChildDisabled = false;
            this.isModalOpen = true;
        }
        if (action === "viewPD") {
            this.creditPdScreenSelection();
            this.isChildDisabled = true;
            this.isSaveDisabled = true;
            this.isModalOpen = true;
            console.log('is child dis::', this.isChildDisabled);
            //await this.getPdRecords();
        }
    }

    openPD() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.pdRecordId,
                objectApiName: 'Personal_Discussion__c',
                actionName: 'view'
            }
        });
    }

    closeViewDetail() {
        this.isViewDetailOpen = false;
        this.pdDetailRec = null;
    }

    handlePicklistChange(event) {
        console.log('Field Name:', event.target.name);
        console.log('Selected Value:', event.detail.value);
        if (event.target.name == 'pdTypeSelection') {
            this.selectedTemplateName = event.detail.value;
            if (this.selectedTemplateName == 'CM-PD') {
                this.isAplicant = true;
                this.isVendor = false;
            } else {
                this.isAplicant = false;
                //this.formalTemplate = false;
                //this.cashTemplate = false;
                //this.senpTemplate = false;
                this.isVendor = true;
                this.loadBranchMapping();
            }
        } else if (event.target.name == 'loanApplicant') {
            this.loanApplicantId = event.detail.value;

        } else if (event.target.name == 'Vendor') {
            this.selectedVendor = event.detail.value;

        }

    }
    creditPdScreenSelection() {
        console.log('this.selectedLoanApplicantId  ', this.selectedLoanApplicantId);
        const record = this.loanAplicantData.find(item => item.Id === this.selectedLoanApplicantId);
        if (record && record.Customer_Profile__c && record.Customer_Profile__c != 'Cash Salaried') {
            console.log('record.Customer_Profile__c', record);
            const templateName = this.templates.find(item => item.Profile__c === record.Customer_Profile__c);
            this.customerTemplateName = templateName.PD_Template__c;
            console.log('this.customerTemplateName', this.customerTemplateName);
            if (templateName.Profile__c === 'Formal Salaried') {
                this.cashTemplate = false;
                this.senpTemplate = false;
                this.formalTemplate = true;
                console.log('this.formalTemplate ', this.formalTemplate);
            } else if (templateName.Profile__c === 'Informal Salaried- Bank Credit' || templateName.Profile__c === 'Informal Salaried- Cash') {
                this.formalTemplate = false;
                this.senpTemplate = false;
                this.cashTemplate = true;
                console.log('this.cashTemplate ', this.cashTemplate);
            } else if (templateName.Profile__c === 'Self Employed- Banking Surrogate' || templateName.Profile__c === 'Self Employed- GST/ITR' || templateName.Profile__c === 'Self Employed- Informal') {
                this.formalTemplate = false;
                this.cashTemplate = false;
                this.senpTemplate = true;
            } else {
                console.log('record.Customer_Profile__c', record.Customer_Profile__c);
            }

        }
    }
    async loadBranchMapping() {
        await getBranchMapping({ applicationId: this.recordId })
            .then(data => {
                console.log('getBranchMapping', data);
                this.branchMappingData = data;
                this.branchMappingOptions = data.map(row => {
                    return {
                        label: row.Vendor__r.Name,
                        value: row.Vendor__r.Id
                    };
                });
                console.log('branchMappingOptions  : ', this.branchMappingOptions);
            })
            .catch(error => {
                console.error('Error fetching branch mapping:', error);
            });
    }

    handleAllData(event) {
        const { sectionName, rows, grossDaily, grossMonthly } = event.detail;

        console.log('Section:', sectionName);
        if (sectionName === 'House Hold') {
            const newVal = Number(grossDaily) || 0;
            /*this.pdRec.total__c =
                (Number(this.pdRec.total__c) || 0) + (newVal - this.previousGrossDaily);*/
            this.previousGrossDaily = newVal;
            this.payload = rows;
            console.log('PARENT ', this.pdRec.total__c);
        }
        else if (sectionName === 'Business Expenses') {
            this.payloadBuseness = rows;
        }

        console.log('Rows:', rows);
        console.log('Gross Daily:', grossDaily);
        console.log('Gross Monthly:', grossMonthly);

    }
    async handleSave() {
        console.log('Data payload', this.payload);

        this.finalArray = [
            ...(Array.isArray(this.payload) ? this.payload : []),
            ...(Array.isArray(this.payloadBuseness) ? this.payloadBuseness : [])
        ];

        console.log('this.finalArray:', this.finalArray);
        await saveDetails({ details: JSON.stringify(this.finalArray), recordId: this.pdRecordId })
            .then(() => {
                //this.showToast('Success', 'Records saved successfully', 'success');
            })
            .catch(err => {
                this.showToast(
                    'Error',
                    err?.body?.message || 'Save failed',
                    'error'
                );
            });
    }


    saveEVerification() {
        if (this.customerTemplateName == 'Formal Salaried') {
            const salariedComp = this.template.querySelector('c-shf_-credit-pd-formal-salaried');
            console.log('salariedComp :', salariedComp);
            if (salariedComp && typeof salariedComp.validateRequiredData === 'function') {
                let isValid = salariedComp.validateRequiredData();
                //console.log('isValid :',isValid);
            }
        } else if (this.customerTemplateName == 'Cash Salaried') {
            const salariedComp = this.template.querySelector('c-shf_-credit-pd-cash-salaried');
            console.log('salariedComp :', salariedComp);
            if (salariedComp && typeof salariedComp.validateRequiredData === 'function') {
                let isValid = salariedComp.validateRequiredData();
                //console.log('isValid :',isValid);
            }
        }
        else if (this.customerTemplateName == 'SENP') {
            const senpComp = this.template.querySelector('c-shf_-credit-pd-s-e-n-p');
            console.log('senpComp :', senpComp);

            if (senpComp && typeof senpComp.validateRequiredData === 'function') {
                let isValid = senpComp.validateRequiredData();
            }

            // const senpProfileComp = this.template.querySelector('c-shf_-credit-p-d-senp-profile');
            // console.log('senpProfileComp :', senpProfileComp);
            // const senpProfileComp = this.template.querySelector('c-shf_-credit-p-d-senp-profile');
            // console.log('senpProfileComp 111:', senpProfileComp);

            // if (senpProfileComp && typeof senpProfileComp.validateRequiredData === 'function') {
            //     isValid = senpProfileComp.validateRequiredData();
            // }

        }

    }
    async getAttchmentRecord() {
        await getAttachmentRecord({ applicantId: this.selectedLoanApplicantId })
            .then(result => {
                console.log('Result Attchent: ', result);
                this.attchmentBase64 = result.base64Data;
            })
            .catch(error => {
                console.log('Error In Fetch Attachment', error);
            })
    }

    handleProfileValidity(event) {
        console.log('Grand Parent received:', event.detail.isValid);

        //this.isAllValid = event.detail.isValid; // store it
    }


    async requiredValidate(event) {
        const { isValid } = event.detail;
        if (this.isMobile) {
            await this.getAttchmentRecord();
        }
        // if (this.isSaving) {
        //     //console.warn('Save already in progress. Ignoring duplicate call.');
        //     return;
        // }
        const today = new Date().toISOString().split('T')[0];
        console.log('today', today);
        console.log('this.pdRec.date_of_purchase__c', this.pdRec.date_of_purchase__c);
        if (this.pdRec.date_of_purchase__c > today) {
            this.showToast('Error', 'Please correct the date fields before saving.', 'error');
            return;
        }
        if (/*this.pdRec?.Distance_from_Branch__c === 0 || */this.pdRec?.Distance_from_Branch__c == null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'GPS is OFF — PD record will not save without location coordinates.',
                    variant: 'error'
                })
            );
            return;
        }
        console.log('Parent isValid:', isValid);
        if (!isValid) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please fill all required fields before proceeding.',
                variant: 'Error'
            }));
        } else if (isValid) {
            this.isSaving = true;
            this.saveRecord();
        }
    }
    async saveRecord() {
        try {
            this.pdRec.Application__c = this.recordId;
            this.pdRec.Loan_Applicant__c = this.selectedLoanApplicantId;
            if (this.sendDMS) {
                await this.sendToDMSHandler();
            }
            await savePDRecords({ pdRec: this.pdRec })
                .then(result => {
                    // success logic
                    console.log('PD saved, Id:', result);
                    this.pdRecordId = result;
                    const payloadString = JSON.stringify(this.bJSON);
                    console.log('payloadString:', payloadString);
                    this.handleSave();
                    if (this.senpTemplate) {
                        this.saveProfileRetails();
                        //this.handleSave();
                        savePDRefrenceRecords({ pdRefJSON: payloadString, recordId: result })
                            .then(result => {
                                // success logic
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Personal Discussion record saved successfully.',
                                    variant: 'success'
                                }));
                                console.log('savePDRefrenceRecords Id:', result);
                                this.isUploading = false;
                                // e.g. show toast, navigate, etc.
                            })
                            .catch(error => {
                                // error handling
                                this.isUploading = false;
                                console.error('Error savePDRefrenceRecords:', error);
                                // e.g. show error toast
                            });
                    }
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Personal Discussion record saved successfully.',
                        variant: 'success'
                    }));
                    this.isUploading = false;
                    // e.g. show toast, navigate, etc.
                })
                .catch(error => {
                    // error handling
                    this.isUploading = false;
                    console.error('Error saving PD:', error);
                    // e.g. show error toast
                });

            this.isUploading = false;
            this.closeModal();
            // window.location.reload();

        } catch (error) {
            console.error('Save error:', error);
            this.isUploading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message || 'An unexpected error occurred.',
                    variant: 'error'
                })
            );
            this.isUploading = false;
            this.closeModal();
        } finally {
            this.isLoading = false;
            this.isUploading = false;
            this.cashTemplate = false;
        }
    }

    saveProfileRetails() {
        const payloadString = JSON.stringify(this.profileJSONRecords);
        console.log('payloadString:', payloadString);
        saveRetailsProfileRelRecords({ pdRefJSON: payloadString, profileName: this.selectedProfile, recordId: this.pdRecordId })
            .then(result => {
                // success logic
                // this.dispatchEvent(new ShowToastEvent({
                //     title: 'Success',
                //     message: 'Personal Discussion record saved successfully.',
                //     variant: 'success'
                // }));
                console.log('saveRetailsProfileRelRecords Id:', result);
                // e.g. show toast, navigate, etc.
            })
            .catch(error => {
                console.error('Error saving PD:', error);
                // e.g. show error toast
            });
    }

    async sendToDMSHandler() {
        this.isUploading = true;
        let base64File;

        if (this.documentData?.base64Data) {
            base64File = this.documentData.base64Data;
        } else if (this.attchmentBase64) {
            console.log('Data attchmentBase641234:', this.attchmentBase64);
            base64File = this.attchmentBase64;
        }
        //const [name, type] = this.documentData.fileName.split('.');
        try {
            const uploader = this.template.querySelector('c-shf-upload-document');
            await uploader.uploadFromParent({
                base64File: base64File,
                fileName: 'Applicant Credit PD',
                docId: null,
                docCategory: 'Others',
                parentObjectName: 'Application__c',
                parentRecordId: this.selectedLoanApplicantId || null,
                applicationId: this.selectedLoanApplicantId,
                applicantId: this.selectedLoanApplicantId || null
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Processing',
                    message: 'Uploading to DMS...',
                    variant: 'success'
                })
            );

        } catch (err) {
            console.error('Error:', err);
            this.isUploading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: err.body?.message || err.message,
                    variant: 'error'
                })
            );
        }
    }
    handleDmsResponse(event) {
        this.isUploading = true;
        const resp = event.detail;
        console.log('DMS Response:', resp);
        console.log('DMS resp.status:', resp.status);
        if (resp.status === 'SUCCESS') {
            try {
                this.isUploading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'success',
                        message: 'Document Sent Successfully To DMS',
                        variant: 'success'
                    })
                );
                //this.dispatchEvent(new CloseActionScreenEvent());
            } catch (err) {
                console.error('Flag update failed:', err.body?.message);
            }
            finally {
                //this.dispatchEvent(new CloseActionScreenEvent());
            }
        } else {
            this.isUploading = false;
            console.error('DMS upload failed:', resp.message || 'Unknown error');
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    handleFileEvent(event) {
        this.documentData = event.detail;
        const [name, type] = this.documentData.fileName.split('.');
        console.log('File Name:', name);
        console.log('File Type:', type);
        console.log('this.documentData:', this.documentData);
        this.sendDMS = true;
    }
    businessDataChanges(event) {
        console.log('File businessDataChanges List:', event.detail.list);
        this.bJSON = event.detail.list;
        this.profileJSONRecords = event.detail.profileList;
        this.selectedProfile = event.detail.selectedProfile;
        console.log('this.profileJSONRecords:', JSON.stringify(this.profileJSONRecords));

    }
    handlePdTemplateEvent(event) {
        const { pdRec } = event.detail;
        this.pdRec = pdRec;
        if (this.pdRec.isSaveDisabled) {
            this.isSaveDisabled = false;
        }

        console.log('this.pdRec:', this.pdRec);
        //this.pdRec.field = value;
    }
    openModal() { this.isModalOpen = true; }

    closeModal() {
        this.pdRec = {
            Are_you_salaried_or_self_employed__c: '',
            Is_BankStatement_avail_for_BankSurrogate__c: '',
            Can_Customer_Income_be_assessed__c: '',
            Is_Form_16_available__c: '',
            Is_the_last_2_month_salary_slip_availabl__c: '',
            Is_salary_credited_in_Bank_Account__c: '',
            Is_the_GST_Report_available__c: '',
            Loan_Applicant__c: '',
            Application__c: ''
        };
        this.selectedEmploymentType = '';
        this.showSelfEmpSection = false;
        this.showSalSection = false;
        this.showQ2 = false;
        this.showQ3 = false;
        this.showQ4 = false;
        this.isModalOpen = false;
    }
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

}