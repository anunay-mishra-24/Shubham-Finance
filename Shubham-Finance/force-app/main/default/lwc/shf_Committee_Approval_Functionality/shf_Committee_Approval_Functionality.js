import { LightningElement, api, wire, track } from 'lwc';
//import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getRecord, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import committeeApprovalCheck from '@salesforce/apex/SHF_CommitteeApprovalController.committeeApprovalCheck';
import updateCommitteeApprovalTask from '@salesforce/apex/SHF_CommitteeApprovalController.updateCommitteeApprovalTask';
import updateApplicationForNegotionTask from '@salesforce/apex/SHF_CommitteeApprovalController.updateApplicationForNegotionTask';
import updateForSpecialConditionApprovalTask from '@salesforce/apex/SHF_CommitteeApprovalController.updateForSpecialConditionApprovalTask';

const FIELDS = [
    'Activity_History__c.Application__c',
    'Activity_History__c.RecordType.Name'
];

export default class Shf_ApproveFunctionality extends LightningElement {
    @api recordId;
    @track isLoading = false;
    actionName;
    recomendation;
    applicationId;
    recordTypeIdName;
    @track approvalModal = false;

    @wire(CurrentPageReference)
    getActHistoryId(currentPageReference) {

        // Set recordId
        if (currentPageReference?.state?.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference?.attributes?.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }
        this.actionName = currentPageReference.attributes.apiName.split('.').pop();
        console.log('Clicked Action:', this.actionName);
        console.log('this.approvalModal-> ', this.approvalModal);
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            console.log('data ', data);
            this.applicationId = data.fields.Application__c.value;
            this.recordTypeIdName = data.fields.RecordType.displayValue;
            console.log(' this.recordTypeId ', this.recordTypeIdName);
            if (this.recordTypeIdName != 'Activity History for Special Condition') {
                 this.approvalModal = true; // open comment modal for other approval taks
            } else {
                this.isLoading = true;
                 this.dispatchEvent(new CloseActionScreenEvent());
                this.callUpdateForSpecialConditionApprovalTask(); // for Special condition approval task 
            }
        } else if (error) {
            console.log('error>>> ', error);
        }
    }

    handleChange(event) {
        console.log('event>> ', event);
        const fieldName = event.target.name;
        const fieldValue = event.detail.value;
        if (fieldName === 'Comment') {
            this.recomendation = fieldValue;
        }
    }

    handleSubmit() {
        this.isLoading = true;
        // Query all input elements inside this template
        const allInputs = this.template.querySelectorAll(
            'lightning-combobox, lightning-textarea, lightning-input'
        );
        let isValid = true;

        allInputs.forEach(input => {
            // Check each field validity
            if (!input.checkValidity()) {
                input.reportValidity(); // shows red message
                isValid = false;
            }
        });
        console.log('isValid> ', isValid);
        if (!isValid) {
            // If validation fails, stop execution
            this.showToast('Error', 'Please fill all required fields before proceeding.', 'error');
            this.isLoading = false;
            return;
        }
        this.approvalModal = false;
        if (this.recordTypeIdName == 'Activity History for Negotiation') {
            this.callUpdateApplicationForNegotionTask(); // for negotiation task 
            // }else if(this.recordTypeIdName == 'Activity History for Special Condition'){
            //          this.callUpdateForSpecialConditionApprovalTask(); // for Special condition approval task 
        } else {
            this.callCommitteeApproval(); //for committee approval
        }
    }
    callCommitteeApproval() {
        console.log('inside callCommitteeApproval> ');
        updateCommitteeApprovalTask({ action: this.actionName, actHistoryId: this.recordId, comment: this.recomendation })
            .then(result => {
                console.log('call callCommitteeApprovalTask ', result);
                if (result.startsWith('Success')) {
                    //call task approval grid 
                    this.callCommitteeApprovalTask();
                    this.closeModal();//Gaurav Kumar
                }
            }).catch(error => {
                this.isLoading = false;
                console.log('error in committe approval');
                this.showToast('error in committe approval ', error.body.message, 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
    }

    callCommitteeApprovalTask() {
        committeeApprovalCheck({ applicationId: this.applicationId, recordId: this.recordId })
            .then(async result => {
                console.log('inside cooooooo');
                if (result == 'Success') {
                    this.isLoading = false; //Gaurav Kumar
                    this.showToast('Success ', 'Task updated successfully.', 'success');
                    this.isLoading = false;
                    notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                    // setTimeout(() => {
                    //     window.location.reload();
                    // }, 500);
                }
            }).catch(error => {
                this.isLoading = false; //Gaurav Kumar
                this.dispatchEvent(new CloseActionScreenEvent());
                console.log('error in committeeApprovalCheck', error);
            })
        this.dispatchEvent(new CloseActionScreenEvent());

    }
    callUpdateApplicationForNegotionTask() {
        updateApplicationForNegotionTask({ action: this.actionName, actHistoryId: this.recordId, comment: this.recomendation, applicationId: this.applicationId })
            .then(async result => {
                if (result.startsWith('Success')) {
                    this.showToast('Success ', 'Task updated successfully.', 'success');
                    this.closeModal();//Gaurav Kumar
                    notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                }
            }).catch(error => {
                this.isLoading = false;
                console.log('error in committe approval');
                this.showToast('error in Negotiation approval ', error.body.message, 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
    }

    callUpdateForSpecialConditionApprovalTask() {
        updateForSpecialConditionApprovalTask({ actHistoryId: this.recordId})
            .then(async result => {
                 this.isLoading = false;
                console.log('result11 > ', result);
                if (result.startsWith('Success')) {
                    this.showToast('Success ', 'Task updated successfully.', 'success');
                    this.closeModal();//Gaurav Kumar
                    notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                } else if (result.startsWith('Pending')) {
                    this.showToast('Success ', 'Kindly provide a decision on all the conditions.', 'error');
                    this.closeModal();//Gaurav Kumar
                }
            }).catch(error => {
                this.isLoading = false;
                console.log('error in committe approval');
                this.showToast('error in Negotiation approval ', error.body.message, 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}