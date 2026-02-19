import { LightningElement,api,track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import moveToNextStage from '@salesforce/apex/SHF_DisbursementMoveToNextController.moveToNextStage';

export default class Shf_MoveToNextDisbursement extends LightningElement {
    @api recordId;
    @track showErrorModal = false;
    @track errorMessages = [];
    @track isLoading = false;
    @wire(CurrentPageReference)
    captureRecordId(currentPageReference) {
        if (currentPageReference?.state?.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference?.attributes?.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }
        console.log('Current Record Id #####', this.recordId);
    }
    connectedCallback() {
        console.log('Record ID:', this.recordId);
        this.handleMoveToNextStage();
    }
    handleMoveToNextStage() {
        console.log('test');
        this.isLoading = true;
        moveToNextStage({ recordId: this.recordId })
            .then(result => {
                if (result.startsWith('SUCCESS')) {
                    this.showToast('Success', result.replace('SUCCESS: ', ''), 'success');
                    getRecordNotifyChange([{ recordId: this.recordId }]);

                    setTimeout(() => {
                        window.location.reload();
                    }, 500);
                } else if (result.startsWith('ERROR')) {
                    // Split multiple error lines if any (using semicolon or newline)
                    const cleanMsg = result.replace('ERROR: ', '');
                    this.errorMessages = cleanMsg.split(/[\n;]+/).map(msg => msg.trim()).filter(msg => msg);
                    this.showErrorModal = true;
                    console.log('this.errorMessages:', this.errorMessages);
                    console.log('showErrorModal set to true',this.showErrorModal);
                } else {
                    this.showToast('Info', result, 'info');
                }
            })
            .catch(error => {
                const errMsg = error.body?.message || error.message;
                this.errorMessages = errMsg.split(/[\n;]+/).map(msg => msg.trim()).filter(msg => msg);
                this.showErrorModal = true;
                console.log('this.errorMessages11111:', this.errorMessages);
                    console.log('showErrorModal set to true1111',this.showErrorModal);
            })
            .finally(() => {
                this.isLoading = false;
                if (!this.showErrorModal) {
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    handleCloseModal() {
        this.showErrorModal = false;
    }
}