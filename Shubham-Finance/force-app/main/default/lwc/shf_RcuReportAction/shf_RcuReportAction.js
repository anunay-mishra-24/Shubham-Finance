import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import generateRCUReport from '@salesforce/apex/SHF_RcuReportGeneratorService.generateRCUReport';
import getPrimaryApplicant  from '@salesforce/apex/SHF_RcuReportGeneratorService.getPrimaryApplicant';

const FIELDS = [
    'Verification_Activity__c.Verification__r.Type__c', 'Verification_Activity__c.Verification__r.Application__c'
];

export default class SHF_RcuReportAction extends LightningElement {

    @api recordId;
    pdfUrl;
    vfPageName = '';
    applicationId = null;

    // @wire(CurrentPageReference)
    // pageRefHandler(currentPageReference) {
    //     if (!this.recordId && currentPageReference) {
    //         this.recordId =
    //             currentPageReference.state?.recordId ||
    //             currentPageReference.state?.c__recordId;
    //     }
    // }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredVerification({ data, error }) {
        if (data) {
            const verificationType =
                data.fields.Verification__r.value.fields.Type__c.value;
            this.applicationId = data.fields.Verification__r.value.fields.Application__c.value;

            if (verificationType === 'Seller') {
                this.pdfUrl = `/apex/SHF_RCU_Report_PDF?id=${this.recordId}`;
                this.vfPageName = 'SHF_RCU_Report_PDF';
            } else if (verificationType === 'Borrower') {
                this.pdfUrl = `/apex/SHF_Applicant_RCU_Report?id=${this.recordId}`;
                this.vfPageName = 'SHF_Applicant_RCU_Report';
            } else {
                this.pdfUrl = null;
            }
        }
    }

    async handleSend() {

        console.log("Send button clicked---");
        this.isUploading = true;
    
        try {
            const res = await generateRCUReport({ applicationId: this.applicationId, verificationActivityId: this.recordId, vfPageName: this.vfPageName });
            console.log("Response from Apex method---", JSON.stringify(res));
            this.documentId = this.recordId.docId;
            const applicantId = await getPrimaryApplicant({ applicationId: this.applicationId });  
            console.log("Applicant Id---", applicantId);  
            const uploader = this.template.querySelector('c-shf-upload-document');
            uploader.uploadFromParent({
                base64File: res.fileBase64,
                fileName: res.fileName,
                docId: res.docId,
                docCategory: 'Loan Specific Documents',
                parentObjectName: 'Application__c',
                parentRecordId: this.recordId,
                applicantId: applicantId || null
            });
    
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Processing',
                    message: 'Uploading to DMS...',
                    variant: 'success'
                })
            );
    
        } catch (err) {
            console.error('Error:', err);
            this.isUploading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: err.body?.message || err.message,
                    variant: 'error'
                })
            );
        }
    }

    handleClose() {
        if (this.isPhone) {
            this.dispatchEvent(new CustomEvent('close'));
        } else {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
    
    async handleDmsResponse(event) {
        const resp = event.detail;
        console.log('DMS Response:', resp);
        this.isUploading = false;
    
        this.dispatchEvent(
            new ShowToastEvent({
                title: resp.status === 'SUCCESS' ? 'Success' : 'Error',
                message: resp.message || 'RCU Report generated successfully.',
                variant: resp.variant || (resp.status === 'SUCCESS' ? 'success' : 'error'),
            })
        );
        handleClose();

        // if (resp.status === 'SUCCESS') {
        //     try {
        //         // await markLAFGenerated({ applicationId: this.recordId });
        //         this.dispatchEvent(new CloseActionScreenEvent());
        //     } catch(err) {
        //         console.error('Flag update failed:', err.body?.message);
        //     }
        //     finally {
        //         this.dispatchEvent(new CloseActionScreenEvent());
        //     }
        // } else {
        //     console.error('DMS upload failed:', resp.message || 'Unknown error');
        //     this.dispatchEvent(new CloseActionScreenEvent());
        // }
    }
}