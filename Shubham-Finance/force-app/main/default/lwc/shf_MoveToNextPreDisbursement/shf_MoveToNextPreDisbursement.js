import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import ERROR from '@salesforce/label/c.Negotiation_Approval_Pending_Error';
import QDEOwnerLabel from '@salesforce/label/c.QDE_Last_Owner_Error';
import ConfirmationLabel from '@salesforce/label/c.Negotiation_Final_Details_Confirmation';
import PendingLabel from '@salesforce/label/c.Negotiation_Submission_Pending';
import getFieldData from '@salesforce/apex/SHF_ApplicationMoveToNextController.getFieldData';
import moveToNextStage from '@salesforce/apex/SHF_ApplicationMoveToNextController.moveToNextStage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CBO_STATUS_FIELD from '@salesforce/schema/Application__c.CBO_Approval_Status__c';
import qde_STATUS_FIELD from '@salesforce/schema/Application__c.QDE_Last_Owner__c';
import RESANCTION_STATUS_FIELD from '@salesforce/schema/Application__c.Re_Sanction_Status__c';
import RECORDTYPE_FIELD from '@salesforce/schema/Application__c.RecordTypeId';

export default class Shf_MoveToNextPreDisbursement extends LightningElement {
    @api recordId;
    @track showErrorModal = false;
    @track showConfirmModal = false;
    ifNegotiationApprovalPending = false;
    @track qdeOwner;
    hasValidated = false;
    @track errorMessages = [];
    @track feeList = [];
    recordTypeId;
    cboValue;
    reSanctionValue;
    label = {
        errorLabel: ERROR,
        pendingLabel: PendingLabel,
        confirmationLabel: ConfirmationLabel,
        ownerError: QDEOwnerLabel
    };
    @wire(CurrentPageReference)
    captureRecordId(currentPageReference) {
        if (currentPageReference?.state?.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference?.attributes?.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }
        console.log('Current Record Id #####', this.recordId);
    }
    // @wire(getRelatedListRecords, {
    //     parentRecordId: '$recordId',
    //     relatedListId: 'Fees__r', // Child relationship name
    //     fields: [
    //         'Fees__c.Id',
    //         'Fees__c.Application__c',
    //         'Fees__c.Status__c'
    //     ],
    //     where: "{ Status__c: { eq: 'Collected' } }"
    // })
    // wiredFees({ data, error }) {
    //     if (data) {
    //         this.feeList = data.records;
    //         console.log('Collected Fees:', this.feeList.length);
    //         this.error = undefined;
    //     } else if (error) {
    //         this.error = error;
    //         this.feeList = [];
    //     }
    // }
    @wire(getFieldData, { recordId: '$recordId' })
    wireBranchCode({ data, error }) {
        if (data) {
            this.ifNegotiationApprovalPending = data;
            console.log('Loan Application Data:', data);
            alert('Loan Application Data: ' + JSON.stringify(data));
        } else if (error) {
            console.error('Error fetching loan Application:', error);
        }
    }
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CBO_STATUS_FIELD, RESANCTION_STATUS_FIELD, RECORDTYPE_FIELD, qde_STATUS_FIELD]
    })
    recordHandler({ data, error }) {
        if (data && !this.hasValidated) {
            this.hasValidated = true;
            this.recordTypeId = data.fields.RecordTypeId.value;
            this.cboValue = data.fields.CBO_Approval_Status__c.value;
            this.reSanctionValue = data.fields.Re_Sanction_Status__c.value;
            this.qdeOwner = data.fields.QDE_Last_Owner__c.value;
            if (this.qdeOwner) {
                this.validateOnLoad();
            }
            else {
                this.errorMessages = [this.label.ownerError];
                this.showErrorModal = true;
            }
        }
    }

    validateOnLoad() {
        if (!this.cboValue && !this.reSanctionValue) {
            if (this.ifNegotiationApprovalPending) {
                console.log('Both CBO and Re-Sanction are empty and Negotiation Approval is pending.');
                this.errorMessages = [this.label.errorLabel];
                this.showErrorModal = true;
                // this.showConfirmModal = true;
            }
            // else if(!this.feeList || this.feeList.length === 0){
            //     console.log('Both CBO and Re-Sanction are empty and No Fees Collected.');
            //     this.errorMessages = ['Login fee collection is mandatory before proceeding.Please complete the fee collection under the Fees and Charges tab to continue.'];
            //     this.showErrorModal = true;
            // }
            else {
                console.log('Both CBO and Re-Sanction are empty but Negotiation Approval is not pending.');
                this.showConfirmModal = true;
            }
        } else if (this.cboValue === 'Pending' || this.reSanctionValue === 'Pending') {
            console.log('Either CBO or Re-Sanction is Pending.');
            this.handleMoveToNextStage();
        }
        // else if(!this.feeList || this.feeList.length === 0){
        //         console.log('Both CBO and Re-Sanction are empty and No Fees Collected.');
        //         this.errorMessages = ['Login fee collection is mandatory before proceeding.Please complete the fee collection under the Fees and Charges tab to continue.'];
        //         this.showErrorModal = true;
        //     }
        else {
            console.log('Either CBO or Re-Sanction has a value other than Pending.');
            this.showConfirmModal = true;
        }
    }
    connectedCallback() {
        console.log('Record Id:Record Id: ' + this.recordId);

        //this.handleMoveToNextStage();
    }
    handleMoveToNextStage() {
        moveToNextStage({ recordId: this.recordId })
            .then(result => {
                console.log('moveToNextStage :', result);
                if (result.startsWith('SUCCESS')) {
                    this.showToast('Success', result.replace('SUCCESS: ', ''), 'success');
                    getRecordNotifyChange([{ recordId: this.recordId }]);

                    setTimeout(() => {
                        window.location.reload();
                    }, 500);
                    this.dispatchEvent(new CloseActionScreenEvent());
                } else if (result.startsWith('ERROR')) {
                    // Split multiple error lines if any (using semicolon or newline)
                    const cleanMsg = result.replace('ERROR: ', '');
                    console.log('moveToNextStage cleanMsg:', cleanMsg);
                    this.errorMessages = cleanMsg.split(/[\n;]+/).map(msg => msg.trim()).filter(msg => msg);
                    this.showErrorModal = true;
                    //this.dispatchEvent(new CloseActionScreenEvent());
                } else {
                    this.showToast('Info', result, 'info');
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            })
            .catch(error => {
                const errMsg = error.body?.message || error.message;
                this.errorMessages = errMsg.split(/[\n;]+/).map(msg => msg.trim()).filter(msg => msg);
                this.showErrorModal = true;
            })
        // .finally(() => {
        //     this.dispatchEvent(new CloseActionScreenEvent());
        // });
    }
    handleConfirmYes() {
        this.showConfirmModal = false;
        this.handleMoveToNextStage();
    }
    handleCancelConfirm() {
        this.showConfirmModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    handleCloseModal() {
        this.showErrorModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}