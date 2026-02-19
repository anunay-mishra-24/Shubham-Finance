import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveCollateralAgreement from '@salesforce/apex/SHF_CollateralController.saveCollateralAgreement';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import AGREEMENT_OBJECT from '@salesforce/schema/Collateral_Agreement__c';
import AGREEMENT_TYPE_FIELD from '@salesforce/schema/Collateral_Agreement__c.Agreement_Type__c';

export default class ShfPropertyRegistrationForm extends LightningElement {
    @api collateralId;
    @api recordId;
    @api agreementRecord;

    @track record = {
        Registration_Number__c: null,
        Agreement_Type__c: null,
        SRO_Master__c: null, 
        Sale_Deed_Number__c: null,
        Registration_Date__c: null,
        Sale_Deed_Date__c: null,
        Agreement_Value_INR__c: null,
        Amenities_Agreement_Value_INR__c: null,
        Remarks__c: null
    };

    @track agreementTypeOptions = [];

    isSaving = false;
    @api hideButtons = false;

    @api
    handleExternalSave() {
        this.handleSave();
    }
    get today() {
        return new Date().toISOString().split('T')[0];
    }
    @wire(getObjectInfo, { objectApiName: AGREEMENT_OBJECT })
    objectInfo;

    get recordTypeId() {
        return this.objectInfo && this.objectInfo.data
            ? this.objectInfo.data.defaultRecordTypeId
            : null;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: AGREEMENT_TYPE_FIELD
    })
    wiredAgreementType({ data, error }) {
        if (data) {
            this.agreementTypeOptions = data.values;
        }
    }

    connectedCallback() {
        if (this.agreementRecord) {
            const r = this.agreementRecord;
            this.record = {
                Registration_Number__c: r.Registration_Number__c || null,
                Agreement_Type__c: r.Agreement_Type__c || null,
                SRO_Master__c: r.SRO_Master__c || null, 
                Sale_Deed_Number__c: r.Sale_Deed_Number__c || null,
                Registration_Date__c: r.Registration_Date__c || null,
                Sale_Deed_Date__c: r.Sale_Deed_Date__c || null,
                Agreement_Value_INR__c: r.Agreement_Value_INR__c || null,
                Amenities_Agreement_Value_INR__c:
                    r.Amenities_Agreement_Value_INR__c || null,
                Remarks__c: r.Remarks__c || null
            };
        }
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.record = {
            ...this.record,
            [field]: value
        };
    }


    handleSroChange(event) {
        const selectedId = event.detail.recordId; 
        this.record = {
            ...this.record,
            SRO_Master__c: selectedId
        };
    }

    validateForm() {
        let isValid = true;

        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea, lightning-record-picker'
        );
        inputs.forEach(input => {
            isValid = input.reportValidity() && input.checkValidity() && isValid;
        });

        return isValid;
    }

    handleSave() {
        if (!this.validateForm()) {
            return;
        }

        this.isSaving = true;

        const payload = {
            ...this.record,
            Id: this.recordId,
            Collateral__c: this.collateralId
        };

        saveCollateralAgreement({
            agreementJson: JSON.stringify(payload)
        })
            .then(() => {
                this.showToast('Success', 'Agreement saved', 'success');
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(error => {
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    getErrorMessage(error) {
        let message = 'Unknown error';
        if (Array.isArray(error?.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (error?.body?.message) {
            message = error.body.message;
        }
        return message;
    }
}