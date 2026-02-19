import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import PROFILE_FIELD from '@salesforce/schema/User.Profile.Name';
import STAGE_FIELD from '@salesforce/schema/Application__c.Application_Stage__c';
import OWNER_FIELD from '@salesforce/schema/Application__c.OwnerId';
import getApplicationDocuments from '@salesforce/apex/SHF_DisplayDocumentsController.getApplicationDocuments';
import updateAcknowledgementStatus from '@salesforce/apex/SHF_DisplayDocumentsController.updateAcknowledgementStatus';
import getAcknowledgementStatusOptions from '@salesforce/apex/SHF_DisplayDocumentsController.getAcknowledgementStatusOptions';
import initiateRCUtoVendor from '@salesforce/apex/SHF_RCUController.initiateRCUtoVendor';
import getDocumentsForRecord from '@salesforce/apex/SHF_DisplayDocumentsController.getDocumentsForRecord';
import FORM_FACTOR from '@salesforce/client/formFactor';
import MOBILE_UPLOAD_URL from '@salesforce/label/c.Mobile_Upload_URL';


/*const rowAction = [
    { label: 'Upload', name: 'Upload', iconName: 'action:upload' },
    { label: 'View', name: 'View', iconName: 'utility:preview' }
    { label: 'Faceliveliness', name: 'Faceliveliness', iconName: 'utility:user' },
    { label: 'Facematch', name: 'Facematch', iconName: 'utility:share' }

];*/


export default class ShfDisplayDocumentDetails extends NavigationMixin(LightningElement) {
    @api documentType;
    @api applicationId;
    @api applicantId;
    @api recordId;        // Auto-passed when placed on record page
    @api objectApiName;   // Auto-passed when placed on record page
    @api contextMode = 'Application'; // Default mode, override in App Builder
    @track ackStatusOptions = [];
    @track documentList = [];
    @track showModal = false;
    @track showPreviewModal = false;
    @track showSpinner = false;
    @track documentId;
    @track docCategory;
    @track fileName = '';
    @track sortBy;
    @track sortDirection;
    @track searchTerm = '';
    @track isDialogVisible = false;
    @track title = 'Document Verification';
    //@track showRCUInitiate = false;
    @track userProfileName;
    @track applicationStage;
    @track showTypeSelectionModal = false;
    @track comment;
    @track rcuType;
    @track ownerId;
    @track selectedDocs = [];
    allDocuments = [];
    pageSize = 5;
    totalPages = 0;
    pageNumber = 1;
    totalRecords = 0;
    recordsToDisplay = [];

