import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import getVFPageName from '@salesforce/apex/SHF_GenerateDocumentController.getVFPageName';
import generatePDF from '@salesforce/apex/SHF_GenerateDocumentController.generatePDF';
import getPrimaryApplicant from '@salesforce/apex/SHF_GenerateDocumentController.getPrimaryApplicant';
import getPrimaryApplicantLanguage from '@salesforce/apex/SHF_GenerateDocumentController.getPrimaryApplicantLanguage';
import validateLMSData from '@salesforce/apex/SHF_GenerateDocumentController.validateLMSData';
import markDocumentUploaded from '@salesforce/apex/SHF_GenerateDocumentController.markDocumentUploaded';
import CONDITION_SANCTION from '@salesforce/label/c.Special_Tab_Sanction_Sync';
import CONDITION_REPAYMENT from '@salesforce/label/c.Sanction_Letter_File_Name';



export default class Shf_GenerateDocument extends LightningElement {

    @api recordId;

    @track isUploading = false;
    @track sanctionVFUrl;
    @track repaymentVFUrl;
    @track isSanctionSent = false;
    @track isRepaymentSent = false;
    @track showErrorScreen = false;
    @track errorMessage = '';


    @track activeTab = 'sanction';


    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && !this.recordId) {
            this.recordId = currentPageReference.state?.recordId
                || currentPageReference.state?.c__recordId;
            console.log('Record Id from URL ==> ', this.recordId);
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
                    'Kindly sync the details with LMS before generating the documents';
                return;
            }

            const language = await getPrimaryApplicantLanguage({
                applicationId: this.recordId
            });

            const vfPage = await getVFPageName({
                applicationId: this.recordId,
                language: language
            });

            this.sanctionVFUrl = `/apex/${vfPage}?id=${this.recordId}`;
            this.repaymentVFUrl =
                `/apex/SHF_Tentative_Repayment_Schedule?id=${this.recordId}`;

        } catch (e) {
            this.showToast('Error', 'Something went wrong', 'error');
        }
    }


    async handleSendSanction() {
        try {
            this.isUploading = true;
            const language = await getPrimaryApplicantLanguage({
                applicationId: this.recordId
            });

            this.sendToDMS(language, 'SANCTION');
        } catch (e) {
            this.showToast('Error', 'Unable to fetch applicant language', 'error');
        }
    }

    handleSendRepayment() {
        this.isUploading = true;
        this.sendToDMS('English', 'TENTATIVE');
    }

    async sendToDMS(language, docType) {
        this.isUploading = true;

        try {
            const res = await generatePDF({
                applicationId: this.recordId,
                language: language,
                docType: docType
            });

            const applicantId = await getPrimaryApplicant({
                applicationId: this.recordId
            });

            const uploader = this.template.querySelector('c-shf-upload-document');

            uploader.uploadFromParent({
                base64File: res.fileBase64,
                fileName: res.fileName,
                docId: res.docId,
                docCategory: 'Others',
                docName: res.fileName,
                parentObjectName: 'Application__c',
                parentRecordId: this.recordId,
                applicantId: applicantId || null
            });

            this.showToast('Processing', `${res.fileName} uploading to DMS...`, 'success');

        } catch (e) {
            this.showToast('Error', e.message, 'error');
        }
    }
    get isRepaymentDisabled() {
        return this.isRepaymentSent || !this.isSanctionSent;
    }



    // DMS CALLBACK

    // handleDmsResponse(event) {
    //     const resp = event.detail;
    //     this.isUploading = false;

    //     this.showToast(
    //         resp.status === 'SUCCESS' ? 'Success' : 'Error',
    //         resp.message,
    //         resp.status === 'SUCCESS' ? 'success' : 'error'
    //     );


    //     if (resp.status === 'SUCCESS' && !this.isSanctionSent) {
    //         this.isSanctionSent = true;   
    //         this.activeTab = 'repayment';
    //         return;
    //     }

    //     if (this.isSanctionSent && !this.isRepaymentSent) {
    //         this.isRepaymentSent = true;
    //         this.dispatchEvent(new CloseActionScreenEvent());
    //     }

    //     //this.dispatchEvent(new CloseActionScreenEvent());
    // }

    async handleDmsResponse(event) {
        const resp = event.detail;
        this.isUploading = false;

        this.showToast(
            resp.status === 'SUCCESS' ? 'Success' : 'Error',
            resp.message,
            resp.status === 'SUCCESS' ? 'success' : 'error'
        );

        if (resp.status !== 'SUCCESS') {
            return;
        }

        try {

            if (!this.isSanctionSent) {

                await markDocumentUploaded({
                    applicationId: this.recordId,
                    conditionLabel: CONDITION_SANCTION
                });

                this.isSanctionSent = true;
                this.activeTab = 'repayment';
                return;
            }

            if (this.isSanctionSent && !this.isRepaymentSent) {

                await markDocumentUploaded({
                    applicationId: this.recordId,
                    conditionLabel: CONDITION_REPAYMENT
                });

                this.isRepaymentSent = true;
                this.dispatchEvent(new CloseActionScreenEvent());
            }

        } catch (e) {
            this.showToast('Error', 'Document status update failed', 'error');
        }
    }


    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Show TOAST 
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }
}