import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getSellerOwner from '@salesforce/apex/SHF_CollateralController.getSellerOwner';
import saveSellerOwner from '@salesforce/apex/SHF_CollateralController.saveSellerOwner';
import getSellerOwnerPicklists from '@salesforce/apex/SHF_CollateralController.getSellerOwnerPicklists';
import getLinkedApplicantText from '@salesforce/apex/SHF_CollateralController.getLinkedApplicantText';
import getSellerRecordTypeId from '@salesforce/apex/SHF_CollateralController.getSellerRecordTypeId';
import getAvailableOwnerApplicants from '@salesforce/apex/SHF_CollateralController.getAvailableOwnerApplicants';
import getOwnerRecordTypeId from '@salesforce/apex/SHF_CollateralController.getOwnerRecordTypeId';

import { refreshApex } from '@salesforce/apex';

export default class ShfCollateralSellerOwnerForm extends LightningElement {
    @track record = {};

    _seedRecord;
    @api collateralId;
    @api applicationId;
    @api recordId;
    @api recordTypeName = 'Owner';
    @api hideButtons = false;

    @track ownerTypeOptions = [];
    @track ownershipStatusOptions = [];
    @track individualNonIndividualOptions = [];
    @track ownerNameOptions = [];

    @api ownerSingleCount = 0;
    @api ownerJointCount = 0;

    isSaving = false;
    sellerRecordTypeId;
    ownerRecordTypeId;

    _refreshNonce = Date.now();
    _wiredOwnerOptsResult;



    @api
    handleExternalSave() {
        this.handleSave();
    }

    @api
    set seedRecord(val) {
        this._seedRecord = val || null;
        this.record = { ...(val || {}) };

        this.ensureOwnerIdFromName();
        this.applyOwnerTypeDateRules();
        this.updateOwnershipDuration(); 
    }
    get seedRecord() {
        return this._seedRecord;
    }

    get today() {
        return new Date().toISOString().split('T')[0];
    }



    get isOwnerForm() {
        return (this.recordTypeName || 'Owner').toLowerCase() === 'owner';
    }

    get isSellerForm() {
        return (this.recordTypeName || 'Owner').toLowerCase() === 'seller';
    }

    get isSingleOwnership() {
        return (
            this.isOwnerForm &&
            this.record &&
            this.record.ownershipStatus__c === 'Single'
        );
    }


    get isCurrentOwnerType() {
        return (
            this.isOwnerForm &&
            this.record &&
            this.record.ownerType__c === 'Current'
        );
    }

    get isFutureOwnerType() {
        return (
            this.isOwnerForm &&
            this.record &&
            this.record.ownerType__c === 'Future'
        );
    }

    get isPreviousOwnerType() {
        return (
            this.isOwnerForm &&
            this.record &&
            this.record.ownerType__c === 'Previous'
        );
    }





    get isFromDateRequired() {
        return this.isPreviousOwnerType;
    }

    get isToDateRequired() {
        return this.isPreviousOwnerType;
    }

    get isToDateDisabled() {
        return this.isCurrentOwnerType || this.isFutureOwnerType;
    }


    get currentApplicantId() {
        const v = this.record && this.record.Owner_Applicant_Id__c;
        if (!v) {
            return null;
        }
        return (v.length === 15 || v.length === 18) ? v : null;
    }



