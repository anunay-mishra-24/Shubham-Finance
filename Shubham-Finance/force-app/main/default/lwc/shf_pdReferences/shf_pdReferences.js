// File: pdReferences.js
import { LightningElement, api, track, wire } from 'lwc';
import getSuplierReferences from '@salesforce/apex/PDReferenceService.getSuplierReferences';
import getCustomerReferences from '@salesforce/apex/PDReferenceService.getCustomerReferences';
import savePDRefrenceRecords from '@salesforce/apex/SHF_PersonalDiscussionController.savePDRefrenceRecords';
import deleteReference from '@salesforce/apex/PDReferenceService.deleteReference';
import checkDMSRequiredDoc from '@salesforce/apex/PDReferenceService.checkDMSRequiredDoc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Shf_pdReferences extends LightningElement {
    @api recordId = 'a0GC1000002NsUtMAK'; // do not hard-code in prod; provided automatically on record pages

    @track suppliers = [];
    @track customers = [];
    @track finalArray = [];
    @track finalArrayJson = '';
    @track isDelete;
    @track isRequired = false;
    @track showConfirm = false;
    @track showModal = true;
    confirmTitle = 'Confirm';
    confirmMessage = 'Are you sure?';
    counter = 0;

    _savedSuppliers = [];
    _savedCustomers = [];

    // --- Wire suppliers ---
    @wire(getSuplierReferences, { parentRecordId: '$recordId' })
    wiredSuppliers({ data, error }) {
        if (data) {
            // ensure sfId and uid exist for each row
            this.suppliers = data.map((r, i) => ({
                sfId: r.sfId || null,
                uid: r.uid || 'supplier-' + i,
                type: r.type || 'Supplier',
                contact: r.contact || '',
                nature: r.nature || '',
                value: r.value || '',
                frequency: r.frequency || '',
                doingSince: r.doingSince || '',
                creditPeriod: r.creditPeriod || ''
            }));
            this._savedSuppliers = JSON.parse(JSON.stringify(this.suppliers));
            this.updateFinalArray();
        } else if (error) {
            this.suppliers = [this.newRow('Supplier')];
            this._showToast('Error', 'Failed to load suppliers: ' + this._getErrorMessage(error), 'error');
        }
    }

    // --- Wire customers ---
    @wire(getCustomerReferences, { parentRecordId: '$recordId' })
    wiredCustomers({ data, error }) {
        if (data) {
            console.log('Data :', data);
            this.customers = data.map((r, i) => ({
                sfId: r.sfId || null,
                uid: r.uid || 'customer-' + i,
                type: r.type || 'Customer',
                contact: r.contact || '',
                nature: r.nature || '',
                value: r.value || '',
                frequency: r.frequency || '',
                doingSince: r.doingSince || '',
                creditPeriod: r.creditPeriod || ''
            }));
            console.log('Data :', this.customers);
            this._savedCustomers = JSON.parse(JSON.stringify(this.customers));
            this.updateFinalArray();
        } else if (error) {
            this.customers = [this.newRow('Customer')];
            this._showToast('Error', 'Failed to load customers: ' + this._getErrorMessage(error), 'error');
        }
    }

    @wire(checkDMSRequiredDoc, { pdRecordId: '$recordId' })
    wiredCustomers({ data, error }) {
        if (data) {
            console.log('Data :', data);
            this.isRequired = data;
        }
    }

    connectedCallback() {
        this.loadCustomers();
    }

    loadCustomers() {
        getCustomerReferences({ parentRecordId: this.recordId })
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

                    this._savedCustomers = JSON.parse(JSON.stringify(this.customers));
                    this.updateFinalArray();
                }
            })
            .catch(error => {
                this.customers = [this.newRow('Customer')];
                this._showToast(
                    'Error',
                    'Failed to load customers: ' + this._getErrorMessage(error),
                    'error'
                );
            });
    }

    // --- helpers ---
    _getErrorMessage(err) {
        if (!err) return 'Unknown error';
        if (Array.isArray(err.body)) return err.body.map(b => b.message).join('; ');
        if (err.body && err.body.message) return err.body.message;
        if (err.message) return err.message;
        return JSON.stringify(err);
    }

    _showToast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
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

    addRow(event) {
        const table = event.currentTarget.dataset.table;
        if (table === 'suppliers') {
            this.suppliers = [...(this.suppliers || []), this.newRow('Supplier')];
        } else {
            this.customers = [...(this.customers || []), this.newRow('Customer')];
        }
        this.updateFinalArray();
    }
    handleCreditPDSuccess() {
        console.log("Record updated successfully!");
        this.showToastMsg('Success', 'Record Saved Successfully.', 'success');
        //window.location.reload();
    }
    handleSubmit(event) {
        console.log("handleCreditPDSuccess Submit!");
        event.preventDefault();
        // Optionally manipulate fields before submit:
        // event.preventDefault();
        // const fields = event.detail.fields;
        // fields.SomeField__c = 'value';
    }

    removeRow(event) {
        const table = event.currentTarget.dataset.table;
        const idxRaw = event.currentTarget.dataset.index;
        const index = Number.isFinite(Number(idxRaw)) ? Number(idxRaw) : -1;
        if (index < 0) {
            console.warn('removeRow: invalid index', idxRaw);
            return;
        }
        if (table === 'suppliers') {
            const rows = [...this.suppliers];
            if (index < rows.length) rows.splice(index, 1);
            this.suppliers = rows.length ? rows : [this.newRow('Supplier')];
        } else {
            const rows = [...this.customers];
            if (index < rows.length) rows.splice(index, 1);
            this.customers = rows.length ? rows : [this.newRow('Customer')];
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
        } else {
            console.log("This record is not available in Salesforce CRM.!");
            this.dispatchEvent(new ShowToastEvent({
                title: 'Warning',
                message: 'This record is not available in Salesforce CRM.',
                variant: 'Warning'
            }));
            console.log("This record is not available in Salesforce CRM.!");
        }
        const table = event.currentTarget.dataset.table;
        const index = Number(event.currentTarget.dataset.index);
        // Your remove logic continues...
    }


    handleInputChange(event) {
        console.log('Event :', event.target.dataset.sfId);
        console.log('Event :', event.target.dataset.id);
        const table = event.target.dataset.table;
        const idxRaw = event.target.dataset.index;
        const index = Number.isFinite(Number(idxRaw)) ? Number(idxRaw) : -1;
        const field = event.target.dataset.field;
        const value = event.detail ? event.detail.value : event.target.value;

        if (index < 0 || !field) {
            console.warn('handleInputChange: missing index/field', idxRaw, field);
            return;
        }

        if (table === 'suppliers') {
            const copy = this.suppliers[index] ? { ...this.suppliers[index] } : this.newRow('Supplier');
            copy[field] = value;
            this.suppliers = this.suppliers.map((r, i) => (i === index ? copy : r));
        } else {
            const copy = this.customers[index] ? { ...this.customers[index] } : this.newRow('Customer');
            copy[field] = value;
            this.customers = this.customers.map((r, i) => (i === index ? copy : r));
        }
        this.updateFinalArray();
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
        };

        reader.readAsDataURL(file);
    }

    updateFinalArray() {
        this.finalArray = [...(this.suppliers || []), ...(this.customers || [])];
        try {
            this.finalArrayJson = JSON.stringify(this.finalArray);
            console.log('Final Array :', this.finalArrayJson);
        } catch (e) {
            this.finalArrayJson = '';
        }
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
    savePdRefrence() {
        const payloadString = JSON.stringify(this.finalArray);
        savePDRefrenceRecords({ pdRefJSON: payloadString, recordId: this.recordId })
            .then(result => {
                // success logic
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Personal Discussion record saved successfully.',
                    variant: 'success'
                }));
                console.log('savePDRefrenceRecords Id:', result);
                // e.g. show toast, navigate, etc.
            })
            .catch(error => {
                // error handling
                console.error('Error saving PD:', error);
                // e.g. show error toast
            });
    }
    showToastMsg(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: "pester"
            })
        )
    }
    closeModal() {
        // clear temp state if needed
        this.showModal = false;
    }
}