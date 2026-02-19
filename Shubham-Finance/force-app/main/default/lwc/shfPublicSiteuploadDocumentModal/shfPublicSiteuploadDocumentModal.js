import { LightningElement ,track,api ,wire} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex'
import getNotUploadedDocuments from '@salesforce/apex/SHF_PublicSiteDocumentController.getNotUploadedDocumentsRecords';
import getPreDisbursementDocumentsRecords from '@salesforce/apex/SHF_PublicSiteDocumentController.getPreDisbursementDocumentsRecords';
import sendLinkToCustomer from '@salesforce/apex/SHF_PublicSiteDocumentController.sendLinkToCustomer';
import captureSendSmsTime from '@salesforce/apex/SHF_PublicSiteDocumentController.captureSendSmsTime';
import captureSendSmsTimeForSC from '@salesforce/apex/SHF_PublicSiteDocumentController.captureSendSmsTimeForSC';
import uploadForPublicSiteTrue from '@salesforce/apex/SHF_PublicSiteDocumentController.uploadForPublicSiteTrue';

export default class ShfPublicSiteuploadDocumentModal extends LightningElement {

    @track recordsToDisplay = [];
    @track documentList = [];
    @track selectedDocumentList = [];
    @track isLoading;
    @api applicationId;
    @api applicantId;
    //SHF-1559 Added to handle calling this modal from different buttons
    @api sourceType; 
    pageSize = 5;
    totalPages = 0;
    pageNumber = 1;
    totalRecords = 0;
    selectedDocumentIdSet = new Set();

    @track columns = [];
    formFactor = FORM_FACTOR;

   handleUnuploadedClose() {
        this.dispatchEvent(new CustomEvent('closemodal', { detail: false }));
    }


    connectedCallback() {
        this.setColumns();
        this.loadDocuments();
    }

    setColumns() {
        if (this.sourceType === 'DISPLAY') {
            this.columns = [
                { label: 'Document Category', fieldName: 'Document_Category__c', sortable: true },
                { label: 'Document Name', fieldName: 'DocumentName', type: 'text', sortable: true },
                { label: 'Document Related To', fieldName: 'DocumentRelatedTo', type: 'text', sortable: true },
                { label: 'Upload Status', fieldName: 'Status__c', sortable: true }
            ];
        } 
        else if (this.sourceType === 'SPECIAL_CONDITION') {
            this.columns = [
                { label: 'Type', fieldName: 'Type_Of_Condition__c', sortable: true },
                { label: 'Condition Description', fieldName: 'Condition_Description__c', type: 'text', sortable: true },
                { label: 'Document Related To', fieldName: 'DocumentRelatedTo', type: 'text', sortable: true },
                { label: 'Upload Status', fieldName: 'Status__c', sortable: true }
            ];
        }
    }

