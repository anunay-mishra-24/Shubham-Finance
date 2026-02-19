import { LightningElement, api } from 'lwc';
import sendBackToQDE from '@salesforce/apex/SHF_LoanApplicationHelper.sendBackToQDE';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from '@salesforce/apex';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class Shf_SendBackToQDE extends LightningElement {
    @api recordId;

    @api invoke() {
        console.log('Invoke called for record:', this.recordId);

        sendBackToQDE({ applicationId: this.recordId })
            .then(() => {
                console.log('Record type updated successfully via Apex');
                this.showToast('Success', 'Application successfully sent back to QDE.', 'success');

                // Refresh record data on parent page
                getRecordNotifyChange([{ recordId: this.recordId }]);
            })
            .catch(error => {
                console.error('Error updating record type via Apex:', error);
                this.showToast('Error', error.body?.message || error.message || 'Failed to change record type.', 'error');
            })
            .finally(() => {
                console.log('Closing action screen');
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    showToast(title, message, variant) {
        console.log(`Toast - ${title}: ${message}`);
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}