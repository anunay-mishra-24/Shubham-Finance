import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import validateBeforeStageChange from '@salesforce/apex/SHF_ApplicationMoveToNextController.validateBeforeStageChange';


const FIELDS = [
    'Application__c.Application_Stage__c',
    'Application__c.Charges_Visible__c'
];

export default class Shf_UpdateApplicationStage extends LightningElement {
    @api recordId;
    currentStage;
    showSpinner = false;
     isRecomendationModal = false;
    @track errorMessages = [];


    @track authorityOptions = [{ label: 'Yet to be add', value: 'Regional Credit Manager' },];
    @track useOptions = [{ label: 'Yet to be add', value: 'Regional Credit Manager' },];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        console.log(' this.recor ',  this.recordId);
        if (data) {
            this.currentStage = data.fields.Application_Stage__c.value;
        } else if (error) {
            console.error('Error fetching record: ', error);
            this.currentStage = null;
        }
    }

    @api invoke() {
        console.log(' this.currentStage ',  this.currentStage);
        // this.showSpinner = true;
        if (this.currentStage === 'Credit Assessment') {
            this.updateStage('Credit Sanction');
        }
        else if (this.currentStage === 'DDE') {
            // Validate first before proceeding
            validateBeforeStageChange({
                applicationId: this.recordId,
                currentStage: this.currentStage,
                nextStage: 'Credit Assessment'
            })
                .then(result => {
                    if (result) {
                        // Error message returned from Apex
                        this.showToast('Error', result, 'error');
                       // this.dispatchEvent(new CloseActionScreenEvent());
                    } else {
                        // Validation passed
                        console.log('about to open the modal');
                         this.isRecomendationModal = true; // recomendation part start from here , after passing all the validation.
                       // this.updateStage('Credit Assessment', true);
                    }
                })
                .catch(error => {
                    this.showToast('Error', error.body?.message || 'Validation failed.', 'error');
                    this.dispatchEvent(new CloseActionScreenEvent());
                });
        }
        else {
            this.showToast('Info', `Cannot move stage from ${this.currentStage}`, 'info');
           // this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
    //added by mansur alam

    handleRemark(event) {
        Console.log('handleRemark ', event.details);
    }
    handleSave(event) {
        console.log('event ', JSON.stringify(event));
    }

    updateStage(nextStage, setChargesVisible = false) {
        const fields = {
            Id: this.recordId,
            Application_Stage__c: nextStage
        };

        if (setChargesVisible === true) {
            // set the flag so the Charges tab will render the items
            fields.Charges_Visible__c = true;
        }

        updateRecord({ fields })
            .then(() => {
                this.showToast('Success', `Application stage updated to ${nextStage}.`, 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Failed to update stage.', 'error');
            })
            .finally(() => {
               this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    closeModal(){
       // this.isRecomendationModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}