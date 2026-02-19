import { LightningElement, api, track } from 'lwc';
import searchAccounts from '@salesforce/apex/SHF_ApplicantSearchController.searchAccounts';
import hasReachedCoApplicantLimit from '@salesforce/apex/SHF_ApplicantSearchController.hasReachedCoApplicantLimit';
import getMessageFromMetadata from '@salesforce/apex/SHF_CommonUtil.getMessageFromMetadata';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';


export default class ShfApplicantSearch extends LightningElement {
    @api recordId; // Application Id

    // Search inputs
    @track phone = '';
    @track pan = '';
    @track dob = null;

    // Search results
    @track accounts = [];
    @track hasSearched = false;
    @track selectedAccountId = null;
    @track selectedAccount = null;
    @track isRecordTypeDisabled = false;


    // UI flags
    @track isLoading = false;
    @track isSubmitting = false; // double-click prevent
    @track showApplicantForm = false;
    @track showRecordTypeModal = false;
    @track selectedRecordType;
    @track showLimitMessage = false;
    @track limitMessage = '';
    @track showPanInlineError = false;


    // Datatable columns
    columns = [
        { label: 'Account Name', fieldName: 'Name' },
        { label: 'Phone', fieldName: 'Phone' },
        { label: 'PAN', fieldName: 'PAN_Number__c' },
        { label: 'DOB', fieldName: 'Date_of_Birth__c' }
    ];

    recordTypeOptions = [
        { label: 'Individual', value: 'Individual' },
        { label: 'Non-Individual', value: 'Non_Individual' }
    ];


    today = new Date().toISOString().split('T')[0];
    tomorrowDate = (() => {
        let d = new Date();
        d.setDate(d.getDate() + 1);
        return d.toISOString().split('T')[0];
    })();

    yesterDayDate = (() => {
        let d = new Date();
        d.setDate(d.getDate() - 1);
        return d.toISOString().split('T')[0];
    })();

    // --- Getters ---

    get isMobile() {
        return FORM_FACTOR === 'Small';
    }


    get maxDob() {
    const today = new Date();
    today.setFullYear(today.getFullYear() - 18);
    return today.toISOString().split('T')[0]; // format YYYY-MM-DD
}

    get isSearchDisabled() {
    const phoneValid = !this.phone || /^[6-9][0-9]{9}$/.test(this.phone);
    const panValid = !this.pan || /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(this.pan);
    let dobValid = true;
    if (this.dob) {
        const today = new Date();
        const min18YearsAgo = new Date(today.getFullYear() - 18, today.getMonth(), today.getDate());
        dobValid = new Date(this.dob) <= min18YearsAgo;
    }

    // Button enabled only if at least one field is filled and all filled fields are valid
    const atLeastOneFilled = this.phone || this.pan || this.dob;
    return !(atLeastOneFilled && phoneValid && panValid && dobValid);
    }
    get isClearDisabled() {
        return !this.phone && !this.pan && !this.dob;
    }
    get disableDoubleClick() {
        return this.isSubmitting;
    }
    get isCreateDisabled() {
    return this.disableDoubleClick || this.isSearchDisabled;
    }
    get showSearchComponent() {
        return !this.showApplicantForm;
    }
    get hasAccounts() {
        return Array.isArray(this.accounts) && this.accounts.length > 0;
    }
    get noAccountsFound() {
        return this.hasSearched && (!this.accounts || this.accounts.length === 0);
    }
    get rowSelection() {
        return this.selectedAccountId ? [this.selectedAccountId] : [];
    }
    get hideCheckboxColumn() {
        return false;
    }

    get accountId() {
        return this.selectedAccountId;
    }

    get applicationId() {
        return this.recordId;
    }

    get searchParams() {
        return { phone: this.phone, pan: this.pan, dob: this.dob };
    }

    isIndividualPanInvalid(pan) {
        return pan && pan.length === 10 && pan.charAt(3) !== 'P';
    }


    handleRecordTypeChange(event) {
        this.selectedRecordType = event.detail.value;

        this.showPanInlineError = false;

        if (!this.pan) {
            return;
        }

        if (
            this.selectedRecordType === 'Individual' &&
            this.isIndividualPanInvalid(this.pan)
        ) {
            this.showPanInlineError = true;
        }
    }


    handleClearClick() {
        this.phone = '';
        this.pan = '';
        this.dob = null;

        // reset datatable results
        this.accounts = [];
        this.hasSearched = false;
        this.selectedAccountId = null;
        this.selectedAccount = null;
    }


    // --- Input handlers ---
    handleInputChange(event) {
    const { name, value } = event.target;
    if (name === 'phone') this.phone = value;
    else if (name === 'pan') this.pan = value;
    else if (name === 'dob') {
        this.dob = value;

        const dobInput = event.target;
        dobInput.setCustomValidity(''); 

        if (this.dob) {
            const dobDate = new Date(this.dob);
            const today = new Date();
            today.setHours(0,0,0,0);

            if (dobDate > today) {
                dobInput.setCustomValidity('Date of Birth cannot be in the future');
            } else {
                const min18 = new Date(today.getFullYear() - 18, today.getMonth(), today.getDate());
                if (dobDate > min18) {
                    dobInput.setCustomValidity('Applicant must be at least 18 years old');
                }
            }
        }
        dobInput.reportValidity(); 
    }
}


