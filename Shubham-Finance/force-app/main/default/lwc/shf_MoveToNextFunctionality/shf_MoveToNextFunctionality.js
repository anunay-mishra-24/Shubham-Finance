import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import ERROR from '@salesforce/label/c.Negotiation_Approval_Pending_Error';
import QDEOwnerLabel from '@salesforce/label/c.QDE_Last_Owner_Error';
import ConfirmationLabel from '@salesforce/label/c.Negotiation_Final_Details_Confirmation';
import PendingLabel from '@salesforce/label/c.Negotiation_Submission_Pending';
import getFieldData from '@salesforce/apex/SHF_ApplicationMoveToNextController.getFieldData';
import validateCreditPDReInitiation from '@salesforce/apex/SHF_ApplicationMoveToNextController.validateCreditPDReInitiation';
import moveToNextStage from '@salesforce/apex/SHF_ApplicationMoveToNextController.moveToNextStage';
import getReciptIds from '@salesforce/apex/SHF_GetReciptStatus_Service.getReciptIds';
import getReciptStatus from '@salesforce/apex/SHF_GetReciptStatus_Service.getReciptStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CBO_STATUS_FIELD from '@salesforce/schema/Application__c.CBO_Approval_Status__c';
import applicationStage_FIELD from '@salesforce/schema/Application__c.Application_Stage__c';
import qde_Owner_FIELD from '@salesforce/schema/Application__c.QDE_Last_Owner__c';
import RESANCTION_STATUS_FIELD from '@salesforce/schema/Application__c.Re_Sanction_Status__c';
import getAllapplicants from '@salesforce/apex/SHF_AML_Service.getAllapplicants';
import buildAMLRequestHash from '@salesforce/apex/SHF_AML_Service.buildAMLRequestHash';
import RECORDTYPE_FIELD from '@salesforce/schema/Application__c.RecordTypeId';
import E_SIGN_EXECUTED_FIELD from '@salesforce/schema/Application__c.E_Sign_Executed__c';
import E_SIGN_SUCCESS_FIELD from '@salesforce/schema/Application__c.E_Sign_Success__c';

export default class Shf_MoveToNextFunctionality extends LightningElement {
    @api recordId;
    @track showErrorModal = false;
    @track errorMessages = [];
    @track isLoading = false;
    @track showConfirmModal = false;
    ifNegotiationApprovalPending = false;
    @track applicationStage;
    @track qdeOwner;
    hasValidated = false;
    @track feeList = [];
    @track applicantList = [];
    recordTypeId;
    cboValue;
    eSignExecuted = false;
    eSignSuccess = false;
    reSanctionValue;
    label = {
        errorLabel: ERROR,
        pendingLabel: PendingLabel,
        confirmationLabel: ConfirmationLabel,
        ownerError: QDEOwnerLabel
    };

    applicationGetReciptStages = new Set([
        'Collateral Details',
        'Document Checklist',
        'Negotiation',
        'Pre-Disbursement Document Collection',
        'Cheque Printing',
        'Disbursement Maker'
    ]);

