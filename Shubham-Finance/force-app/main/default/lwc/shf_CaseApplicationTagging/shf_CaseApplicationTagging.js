import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import searchApplications
    from '@salesforce/apex/shf_ApplicationSearchController.searchApplications';
import updateCaseWithApplication
    from '@salesforce/apex/SHF_CaseUpdateController.updateCaseWithApplication';

export default class Shf_CaseApplicationTagging extends LightningElement {

    @api recordId;

    /* ================= SEARCH INPUT ================= */
    @track application = '';
    @track loanAggrement = '';
    @track phone = '';

    /* ================= SEARCH RESULT ================= */
    @track applications = [];
    @track hasSearched = false;
    @track selectedApplicationId = null;

    /* ================= MANUAL INPUT ================= */
    @track customerName = '';
    @track email = '';
    @track contact = '';
    @track selectedApplication = '';
    @track branchId = null;

    /* ================= FLAGS ================= */
    @track isLoading = false;
    @track searchCriteriaNotAvailable = false;

    /* ================= DATATABLE ================= */
    columns = [
        { label: 'Application Name', fieldName: 'Name' },
        { label: 'Loan Agreement No', fieldName: 'Loan_Agreement_No__c' },
        { label: 'Phone', fieldName: 'Contact_No1__c' },
        { label: 'Customer Name', fieldName: 'CustomerName' },
        { label: 'Customer Email', fieldName: 'CustomerEmail' },
        { label: 'Customer Contact', fieldName: 'CustomerPhone' },
        { label: 'Branch', fieldName: 'BranchName' }
    ];

    dummyApplications = [
        { label: 'New Lead', value: 'New Lead' },
        { label: 'App. Not Shared', value: 'App. Not Shared' },
        { label: 'Third Party', value: 'Third Party' }
    ];

    /* ================= GETTERS ================= */
    get isSearchDisabled() {
        return !(this.application || this.loanAggrement || this.phone);
    }

    get isClearDisabled() {
        return !this.application && !this.loanAggrement && !this.phone;
    }

    get hasApplications() {
        return this.applications.length > 0;
    }

    get noApplicationsFound() {
        return this.hasSearched && this.applications.length === 0;
    }

    get rowSelection() {
        return this.selectedApplicationId ? [this.selectedApplicationId] : [];
    }

    /* ================= HANDLERS ================= */
    handleInputChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleManualInput(event) {
        this[event.target.name] = event.target.value;
    }

    handleBranchChange(event) {
        const value = event.detail.value;
        this.branchId = Array.isArray(value) && value.length ? value[0] : null;
    }

    handleClearClick() {
        this.application = '';
        this.loanAggrement = '';
        this.phone = '';
        this.applications = [];
        this.hasSearched = false;
        this.selectedApplicationId = null;
        this.searchCriteriaNotAvailable = false;
    }

    handleSearch() {
        if (!this.application && !this.loanAggrement && !this.phone) {
            this.showToast('Error', 'Please enter search criteria', 'error');
            return;
        }

        this.isLoading = true;
        this.applications = [];
        this.hasSearched = false;

        searchApplications({
            name: this.application,
            loanAggrement: this.loanAggrement,
            phone: this.phone
        })
        .then(result => {
            this.applications = result.map(app => ({
                ...app,
                CustomerName: app.Account__r?.Name || '',
                CustomerEmail: app.Account__r?.Email_id__c || '',
                CustomerPhone: app.Account__r?.Phone || '',
                BranchName: app.Branch__r?.Name || ''
            }));

            this.hasSearched = true;
            this.searchCriteriaNotAvailable = this.applications.length === 0;
        })
        .catch(error => {
            this.showToast(
                'Error',
                error?.body?.message || error.message,
                'error'
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleRowSelection(event) {
        const row = event.detail.selectedRows[0];
        if (row) {
            this.selectedApplicationId = row.Id;

            // reset manual-only fields
            this.searchCriteriaNotAvailable = false;
            this.branchId = null;
            this.customerName = '';
            this.email = '';
            this.contact = '';
            this.selectedApplication = '';
        }
    }

    /* ================= SUBMIT ================= */
    handleSubmit() {
        const isManual = this.searchCriteriaNotAvailable === true;
        const isAppSelected = !!this.selectedApplicationId;

        /* ---------- VALIDATIONS ---------- */

        if (!isAppSelected && !isManual) {
            this.showToast('Error', 'Please select an application', 'error');
            return;
        }

        if (isManual && (!this.customerName || !this.email)) {
            this.showToast('Error', 'Please enter customer details', 'error');
            return;
        }

        if (isManual && !this.branchId) {
            this.showToast('Error', 'Please select Branch', 'error');
            return;
        }

        const selectedApp = this.applications.find(
            app => app.Id === this.selectedApplicationId
        );

        this.isLoading = true;

        updateCaseWithApplication({
            caseId: this.recordId,
            applicationId: isAppSelected ? selectedApp.Id : null,
            customerName: isAppSelected ? selectedApp.CustomerName : this.customerName,
            customerEmail: isAppSelected ? selectedApp.CustomerEmail : this.email,
            contactNumber: isAppSelected ? selectedApp.CustomerPhone : this.contact,
            dummyApplication: this.selectedApplication ? this.selectedApplication : null,
            searchCriteriaNotAvailable: isManual,
            branch: isManual ? this.branchId : null
        })
        .then(() => {
            this.showToast('Success', 'Case updated successfully', 'success');
            this.dispatchEvent(new CloseActionScreenEvent());
            setTimeout(() => window.location.reload(), 300);
        })
        .catch(error => {
            this.showToast(
                'Error',
                error?.body?.message || error.message,
                'error'
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    /* ================= HELPERS ================= */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}