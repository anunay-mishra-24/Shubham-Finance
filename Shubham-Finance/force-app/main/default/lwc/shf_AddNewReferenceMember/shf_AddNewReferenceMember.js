import { LightningElement, api, track, wire } from 'lwc';
import { createRecord, getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPrimaryApplicantName from '@salesforce/apex/SHF_AddNewReferenceMemberController.getPrimaryApplicantName';
import REFERENCE_MEMBER_OBJECT from '@salesforce/schema/Reference_Member__c';
import GENDER_FIELD from '@salesforce/schema/Reference_Member__c.Gender__c';
import TYPE_FIELD from '@salesforce/schema/Reference_Member__c.Type__c';
import RELATIONSHIP_FIELD from '@salesforce/schema/Reference_Member__c.Relationship__c';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import Reference_Relationship_Labels from '@salesforce/label/c.Reference_Relationship_Labels';
import Family_Relationship_Labels from '@salesforce/label/c.Family_Relationship_Labels';
import Witness_Relationship_Labels from '@salesforce/label/c.Witness_Relationship_Labels';
import SALUTATION_FIELD from '@salesforce/schema/Reference_Member__c.Salutation__c';
import IS_CORPORATE_FIELD from '@salesforce/schema/Reference_Member__c.Is_Corporate_Signatory__c';
import IS_KEY_FIELD from '@salesforce/schema/Reference_Member__c.Is_Key_Employee__c';
import ADDRESS_TYPE_FIELD from '@salesforce/schema/Reference_Member__c.Address_Type__c';
import IS_ADDRESS_VERIFIED_FIELD from '@salesforce/schema/Reference_Member__c.Is_Address_Verified__c';
import INDIVIDUAL_COMPANY_FIELD from '@salesforce/schema/Reference_Member__c.Individual_Company__c';
import TITLE_FIELD from '@salesforce/schema/Reference_Member__c.Title__c';

const PINCODE_FIELDS = [
    'Pincode_Master__c.City_Master__r.Name',
    'Pincode_Master__c.City_Master__r.State_Master__r.Name',
    'Pincode_Master__c.City_Master__r.Country__c'
];


export default class Shf_AddNewReferenceMember extends LightningElement {

    // Parent record id and object name from record page
    @api recordId;
    @api objectApiName;

    @track showTypeModal = false;
    @track showFormModal = false;
    primaryApplicantName;
    @track showIndividualCompanyModal = false;

    @track city = '';
    @track state = '';
    @track country = '';
    @track selectedPincodeId;

    isSaving = false;

    @track selectedType = '';
    @track formData = {};
    @track genderOptions = [];
    @track applicantTypeOptions = [];
    @track relationshipOptions = [];
    @track salutationOptions = [];
    @track yesNoOptions = [];
    @track keyEmployeeOptions = [];
    @track addressTypeOptions = [];
    @track addressVerifiedOptions = [];
    @track individualCompanyOptions = [];
    @track titleOptions = [];




    connectedCallback() {
        // Fetch only if the current object is Loan_Applicant__c
        if (this.objectApiName === 'Loan_Applicant__c') {
            this.fetchPrimaryApplicant();
        }
    }

    fetchPrimaryApplicant() {
        getPrimaryApplicantName({ applicantId: this.recordId })
            .then(result => {
                this.primaryApplicantName = result;
            })
            .catch(error => {
                console.error('Error fetching primary applicant', error);
            });
    }


    @wire(getRecord, { recordId: '$selectedPincodeId', fields: PINCODE_FIELDS })
    wiredPincode({ error, data }) {
        if (data) {
            const cityRec = data.fields.City_Master__r;
            if (cityRec) {
                this.city = cityRec.value?.fields?.Name?.value || '';
                this.state = cityRec.value?.fields?.State_Master__r?.value?.fields?.Name?.value || '';
                this.country = cityRec.value?.fields?.Country__c?.value || '';
            }
            //this.updateFormData();
        } else if (error) {
            console.error(error);
            this.showToast('Error', 'Failed to fetch City/State/Country', 'error');
        }
    }


    @wire(getObjectInfo, { objectApiName: REFERENCE_MEMBER_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: GENDER_FIELD
    })
    wiredGender({ data, error }) {
        if (data) {
            this.genderOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: TYPE_FIELD
    })
    wiredtype({ data, error }) {
        if (data) {
            this.applicantTypeOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: INDIVIDUAL_COMPANY_FIELD
    })
    wiredIndividualCompany({ data, error }) {
        if (data) {
            this.individualCompanyOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: RELATIONSHIP_FIELD
    })
    wiredRelationship({ data, error }) {
        if (data) {
            this.relationshipOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: SALUTATION_FIELD
    })
    wiredSalutation({ data }) {
        if (data) this.salutationOptions = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: IS_CORPORATE_FIELD
    })
    wiredCorporate({ data }) {
        if (data) this.yesNoOptions = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: IS_KEY_FIELD
    })
    wiredKeyEmp({ data }) {
        if (data) this.keyEmployeeOptions = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: ADDRESS_TYPE_FIELD
    })
    wiredAddressType({ data }) {
        if (data) this.addressTypeOptions = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: IS_ADDRESS_VERIFIED_FIELD
    })
    wiredAddressVerified({ data }) {
        if (data) this.addressVerifiedOptions = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: TITLE_FIELD
    })
    wiredTitle({ data, error }) {
        if (data) {
            this.titleOptions = data.values;
        }
    }

    get referenceLabels() {
        return Reference_Relationship_Labels.split(',').map(i => i.trim());
    }

    get familyLabels() {
        return Family_Relationship_Labels.split(',').map(i => i.trim());
    }

    get witnessLabels() {
        return Witness_Relationship_Labels.split(',').map(i => i.trim());
    }

    get filteredRelationshipOptions() {
        if (!this.relationshipOptions) return [];

        let allowed = [];

        if (this.selectedType === 'Reference') {
            allowed = this.referenceLabels;
        }
        else if (this.selectedType === 'Family') {
            allowed = this.familyLabels;
        }
        else if (this.selectedType === 'Witness') {
            allowed = this.witnessLabels;
        }

        return this.relationshipOptions.filter(opt =>
            allowed.includes(opt.label)
        );
    }




    // -----------------------------
    // OPEN FIRST MODAL
    // -----------------------------
    openTypeModal() {
        this.showTypeModal = true;
    }

    closeModal() {
        this.showTypeModal = false;
        this.showFormModal = false;
        this.showIndividualCompanyModal = false;
        this.formData = {}; 


        this.selectedType = '';
        this.selectedCategory = '';

        // // Reset flags
        // this.isIndividual = false;
        // this.isCompany = false;
        // this.selectedPincodeId = '';

        this.resetAddressFields();

        



    }


    get filteredTitleOptions() {
        if (this.isCompany) {
            return this.titleOptions.filter(opt => opt.value === 'M/S');
        }
        return this.titleOptions.filter(opt => opt.value !== 'M/S');
    }

    handleCategoryChange(event) {
        const selected = event.detail.value;

        this.formData.Individual_Company__c = selected;

        if (selected === 'Company') {
            this.formData.Title__c = 'M/S';
        } else {
            this.formData.Title__c = null;
        }

        this.formData = { ...this.formData };
    }

    // -----------------------------
    // OPTIONS FOR TYPE (DYNAMIC)
    // -----------------------------
    get typeOptions() {
        if (this.objectApiName === 'Application__c') {
            return [
                { label: 'Reference', value: 'Reference' },
                { label: 'Family', value: 'Family' },
                { label: 'Witness', value: 'Witness' }
            ];
        } else {
            return [
                { label: 'Contact Person & Key Employee', value: 'Contact Person & Key Employee' },
                { label: 'Partner & Director', value: 'Partner & Director' }
            ];
        }
    }

    // -----------------------------
    // HANDLE TYPE SELECT
    // -----------------------------
    handleTypeChange(event) {
        this.selectedType = event.detail.value;
    }

    // NEXT → SHOW FORM
    goToForm() {
        if (!this.selectedType) {
            this.showToast('Error', 'Please select a type.', 'error');
            return;
        }

        if (this.selectedType === 'Partner & Director') {
            this.showTypeModal = false;
            this.showIndividualCompanyModal = true;
            return;
        }

        this.showTypeModal = false;
        this.showFormModal = true;
    }

    backFromIndividualCompany() {
        this.resetAddressFields();

        this.showIndividualCompanyModal = false;
        this.showTypeModal = true;
    }

    continueAfterIndividualCompany() {
        if (!this.formData.Individual_Company__c) {
            this.showToast('Error', 'Please select Individual/Company.', 'error');
            return;
        }

        this.showIndividualCompanyModal = false;
        this.showFormModal = true;
    }



    // BACK → SHOW TYPE MODAL
    backToType() {

        this.resetAddressFields();

        if (this.isIndividual || this.isCompany) {
            this.showFormModal = false;
            this.showIndividualCompanyModal = true;
        }
        this.showFormModal = false;
        this.showTypeModal = true;
    }

    // -----------------------------
    // FLAGS FOR CONDITIONAL RENDERING
    // -----------------------------
    get isReference() {
        return this.selectedType === 'Reference';
    }

    get isFamily() {
        return this.selectedType === 'Family';
    }

    get isWitness() {
        return this.selectedType === 'Witness';
    }

    get isContactPerson() {
        return this.selectedType === 'Contact Person & Key Employee';
    }

    get isPartnerDirector() {
        return this.selectedType === 'Partner & Director';
    }

    get isIndividual() {
        return this.formData.Individual_Company__c === 'Individual';
    }

    get isCompany() {
        return this.formData.Individual_Company__c === 'Company';
    }

    // -----------------------------
    // HANDLE FIELD CHANGE
    // -----------------------------
    handleChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.value;

        if (fieldName === 'Company_Name__c' && this.isCompany) {
        this.formData.Name = value; // auto-fill standard Name field
    }

    // If Individual and user is typing Name
    if (fieldName === 'Name' && !this.isCompany) {
        this.formData.Name = value; // normal behavior
    }

        // --------------------------
        // Date Validation
        // --------------------------
        if (fieldName === 'Date_of_Birth__c') {
            const today = new Date().toISOString().split('T')[0]; // yyyy-mm-dd
            if (value >= today) {
                event.target.setCustomValidity('Date of Birth cannot be today or in the future.');
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }

        if (fieldName === 'Date_Of_Incorporation__c') {
            const today = new Date().toISOString().split('T')[0];
            if (value >= today) {
                event.target.setCustomValidity('Date of Incorporation cannot be today or in the future.');
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }

        // --------------------------
        // Holding Percentage Validation
        // --------------------------
        if (fieldName === 'Holding_Percentage__c') {
            const numValue = parseFloat(value);
            if (numValue > 100) {
                event.target.setCustomValidity('Holding Percentage cannot exceed 100%.');
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }

        // --------------------------
        // Update formData
        // --------------------------
        this.formData[fieldName] = value;
    }


    validateAllFields() {
        let isValid = true;

        const fields = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea, lightning-record-picker'
        );

        fields.forEach(field => {
            // Disabled fields should not validate
            if (field.disabled) {
                return;
            }

            field.reportValidity();

            if (!field.checkValidity()) {
                isValid = false;
            }
        });

        return isValid;
    }


    // -----------------------------
    // SAVE RECORD 
    // -----------------------------
    saveRecord() {

        if (this.isSaving) {
            return;
        }

        this.isSaving = true;
        const fields = { ...this.formData };

        ['City__c', 'State__c', 'Country__c'].forEach(f => delete fields[f]);

        if (!this.validateAllFields()) {
            this.showToast('Error', 'Please complete all mandatory fields.', 'error');
            this.isSaving = false;
            return;
        }

        if (this.isContactPerson && !this.formData.Pincode__c) {
            this.showToast('Error', 'Please select a Pincode.', 'error');
            this.isSaving = false;
            return;
        }
        // Set Parent Lookup dynamically
        if (this.objectApiName === 'Application__c') {
            fields.Application__c = this.recordId;
        } else {
            fields.Loan_Applicant__c = this.recordId;
        }

        // Set Type picklist value
        fields.Type_of_Member__c = this.selectedType;
        delete fields.City__c;
        delete fields.State__c;
        delete fields.Country__c;

        const recordInput = {
            apiName: 'Reference_Member__c',
            fields
        };

        

        createRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Record saved successfully!', 'success');

                this.closeModal();

                setTimeout(() => {
                    window.location.reload();
                }, 500);


            })
            .catch(error => {
                console.error('Full Error:', error);

                let message = 'An unexpected error occurred';

                if (error?.body) {
                    if (error.body.message) {
                        message = error.body.message;
                    }

                    // Field-specific errors
                    if (error.body.output && error.body.output.fieldErrors) {
                        const fieldMsgs = [];
                        for (let field in error.body.output.fieldErrors) {
                            error.body.output.fieldErrors[field].forEach(err => {
                                fieldMsgs.push(`${field}: ${err.message}`);
                            });
                        }
                        if (fieldMsgs.length) message = fieldMsgs.join(', ');
                    }

                    // Other output errors
                    if (error.body.output && error.body.output.errors && error.body.output.errors.length) {
                        message += ' | ' + error.body.output.errors.map(e => e.message).join(', ');
                    }
                }

                this.showToast('Error', message, 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });

    }

    resetAddressFields() {
        this.formData.Pincode__c = null;
        this.selectedPincodeId = null;

        this.city = '';
        this.state = '';
        this.country = '';

        delete this.formData.City__c;
        delete this.formData.State__c;
        delete this.formData.Country__c;

    }



    handlePincodeChange(event) {
        const pincodeId = event.detail.recordId;
        if (!pincodeId) return;

        this.formData.Pincode__c = pincodeId;
        this.selectedPincodeId = pincodeId; 
    }


    // -----------------------------
    // TOAST 
    // -----------------------------
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissible'
            })
        );
    }
}