    //SHF-1559 Added to handle calling this modal from different buttons
    loadDocuments() {
        this.isLoading = true;

        let apexCall;

        if (this.sourceType === 'DISPLAY') {
            apexCall = getNotUploadedDocuments({ applicationId: this.applicationId });
        } else if (this.sourceType === 'SPECIAL_CONDITION') {
            apexCall = getPreDisbursementDocumentsRecords({ applicationId: this.applicationId });
        } else {
            this.isLoading = false;
            console.error('Unknown sourceType:', this.sourceType);
            return;
    }

    apexCall
        .then(data => {
            if (!data.isSuccess) {
                this.handleDocumentFetchError(data);
                return;
            }

            const allDocs = JSON.parse(data.responseBody);

            this.documentList = allDocs.map(doc => ({
                ...doc,
                DocumentName: doc.File_Name__c,
                DocumentRelatedTo: doc.Loan_Applicant__r?.Name || 'Application',
                Status__c: doc.Status__c
            }));

            this.filterAndPaginateDocuments();
        })
        .catch(error => {
            this.handleDocumentFetchError(error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }


    filterAndPaginateDocuments() {
        this.totalRecords = this.documentList.length;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.paginate();
    }

    handleDocumentFetchError(error) {
        this.allDocuments = [];
        this.documentList = [];
        this.recordsToDisplay = [];
        this.totalRecords = 0;
        console.error('Document fetch error:', error);
    }

    get bDisableFirst() {
        return this.pageNumber === 1;
    }

    get bDisableLast() {
        return this.pageNumber === this.totalPages;
    }

    get isMobile() {
        return this.formFactor === 'Small';
    }

    previousPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.paginate();
        }
    }

    nextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.paginate();
        }
    }

    firstPage() {
        this.pageNumber = 1;
        this.paginate();
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginate();
    }

    paginate() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;

        const pageRecords = this.documentList.slice(start, end);

        this.recordsToDisplay = pageRecords.map(rec => ({
            ...rec,
            isChecked: this.selectedDocumentIdSet.has(rec.Id)
        }));
    }


    handleCancel(){
        this.handleUnuploadedClose();
    }

   getSelectedAction(event) {

    if (!this.selectedDocumentIdSet) {
        this.selectedDocumentIdSet = new Set();
    }

    const currentPageSelectedRows = event.detail.selectedRows || [];
    const currentPageIds = this.recordsToDisplay.map(row => row.Id);

    // Remove unselected rows of current page
    currentPageIds.forEach(id => {
        const stillSelected = currentPageSelectedRows.some(row => row.Id === id);
        if (!stillSelected) {
            this.selectedDocumentIdSet.delete(id);
        }
    });

    // Add newly selected rows
    currentPageSelectedRows.forEach(row => {
        this.selectedDocumentIdSet.add(row.Id);
    });

    // Final selected docs (all pages)
    this.selectedDocumentList = this.documentList.filter(doc =>
        this.selectedDocumentIdSet.has(doc.Id)
    );

    console.log('Selected IDs =>', [...this.selectedDocumentIdSet]);
}



    get selectedRowIds() {
        return Array.from(this.selectedDocumentIdSet);
    }

    isTileSelected(id) {
        return this.selectedDocumentIdSet.has(id);
    }

    get isAllTilesSelected() {
        if (!this.recordsToDisplay.length) return false;

        return this.recordsToDisplay.every(rec =>
            this.selectedDocumentIdSet.has(rec.Id)
        );
    }

    handleSelectAllTiles(event) {
        const isChecked = event.target.checked;

        this.recordsToDisplay.forEach(rec => {
            if (isChecked) {
                this.selectedDocumentIdSet.add(rec.Id);
            } else {
                this.selectedDocumentIdSet.delete(rec.Id);
            }
        });

        this.selectedDocumentList = this.documentList.filter(doc =>
            this.selectedDocumentIdSet.has(doc.Id)
        );

        this.paginate(); // refresh 
    }




    handleTileSelect(event) {
        const recordId = event.target.dataset.id;

        if (event.target.checked) {
            this.selectedDocumentIdSet.add(recordId);
        } else {
            this.selectedDocumentIdSet.delete(recordId);
        }

        this.selectedDocumentList = this.documentList.filter(doc =>
            this.selectedDocumentIdSet.has(doc.Id)
        );

        this.paginate(); // refresh tile checked state
    }



    handleSave(event) {
      if (!this.selectedDocumentList || this.selectedDocumentList.length === 0) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Please select at least one record.',
                variant: 'error'
            })
        );
        return;
    }
    this.isLoading = true;
    this.documentId = '';

    const selectedIds = new Set(
        this.selectedDocumentList.map(doc => doc.Id)
    );
    
    this.documentId = Array.from(selectedIds);

    /*Send link to customer */
    sendLinkToCustomer({
         docList: JSON.stringify(this.selectedDocumentList)
    })
    .then(() => {
        console.log('Link Sent Successfully');
        /*Update document public site flag */
        return uploadForPublicSiteTrue({ documentId: this.documentId });
    })
    .then(() => {
        this.documentList = this.documentList.filter(
            doc => !selectedIds.has(doc.Id)
        );
        this.filterAndPaginateDocuments();
        /*Capture SMS time */
        if(this.sourceType === 'DISPLAY'){
            return captureSendSmsTime({ applicationId: this.applicationId });
        }
        if (this.sourceType === 'SPECIAL_CONDITION') {
            return captureSendSmsTimeForSC({ applicationId: this.applicationId });
        } else {
            console.error('Unknown sourceType:', this.sourceType);
            return;
        }
    })
    .then(() => {
         this.isLoading = false;
        console.log('Clickable time updated successfully');
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Message Sent',
                message: 'Send Link To Customer Successfully',
                variant: 'success',
                mode: 'dismissable'
            })
        );
        this.handleUnuploadedClose();
    })
    .catch(err => {
        console.error('Error occurred', err);
        this.isLoading = false;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: err.body?.message || 'Something went wrong',
                variant: 'error'
            })
        );
    });
}

}