import { LightningElement, api, wire,track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import validateOnly from '@salesforce/apex/SHF_CAM_GeneratorService.validateOnly';
import generatePdf from '@salesforce/apex/SHF_CAM_GeneratorService.generatePDF';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import markCAMGenerated from '@salesforce/apex/SHF_CAM_GeneratorService.markCAMGenerated';
import getPrimaryApplicant from '@salesforce/apex/SHF_CAM_GeneratorService.getPrimaryApplicant';

export default class Shf_CAMGenerationAction extends LightningElement {
    @api recordId;
    pdfUrl;
    @track isUploading = false;
    showPdfScreen = false;
    showMissingScreen = false;
    missingFields = [];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && !this.recordId) {
            this.recordId = currentPageReference.state?.recordId 
                         || currentPageReference.state?.c__recordId;
            console.log('Record Id from URL ==> ', this.recordId);
        }
    }

    connectedCallback() {
        console.log('Record Id in connectedCallback ===> ', this.recordId);

        if (!this.recordId) {
            setTimeout(() => this.init(), 200);
        } else {
            this.init();
        }
    }

    init() {
        debugger;
        console.log('Init method entered -->');
        validateOnly({ applicationId: this.recordId })
        .then(res => {
            if (res.status === 'error') {
                this.missingFields = res.missing;
                this.showMissingScreen = true;
            } else {
                this.pdfUrl = `/apex/SHF_CAMGenerationReport?id=${this.recordId}`;
                this.showPdfScreen = true;
            }
        })
        .catch(err => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: err.body?.message,
                variant: 'error'
            }));
            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }

    async handleSend() {
    this.isUploading = true;

    try {
        const res = await generatePdf({ applicationId: this.recordId });
        console.log('PDF Generate Response =>', res);

        const applicantId = await getPrimaryApplicant({ applicationId: this.recordId });
        console.log('Primary Applicant Id =>', applicantId);

        debugger;
        const uploader = this.template.querySelector('c-shf-upload-document');
        uploader.uploadFromParent({
            base64File: res.fileBase64,
            fileName: res.fileName,
            docId: res.docId,
            docCategory: 'Loan Specific Documents',
            docName:   res.fileName,
            parentObjectName: 'Application__c',
            parentRecordId: this.recordId,
            applicantId: applicantId || null
        });

        debugger;
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
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleDmsResponse(event) {
    debugger;
    const resp = event.detail;
    console.log('DMS Response:', resp);
    this.isUploading = false;
    this.dispatchEvent(
        new ShowToastEvent({
            title: resp.status === 'SUCCESS' ? 'Success' : 'Error',
            message: 'CAM has been successfully generated.',
            variant: resp.variant || (resp.status === 'SUCCESS' ? 'success' : 'error'),
        })
    );
    if (resp.status === 'SUCCESS') {
        try {
            await markCAMGenerated({ applicationId: this.recordId });
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch(err) {
            console.error('CAMGenerationDateTime field update failed:', err.body?.message);
        }
        finally {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    } else {
        console.error('DMS upload failed:', resp.message || 'Unknown error');
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}

}