    @wire(CurrentPageReference)
    captureRecordId(currentPageReference) {
        if (currentPageReference?.state?.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference?.attributes?.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }
        console.log('Current Record Id #####', this.recordId);
    }
    @wire(getFieldData, { recordId: '$recordId' })
    wiredNegotiationStatus({ data, error }) {
        if (data !== undefined) {
            console.log('Invoke data #####', data);
            this.ifNegotiationApprovalPending = data;
        }
    }
    @wire(validateCreditPDReInitiation, { recordId: '$recordId' })
    wiredNegotiationStatus({ data, error }) {
        if (data !== undefined) {
            console.log('Invoke data applicantList#####', data);
            this.applicantList = data;

        }
    }
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CBO_STATUS_FIELD, RESANCTION_STATUS_FIELD, qde_Owner_FIELD, applicationStage_FIELD, E_SIGN_EXECUTED_FIELD, E_SIGN_SUCCESS_FIELD]
    })
    recordHandler({ data }) {
        if (data && !this.hasValidated) {
            console.log('Invoke data recordHandler #####', data);
            this.hasValidated = true;

            this.cboValue = data.fields.CBO_Approval_Status__c.value;
            this.reSanctionValue = data.fields.Re_Sanction_Status__c.value;
            this.qdeOwner = data.fields.QDE_Last_Owner__c.value;
            this.applicationStage = data.fields.Application_Stage__c.value;
            this.eSignExecuted = data.fields.E_Sign_Executed__c.value;
            this.eSignSuccess = data.fields.E_Sign_Success__c.value;
            console.log('this.cboValue #####', this.cboValue);
            console.log('this.reSanctionValue #####', this.reSanctionValue);
            console.log('this.qdeOwner #####', this.qdeOwner);
            console.log('this.applicationStage #####', this.applicationStage);
            console.log('this.eSignExecuted #####', this.eSignExecuted);
            console.log('this.eSignSuccess #####', this.eSignSuccess);
            // if (!this.eSignExecuted) {
            //     this.errorMessages = ['E-Sign must be initiated before creating a manual signed document or progressing to the next stage'];
            //     this.showErrorModal = true;
            //     return;
            // }
        }
        this.validateAndProceed();
    }

    @api invoke() {
        console.log('Invoke Id #####', this.recordId);
        console.log('this.cboValue #####', this.cboValue);
        console.log('this.reSanctionValue #####', this.reSanctionValue);
        console.log('this.qdeOwner #####', this.qdeOwner);
        console.log('this.applicationStage #####', this.applicationStage);
        console.log('this.eSignExecuted #####', this.eSignExecuted);
        console.log('this.eSignSuccess #####', this.eSignSuccess);
        // if (!this.eSignExecuted) {
        //     this.errorMessages = ['E-Sign must be initiated before creating a manual signed document or progressing to the next stage'];
        //     this.showErrorModal = true;
        //     return;
        // }
    }
    connectedCallback() {
        console.log('Invoke Id1234 #####', this.recordId);
        this.isLoading = true;
        console.log('this.isLoading #####', this.isLoading);
        // this.validateAndProceed();
    }
    handleConfirmYes() {
        this.showConfirmModal = false;
        this.handleMoveToNextStage();
    }

    handleCancelConfirm() {
        this.showErrorModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    async checkFeeCollectionStatus() {
        await getReciptIds({ applicationId: this.recordId })
            .then(result => {
                console.log('moveToNextStage recipt id', result);
                if (result != null) {
                    result.forEach(element => {

                        getReciptStatus({ feeId: element })
                            .then(res => {
                                console.log('res -- ', res);
                                console.log('res check -- ', (res == 'Cancelled'));
                                if (res == 'Cancelled') {
                                    this.errorMessages = ['Fee collection is marked as Cancelled in LMS. Please re-initiate the payment and complete fee collection before moving to the next stage'];
                                }
                                // else if(res == 'Pending'){

                                // }
                            })
                            .catch(err => {
                                console.log('first catch');
                                const errMsg = err.body?.message || err.message;
                                this.errorMessages = errMsg;
                            })
                    });
                }

            })
            .catch(error => {
                console.log('first catch');

                const errMsg = error.body?.message || error.message;
                this.errorMessages = errMsg;
                // .split(/[\n;]+/)
                // .map(msg => msg.trim())
                // .filter(msg => msg);
                // this.showErrorModal = true;
            })
    }
    async handleMoveToNextStage() {
        if (this.applicationStage === 'Application Form Generation') {

            await getAllapplicants({ applicationId: this.recordId })
                .then(result => {
                    console.log('moveToNextStage recipt id', result);
                    if (result != null) {
                        result.forEach(element => {
                            buildAMLRequestHash({ applicantId: element })
                                .then(res => {
                                    console.log('buildAMLRequestHash res', res);
                                })
                                .catch(err => {
                                    const errMsg = err.body?.message || err.message;
                                    this.errorMessages = errMsg;
                                    console.error('AML Error:', errMsg);
                                })

                        })
                    }
                })
                .catch(error => {
                    const errMsg = error.body?.message || error.message;
                    this.errorMessages = errMsg;
                    console.error('AML Error:', errMsg);
                })

        }
        // working aml
        await moveToNextStage({ recordId: this.recordId })
            .then(result => {
                console.log('moveToNextStage', result);
                if (result.startsWith('SUCCESS')) {
                    console.log('moveToNextStage', result);
                    this.showToast('Success', result.replace('SUCCESS: ', ''), 'success');
                    getRecordNotifyChange([{ recordId: this.recordId }]);

                    setTimeout(() => {
                        window.location.reload();
                    }, 500);
                }
                else if (result.startsWith('ERROR')) {
                    const cleanMsg = result.replace('ERROR: ', '');
                    // console.log('cleanMsg :: ',cleanMsg);
                    this.errorMessages = cleanMsg
                        .split(/[\n;]+/)
                        .map(msg => msg.trim())
                        .filter(msg => msg);
                    if (this.errorMessages[0] != 'List has no rows for assignment to SObject') {
                        this.showErrorModal = true;
                    }

                    console.log('this.showErrorModal', this.showErrorModal);
                    console.log('this.errorMessages', this.errorMessages);
                }
                else {
                    this.showToast('Info', result, 'info');
                }
            })
            .catch(error => {
                const errMsg = error.body?.message || error.message;
                this.errorMessages = errMsg
                    .split(/[\n;]+/)
                    .map(msg => msg.trim())
                    .filter(msg => msg);
                this.showErrorModal = true;
            })
        if (this.applicantList && this.applicantList.length > 0) {
            console.log('applicantList3333444444 :');
            const applicants = JSON.parse(JSON.stringify(this.applicantList));

            const applicantNames = applicants
                .map(app => app.Name)
                .filter(name => name) // extra safety
                .join(', ');

            this.errorMessages.push(
                'Credit PD must be re-initiated as Credit PD–related parameters were modified after sendback for Applicant(s): '
                + applicantNames
            );
        }
        // .finally(() => {
        //     this.isLoading = false;
        //     this.dispatchEvent(new CloseActionScreenEvent());
        // });
    }
    validateAndProceed() {
        console.log('validateAndProceed #####');
        // if (!this.qdeOwner) {
        //     console.log('validateAndProceed his.qdeOwner #####', this.qdeOwner);
        //     this.isLoading = false;
        //     this.errorMessages = [this.label.ownerError];
        //     this.showErrorModal = true;
        // }
        console.log('validateAndProceed33333 #####', this.qdeOwner);

        console.log('applicationStage #####', this.applicationStage);
        console.log('this.checking #####', this.applicationGetReciptStages.has(this.applicationStage));
        if (this.applicationGetReciptStages.has(this.applicationStage)) {
            this.checkFeeCollectionStatus();
        }
        if (!this.cboValue && !this.reSanctionValue) {
            if (this.ifNegotiationApprovalPending) {
                this.errorMessages = [this.label.errorLabel];
                this.showErrorModal = true;
                this.isLoading = false;
            } else if (this.applicationStage === 'Negotiation') {
                this.showConfirmModal = true;
                this.isLoading = false;
            } else {
                console.log('this.applicationStage else #####', this.applicationStage);
                this.handleMoveToNextStage();
            }
        }
        else if (this.cboValue === 'Pending' || this.reSanctionValue === 'Pending') {
            console.log('this.cboValue #####', this.cboValue);
            console.log('this.reSanctionValue #####', this.reSanctionValue);
            console.log('this.qdeOwner #####', this.qdeOwner);
            this.handleMoveToNextStage();
        }
        else {
            if (this.applicationStage === 'Negotiation') {
                this.showConfirmModal = true;
            } else {
                console.log('this.applicationStage else #####', this.applicationStage);
                this.handleMoveToNextStage();
            }
            this.isLoading = false;
        }
        this.isLoading = false;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    // handleCloseModal() {
    //     this.showErrorModal = false;
    // }
}