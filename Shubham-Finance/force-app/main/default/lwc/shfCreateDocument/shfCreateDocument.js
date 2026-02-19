import { LightningElement, api, track, wire } from 'lwc';
import getChecklistOptions from '@salesforce/apex/SHF_DisplayDocumentsController.getChecklistOptions';
import createDocumentRecord from '@salesforce/apex/SHF_DisplayDocumentsController.createDocumentRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ShfCreateDocument extends LightningElement {
    @api applicationId;
    @api applicantList = []; // List of { Id, Name } from parent

    @track forWhom = '';
    @track selectedApplicantId;
    @track categoryOptions = [];
    @track typeOptions = [];
    @track nameOptions = [];

    @track selectedCategory;
    @track selectedType;
    @track selectedDocName;
    @track showApplicantDropdown = false;
    @track isLoading = false;
   

    get forWhomOptions() {
        return [
            { label: 'Application', value: 'Application' },
            { label: 'Applicant', value: 'Applicant' }
        ];
    }

    get applicantOptions() {
        return this.applicantList.map(app => ({ label: app.Name, value: app.Id }));
    }

    handleForWhomChange(event) {
        this.forWhom = event.detail.value;
        this.selectedApplicantId = null;
        this.categoryOptions = [];
        this.typeOptions = [];
        this.nameOptions = [];
        this.selectedCategory = null;
        this.selectedType = null;
        this.selectedDocName = null;
        this.showApplicantDropdown = this.forWhom === 'Applicant' && this.applicantList.length >  0;

        if (this.forWhom === 'Application') {
            this.loadChecklistOptions();
        }
    }

    handleApplicantChange(event) {
        this.selectedApplicantId = event.detail.value;
        this.loadChecklistOptions();
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        this.filterDocumentNames();
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.filterDocumentNames();
    }

    handleDocNameChange(event) {
        this.selectedDocName = event.detail.value;
    }

    
    @track fullChecklist = []; // Store raw checklist to filter later

    loadChecklistOptions() {
        if (this.forWhom === 'Applicant' && !this.selectedApplicantId) return;

        this.isLoading = true;

        getChecklistOptions({
            applicationId: this.applicationId,
            applicantId: this.forWhom === 'Applicant' ? this.selectedApplicantId : null,
            forWhom: this.forWhom
        })
        .then(result => {
            this.fullChecklist = result || [];
            this.updateCategoryOptions();
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || error.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    updateCategoryOptions() {
        const categories = [...new Set(this.fullChecklist.map(doc => doc.Document_Category__c).filter(Boolean))];
        this.categoryOptions = categories.map(cat => ({ label: cat, value: cat }));
        this.typeOptions = [];
        this.nameOptions = [];
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        this.selectedType = null;
        this.selectedDocName = null;
        this.updateTypeOptions();
    }

    updateTypeOptions() {
        const types = [
            ...new Set(
                this.fullChecklist
                    .filter(doc => doc.Document_Category__c === this.selectedCategory)
                    .map(doc => doc.Document_Type__c)
                    .filter(Boolean)
            )
        ];
        this.typeOptions = types.map(t => ({ label: t, value: t }));
        this.nameOptions = [];
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.selectedDocName = null;
        this.updateNameOptions();
    }

    updateNameOptions() {
        const names = [
            ...new Set(
                this.fullChecklist
                    .filter(doc =>
                        doc.Document_Category__c === this.selectedCategory &&
                        doc.Document_Type__c === this.selectedType
                    )
                    .map(doc => doc.Name)
                    .filter(Boolean)
            )
        ];
        this.nameOptions = names.map(n => ({ label: n, value: n }));
    }

    filterDocumentNames() {
        // This example assumes Apex filters documentNames by profile/type/category already
        // If needed: add filtering logic here
    }

    handleSave() {
        if (!this.selectedCategory || !this.selectedType || !this.selectedDocName) {
            this.showToast('Validation Error', 'Please fill all required fields', 'warning');
            return;
        }

        this.isLoading = true;
        createDocumentRecord({
            applicationId: this.applicationId,
            applicantId: this.selectedApplicantId,
            documentFor: this.forWhom,
            category: this.selectedCategory,
            type: this.selectedType,
            docName: this.selectedDocName
        })
            .then(result => {
                if (result.isSuccess) {
                    this.showToast('Success', result.responseBody, 'success');
                    this.dispatchEvent(new CustomEvent('closemodal', { detail: false }));
                    window.location.reload();

                } else {
                    this.showToast('Error', result.responseBody, 'error');
                }
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('closemodal', { detail: false }));
    }
}