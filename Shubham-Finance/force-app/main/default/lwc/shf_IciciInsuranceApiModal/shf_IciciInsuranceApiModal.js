import { LightningElement, track, wire,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getChildApplicants from '@salesforce/apex/SHF_InsuranceAPIService.getChildApplicants';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import INSURANCE_VERIFICATION_FIELD from '@salesforce/schema/Loan_Applicant__c.Insurance_Verification__c';
import E_VERIFICATION_OBJECT from '@salesforce/schema/E_Verification__c';
import getEVerificationById from '@salesforce/apex/SHF_InsuranceAPIService.getEVerificationById';
import updateEVerification from '@salesforce/apex/SHF_InsuranceAPIService.updateEVerification';
import getKotakPlans from '@salesforce/apex/SHF_InsuranceAPIService.getKotakPlans';
import getInsuranceNominees from '@salesforce/apex/SHF_InsuranceAPIService.getInsuranceNominees';


export default class Shf_IciciInsuranceApiModal extends LightningElement {
    @api showInputSection = false;  // We Can Manage Input Form Visiblity Be Passing This As True, So We Want To Display Only Output Then We Don't Need To Pass Value
    @track insuranceObj = {};
    @track applicantDetails = [];   //We Will Have Primary Applicant Details in This Array as Label & Value Pair.
    @track isOutputShow = false;
    @api applicantId; 
    @api applicantData;
    @api applicationId;
    @track applicantList = [];
    @api isIcici;
    @api isKotak;
    @api applicationData;
    @track isSaving = false;
    @track isLocked = false;
    //Metadata for KOTAK 
    @track planOptions = []; 
    @track planConfigMap = {}; 
    @track selectedPlanConfig; 


    // ---------Picklist---------
    @track fundedOptions = [];
    @track lifeInsuredOptions = [];
    @track loanTypeOptions = [];
    @track coverOptions = [];
    @track benefitOptions = [];
    @track jointLifeOptions = [];
    @track yesNoOptions = [];
    @track today;
    @track nominees = [];
    @track nomineeToDeleteIndex;


    genderOptions = [
        { label: 'Male', value: 'Male' },
        { label: 'Female', value: 'Female' },
        { label: 'Not Specified', value: 'Not Specified' },
        { label: 'Third Gender', value: 'Third Gender' }
    ];

    nomineeGenderOptions = [
        { label: 'Male', value: 'Male' },
        { label: 'Female', value: 'Female' },
        { label: 'Transgender', value: 'Transgender' },
    ];

    relationshipOptions = [
        {label:'Brother', value:'Brother'}, 
        {label:'Business Associate', value:'Business Associate'},
		{label:'Daughter', value:'Daughter'}, 
		{label:'Director', value:'Director'}, 
		{label:'Employee', value:'Employee'}, 
		{label:'Father', value:'Father'}, 
		{label:'Mother', value:'Mother'}, 
		{label:'Partner', value:'Partner'}, 
		{label:'Proprietor', value:'Proprietor'}, 
		{label:'Relative', value:'Relative'}, 
		{label:'Self', value:'Self'}, 
		{label:'Self Duplicate', value:'Self Duplicate'}, 
		{label:'Sister', value:'Sister'}, 
		{label:'Son', value:'Son'}, 
		{label:'Spouse', value:'Spouse'}, 
    ];



    connectedCallback() {
        if (this.isKotak) { 
            getKotakPlans() 
            .then(result => { 
                this.planOptions = result.map(p => 
                ({ label: p.planCode, value: p.planCode })); 
                    result.forEach(p => 
                    { this.planConfigMap[p.planCode] = p; 
                    }); 
                    }) 
            .catch(err => 
            { console.error(err); 
            }); 
        } 
        let d = new Date();
        this.today = `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
        console.log('TEST  ', this.recordId, this.today);
        console.log('connectedCallback fired in modal');
        console.log('applicantData received:', JSON.stringify(this.applicantData));
        console.log('applicantId-----', this.applicantId);
        console.log('applicationId-----', this.applicationId);
        const today = new Date();
        const formatted = today.toISOString().slice(0, 10); // YYYY-MM-DD
        this.insuranceObj.Date_Of_Cover_Of_Commencement__c = formatted;
        this.nominees = [this.createEmptyNominee(1)];
        if (this.applicantData) {
            this.insuranceObj = {
                ...this.insuranceObj,
                Tenure__c: this.applicantData.tenure,
                Outstanding_Loan_Tenure__c: this.applicantData.tenure,
                Sanctioned_Loan_Amount__c: this.applicantData.sanctionAmount,
                Applicant__c: this.applicantData.name,
                Loan_Type__c: this.applicantData.product,
                Gender__c: this.applicantData.gender,
                Date_Of_Birth__c: this.applicantData.dob,
                Applicant_Age__c: this.applicantData.age
            };

            this.applicantDetails = [
                { label: this.applicantData.name, value: this.applicantData.name }
            ];

            console.log('insuranceObj initialized:', JSON.stringify(this.insuranceObj));
            console.log('applicantDetails set:', JSON.stringify(this.applicantDetails));
        } else {
            console.warn('No applicantData passed from parent component');
        }
        /*if (this.applicationData && this.isKotak) {
            this.insuranceObj = {
                ...this.insuranceObj,
                Tenure__c: this.applicationData.tenure,
                Sanction_Amount__c: this.applicationData.sanctionAmount
                //Date_Of_Birth__c: this.applicantData.dob,
            };

            this.applicationDetails = [
                { label: this.applicationData.name, value: this.applicationData.name }
            ];

            console.log('insuranceObj initialized:', JSON.stringify(this.insuranceObj));
            console.log('applicationDetails set:', JSON.stringify(this.applicationDetails));
        }
        else {
            console.warn('No applicationData passed from parent component');
        }*/
    }
    

    @wire(getRecord, {
        recordId: '$applicantId',
        fields: [INSURANCE_VERIFICATION_FIELD]
    })
    wiredApplicant({ data, error }) {
        if (data) {
            this.verificationId = data.fields.Insurance_Verification__c.value;
            console.log('Verification Id:', this.verificationId);
            this.loadEVerification();
        }
        if (error) console.error(error);
    }
    createEmptyNominee(sequence) {
        return {
            tempId: Date.now() + Math.random(),
            sequence: sequence,

            Nominee_Name__c: '',
            Nominee_Relationship__c: '',
            Nominee_Date_of_Birth__c: null,
            Nominee_Gender__c: '',
            Is_Minor__c: '',
            Appointee_Name__c: '',
            Appointee_Relationship__c: '',
            Appointee_DOB__c: null,
            Percentage_of_Entitlement__c: 100,
            Nominee_Address__c: ''
        };
    }


    loadEVerification() {
        getEVerificationById({ eVerificationId: this.verificationId })
            .then(result => {
                if (!result) return;
                this.eVerification = { ...result };
                this.loadNominees();
                // Populate UI from existing EV
                this.insuranceObj = {
                    ...this.insuranceObj,
                        Funded__c: result.Funded__c,
                        Life_Insured__c: result.Life_Insured__c,
                        Loan_Type__c: (this.insuranceObj?.Loan_Type__c) ? this.insuranceObj?.Loan_Type__c :result.Loan_Type__c,
                        Cover__c: result.Cover__c,
                        Benefit_Option__c: result.Benefit_Option__c,
                        Outstanding_Loan_Amount__c: result.Outstanding_Loan_Amount__c,
                        Outstanding_Loan_Tenure__c: result.Outstanding_Loan_Tenure__c,
                        Loan_Applicant_2__c: result.Loan_Applicant_2__c,
                        Joint_Life_Option__c: result.Joint_Life_Option__c,
                        Date_Of_Cover_Of_Commencement__c: result.Date_Of_Cover_Of_Commencement__c,
                        Sanctioned_Loan_Amount__c: result.Sanctioned_Loan_Amount__c,
                        Flat_Tenure__c: result.Flat_Tenure_In_Years__c,
                        Reducing_Tenure__c: result.Reducing_Tenure_In_Years__c,
                        LDD__c: result.LDD__c,
                        Date_Of_Birth_of_Older_Borrower__c: result.Date_Of_Birth_of_Older_Borrower__c,
                        Does_Premium_Have_To_Be_Funding__c: result.Does_Premium_Have_To_Be_Funding__c,
                        Date_Of_Birth_of_Younger_Borrower__c: result.Date_Of_Birth_of_Younger_Borrower__c,
                        Sum_Assured_Death__c: result.Sum_Assured_Death__c,
                        Coverage_Term_Death__c: result.Coverage_Term_Death__c,
                        Sum_Assured_ACI__c: result.Sum_Assured_ACI__c,
                        Coverage_Term_ACI__c: result.Coverage_Term_ACI__c,
                        Sum_Assured_ADB__c: result.Sum_Assured_ADB__c,
                        Coverage_Term_ADB__c: result.Coverage_Term_ADB__c,
                        Plan_Code__c: result.Plan_Code__c
                    };
                    

                const dt = new Date();
                dt.setDate(dt.getDate() + 120);
                this.insuranceObj.LDD__c = dt.toISOString().split('T')[0];
                // If existing was joint, enable the second applicant selection UI
                if ((result.Life_Insured__c === 'Joint Life' || result.Joint_Life_Option__c === 'Yes')&& result.Loan_Applicant_2__c) {
                    this.showSecondApplicant = true;
                    this.insuranceObj = {
                        ...this.insuranceObj,
                        Loan_Applicant_2__c: result.Loan_Applicant_2__c
                    };
                    console.log('>>>>Loan_Applicant_2__c',this.insuranceObj.Loan_Applicant_2__c);
                }
            })
            .catch(error => {
                console.error('Error loading E-Verification:', error);
            });
    }

    loadNominees() {
        getInsuranceNominees({ eVerificationId: this.verificationId })
            .then(result => {
                if (result && result.length > 0) {
                    this.nominees = result.map(n => ({
                        id: n.Id,
                        sequence: n.Sequence__c,

                        Nominee_Name__c: n.Nominee_Name__c,
                        Nominee_Relationship__c: n.Nominee_Relationship__c,
                        Nominee_Date_of_Birth__c: n.Nominee_Date_of_Birth__c,
                        Nominee_Gender__c: n.Nominee_Gender__c,
                        Is_Minor__c: (n.Is_Minor__c)? 'Yes' : 'No',
                        Appointee_Name__c: n.Appointee_Name__c,
                        Appointee_Relationship__c: n.Appointee_Relationship__c,
                        Appointee_DOB__c: n.Appointee_DOB__c,
                        Percentage_of_Entitlement__c: n.Percentage_of_Entitlement__c,
                        Nominee_Address__c: n.Nominee_Address__c
                    }));
                } else {
                    this.nominees = [this.createEmptyNominee(1)];
                }
            })
            .catch(error => {
                console.error('Error loading nominees', error);
                this.nominees = [this.createEmptyNominee(1)];
            });
    }



    @wire(getObjectInfo, { objectApiName: E_VERIFICATION_OBJECT })
    objectInfo;

    @wire(getPicklistValuesByRecordType, {
        objectApiName: E_VERIFICATION_OBJECT,
        recordTypeId: '$objectInfo.data.defaultRecordTypeId'
    })
    picklistHandler({ data, error }) {
        if (data) {
            console.log('datadata=> ', JSON.stringify(data));
            this.fundedOptions = data.picklistFieldValues.Funded__c.values;
            this.lifeInsuredOptions = data.picklistFieldValues.Life_Insured__c.values;
            this.loanTypeOptions = data.picklistFieldValues.Loan_Type__c.values;
            this.coverOptions = data.picklistFieldValues.Cover__c.values;
            this.benefitOptions = data.picklistFieldValues.Benefit_Option__c.values;
            this.jointLifeOptions = data.picklistFieldValues.Joint_Life_Option__c.values;
            this.yesNoOptions = data.picklistFieldValues.Does_Premium_Have_To_Be_Funding__c.values;
        }

        if (error) {
            console.error('Picklist fetch error:', error);
        }
    }


    get applicantDetailTitle(){
        return this.insuranceObj.Life_Insured__c == 'Single Life' ? 'Applicant Details' : 'Applicant 1 Details';
    }

    get showDeathBenefitSection(){
        return (this.insuranceObj.Benefit_Option__c && this.insuranceObj.Benefit_Option__c.includes('Death')) ? true : false;
    }

    get showADBSection(){
        return (this.insuranceObj.Benefit_Option__c && this.insuranceObj.Benefit_Option__c.includes('ADB')) ? true : false;
    }

    get showACISection(){
        return (this.insuranceObj.Benefit_Option__c && this.insuranceObj.Benefit_Option__c.includes('ACI')) ? true : false;
    }

    get showApplicantSecondApplicantSection(){
        return this.insuranceObj.Life_Insured__c == 'Joint Life' ? true : false;
    }

    get showYoungerBorrowerSection(){
        return (this.insuranceObj.Joint_Life_Option__c == 'Yes') ? true : false;
    }

    get isOnlyOneNominee() {
        return this.nominees.length === 1;
    }

    getTotalEntitlement() {
        return this.nominees.reduce(
            (sum, n) => sum + (Number(n.Percentage_of_Entitlement__c) || 0),
            0
        );
    }


    isMinorFromDob(dobValue) {
        if (!dobValue) return false;

        const dob = new Date(dobValue);
        const today = new Date();

        let age = today.getFullYear() - dob.getFullYear();
        const m = today.getMonth() - dob.getMonth();

        if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) {
            age--;
        }

        return age < 18;
    }


    handlePlanChange(event){ 
    const planCode = event.detail.value; 
    this.insuranceObj.Plan_Code__c = planCode; 
    this.selectedPlanConfig = this.planConfigMap[planCode]; 
    }

    handleChange(event){
        let name = event.target.name;
        const field = event.target.name;
        const value = event.target.value;
            this.insuranceObj = {
            ...this.insuranceObj,
            [field]: value
        };

        // Detect Life Insured type switch
        if (field === 'Life_Insured__c') {

            // User switched to Single
            if (value === 'Single Life') {
                this.insuranceObj.Loan_Applicant_2__c = null;
            }

            // User switched to Joint
            if (value === 'Joint Life') {
                // Reset second applicant to force re-selection
                this.insuranceObj.Loan_Applicant_2__c = null;
            }
        }
        if (field === 'Joint_Life_Option__c') {

            // User switched to Single
            if (value === 'No') {
                this.insuranceObj.Loan_Applicant_2__c = null;
            }

            // User switched to Joint
            if (value === 'Yes') {
                // Reset second applicant to force re-selection
                this.insuranceObj.Loan_Applicant_2__c = null;
            }
        }
    
    }

    handleNomineeChange(event) {
        const index = Number(event.target.dataset.index);
        const field = event.target.name;
        const value = event.target.value;

        this.nominees[index][field] = value;

        if (field === 'Nominee_Date_of_Birth__c') {
            this.nominees[index].Is_Minor__c =
                this.isMinorFromDob(value) ? 'Yes' : 'No';
        }

        this.nominees = [...this.nominees];
    }

    addNominee() {
        this.nominees = [
            ...this.nominees,
            this.createEmptyNominee(this.nominees.length + 1)
        ];
    }

    removeNominee(event) {
        const index = Number(event.target.dataset.index);
        const nominee = this.nominees[index];

        // If existing nominee - confirmation
        if (nominee.id) {
            this.nomineeToDeleteIndex = index;
            this.template.querySelector('c-shf-confirm-modal').open();
            console.log('modal found', modal);
        } else {
            // New nominee - delete immediately
            this.deleteNomineeAtIndex(index);
        }
    }


    handleClose(){
        const event = new CustomEvent('close', {
            detail: {"action": "close"}
        });
        this.dispatchEvent(event);
    }

    validateKotakPlanRules() { 
        const cfg = this.selectedPlanConfig;
        if (!cfg) return null;

        const sum = this.insuranceObj.Sanctioned_Loan_Amount__c; 
        const tenure = this.insuranceObj.Tenure__c; 
        const age = this.insuranceObj.Applicant_Age__c; 

        if (sum < cfg.minSum || sum > cfg.maxSum) {
            return `Sum Assured must be between ${cfg.minSum} and ${cfg.maxSum}`;
        }
        if (tenure < cfg.minTenure || tenure > cfg.maxTenure) {
            return `Tenure must be between ${cfg.minTenure} and ${cfg.maxTenure}`;
        }
        if (tenure > this.insuranceObj.Tenure__c) {
            return `Insurance tenure cannot exceed loan tenure`;
        }
        if (age < cfg.minAge || age > cfg.maxAge) {
            return `Age must be between ${cfg.minAge} and ${cfg.maxAge}`;
        }
        if ((age + tenure) > cfg.ceaseAge) {
            return `Age + Tenure must not exceed Cease Age ${cfg.ceaseAge}`;
        }

        return null; 
    }


    /*handleSave() {
        
    const saveEvent = new CustomEvent('save', {
        detail: { applicantId: this.applicantId,
        insuranceData: this.insuranceObj,
        isIcici: this.isIcici,
        isKotak: this.isKotak}
    });
        this.dispatchEvent(saveEvent);
    }*/

    getEVerificationCleanObject() {
    return {
        //Id: this.eVerification.Id,
        Loan_Application__c: this.applicationId,
        Funded__c: this.insuranceObj.Funded__c,
        Life_Insured__c: this.insuranceObj.Life_Insured__c,
        Loan_Type__c: this.insuranceObj.Loan_Type__c,
        Cover__c: this.insuranceObj.Cover__c,
        Benefit_Option__c: this.insuranceObj.Benefit_Option__c,
        Outstanding_Loan_Amount__c: this.insuranceObj.Outstanding_Loan_Amount__c,
        Outstanding_Loan_Tenure__c: this.insuranceObj.Outstanding_Loan_Tenure__c,
        Loan_Applicant_2__c: this.insuranceObj.Loan_Applicant_2__c,

        Joint_Life_Option__c: this.insuranceObj.Joint_Life_Option__c,
        Date_Of_Birth_of_Older_Borrower__c: this.insuranceObj.Date_Of_Birth__c,
        Date_Of_Birth_of_Younger_Borrower__c: this.insuranceObj.DOB_Younger__c,
        Date_Of_Cover_Of_Commencement__c: this.insuranceObj.Date_Of_Cover_Of_Commencement__c,
        Sanctioned_Loan_Amount__c: this.insuranceObj.Sanctioned_Loan_Amount__c,
        //Flat_Tenure_In_Years__c: this.insuranceObj.Flat_Tenure__c,
        //Reducing_Tenure_In_Years__c: this.insuranceObj.Reducing_Tenure__c,
        Loan_Tenure_In_Years__c: this.insuranceObj.Tenure__c,
        Does_Premium_Have_To_Be_Funding__c: this.insuranceObj.Does_Premium_Have_To_Be_Funding__c,
        Plan_Code__c: this.insuranceObj.Plan_Code__c, 
        //Age_Of_Younger_Borrower__c: this.insuranceObj.Age_Younger__c,
        //UnderWriting_Status_Of_Younger_Borrower__c: this.insuranceObj.UW_Status__c,
        //Younger_Borrower_s_Premium__c: this.insuranceObj.Premium__c
        Sum_Assured_Death__c: this.insuranceObj.Sum_Assured_Death__c,
        Coverage_Term_Death__c: this.insuranceObj.Coverage_Term_Death__c,
        Sum_Assured_ADB__c: this.insuranceObj.Sum_Assured_ADB__c,
        Coverage_Term_ADB__c: this.insuranceObj.Coverage_Term_ADB__c,
        Sum_Assured_ACI__c: this.insuranceObj.Sum_Assured_ACI__c,
        Coverage_Term_ACI__c: this.insuranceObj.Coverage_Term_ACI__c
        };
    }

    getNomineeLineItemsPayload() {
        return this.nominees.map(n => ({
            Id: n.id || null,
            Sequence__c: n.sequence,

            Nominee_Name__c: n.Nominee_Name__c,
            Nominee_Relationship__c: n.Nominee_Relationship__c,
            Nominee_Date_of_Birth__c: n.Nominee_Date_of_Birth__c,
            Nominee_Gender__c: n.Nominee_Gender__c,
            Is_Minor__c: n.Is_Minor__c,
            Appointee_Name__c: n.Appointee_Name__c,
            Appointee_Relationship__c: n.Appointee_Relationship__c,
            Appointee_DOB__c: n.Appointee_DOB__c,
            Percentage_of_Entitlement__c: n.Percentage_of_Entitlement__c,
            Nominee_Address__c: n.Nominee_Address__c
        }));
    }



    handleSave() {
        if (!this.validateRequiredFields()) {
            this.dispatchEvent(new ShowToastEvent({
                title: "Missing Required Information",
                message: "Please check all the validation errors before saving.",
                variant: "error"
            }));
            return;
        }
        const validationMsg = this.validateNumberAndDate();
        if (validationMsg) {
            this.dispatchEvent(new ShowToastEvent({
                title: "Validation Error",
                message: validationMsg,
                variant: "error"
            }));
            return;
        }
        const total = this.getTotalEntitlement();
        if (total !== 100) {
            this.dispatchEvent(new ShowToastEvent({
                title: "Validation Error",
                message: "Total nominee entitlement must be exactly 100%.",
                variant: "error"
            }));
            return;
        }
        if (this.isKotak) { 
            const kotakError = this.validateKotakPlanRules();
            if (kotakError) { 
                this.dispatchEvent(new ShowToastEvent({ 
                    title: 'Validation Error', 
                    message: kotakError, 
                    variant: 'error' 
                }));
                return;
            }
        }
        this.isLocked = true;
        this.isSaving = true;

        const finalRecord = this.getEVerificationCleanObject();

        updateEVerification({ inputRecord: finalRecord,
                            applicantId: this.applicantId,
                            oldEVId: this.eVerification?.Id || null , 
                            nominees: this.getNomineeLineItemsPayload()
                            })
            .then((newEvId) => {
                this.dispatchEvent(new CustomEvent("save", {
                    detail: {
                        eVerificationId: newEvId,
                        applicantId: this.applicantId,
                        insuranceData: this.insuranceObj,
                        isIcici: this.isIcici,
                        isKotak: this.isKotak
                    },
                    bubbles: true,
                    composed: true
                }));
            })
            .catch(error => {
                console.error("Save error:", error);
                this.dispatchEvent(new ShowToastEvent({
                    title: "Error",
                    message: "Failed to save",
                    variant: "error"
                }));
                this.isLocked = false;
            })
            .finally(() => {
                this.isSaving = false;   // ← spinner ends NOW
            });
    }



    @wire(getChildApplicants, { applicationId: '$applicationId', excludeApplicantId: '$applicantId' })
    wiredApplicants({ data, error }) {
        console.log(' WIRE TRIGGERED');
        console.log('applicationId >> ', this.applicationId);
        console.log('excludeApplicantId >> ', this.applicantId);
        console.log('Loan_Applicant_2__c>>',this.insuranceObj.Loan_Applicant_2__c);
        if (data && data.length > 0) {
            this.applicantList = data
                //.filter(app => !app.Insurance_Verification__c || app.Id === this.insuranceObj.Loan_Applicant_2__c)  
                .map(app => ({
                    id: app.Id,
                    label: app.Name,
                    value: app.Id,
                    gender: app.Gender__c,
                    dob: app.Date_of_Birth__c,
                    age: app.Applicant_Age__c
                }));
            console.log('Applicant List:', JSON.stringify(this.applicantList));
        } else if (data && data.length === 0) {
            console.warn('No child applicants found for this application');
            this.applicantList = [];
        } else if (error) {
            console.error('Error fetching applicants:', error);
        }
    }


    validateRequiredFields() {
        let isValid = true;

        const inputs = this.template.querySelectorAll('.validate');

        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });

        return isValid;
    }

    validateNumberAndDate() {
        let msg = null;

        // Number Fields 
        const numberFields = [
            { value: this.insuranceObj.Sanctioned_Loan_Amount__c, label: "Sanctioned Loan Amount" },
            { value: this.insuranceObj.Outstanding_Loan_Amount__c, label: "Outstanding Loan Amount" },
            { value: this.insuranceObj.Outstanding_Loan_Tenure__c, label: "Outstanding Loan Tenure" },
            { value: this.insuranceObj.Flat_Tenure__c, label: "Flat Tenure" },
            { value: this.insuranceObj.Reducing_Tenure__c, label: "Reducing Tenure" },
            { value: this.insuranceObj.Tenure__c, label: "Loan Tenure" },
            { value: this.insuranceObj.Premium__c, label: "Younger Borrower Premium" }
        ];

        for (let f of numberFields) {
            if (f.value !== undefined && f.value !== null && f.value !== '' && Number(f.value) <= 0) {
                msg = `${f.label} must be greater than 0`;
                break;
            }
        }

        // DATE VALIDATION: cannot be before same date last month
        if (!msg) {
            const docDate = this.insuranceObj.Date_Of_Cover_Of_Commencement__c;
            if (docDate) {
                const today = new Date();
                const limitDate = new Date(today);   // copy today

                // Move 1 month backward correctly (handles 31 → 30/28)
                limitDate.setMonth(limitDate.getMonth() - 1);

                // normalize
                limitDate.setHours(0, 0, 0, 0);
                const enteredDate = new Date(docDate);
                enteredDate.setHours(0, 0, 0, 0);

                if (enteredDate < limitDate) {
                    msg = `DATE OF COMMENCEMENT CANNOT BE BEFORE ${limitDate.toISOString().slice(0,10)}`;
                }
            }
        }

        return msg;  // return null if OK
    }

    handleNomineeDeleteConfirm() {
        if (this.nomineeToDeleteIndex !== undefined) {
            this.deleteNomineeAtIndex(this.nomineeToDeleteIndex);
            this.nomineeToDeleteIndex = null;
        }
    }

    deleteNomineeAtIndex(index) {
        this.nominees.splice(index, 1);
        this.nominees = this.nominees.map((n, i) => ({
            ...n,
            sequence: i + 1
        }));
    }



    handleApplicantChange(event) {
        const selectedId = event.detail.value;
        const selectedApplicant = this.applicantList.find(app => app.value === selectedId);

        if (selectedApplicant) {
            this.insuranceObj.Loan_Applicant_2__c = selectedApplicant.value;
            this.insuranceObj.Gender_2__c = selectedApplicant.gender;
            this.insuranceObj.Date_Of_Birth_2__c = selectedApplicant.dob;
            this.insuranceObj.Applicant_Age_2__c = selectedApplicant.age;
            this.insuranceObj.Loan_Applicant_2__c = selectedApplicant.value;

        }
    }

}