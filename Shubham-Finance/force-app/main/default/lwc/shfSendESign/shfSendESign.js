import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import sendForESign from '@salesforce/apex/SHF_Leegality_Service.legalityApiCall';
import { getRecord } from 'lightning/uiRecordApi';


const FIELDS = [
    'Application__c.E_Sign_Executed__c', 'Application__c.E_Sign_Success__c'
];

export default class ShfSendESign extends LightningElement {
    recordId;
    eSignExecuted = false;
    eSignSuccess = false;
    showSpinner = true;

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef) {
            this.recordId = pageRef.state.recordId;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredApplication({ data, error }) {
        if (data) {
            const { E_Sign_Executed__c, E_Sign_Success__c } = data.fields;
            this.eSignExecuted = E_Sign_Executed__c.value;
            this.eSignSuccess = E_Sign_Success__c.value;
        } else if (error) {
            console.error('wiredApplication : error --> ' + JSON.stringify(error));
        }
    }

    connectedCallback() {
        console.log('connectedCallback : this.recordId --> ' + this.recordId);
        sendForESign({ loanApplicationId: this.recordId })
            .then(result => {
                console.log('sendForESign result --> ' + result);
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error('sendForESign error --> ', error);
                this.showToast('Error', 'An error occurred while initiating E-Sign process.', 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}