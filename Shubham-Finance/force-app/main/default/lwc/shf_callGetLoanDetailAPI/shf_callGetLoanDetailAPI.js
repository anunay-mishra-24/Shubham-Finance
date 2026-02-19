import { LightningElement, api, track, wire } from 'lwc';
import getLoanDetails from '@salesforce/apex/shf_getLoanService.getLoanDetails';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getMsgConfigRecord from '@salesforce/apex/SHF_CommonUtil.getMessageConfigurationsBySource';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Shf_callGetLoanDetailAPI extends LightningElement {
    @api recordId;
    @track isLoading = false;

    source = 'JointExposure';
    @track messagesMap = {};
    result;
    msgConfig;


    connectedCallback() {
        this.isLoading = true;

        // Remove X button & backdrop for modal
        setTimeout(() => {
            const closeButton = document.querySelector('.slds-modal__close');
            if (closeButton) closeButton.style.display = 'none';

            const backdrop = document.querySelector('.slds-backdrop');
            if (backdrop) backdrop.style.display = 'none';
        }, 100);

        // Get all message config metadata for this source
        this.fetchMsgConfigMetadata();
    }

    @wire(CurrentPageReference)
    getApplicationId(currentPageReference) {
        if (currentPageReference.state?.recordId) {
            this.recordId = currentPageReference.state.recordId;
            this.invokeGetLoanApi();
        } else if (currentPageReference.attributes?.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
            this.invokeGetLoanApi();
        }
    }

    async invokeGetLoanApi() {
        try {
            console.log('Calling Apex getLoanDetails...');
            this.result = await getLoanDetails({ recordId: this.recordId });
            console.log('Apex result:', this.result);
            this.msgConfig = this.messagesMap[this.result];
            if (this.result == 'Joint_Exposure_Success_Msg') {
                this.updateFlagOnApplication();
            }
            this.showToast(
                this.msgConfig.Message_Type__c,
                 this.msgConfig.Message__c,
                  this.msgConfig.Message_Type__c
            );

            // Delay closing the action screen so toast shows
            setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 500);
            this.isLoading = false;

        } catch (error) {
            this.isLoading = false;
            console.log('Error:', JSON.stringify(error));

            const message =
                error?.body?.output?.errors?.[0]?.message ||
                error?.body?.message ||
                "Unknown error";

            this.showToast('Error', message, 'error');

            // Close screen after error toast
            setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 500);
        }
    }

    updateFlagOnApplication() {
        console.log('Updating isFetchAppDetailExecuted__c...');

        const fields = {
            Id: this.recordId,
            isFetchAppDetailExecuted__c: true
        };

        updateRecord({ fields })
            .then(() => {
                console.log('Update success, preparing toast...');
                this.showToast(
                     this.msgConfig.Message_Type__c,
                     this.msgConfig.Message__c,
                     this.msgConfig.Message_Type__c
                );

                // Delay closing the action screen so toast shows
                setTimeout(() => {
                    this.dispatchEvent(new CloseActionScreenEvent());
                }, 500);
            })
            .catch(error => {
                console.error('Update error:', JSON.stringify(error));
                const message =
                    error?.body?.output?.errors?.[0]?.message ||
                    error?.body?.message ||
                    "Unknown error";

                this.showToast('Error', message, 'error');

                setTimeout(() => {
                    this.dispatchEvent(new CloseActionScreenEvent());
                }, 500);
            });
    }

    async fetchMsgConfigMetadata() {
        getMsgConfigRecord({ source: this.source })
            .then(result => {
                this.messagesMap = result;
                console.log('Messages Map:', JSON.stringify(this.messagesMap));
            })
            .catch(error => {
                console.error('Error fetching message config:', error);
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}