    @track columns = [
        { label: 'Document Category', fieldName: 'Document_Category__c', sortable: true },
        {
            label: 'Document Name',
            fieldName: 'DocumentName',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: { fieldName: 'DocumentLabel' },
                target: '_blank'
            }
        },
        { label: 'Document Received Date', fieldName: 'Document_Received_Date__c', type: 'date', sortable: true },
        { label: 'Document Source', fieldName: 'Document_Source__c', sortable: true },
        { label: 'Document Created By', fieldName: 'DocumentCreatedBy', sortable: true }, // or backend computed field
        { label: 'Upload Status', fieldName: 'Status__c', sortable: true },
        { label: 'Mandatory Status', fieldName: 'MandatoryText', sortable: true },
        { label: 'RCU Required', fieldName: 'RCU_Required__c', sortable: true },
        { label: 'RCU Verification Status', fieldName: 'RCU_Verification_Status__c', sortable: true },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions.bind(this) }
        }
    ];

    acceptedFormats = [
        '.jpg', '.jpeg', '.png', '.bmp', '.csv', '.doc', '.docx', '.pdf', '.ppt', '.pptx', '.xls', '.xlsx', '.txt'
    ];

    get bDisableFirst() {
        return this.pageNumber === 1;
    }

    get bDisableLast() {
        return this.pageNumber === this.totalPages;
    }

    get rcuTypeOptions() {
        return [
            { label: 'Borrower', value: 'Borrower' },
            { label: 'Document', value: 'Document' }
        ];
    }

    connectedCallback() {
        console.log('output this.contextMode ',this.contextMode);
        
        if (this.contextMode === 'Generic') {
            this.getGenericDocuments(); // Logic for Generic Display
        } else {
            this.getApplicationDocuments(); // Document CheckList logic
        }
        this.fetchAcknowledgePicklistOptions();
    }

    @wire(getRecord, { recordId: Id, fields: [PROFILE_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userProfileName = data.fields.Profile.displayValue || data.fields.Profile.value.fields.Name.value;
            this.updateRCUVisibility();
        } else if (error) {
            console.error('Error fetching user profile', error);
        }
    }

    @wire(getRecord, { recordId: '$applicationId', fields: [STAGE_FIELD, OWNER_FIELD] })
    wiredApplication({ error, data }) {
        if (data) {
            this.applicationStage = data.fields.Application_Stage__c.value;
            this.ownerId = data.fields.OwnerId.value;
            this.updateRCUVisibility();
        } else if (error) {
            console.error('Error fetching application stage', error);
        }
    }

    get showRCUInitiate(){
        console.log('this.ownerId = ',this.ownerId);
        console.log('this.applicationStage = ',this.applicationStage);
        console.log('this.ownerId = ',Id);
        return ((this.ownerId == Id || this.userProfileName === 'System Administrator') && this.applicationStage === 'Credit Sanction');
    }

    get isApplicationContext() {
        return this.contextMode === 'Application';
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        const docName = row.File_Name__c;
        console.log('docName : ', docName);
        if (docName === 'Tentative Repayment Schedule') {
        actions.push({
            label: 'View',
            name: 'View',
            iconName: 'utility:preview'
        });

        setTimeout(() => doneCallback(actions), 0);
        return; 
        }
        // Always show "View"
        actions.push({ label: 'View', name: 'View', iconName: 'utility:preview' });
        actions.push({ label: 'Faceliveliness', name: 'Faceliveliness', iconName: 'utility:user' });
        actions.push({ label: 'Facematch', name: 'Facematch', iconName: 'utility:share' });

        // Conditionally show "Upload"
        const loggedInUserId = Id; // from @salesforce/user/Id
        const appOwnerId = row.Application__r?.OwnerId;
        const isSystemAdmin = this.userProfileName === 'System Administrator';
        const isAppOwner = appOwnerId === loggedInUserId;

        if ((isAppOwner || isSystemAdmin) && row.File_Name__c !== 'Account Statement') {
            actions.unshift({ label: 'Upload', name: 'Upload', iconName: 'action:upload' });
        }


        setTimeout(() => doneCallback(actions), 0);
    }

    updateRCUVisibility() {
        if (!this.userProfileName || !this.applicationStage) {
            return; // Wait until both are set
        }

        //this.showRCUInitiate = ((this.userProfileName === 'RCU' || this.userProfileName === 'System Administrator') && this.applicationStage === 'Credit Sanction');
    }

    fetchAcknowledgePicklistOptions() {
        getAcknowledgementStatusOptions()
            .then(result => {
                this.ackStatusOptions = result.map(val => {
                    return { label: val, value: val };
                });
            })
            .catch(error => {
                console.error('Error fetching acknowledge status options', error);
            });
    }

    getApplicationDocuments() {
        this.showSpinner = true;
        console.log('this.recordId - ',this.recordId);
        console.log('this.objectApiName - ',this.recordId);
        
        getApplicationDocuments({
            applicationId: this.applicationId,
            loanApplicantId: this.applicantId
        })
            .then(result => {
                if (!result.isSuccess) {
                    this.handleDocumentFetchError(result);
                    return;
                }

                const allDocs = JSON.parse(result.responseBody);

                this.allDocuments = allDocs.map(doc => ({
                    ...doc,
                    DocumentName: `/lightning/r/Document__c/${doc.Id}/view`,
                    DocumentLabel: doc.File_Name__c || 'View Document',
                    MandatoryText: doc.Mandatory_Document__c ? 'Yes' : 'No',
                    DocumentCategory: doc.Document_Category__c,
                    Document_Received_Date__c: doc.Document_Received_Date__c,
                    Document_Source__c: doc.Document_Source__c,
                    DocumentCreatedBy: doc.CreatedBy?.Name || 'System',
                    RCU_Required__c: doc.RCU_Required__c ? 'Yes' : 'No',
                    RCU_Verification_Status__c: 'Pending'
                }));

                this.filterAndPaginateDocuments();
            })
            .catch(error => this.handleDocumentFetchError(error))
            .finally(() => {
                this.showSpinner = false;
            });
    }
    getGenericDocuments() {
        this.showSpinner = true;
        console.log('this.recordId - ',this.recordId);
        console.log('this.objectApiName - ',this.objectApiName);
        
        getDocumentsForRecord({
            recordId: this.recordId,
            objectApiName: this.objectApiName
        })
            .then(result => {
                if (!result.isSuccess) {
                    this.handleDocumentFetchError(result);
                    return;
                }

                const allDocs = JSON.parse(result.responseBody);
                this.allDocuments = allDocs.map(doc => ({
                    ...doc,
                    DocumentName: `/lightning/r/Document__c/${doc.Id}/view`,
                    DocumentLabel: doc.File_Name__c || 'View Document',
                    MandatoryText: doc.Mandatory_Document__c ? 'Yes' : 'No',
                    DocumentCategory: doc.Document_Category__c,
                    Document_Received_Date__c: doc.Document_Received_Date__c,
                    Document_Source__c: doc.Document_Source__c,
                    Created_By__c: doc.Created_By__c || (doc.CreatedBy ? doc.CreatedBy.Name : 'System')
                }));

                this.filterAndPaginateDocuments();
            })
            .catch(error => this.handleDocumentFetchError(error))
            .finally(() => {
                this.showSpinner = false;
            });
    }
    handleDocumentFetchError(error) {
        this.allDocuments = [];
        this.documentList = [];
        this.recordsToDisplay = [];
        this.totalRecords = 0;
        console.error('Document fetch error:', error);
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.pageNumber = 1;
        this.filterAndPaginateDocuments();
    }

    filterAndPaginateDocuments() {
        const term = this.searchTerm.trim();

        if (term) {
            this.documentList = this.allDocuments.filter(doc =>
                (doc.File_Name__c || '').toLowerCase().includes(term) ||
                (doc.Document_Type__c || '').toLowerCase().includes(term)
            );
        } else {
            this.documentList = [...this.allDocuments];
        }

        this.totalRecords = this.documentList.length;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.paginate();
    }

    paginate() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.recordsToDisplay = this.documentList.slice(start, end);
    }

    handleRecordsPerPage(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.pageNumber = 1;
        this.filterAndPaginateDocuments();
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

    handleSortAccountData(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData();
    }

    sortData() {
        const fieldname = this.sortBy;
        const direction = this.sortDirection;
        const isReverse = direction === 'asc' ? 1 : -1;

        this.documentList.sort((a, b) => {
            const valA = a[fieldname] || '';
            const valB = b[fieldname] || '';
            return isReverse * ((valA > valB) - (valB > valA));
        });

        this.paginate();
    }

    getSelectedAction(event) {
        console.log('event-> ', event);
        let selectedRows = JSON.parse(JSON.stringify(event.detail.selectedRows));
        console.log('selectedRows-> ', selectedRows);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        this.documentId = event.detail.row.Id;
        this.docCategory = event.detail.row.DocumentCategory;
        this.docName = event.detail.row.File_Name__c;
        console.log('Document Id: ', this.documentId);
        console.log('Document Name: ', this.docName);
        console.log('ApplicantId: ', this.applicantId);

        if (actionName === 'Upload') {
            if ((this.docName === 'Applicant Photo') || (this.docName === 'Applicant Signature') || (this.docName === 'RM Selfie')) {
                if (FORM_FACTOR === 'Small') { // Only on Mobile open  link
                    // this.openCustomUrl(`shubhamshf://imagecapture?recordId=${this.documentId}&docName=${this.docName}`);
                    const url = MOBILE_UPLOAD_URL
                        .replace('{DocumentRecordId}', this.documentId)
                        .replace('{Documentname}', this.docName);

                    this.openCustomUrl(url);
                }
                else {
                    this.showModal = true;
                }
            }
            else {
                this.showModal = true;
            }
        } else if (actionName === 'View') {
            //this.showPreviewModal = true;
            this.template.querySelector('c-shf-preview-document').preview(this.documentId);

        } else if (actionName === 'Faceliveliness') {
            this.openCustomUrl('shubhamshf://faceliveness');

        } else if (actionName === 'Facematch') {
            this.openCustomUrl('shubhamshf://facematch');

        } else {
            console.warn('Unknown action:', actionName);
        }
    }

    /*closePreviewModal(event) {
        this.showPreviewModal = event.detail;
    }*/

    /*previewDocument(documentId) {
    this.showSpinner = true;

        getPreviewUrl({ documentId })
        .then(url => {
            this.showSpinner = false;

            if (url) {
                window.open(url, '_blank'); // Opens in new tab
            } else {
                this.showNotification('Error', 'Unable to generate preview URL.', 'error');
            }
        })
        .catch(error => {
            this.showSpinner = false;
            this.showNotification('Error', error.body?.message || 'Failed to preview document.', 'error');
        });
    }*/

    openCustomUrl(url) {
        try {
            console.log('Opening custom URL:', url);
            window.location.href = url;
        } catch (error) {
            console.error('Failed to open URL:', url, error);
            this.showNotification('Error', 'Unable to open link: ' + url, 'error');
        }
    }


    handleAcknowledge() {
        const selectedRecords = this.template.querySelector('lightning-datatable')?.getSelectedRows() || [];
        const selectedIds = [];

        let hasCompleted = false;

        selectedRecords.forEach(record => {
            if (['Uploaded', 'Not Uploaded'].includes(record.Status__c)) {
                selectedIds.push(record.Id);
            }
            if (['Completed', 'Waived Off'].includes(record.Acknowledge_Status__c)) {
                hasCompleted = true;
            }
        });

        if (selectedIds.length === 0) {
            this.showNotification('Warning', 'Please select at least one document.', 'warning');
        } else if (hasCompleted) {
            this.showNotification('Warning', 'Some selected documents are already Completed or Waived Off.', 'warning');
        } else {
            this.selectedDocumentIds = selectedIds;
            this.isDialogVisible = true;
        }
    }


    handleModalConfirm(event) {
        const { status, comments } = event.detail;
        const selectedRecords = this.template.querySelector('lightning-datatable')?.getSelectedRows() || [];
        const selectedIds = selectedRecords.map(record => record.Id);

        if (selectedIds.length > 0) {
            updateAcknowledgementStatus({ documentIds: selectedIds, status: status, comment: comments })
                .then(() => {
                    this.showNotification('Success', 'Acknowledgement status updated successfully.', 'success');
                    this.showModal = false;
                    this.getApplicationDocuments();
                })
                .catch(error => {
                    this.showNotification('Error', error.body?.message || 'Unexpected error occurred.', 'error');
                });
        }
        this.isDialogVisible = false;


    }

    closeModal() {
        this.showModal = false;
        this.isDialogVisible = false;
    }

    showNotification(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    handleRCUInitiateToVendors() {
        let selectedIds = [];
        this.selectedDocs = [];
        let selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        if (selectedRecords.length > 0) {
            selectedRecords.forEach(currentItem => {
                console.log('currentItem-> ', currentItem);
                selectedIds.push(currentItem.Id);
            });
        } else {
            this.showNotification('Warning', 'Please select atleast one Document.', 'warning');
        }
        console.log('selectedIds : ', selectedIds.length, selectedRecords.length);
        if (selectedIds.length > 0 && selectedIds.length == selectedRecords.length) {
            this.selectedDocs = selectedIds;
            this.showTypeSelectionModal = true;
        }
    }

    handleSave() {
        console.log('HANDLE SAVE = ', this.comment, this.rcuType, this.selectedDocs);
        if (this.comment && this.rcuType) {
            this.documentId = this.selectedDocs;
            this.initiateRCUtoVendor();
        } else {
            this.showNotification('Warning', 'Please fill all the required fields.', 'error');
        }
    }


    handleCloseRCUModel() {
        this.showTypeSelectionModal = false;
    }

    initiateRCUtoVendor() {
        this.showSpinner = true;
        initiateRCUtoVendor({ docIds: this.documentId, applicationId: this.applicationId, rcuType: this.rcuType, comments: this.comment }).then(result => {
            console.log('result.initiateRCUtoVendor-> ', result);
            console.log('getUsersManagersList result === > ', JSON.stringify(result));
            if (result.isSuccess) {
                this.showNotification('Success', result.responseBody, 'success');
                this.showSpinner = false;
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.recordId,
                        objectApiName: 'Verification__c',
                        actionName: 'view'
                    }
                });
            } else {
                this.showNotification('Error', result.responseBody, 'error');
                this.showSpinner = false;
            }
        }).catch(error => {
            this.showTypeSelectionModal = false;
            console.log('Error initiateRCUtoVendor= ', error);
            //console.log('Error= ', error.body.message);
            this.showNotification('Error', error, 'error');
            this.showSpinner = false;
        }).finally(() => {
            this.showTypeSelectionModal = false;
            this.showSpinner = false;
        });

    }

    handleChange(event) {
        console.log('handleChange ', event.target.name, event.target.value);
        if (event.target.name == 'Remark')
            this.comment = event.target.value;
        if (event.target.name == 'RCU Type')
            this.rcuType = event.target.value;
    }
}