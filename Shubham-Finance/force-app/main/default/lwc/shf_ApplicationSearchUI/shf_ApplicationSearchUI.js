import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import searchApplications from '@salesforce/apex/shf_ApplicationSearchController.searchApplications';
import getMessageFromMetadata from '@salesforce/apex/SHF_CommonUtil.getMessageFromMetadata';
import getLMSLoanDetail from '@salesforce/apex/SHF_GetLoanDetailsLMSService.getLoanDetails';
import getLinkedLoanDetails from '@salesforce/apex/SHF_getLinkedLoanLMSService.getLinkedLoanDetails';

export default class Shf_ApplicationSearchUI extends NavigationMixin(LightningElement) {
    @api recordId;

    // Inputs
    @track application = '';
    @track loanAggrement = '';
    @track phone = '';

    // Search results
    @track applications = [];
    @track hasSearched = false;
    @track selectedApplicationId = null;
    @track selectedApplicationName = null;

    // Modal Data
    @track isModalOpen = false;
    @track linkedLoan = null;

    // Loader
    @track isLoading = false;
    @track customerName = '';
    @track linkedLoanList = [];

    linkedLoanColumns = [
        { label: 'Loan Account No', fieldName: 'loanAccountNumber' },
        { label: 'Disbursal Status', fieldName: 'disbursalStatus' },
        { label: 'Loan Status', fieldName: 'loanStatus' },
        { label: 'Relationship Type', fieldName: 'relationshipType' }
    ];


    // Columns
    columns = [
        { label: 'Application No', fieldName: 'Name' },
        { label: 'Loan Agreement No', fieldName: 'Loan_Agreement_No__c' },
        { label: 'Phone', fieldName: 'Contact_No1__c' },
        { label: 'Customer Name', fieldName: 'CustomerName' },
        { label: 'Customer Email', fieldName: 'CustomerEmail' },
        { label: 'Customer Contact', fieldName: 'CustomerPhone' },
        { label: 'Branch', fieldName: 'BranchName' },

        //  NEW BUTTON COLUMN
        {
            type: 'button',
            label: 'Linked Loan',
            typeAttributes: {
                label: 'View',
                name: 'viewLinked',
                variant: 'base'
            }
        }
    ];

    // Getters
    get isSearchDisabled() {
        return !(this.application || this.loanAggrement || this.phone);
    }

    get isClearDisabled() {
        return !this.application && !this.loanAggrement && !this.phone;
    }

    get hasApplications() {
        return Array.isArray(this.applications) && this.applications.length > 0;
    }

    get noApplicationsFound() {
        return this.hasSearched && (!this.applications || this.applications.length === 0);
    }

    get rowSelection() {
        return this.selectedApplicationId ? [this.selectedApplicationId] : [];
    }

    get hideCheckboxColumn() {
        return false;
    }

    // Input
    handleInputChange(event) {
        const { name, value } = event.target;
        if (name === 'application') this.application = value;
        else if (name === 'loanAggrement') this.loanAggrement = value;
        else if (name === 'phone') this.phone = value;
    }

    handleClearClick() {
        this.application = '';
        this.loanAggrement = '';
        this.phone = '';
        this.applications = [];
        this.hasSearched = false;
        this.selectedApplicationId = null;
        this.selectedApplicationName = null;
    }

    // Search
    handleSearch() {
        if (!this.application && !this.loanAggrement && !this.phone) {
            this.showMetadataToast('SEARCH_APPLICATION_ERROR');
            return;
        }
        this._runSearch();
    }

    _runSearch() {
        this.isLoading = true;
        this.hasSearched = false;
        this.applications = [];
        this.selectedApplicationId = null;

        searchApplications({
            name: this.application,
            loanAggrement: this.loanAggrement,
            phone: this.phone
        })
            .then(result => {
                this.applications = result.map(app => ({
                    ...app,
                    CustomerName: app.Account__r ? app.Account__r.Name : '',
                    CustomerEmail: app.Account__r ? app.Account__r.Email_id__c : '',
                    CustomerPhone: app.Account__r ? app.Account__r.Phone : '',
                    BranchName: app.Branch__r ? app.Branch__r.Name : '',
                    Branch: app.Branch__c || '',
                    LoanAggrementNumber: app.Loan_Agreement_No__c || ''
                }));
                this.hasSearched = true;
            })
            .catch(error => {
                this.showToast('Error', this._getErrorMessage(error), 'error');
            })
            .finally(() => (this.isLoading = false));
    }

