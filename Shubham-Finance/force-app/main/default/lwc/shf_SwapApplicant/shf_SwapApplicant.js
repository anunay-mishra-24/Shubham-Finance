3/**
 * @File Name          : shf_SwapApplicant.js
 * @Description        : LWC for Swap Applicant Quick Action
 * @Author             : Preeti
 * @Last Modified By   : Preeti
 * @Last Modified On   : October 27, 2025
 * @Modification Log   :
 * Ver | Date | Author | Modification
 * 1.0 | Oct 27 2025 | Preeti  | Initial Version
 **/


import { LightningElement, api, track, wire } from 'lwc';
import getApplicants from '@salesforce/apex/SHF_SwapApplicantController.getApplicants';
import performSwap from '@salesforce/apex/SHF_SwapApplicantController.performSwap';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import LOAN_APPLICANT_OBJECT from '@salesforce/schema/Loan_Applicant__c';
import SWAP_REASON_FIELD from '@salesforce/schema/Loan_Applicant__c.Swap_Reason__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SwapApplicant extends LightningElement {

    @api recordId; // Application Id

    isLoading = false;
    @track isModalOpen = false;
    @track applicants = [];
    @track applicantOptions = [];
    @track swapWithOptions = [];
    @track typeSameError = false;


    selectedA;
    selectedB;
    applicantAType;
    applicantBType;
    isDisable;

    // Screens
    swapScreen = true;
    swapCommentScreen = false;

    // Swap Reason picklist
    swapReasonOptions = [];
    swapReason;
    swapComments;

    //  Load object info
    @wire(getObjectInfo, { objectApiName: LOAN_APPLICANT_OBJECT })
    objectInfo;

    // Load swap reason picklist
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: SWAP_REASON_FIELD
    })
    pickVals({ data }) {
        if (data) {
            this.swapReasonOptions = data.values;
        }
    }

    connectedCallback() {
        this.isLoading = true;

        getApplicants({ applicationId: this.recordId })
            .then(res => {
                this.applicants = res || [];

                this.applicantOptions = this.applicants.map(a => ({
                    label: a.Account_Name__c ? a.Account_Name__c : 'Unknown',
                    value: a.Id
                }));


                // Disable button if NO applicants
                this.isDisable = this.applicants.length === 0;
                console.log('applicants.length : ',this.applicants[0]);
                console.log('isDisable : ',this.isDisable);
            })
            .catch(error => {
                console.error(error);
                this.isDisable = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Open Modal
    openModal() {
        this.isModalOpen = true;   
    }

    closeModal() {
        this.isModalOpen = false;

        // Reset selections
        this.selectedA = null;
        this.selectedB = null;
        this.applicantAType = null;
        this.applicantBType = null;
        this.swapWithOptions = [];

        // Reset screens
        this.swapScreen = true;
        this.swapCommentScreen = false;

        // Reset swap reason and comments
        this.swapReason = null;
        this.swapComments = null;

        // Reset error
        this.typeSameError = false;
    }


    handleSelectA(event) {
        this.selectedA = event.detail.value;

        // Set A type
        let rec = this.applicants.find(x => x.Id === this.selectedA);
        this.applicantAType = rec.Applicant_Type__c;

        // RESET Swap With (B)
        this.selectedB = null;
        this.applicantBType = null;
        this.typeSameError = false;

        // Rebuild Swap With options
        this.swapWithOptions = this.applicants
            .filter(a => a.Id !== this.selectedA)
            .map(a => ({
                label: (a.Account_Name__c ? a.Account_Name__c : 'Unknown'),
                value: a.Id
            }));
    }

    handleSelectB(event) {
        this.selectedB = event.detail.value;
        let rec = this.applicants.find(x => x.Id === this.selectedB);
        this.applicantBType = rec.Applicant_Type__c;
        this.typeSameError = (this.applicantAType === this.applicantBType);
    }

    get disableNext() {
        return !(this.selectedA && this.selectedB && this.applicantAType !== this.applicantBType);
    }

    goToStep2() {
        this.swapScreen = false;
        this.swapCommentScreen = true;
    }

    goToStep1() {
        this.swapScreen = true;
        this.swapCommentScreen = false;
    }

    handleReasonChange(event) {
        this.swapReason = event.detail.value;
    }

    handleCommentsChange(event) {
        this.swapComments = event.target.value;
    }

    saveSwap() {

        const inputFields = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea'
        );

        let allValid = true;

        // report validity
        inputFields.forEach(field => {
            allValid = field.reportValidity() && allValid;
        });

        if (!allValid) {
            // return if any field is invalid
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill all required fields before confirming swap.',
                    variant: 'error'
                })
            );
            return;
        }
        this.isLoading = true;

        performSwap({
            applicantAId: this.selectedA,
            applicantBId: this.selectedB,
            reason: this.swapReason || null,
            comments: this.swapComments || null
        })
            .then(() => {

                this.showToast(
                    "Success",
                    "Applicant swap completed successfully!",
                    "success"
                );

                this.isLoading = false;
                this.closeModal();

                setTimeout(() => {
                    location.reload();
                }, 500);

            })
            .catch(error => {
                this.isLoading = false;

                let message = 'Swap action failed.';

                if (error && error.body && error.body.message) {
                    // Try to extract text after 'FIELD_CUSTOM_VALIDATION_EXCEPTION, '
                    let match = error.body.message.match(/FIELD_CUSTOM_VALIDATION_EXCEPTION,\s*(.+?):\s*\[.+\]/);
                    if (match && match[1]) {
                        message = match[1]; // The user-friendly validation text
                    } else {
                        message = error.body.message;
                    }
                }

                this.showToast('Error', message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            })
        );
    }

}