    @wire(getSellerOwnerPicklists)
    wiredPicklists({ error, data }) {
        if (data) {
            const toOptions = list =>
                (list || []).map(v => ({ label: v, value: v }));
            this.ownerTypeOptions = toOptions(data.ownerType__c);
            this.ownershipStatusOptions = toOptions(data.ownershipStatus__c);
            this.individualNonIndividualOptions = toOptions(
                data.individualNonIndividual__c
            );


            const hasPrevious = this.ownerTypeOptions.some(
                o => o.value === 'Previous'
            );
            if (!hasPrevious) {
                this.ownerTypeOptions = [
                    ...this.ownerTypeOptions,
                    { label: 'Previous', value: 'Previous' }
                ];
            }
        } else if (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    @wire(getSellerOwner, {
        recordId: '$recordId',
        _refreshNonce: '$_refreshNonce'
    })
    wiredRecord({ error, data }) {
        if (data) {
            this.record = { ...data };

            this.ensureOwnerIdFromName();
            this.applyOwnerTypeDateRules();
            this.updateOwnershipDuration(); 
        } else if (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    @wire(getLinkedApplicantText, { applicationId: '$applicationId' })
    wiredLinked({ error, data }) {
        if (data && this.isOwnerForm) {
            this.record = {
                ...this.record,
                Linked_Applicant__c: data
            };
        } else if (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    @wire(getSellerRecordTypeId)
    wiredSellerRT({ error, data }) {
        if (data) {
            this.sellerRecordTypeId = data;
        } else if (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    @wire(getOwnerRecordTypeId)
    wiredOwnerRT({ error, data }) {
        if (data) {
            this.ownerRecordTypeId = data;
        } else if (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    @wire(getAvailableOwnerApplicants, {
        applicationId: '$applicationId',
        collateralId: '$collateralId',
        currentApplicantId: '$currentApplicantId',
        refreshNonce: '$_refreshNonce'
    })
    wiredOwnerApplicantOptions(result) {
        this._wiredOwnerOptsResult = result;
        const { data, error } = result;
        if (data) {
            this.ownerNameOptions = data.map(o => ({
                label: o.name,
                value: o.id
            }));
            this.ensureOwnerIdFromName();
        } else if (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }



    ensureOwnerIdFromName() {
        if (!this.isOwnerForm) {
            return;
        }

        if (this.record && this.record.Owner_Applicant_Id__c) {
            return;
        }

        if (!this.ownerNameOptions || !this.ownerNameOptions.length) {
            return;
        }

        const existingName =
            (this.record &&
                (this.record.ownerName__c || this.record.Name)) ||
            null;

        if (!existingName) {
            return;
        }

        const match = this.ownerNameOptions.find(
            o => o.label === existingName
        );
        if (match) {
            this.record = {
                ...this.record,
                Owner_Applicant_Id__c: match.value
            };
        }
    }


    applyOwnerTypeDateRules() {
        if (!this.isOwnerForm || !this.record) {
            return;
        }
        const type = this.record.ownerType__c;
        if (type === 'Current' || type === 'Future') {
            this.record = {
                ...this.record,
                To_Date__c: null
            };
        }
    }



   calculateMonthsBetween(startStr, endStr) {
    if (!startStr || !endStr) {
        return null;
    }

    const start = new Date(startStr);
    const end = new Date(endStr);

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        return null;
    }


    let months =
        (end.getFullYear() - start.getFullYear()) * 12 +
        (end.getMonth() - start.getMonth());


    if (months < 0) {
        months = 0;
    }


    return months;
}



    updateOwnershipDuration() {
    if (!this.isOwnerForm || !this.record) {
        return;
    }

    const ownerType = this.record.ownerType__c;
    const fromStr = this.record.From_Date__c;


    if (!fromStr) {
        this.record = {
            ...this.record,
            ownershipDates__c: null
        };
        return;
    }

    let endStr = null;

    if (ownerType === 'Previous') {
        const toStr = this.record.To_Date__c;
        if (!toStr) {

            this.record = {
                ...this.record,
                ownershipDates__c: null
            };
            return;
        }
        endStr = toStr;
    } else if (ownerType === 'Current' || ownerType === 'Future') {

        endStr = this.today;
    } else {

        this.record = {
            ...this.record,
            ownershipDates__c: null
        };
        return;
    }

    const months = this.calculateMonthsBetween(fromStr, endStr);

    this.record = {
        ...this.record,
        ownershipDates__c: months
    };
}




    handleChange(event) {
    const field = event.target.dataset.field;
    const value = event.detail.value ?? event.target.value;

    if (!field) {
        return;
    }

    
    if (field === 'dobIncorporationDate__c' && value) {
        const today = this.today;
        if (value > today) {
            this.showToast(
                'Validation',
                'DOB/Incorporation Date cannot be greater than today',
                'error'
            );
            event.target.value = null;
            return;
        }
    }

    let updated = {
        ...this.record,
        [field]: value
    };

    
    if (field === 'ownershipStatus__c') {
        if (value === 'Single') {
            updated.Percent_Share__c = 100;
        } else {
            updated.Percent_Share__c = null;
        }
    }

    
    if (field === 'ownerType__c') {
        if (value === 'Current' || value === 'Future') {
            updated.To_Date__c = null;
        }
    }

    this.record = updated;

    
    if (this.isOwnerForm) {
        this.updateOwnershipDuration();
    }
}


    handleOwnerApplicantChange(event) {
        const val = event.detail.value;
        const opt = (this.ownerNameOptions || []).find(o => o.value === val);
        const label = opt ? opt.label : null;

        this.record = {
            ...this.record,
            Owner_Applicant_Id__c: val,
            Name: label,
            ownerName__c: label
        };
    }

    handleSave() {
        const valid = this.validate();
        if (!valid) {
            return;
        }
        if (this.isOwnerForm && !this.validateOwnershipRules()) {
            return;
        }

        const payload = { ...this.record };
        payload.Collateral__c = this.collateralId;

        if (!payload.RecordTypeId) {
            if (this.isSellerForm && this.sellerRecordTypeId) {
                payload.RecordTypeId = this.sellerRecordTypeId;
            } else if (this.isOwnerForm && this.ownerRecordTypeId) {
                payload.RecordTypeId = this.ownerRecordTypeId;
            }
        }

        this.isSaving = true;

        saveSellerOwner({
            record: payload,
            applicationId: this.applicationId
        })
            .then(id => {
                this.showToast(
                    'Success',
                    'Seller/Owner saved successfully',
                    'success'
                );
                this.dispatchEvent(new CustomEvent('success'));
                this._refreshNonce = Date.now();
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    this.getErrorMessage(error),
                    'error'
                );
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    validateOwnershipRules() {
        const status = this.record.ownershipStatus__c;
        const isNew = !this.record.Id;

        if (!isNew || !status) {
            return true;
        }

        const singleCount = this.ownerSingleCount || 0;
        const jointCount = this.ownerJointCount || 0;

        if (status === 'Single') {
            if (singleCount > 0 || jointCount > 0) {
                this.showToast(
                    'Warning',
                    'Ownership Status is Single. Only one owner is allowed for this collateral.',
                    'warning'
                );
                return false;
            }
        }

        if (status === 'Joint') {
            if (singleCount > 0) {
                this.showToast(
                    'Warning',
                    'Cannot add Joint owner when an owner with Ownership Status "Single" already exists for this collateral.',
                    'warning'
                );
                return false;
            }
        }

        return true;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    @api
    async forceReload() {
        this._refreshNonce = Date.now().toString();

        if (this._wiredOwnerOptsResult) {
            try {
                await refreshApex(this._wiredOwnerOptsResult);
            } catch (e) {

            }
        }
    }



    validate() {
        let isValid = true;
        let focused = false;
        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea'
        );
        inputs.forEach(i => {
            i.reportValidity();
            if (!i.checkValidity()) {
                isValid = false;
                if (!focused && typeof i.focus === 'function') {
                    i.focus();
                    focused = true;
                }
            }
        });

        if (isValid && this.isOwnerForm && !this.record.Owner_Applicant_Id__c) {
            this.showToast(
                'Validation',
                'Owner Name is required.',
                'error'
            );
            isValid = false;
        }

        return isValid;
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