    // Row selection
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        console.log('selectedRows : ',selectedRows);
        if (selectedRows && selectedRows.length > 0) {
            this.selectedApplicationId = selectedRows[0].Id;
            this.selectedApplicationName = selectedRows[0].Name;
        } else {
            this.selectedApplicationId = null;
            this.selectedApplicationName = null;
        }
    }

    // --- CREATE CASE CLICK (with delay) ---
    handleCreateNewCaseClick() {
        this.isLoading = true;
        
        console.log('Inside handleCreateNewCaseClick : ');
        let selectedApp = null;
        if (this.selectedApplicationId) {
            selectedApp = this.applications.find(app => app.Id === this.selectedApplicationId);
            console.log('selectedApp : ',selectedApp);
        }

        // Delay before calling LMS API
        setTimeout(() => {
            this.getLoanStatusThenNavigate(selectedApp);
        }, 1200);
    }

    // --- Fetch loan status then navigate ---
    getLoanStatusThenNavigate(selectedApp) {
        if (!selectedApp) {
            this.navigateCaseWithDefaults(null, null);
            return;
        }

        if (!selectedApp.LoanAggrementNumber) {
            this.navigateCaseWithDefaults(selectedApp, null);
            return;
        }

        getLMSLoanDetail({
            accountNumber: selectedApp.LoanAggrementNumber
        })
            .then(response => {
                this.wrapperData = response || {};
                console.log('wrapperData : ',this.wrapperData);
                this.navigateCaseWithDefaults(selectedApp, this.wrapperData);
            })
            .catch(error => {
                console.error('LMS API Error:', error);
                this.navigateCaseWithDefaults(selectedApp, null);
            });
    }

    // --- Navigate AFTER LMS data is ready ---
    navigateCaseWithDefaults(selectedApp, wrapper) {
        let defaultFieldValues = '';
        console.log('Inside navigateCaseWithDefaults : ');
        if (selectedApp) {
            defaultFieldValues =
                `Application__c=${selectedApp.Id},` +
                `Search_Criteria_Not_Available__c=false,` +
                `Customer_Name__c=${selectedApp.CustomerName || ''},` +
                `Customer_Email__c=${selectedApp.CustomerEmail || ''},` +
                `Contact_No_1__c=${selectedApp.CustomerPhone || ''},` +
                `Branch__c=${selectedApp.Branch || ''},` +
                `Loan_Status__c=${wrapper?.loanStatus || ''}`;
        } else {
            defaultFieldValues = `Search_Criteria_Not_Available__c=true`;
        }

        // Navigate ONLY once (prevents refresh issue)
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            },
            state: {
                defaultFieldValues
            }
        });

        this.isLoading = false;
    }

    //  NEW BUTTON CLICK HANDLER
    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        console.log('row : ',row);
        if (action === 'viewLinked') {
            this.fetchLinkedLoan(row);
        }
    }

   fetchLinkedLoan(row) {
    this.isLoading = true;

    const loan = row.Loan_Agreement_No__c || '';
    const mobile = row.Account__r?.Phone || '';

    getLinkedLoanDetails({ accountNumber: loan, mobile: mobile })
        .then(res => {

            console.log('Linked Loan Response:', res);

            // -------------------------------
            //    VALIDATION FOR EMPTY DATA
            // -------------------------------
            if (!res || !Array.isArray(res) || res.length === 0) {

                this.customerName = '';
                this.linkedLoanList = [];
                this.isModalOpen = false;

                this.showToast(
                    'No Linked Loan Found',
                    'No linked loan details are available for this customer.',
                    'warning'
                );

                return; // STOP FURTHER EXECUTION
            }

            //   DATA FOUND
            
            this.linkedLoanList = res;

            // Set customer name
            this.customerName = res[0].customerName || '';

            // Open modal
            this.isModalOpen = true;
        })
        .catch(err => {
            this.showToast('Error', this._getErrorMessage(err), 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
}



    closeModal() {
        this.isModalOpen = false;
        this.linkedLoan = null;
    }

    // Helpers
    _getErrorMessage(err) {
        if (!err) return 'Unknown error';
        if (err.body?.message) return err.body.message;
        if (err.message) return err.message;
        return JSON.stringify(err);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    showMetadataToast(recordDevName) {
        getMessageFromMetadata({ recordDevName })
            .then(res => {
                const variant =
                    res.MessageType?.toLowerCase() === 'error'
                        ? 'error'
                        : res.MessageType?.toLowerCase() === 'success'
                        ? 'success'
                        : 'info';

                this.showToast(res.MessageType || variant, res.Message || 'Message not found', variant);
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }
}