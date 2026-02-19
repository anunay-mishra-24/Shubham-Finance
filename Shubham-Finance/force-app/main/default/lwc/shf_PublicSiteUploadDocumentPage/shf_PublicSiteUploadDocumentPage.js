import { LightningElement ,track,api ,wire} from 'lwc';
import { refreshApex } from '@salesforce/apex'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDocumentsForApplicant from '@salesforce/apex/SHF_PublicSiteDocumentExternalController.getDocumentsForApplicant';

export default class ShfPublicSiteuploadDocumentPage extends LightningElement {

    @track recordsToDisplay = [];
    @track documentList = [];
    @track selectedDocumentList = [];
    @track applicantId;
    @track docName;
    @track documentId;
    @track applicationId;
    @track docCategory;
    @track showModal = false; 
    isFromPublicSite = true;
    pageSize = 5;
    totalPages = 0;
    pageNumber = 1;
    totalRecords = 0;


    @track columns = [
        { label: 'Document Category', fieldName: 'Document_Category__c', sortable: true },
        { label: 'Document Name', fieldName: 'DocumentName', type: 'text', sortable: true },
        { label: 'Document RelatedTo', fieldName: 'DocumentRelatedTo', type: 'text', sortable: true },
        { label: 'Upload Status', fieldName: 'Status__c', sortable: true },
        {
            type: "button", label: 'Upload', initialWidth: 125, typeAttributes: {
                label: 'Upload',
                name: 'Upload',
                title: 'Upload',
                disabled: false,
                value: 'Upload',
                iconPosition: 'left',
                iconName: 'utility:upload',
                variant:'Brand'
            }
        },
       
    ];
  
   connectedCallback() {
        const urlParams = new URL(window.location.href).searchParams;
        this.applicantId = urlParams.get('applicantId');
        console.log('applicantId==>',this.applicantId);
    }

   handleUnuploadedClose() {
        this.dispatchEvent(new CustomEvent('closemodal', { detail: false }));
    }


    @wire(getDocumentsForApplicant,{ applicantId: '$applicantId'})
    wiredDocuments(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            if (!data.isSuccess) {
                this.handleDocumentFetchError(data);
                return;
            }
            const allDocs = JSON.parse(data.responseBody);
            console.log('allDocs===> ', allDocs);
            this.documentList = allDocs.map(doc => ({
                ...doc,
                DocumentName:doc.File_Name__c,
                DocumentCategory: doc.Document_Category__c,
                DocumentRelatedTo: doc.Loan_Applicant__r?.Name || 'Application',
                Status__c:doc.Status__c
               
            }));
            console.log('this.documentList===> ', this.documentList);
            this.filterAndPaginateDocuments();

            if (this.documentList.length === 0) {
                this.notifyAllDocsUploaded();
            }
        }
        else if (error) {
            this.handleDocumentFetchError(error);
            this.showSpinner = false;
        }
    }

    handleOnUpload(event){
        console.log('event.detail.row--->'+JSON.stringify(event.detail.row));
        this.showModal = true;
        const documentName = event.detail.row.DocumentName;
        const docId =  event.detail.row.Id;
        const applicationId = event.detail.row.Application__c;
        const documentCategory = event.detail.row.DocumentCategory;
        this.docName = documentName;
        console.log('docName--->'+this.docName);
        this.documentId = docId;
        console.log('this.documentId--->'+this.documentId);
        this.applicationId = applicationId;
        this.docCategory = documentCategory;
        console.log('this.docCategory--->'+this.docCategory);
        this.handleUnuploadedClose();
        
        new ShowToastEvent({
                title: 'Upload Document',
                message: 'Upload Document Successfully',
                variant: 'success',
                mode: 'dismissable'
            })
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
        this.recordsToDisplay = this.documentList.slice(start, end);
    }
       

    closeModal(){
        this.showModal = false;
        console.log('this.showModal==>');
        refreshApex(this.wiredResult);
    }
    
    notifyAllDocsUploaded() {
        console.log('thisisNotified to aura');
        this.dispatchEvent(
        new CustomEvent('docscompleted', {
            bubbles: true,
            composed: true
        })
    );
    }

}