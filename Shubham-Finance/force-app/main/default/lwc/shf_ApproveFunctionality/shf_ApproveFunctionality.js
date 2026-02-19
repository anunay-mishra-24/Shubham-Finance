import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord,notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import validateBeforeStageChange from '@salesforce/apex/SHF_ApplicationMoveToNextController.validateBeforeStageChange';
import checkApprovalMatrix from '@salesforce/apex/SHF_Approval_FuctionalityController.checkApprovalMatrix';


const FIELDS = [
    'Application__c.Application_Stage__c',
    'Application__c.Charges_Visible__c',
    'Application__c.OwnerId',
];
export default class Shf_ApproveFunctionality extends LightningElement {
    @api recordId;
    @track errorMessages = [];
    currentStage;
    @track showSpinner = false;
    @track shouldRunValidation = false;
    @track isLoading = false;
    @track showErrorModal = false;
    @track approvalModal = false;
    recomendation;
    currentOwnerId;


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.currentOwnerId = data.fields.OwnerId.value;
            this.currentStage = data.fields.Application_Stage__c.value;
            console.log('this.currentStage ', this.currentStage);

            //  record is loaded → now it's safe to call validation
            if (this.shouldRunValidation) {
                this.checkValidations();
                 this.isLoading  = true;
                this.shouldRunValidation = false; // prevent duplicate calls
            }
        } else if (error) {
            console.error('Error fetching record: ', error);
            this.currentStage = null;
        }
    }

    @wire(CurrentPageReference)
    getAddressId(currentPageReference) {

        // Set recordId
        if (currentPageReference?.state?.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference?.attributes?.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }

        this.actionName = currentPageReference.attributes.apiName.split('.').pop();

        console.log('Clicked Action:', this.actionName);
        console.log('recordId-> ', this.recordId);

        // Tell component to run validation AFTER record loads
        this.shouldRunValidation = true;
    }

    handleChange(event) {
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

        if (!isValid) {
            // If validation fails, stop execution
            this.showToast('Error', 'Please fill all required fields before proceeding.', 'error');
            this.isLoading = false;
            return;
        }
        //  All fields have values going for update
          this.callApprovalMatrix();
    }

    callApprovalMatrix() {
        this.approvalModal = false;
        checkApprovalMatrix({ applicationId: this.recordId, comment: this.recomendation, approver: this.currentOwnerId})
            .then(async result => {
                console.log('Apex Response:', result);
                if (result.startsWith('Success')) {
                    let msg = result.replace("Success:", "").trim();
                     this.showToast('Success', msg, 'success');
                     //logic to update application stage and recordtype
                     this.isLoading = false;
                } else if (result.startsWith('Error')) {
                     let msg = result.replace("Error:", "").trim();
                    this.showToast('Error', msg, 'error');
                }
                this.dispatchEvent(new CloseActionScreenEvent());
                this.isLoading = false;
                notifyRecordUpdateAvailable([{recordId: this.recordId}]);
            })
            .catch(error => {
                this.dispatchEvent(new CloseActionScreenEvent());
                console.error('Apex Error:', error);
                this.showToast('Apex Exception', error.body.message, 'error');
            })

    }
    checkValidations() {
        // Validate first before proceeding
        validateBeforeStageChange({
            applicationId: this.recordId,
            currentStage: this.currentStage,
            buttonLabel: this.actionName
        })
            .then(result => {
                console.log('inside the result');
                if (result) {
                    console.log('result>> ', result);
                    // Error message returned from Apex
                    this.isLoading = false;
                    this.showErrorModal = true;
                    // this.showToast('Error', result, 'error');
                    const cleanMsg = result;
                    this.errorMessages = cleanMsg
                        .split(/[\n;]+/)
                        .map((msg) => msg.trim())
                        .filter((msg) => msg);
                        

                } else {
                    // Validation passed
                    console.log('about to open the modal');
                    this.approvalModal = true;
                     this.isLoading = false;
                  console.log('this.approvalModal ', this.approvalModal);
                }
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Validation failed.', 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeModal() {
        this.approvalModal = false;
        this.showErrorModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}