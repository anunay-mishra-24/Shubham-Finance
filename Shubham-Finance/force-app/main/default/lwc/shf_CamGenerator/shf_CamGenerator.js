import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import generateCAM from '@salesforce/apex/SHF_CAMService.generateCAM';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

// required fields
import NAME_FIELD from '@salesforce/schema/Application__c.Name';
import LOAN_FIELD from '@salesforce/schema/Application__c.Applied_Loan_Amount__c';

export default class CamGenerator extends LightningElement {
    @api recordId;
    @track showModal = false;
    @track missingFields = [];

    // when record loads, auto-trigger
    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD, LOAN_FIELD] })
    wiredApplication({ error, data }) {
        if (data) {
            this.handleGenerate(data.fields);
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }

    handleGenerate(app) {
        this.missingFields = [];

        if (!app?.Name?.value) {
            this.missingFields.push('Applicant Name');
        }
        if (!app?.Applied_Loan_Amount__c?.value) {
            this.missingFields.push('Loan Amount');
        }

        if (this.missingFields.length > 0) {
            this.showModal = true;
        } else {
            generateCAM({ applicationId: this.recordId })
                .then(docId => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'CAM generated and stored. Document Id: ' + docId,
                            variant: 'success'
                        })
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error generating CAM',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        }
    }

    closeModal() {
        this.showModal = false;
    }
}