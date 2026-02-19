import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveBankDetail from '@salesforce/apex/SHF_CollateralController.saveBankDetail';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import IFSC_BANK_NAME_FIELD from '@salesforce/schema/IFSC_Code_Master__c.Bank_Name__c';
import IFSC_BRANCH_NAME_FIELD from '@salesforce/schema/IFSC_Code_Master__c.Branch_Name__c';


const TYPE_OF_ACCOUNT_OPTIONS = [
    { label: 'Cash Credit', value: 'Cash Credit' },
    { label: 'Current Account', value: 'Current Account' },
    { label: 'KCC Account', value: 'KCC Account' },
    { label: 'Over Draft Account', value: 'Over Draft Account' },
    { label: 'Saving Account', value: 'Saving Account' }
];

export default class ShfSellerBankForm extends LightningElement {
    @api collateralId;
    @api recordId;
    @api sellerOptions = [];
    @api bankRecord;

    @track record = {
    Account_No__c: null,
    Type_of_Account__c: null,
    Name: null,
    IFSC_Code_Master__c: null,
    Branch_Name__c: null
};


    typeOfAccountOptions = TYPE_OF_ACCOUNT_OPTIONS;
    selectedSellerId;
    isSaving = false;


    ifscId;          
    ifscBankName;   
        

    connectedCallback() {
    if (this.bankRecord) {
        const r = this.bankRecord;

        this.record.Account_No__c       = r.Account_No__c || null;
        this.record.Type_of_Account__c  = r.Type_of_Account__c || null;
        this.record.Name                = r.Name || null;
        this.record.IFSC_Code_Master__c = r.IFSC_Code_Master__c || null;
        this.record.Branch_Name__c      = r.Branch_Name__c || null;

        this.selectedSellerId = r.Collateral_Seller_Owner__c || null;
        this.ifscId = this.record.IFSC_Code_Master__c;
    }
}



    @wire(getRecord, {
        recordId: '$ifscId',
        fields: [IFSC_BANK_NAME_FIELD, IFSC_BRANCH_NAME_FIELD]
    })
    wiredIfscMaster({ data, error }) {
        if (data) {
            this.ifscBankName = getFieldValue(data, IFSC_BANK_NAME_FIELD);
            const branchName = getFieldValue(data, IFSC_BRANCH_NAME_FIELD);
             this.record.Branch_Name__c = branchName || null;


           // this.record.Branch_Master__c = branchId || null;
        } else if (error) {


            console.error('Error loading IFSC master', JSON.stringify(error));
        }
    }

    handleSellerChange(event) {
        this.selectedSellerId = event.detail.value;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value =
            event.detail && event.detail.value !== undefined
                ? event.detail.value
                : event.target.value;

        if (!field) return;

        this.record[field] = value;
    }


    handleIfscChange(event) {
    const value = event.detail.recordId || event.detail.value || null;

    this.ifscId = value;
    this.record.IFSC_Code_Master__c = value;

    this.ifscBankName = null;
    this.record.Branch_Name__c = null;
}


    validateForm() {
        let isValid = true;

        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-record-picker'
        );

        inputs.forEach(input => {
            input.reportValidity();
            if (!input.checkValidity()) {
                isValid = false;
            }
        });

        if (!this.selectedSellerId) {
            this.showToast('Error', 'Seller is required', 'error');
            isValid = false;
        }

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
            Collateral_Seller_Owner__c: this.selectedSellerId

        };

        saveBankDetail({ bankDetailJson: JSON.stringify(payload) })
            .then(() => {
                this.showToast('Success', 'Bank details saved', 'success');
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