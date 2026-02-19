import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';

import validateLMSData from '@salesforce/apex/SHF_GenerateDocumentController.validateLMSData';
import generatePDF from '@salesforce/apex/SHF_GenerateDocumentController.generatePDF';
import getPrimaryApplicant from '@salesforce/apex/SHF_GenerateDocumentController.getPrimaryApplicant';

export default class ShfGenerateTentativeRepaymentSchedule extends LightningElement {

    @api recordId;

    @track repaymentVFUrl;
    @track isUploading = false;
    @track isRepaymentSent = false;
    @track showErrorScreen = false;
    @track errorMessage = '';

    @wire(CurrentPageReference)
    getStateParams(ref) {
        if (ref && !this.recordId) {
            this.recordId =
                ref.state?.recordId || ref.state?.c__recordId;
        }
    }

    async connectedCallback() {
        try {
            const isValid = await validateLMSData({
                applicationId: this.recordId
            });

            if (!isValid) {
                this.showErrorScreen = true;
                this.errorMessage =
                    'Kindly sync the details with LMS before generating the document';
                return;
            }

            this.repaymentVFUrl =
                `/apex/SHF_Tentative_Repayment_Schedule?id=${this.recordId}`;

        } catch (e) {
            this.showToast('Error', 'Something went wrong', 'error');
        }
    }

    async handleSendRepayment() {
        try {
            this.isUploading = true;

            const res = await generatePDF({
                applicationId: this.recordId,
                language: 'English',
                docType: 'TENTATIVE'
            });

            const applicantId = await getPrimaryApplicant({
                applicationId: this.recordId
            });

            this.template
                .querySelector('c-shf-upload-document')
                .uploadFromParent({
                    base64File: res.fileBase64,
                    fileName: res.fileName,
                    docId: res.docId,
                    docCategory: 'Others',
                    docName: res.fileName,
                    parentObjectName: 'Application__c',
                    parentRecordId: this.recordId,
                    applicantId: applicantId || null
                });

            this.showToast(
                'Processing',
                `${res.fileName} uploading to DMS...`,
                'success'
            );

        } catch (e) {
            this.isUploading = false;
            this.showToast('Error', e.message, 'error');
        }
    }

    handleDmsResponse(event) {
        this.isUploading = false;

        const resp = event.detail;
        this.showToast(
            resp.status === 'SUCCESS' ? 'Success' : 'Error',
            resp.message,
            resp.status === 'SUCCESS' ? 'success' : 'error'
        );

        if (resp.status === 'SUCCESS') {
            this.isRepaymentSent = true;
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}