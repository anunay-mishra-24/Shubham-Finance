import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initiateTransaction from '@salesforce/apex/UB_Perfios_API.initiateTransaction';

export default class InitiatePerfios extends LightningElement {

    @api recordId;
    @track openModal = false;

    @track fileNames = [];
    password = null;
    fromDate = null;
    toDate = null;

    
    @track fileTypeError = '';
    @track fromDateError = '';
    @track toDateError = '';

    @api open() {
        this.openModal = true;
    }

    @api openModalFromParent(recordId) {
        this.recordId = recordId;
        this.openModal = true;
    }

    closeModal() {
        this.openModal = false;

        this.fileNames = [];
        this.password = null;
        this.fromDate = null;
        this.toDate = null;

       
        this.fileTypeError = '';
        this.fromDateError = '';
        this.toDateError = '';

        const upload = this.template.querySelector('lightning-file-upload');
        if (upload) {
            upload.files = [];
        }
    }


   
    handleUpload(event) {
        this.fileTypeError = '';

        const uploaded = event.detail.files;

        uploaded.forEach(file => {
            if (!file.name.toLowerCase().endsWith('.pdf')) {
                this.fileTypeError = "Your company doesn't support the following file types: ." + file.name.split('.').pop();
            }
        });

        if (!this.fileTypeError) {
            this.fileNames = uploaded.map(f => f.name);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Files uploaded successfully.",
                    variant: "success"
                })
            );
        }
    }
    handleChange(event) {
        const fieldName = event.target.name;

        if (fieldName === 'Password' || event.target.label === 'Password') {
            this.password = event.target.value;
            return;
        }

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        if (fieldName === 'fromDate') {
            this.fromDate = event.target.value;

            const selected = new Date(this.fromDate);
            selected.setHours(0, 0, 0, 0);

            this.fromDateError = selected > today ? "Date cannot be in the future." : "";
            return;
        }

        if (fieldName === 'toDate') {
            this.toDate = event.target.value;

            const selected = new Date(this.toDate);
            selected.setHours(0, 0, 0, 0);

            this.toDateError = selected > today ? "Date cannot be in the future." : "";
            return;
        }
    }


    handleSave() {
        if (!this.fromDate || !this.toDate) {
            this.dispatchEvent(new ShowToastEvent({
                title: "Error",
                message: "Please fill all required fields.",
                variant: "error"
            }));
            return;
        }

        if (this.fromDateError || this.toDateError || this.fileTypeError) {
            this.dispatchEvent(new ShowToastEvent({
                title: "Error",
                message: "Please resolve errors before saving.",
                variant: "error"
            }));
            return;
        }

        // Call Apex test method that creates 3 Api_Logger__c records
        initiateTransaction({
            customerId: this.recordId,
            password: this.password,
            fromDate: this.fromDate,
            toDate: this.toDate
        })
        .then(result => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Transaction innitiated ' + result,
                variant: 'success'
            }));
            this.closeModal();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error innitiating transactions',
                message: error?.body?.message || error.message || JSON.stringify(error),
                variant: 'error'
            }));
        });
    }
}