    // --- Search ---
    handleSearch() {
        if (!this.phone && !this.pan && !this.dob) {
            this.showMetadataToast('SEARCH_ERROR');
            return;
        }
        this._runSearch();
    }

    async _runSearch() {
        this.isLoading = true;
        this.hasSearched = false;
        this.accounts = [];
        this.selectedAccountId = null;
        this.selectedAccount = null;

        try {
            const result = await searchAccounts({ phone: this.phone, pan: this.pan, dob: this.dob || null, applicationId: this.applicationId });
            this.accounts = result.map(a => ({ ...a, Date_of_Birth__c: a.Date_of_Birth__c || null,
            isSelected: false 
            }));
            this.hasSearched = true;
        } catch (err) {
            console.error('searchAccounts error', err);
            this.showToast('Error', this._getErrorMessage(err), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleTileSelection(event) {
        const accId = event.target.dataset.id;

        this.accounts = this.accounts.map(acc => ({
            ...acc,
            isSelected: acc.Id === accId
        }));

        const selected = this.accounts.find(a => a.Id === accId);

        this.selectedAccount = selected;
        this.selectedAccountId = selected.Id;

        const custType = selected.Customer_Type__c;

        if (custType === 'Individual') {
            this.selectedRecordType = 'Individual';
            this.isRecordTypeDisabled = true;
        } else if (custType === 'Non-Individual') {
            this.selectedRecordType = 'Non_Individual';
            this.isRecordTypeDisabled = true;
        } else {
            this.selectedRecordType = null;
            this.isRecordTypeDisabled = false;
        }
    }



    handleCloseRecordTypeModal() {
        this.showRecordTypeModal = false;
        this.selectedRecordType = null;
        this.isRecordTypeDisabled = false;
        this.showPanInlineError = false;
    }

    handleProceedToApplicantForm() {
        if (!this.selectedRecordType) {
            this.showMetadataToast('RECORD_TYPE_REQUIRED');
            return;
        }
        this.showRecordTypeModal = false;
        this.showApplicantForm = true;
    }

    // --- Row selection ---
    handleRowSelection(event) {
    const selectedRows = event.detail.selectedRows;
    console.log('Row selection event:', selectedRows);

    if (selectedRows && selectedRows.length > 0) {
        this.selectedAccount = selectedRows[0];
        this.selectedAccountId = this.selectedAccount.Id;
        console.log('Selected Account Id:', this.selectedAccountId);
        console.log('Selected Account Customer_Type__c:', this.selectedAccount.Customer_Type__c);

        const custType = this.selectedAccount.Customer_Type__c;

        if (custType === 'Individual') {
            this.selectedRecordType = 'Individual';
            this.isRecordTypeDisabled = true;
            console.log('Record type set to Individual, disabled:', this.isRecordTypeDisabled);
        } else if (custType === 'Non-Individual') {
            this.selectedRecordType = 'Non_Individual';
            this.isRecordTypeDisabled = true;
            console.log('Record type set to Non-Individual, disabled:', this.isRecordTypeDisabled);
        } else {
            this.selectedRecordType = null;
            this.isRecordTypeDisabled = false;
            console.log('No Customer Type, record type enabled');
        }
    } else {
        // No selection
        this.selectedAccount = null;
        this.selectedAccountId = null;
        this.selectedRecordType = null;
        this.isRecordTypeDisabled = false;
        console.log('No account selected, record type enabled');
    }
}



    // --- Create New Applicant ---
    handleCreateNewApplicantClick() {
        this.isLoading = false;
        hasReachedCoApplicantLimit({ applicationId: this.applicationId })
            .then(limitReached => {
                if (limitReached) {
                    // Fetch message from Metadata
                    return getMessageFromMetadata({ recordDevName: 'Create_New_Applicant_Limit' })
                        .then(result => {
                            this.limitMessage = result.Message;
                            this.showLimitMessage = true;
                        });
                } else {
                    this.showRecordTypeModal = true; // Show record type modal
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error checking co-applicant limit:', error);
            });
    }

    handleCloseLimitMessage() {
        this.showLimitMessage = false;
        this.handleClearClick();
    }

    handleApplicantSaved() {
        this.showApplicantForm = false;
        this.dispatchEvent(new CustomEvent('applicantcreated', { bubbles: true }));
    }

    handleBackToAccount() {
        this.showApplicantForm = true;
    }

    // --- Helpers ---
    _getErrorMessage(err) {
        if (!err) return 'Unknown error';
        if (err.body && err.body.message) return err.body.message;
        if (err.message) return err.message;
        return JSON.stringify(err);
    }

    handleCloseModal() {
        this.showApplicantForm = false;
    }

    handlePreviousStep() {
        this.showApplicantForm = false;
        this.showRecordTypeModal = true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Fetch message from metadata and show toast
    showMetadataToast(recordDevName) {
        getMessageFromMetadata({ recordDevName })
            .then(res => {
                const variant = res.MessageType?.toLowerCase() === 'error' ? 'error' :
                    res.MessageType?.toLowerCase() === 'success' ? 'success' :
                        'info';
                this.showToast(res.MessageType || variant, res.Message || 'Message not found', variant);
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }


}