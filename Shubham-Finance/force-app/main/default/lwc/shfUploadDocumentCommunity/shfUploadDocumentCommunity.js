import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getRecordUi } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
//import uploadDocumentCommunity from '@salesforce/apex/SHF_DisplayDocumentsController.uploadDocumentCommunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const VERIFICATION_FIELDS = ['Verification__c.Application__c'];

export default class ShfUploadDocumentWrapper extends LightningElement {
    recordId; 
    objectApiName;
    applicationId;
    verificationId;
    documentId;
    dmsDocumentId; 
    showUploadModal = false;
    showPreviewModal = false;

    uploadDocumentButton = true;
    disabledUploadButton = false;
    disabledViewButton = false;

     @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('CurrentPageReference:', currentPageReference);

        if (currentPageReference) {
            this.recordId = currentPageReference?.attributes?.recordId
                || currentPageReference?.state?.c__recordId;

            if (!this.recordId) {
                const pathSegments = window.location.pathname.split('/');
                const lastSegment = pathSegments[pathSegments.length - 1];
                if (/^va[a-zA-Z0-9]{6,}$/.test(lastSegment)) {
                    this.recordId = lastSegment;
                }
            }

        }
    }

    


    @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
wiredRecordUi({ error, data }) {
    if (data) {
        const record = data.records[this.recordId];
        this.documentId = record.fields.Verification__c.value;
        this.objectApiName = record.apiName;
        this.verificationId =  record.fields.Verification__c.value;
        console.log('Object API Name:', this.objectApiName);
        console.log('document Name:', this.documentId);
    } else if (error) {
        console.error('Error fetching record UI:', error);
    }
}

@wire(getRecord, { recordId: '$verificationId', fields: VERIFICATION_FIELDS })
wiredVerification({ error, data }) {
    if (data) {
        this.applicationId = data.fields.Application__c.value;
        console.log('Application Id:', this.applicationId);
    } else if (error) {
        console.error('Error fetching Application Id:', error);
    }
}



    handleFileUpload(event) {
    const { fileName, base64, relatedId } = event.detail;
     uploadDocumentCommunity({ fileName, base64Data: base64, verificationActivityId: relatedId })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Document uploaded successfully.',
                variant: 'success'
            }));
            this.closeUploadModal();
        })
        .catch(error => {
            console.error('Upload failed:', JSON.stringify(error));
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error uploading document',
                message: error.body?.message || 'Unknown error',
                variant: 'error'
            }));
        });
}


    openUploadModal() {
        this.showUploadModal = true;
    }

    closeUploadModal() {
        this.showUploadModal = false;
    }

    openPreviewModal() {
        this.showPreviewModal = true;
    }

    closePreviewModal() {
        this.showPreviewModal = false;
    }
}