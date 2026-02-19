import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getMessageFromMetadata from '@salesforce/apex/SHF_CommonUtil.getMessageFromMetadata';
import getSiblingApplicants from '@salesforce/apex/SHF_LoanApplicantHelper.getSiblingApplicants';
import deleteApplicant from '@salesforce/apex/SHF_LoanApplicantHelper.deleteApplicant';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordUi,getRecord,updateRecord } from 'lightning/uiRecordApi';
import LOAN_APPLICANT_ID from '@salesforce/schema/Address__c.Loan_Applicant__c';


export default class Shf_ApplicantDeleteButton extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showModal = false;
    @track siblings = [];
    @track canDelete = false;
    @track message = '';
    currentObjectApiName;
    @api objectApiName; // e.g., 'Account' or 'Contact'
    fieldName1 = 'Name';
    newValue = 'Updated Name';
    isLoading = false;
    applicantRecordId;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (!this.recordId && pageRef && pageRef.state) {
            this.recordId = pageRef.state.recordId || pageRef.state.c__recordId;
            console.log('recorddddd> ', this.recordId);

        }
    }

    //Added by mansur to fetch the object api name
    @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: ['Compact'], modes: ['View'] })
    wiredRecordUi({ data, error }) {
        if (data && this.recordId) {
            const record = data.records[this.recordId];
            this.currentObjectApiName = record.apiName;
            //on the basis of object name run the functionality
            if (this.currentObjectApiName == 'Loan_Applicant__c') {
                this.loadSiblings();
            } else if (this.currentObjectApiName == 'Address__c') {
                this.isLoading = true;
                this.handleProceed();
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        }
        if (error) {
            console.error('Error fetching record:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [LOAN_APPLICANT_ID] })
    recordHandler({ data, error }) {
        if (data) {

        this.applicantRecordId = data.fields.Loan_Applicant__c.value;
        } else if (error) {
            console.error(error);
        }
    }
    // end here

    connectedCallback() {

    }

    // Generic method to fetch message from metadata and set modal message
    setMessageFromMetadata(recordDevName) {
        getMessageFromMetadata({ recordDevName })
            .then(res => {
                this.message = res.Message;
                this.showModal = true;
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }

    // Load sibling applicants and determine modal message
    loadSiblings() {
        if (!this.recordId) return;

        getSiblingApplicants({ loanApplicantId: this.recordId })
            .then(result => {
                this.siblings = result;
                // Count co-applicants (non-primary)
                const coApplicants = this.siblings.filter(app => app.Applicant_Type__c !== 'Primary Applicant' && app.Applicant_Type__c != null);

                if (coApplicants.length <= 1) {
                    this.canDelete = false;
                    this.setMessageFromMetadata('CO_APPLICANT_REQUIRED');
                } else {
                    this.canDelete = true;
                    this.setMessageFromMetadata('DELETE_APPLICANT_CONFIRM');
                }

                this.showModal = true;
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }

    // Close modal (used for both Cancel and OK)
    handleClose() {
    this.showModal = false;
    this.dispatchEvent(new CloseActionScreenEvent());
}

    // Proceed with deletion
    handleProceed() {
       
        if (this.currentObjectApiName == 'Address__c') {
            this.fieldName1 = 'is_Deleted__c';//fields which will update on delete
            this.newValue = 'Inactive';
            this.deleteRecord();
        } else {
            deleteApplicant({ loanApplicantId: this.recordId })
                .then(parentId => {
                    this.showMessageToast('DELETE_APPLICANT_SUCCESS');
                    this.showModal = false;

                    this.dispatchEvent(new CloseActionScreenEvent());

                    const url = `/lightning/r/Application__c/${parentId}/view`;
                    window.open(url, '_self');
                })
                .catch(error => {
                    this.showToast('Error', error.body?.message || error.message, 'error');
                });
        }
    }

    deleteRecord() {
        this.isLoading = false;
        const fields = {};
        fields['Id'] = this.recordId;        // Always include Id
        fields[this.fieldName1] = this.newValue; // dynamic field

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                const objectName = this.currentObjectApiName
                    .replace(/__c$/, '')       // remove trailing __c
                    .replace(/_/g, ' ');       // replace underscores with spaces

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `${objectName} Deleted successfully`,
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
            //redirect to the applicant page
             this.navigateToRecord(this.applicantRecordId, 'Loan_Applicant__c');
      window.setTimeout(() => {
            window.location.reload();
        }, 1000);
    }


    // Fetch message from metadata and show toast
    showMessageToast(recordDevName) {
        getMessageFromMetadata({ recordDevName })
            .then(res => {
                const variant = res.MessageType?.toLowerCase() === 'error' ? 'error' : 'success';
                this.showToast(res.MessageType, res.Message, variant);
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }


    // show toast messages
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
        navigateToRecord(recordId, objectApiName, actionName = 'view') {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName,
                actionName
            }
        });
    }
}