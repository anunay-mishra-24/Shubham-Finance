import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveCostOfPropertyRecord from '@salesforce/apex/SHF_CollateralController.saveCostOfPropertyRecord';

export default class ShfCostOfPropertyForm extends LightningElement {
    @api collateralId;
    @api recordId;      
    @api costRecord;    
    @api hideButtons = false;

    @track record = {
        Break_Up_Head__c: null,
        Break_Up_Cost__c: null,
        Break_Up_Description__c: null
    };

    isSaving = false;
    @api breakUpHeadOptions = [];
    @api usedBreakUpHeadByValue = {};
    @api defaultBreakUpHead;
    _norm(v) { return (v || '').toString().trim().toLowerCase(); }

get breakUpHeadOptionsComputed() {
    const all = (this.breakUpHeadOptions?.length)
        ? this.breakUpHeadOptions
        : [
            { label: 'Particular 1', value: 'Particular 1' },
            { label: 'Particular 2', value: 'Particular 2' }
        ];

    const usedMap = this.usedBreakUpHeadByValue || {};
    const current = this._norm(this.record?.Break_Up_Head__c);

    
    if (!this.recordId) {
        return all.filter(opt => !usedMap[this._norm(opt.value)]);
    }

    
    return all.filter(opt => {
        const key = this._norm(opt.value);
        if (key === current) return true;
        return !usedMap[key];
    });
}



    get breakUpHeadOptions() {
        return [
            { label: 'Particular 1', value: 'Particular 1' },
            { label: 'Particular 2', value: 'Particular 2' }
        ];
    }

    connectedCallback() {
    if (this.costRecord) {
        const r = this.costRecord;
        this.record = {
            Break_Up_Head__c: r.Break_Up_Head__c || null,
            Break_Up_Cost__c: r.Break_Up_Cost__c || null,
            Break_Up_Description__c: r.Break_Up_Description__c || null
        };
        return;
    }

    if (!this.recordId && this.defaultBreakUpHead) {
        this.record = { ...this.record, Break_Up_Head__c: this.defaultBreakUpHead };
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

    validateForm() {
        let isValid = true;

        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea'
        );
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });

        return isValid;
    }

    handleSave() {
        if (!this.validateForm()) {
            return;
        }
          const key = this._norm(this.record.Break_Up_Head__c);
    const usedId = (this.usedBreakUpHeadByValue || {})[key];

    
    if (usedId && usedId !== this.recordId) {
        this.showToast('Error', 'This Break Up Head already exists for this collateral.', 'error');
        return;
    }
        this.isSaving = true;

        const payload = {
            ...this.record,
            Id: this.recordId,
            Collateral__c: this.collateralId   
        };


        saveCostOfPropertyRecord({
            costJson: JSON.stringify(payload)
        })
            .then(() => {
                this.showToast('Success', 'Cost of Property saved', 'success');
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(error => {
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }


    @api
    handleExternalSave() {
        this.handleSave();
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