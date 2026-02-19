import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getDocuments from '@salesforce/apex/SHF_DisplayDocumentsController.getDocuments';

export default class Shf_FilePreviewModal extends LightningElement {
    recordId;

    @track documents = [];
    isLoading = true;
    hasNoDocuments = false;

    columns = [
        { label: 'File Name', fieldName: 'Name' },
        { label: 'Category', fieldName: 'Document_Category__c' },
        { label: 'Uploaded On', fieldName: 'CreatedDate', type: 'date' },
        { label: 'Status', fieldName: 'Status__c'},
         {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'View', name: 'view_document',iconName: 'utility:preview' }
            ]
        }
    }
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('CurrentPageReference1:', currentPageReference);

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
          console.log('recordId2:', this.recordId);
        }
    }

    connectedCallback() {
        this.loadDocuments();
    }

    loadDocuments() {
        getDocuments({ verificationActivityId: this.recordId })
            .then(result => {
                this.documents = result;
                this.hasNoDocuments = result.length === 0;
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error loading documents:', error);
                this.hasNoDocuments = true;
                this.isLoading = false;
            });
    }

     handleRowAction(event) {
        const actionName = event.detail.action.name;
        this.documentId = event.detail.row.Id;
        this.docCategory = event.detail.row.DocumentCategory;

        if (actionName === 'view_document') {
            //this.showPreviewModal = true;
            this.template.querySelector('c-shf-preview-document').preview(this.documentId);

        }
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }
}