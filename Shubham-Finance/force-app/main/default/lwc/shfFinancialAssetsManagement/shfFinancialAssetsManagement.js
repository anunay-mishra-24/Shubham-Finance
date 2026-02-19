import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAssets from '@salesforce/apex/SHF_FinancialSheetController.getAssets';
import saveAssets from '@salesforce/apex/SHF_FinancialSheetController.saveAssets';

export default class ShfFinancialAssetsManagement extends LightningElement {
    @api recordId;
    @api loanApplicantId;

    @track rows = [];
    @track deletedRowIds = [];

    @track isDeleteModalOpen = false;
    rowToDeleteId = null;
    
    isLoading = false;

    get typeOptions() {
    return [
        { label: 'Agriculture Land', value: 'Agriculture Land' },
        { label: 'Car', value: 'Car' },
        { label: 'Fixed Deposits', value: 'Fixed Deposits' },
        { label: 'Flat', value: 'Flat' },
        { label: 'Furniture', value: 'Furniture' },
        { label: 'House', value: 'House' },
        { label: 'Jewellery', value: 'Jewellery' },
        { label: 'Land', value: 'Land' },
        { label: 'Lease Land', value: 'Lease Land' },
        { label: 'Life Insurance', value: 'Life Insurance' },
        { label: 'Mutual Funds', value: 'Mutual Funds' },
        { label: 'Recurring Deposit Account', value: 'Recurring Deposit Account' },
        { label: 'Savings Account', value: 'Savings Account' },
        { label: 'Scooter', value: 'Scooter' },
        { label: 'Shares', value: 'Shares' }
    ];
}


    get categoryOptions() {
    return [
        { label: 'Accounts', value: 'Accounts' },
        { label: 'Agriculture Land', value: 'Agriculture Land' },
        { label: 'Investments/Shares', value: 'Investments/Shares' },
        { label: 'Motor Vehicles', value: 'Motor Vehicles' },
        { label: 'Other Assets', value: 'Other Assets' },
        { label: 'Real Asset', value: 'Real Asset' },
        { label: 'Real Estate Assets', value: 'Real Estate Assets' }
    ];
}


    connectedCallback() {
        this.loadData();
    }

    loadData() {
        this.isLoading = true;
        getAssets({ loanApplicantId: this.loanApplicantId })
            .then(data => {
                this.rows = data.map((item, index) => ({
                    ...item,
                    tempId: item.Id || `new-${index}`,
                    isNew: false
                }));
                
                if (this.rows.length === 0) {
                    this.handleAddRow();
                }
            })
            .catch(error => {
                console.error('Error loading assets', error);
                this.showToast('Error', 'Error loading assets', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleAddRow() {
        const newRow = {
            tempId: `new-${Date.now()}`,
            Name: '',
            Asset_Type__c: '',
            Category__c: '',
            Asset_Type_Description__c: '', 
            Asset_Value__c: 0,
            isNew: true
        };
        this.rows = [...this.rows, newRow];
    }

    openDeleteModal(event) {
        this.rowToDeleteId = event.target.dataset.id;
        this.isDeleteModalOpen = true;
    }

    closeDeleteModal() {
        this.isDeleteModalOpen = false;
        this.rowToDeleteId = null;
    }

    confirmDelete() {
        if (this.rowToDeleteId) {
            const rowIndex = this.rows.findIndex(row => row.tempId === this.rowToDeleteId);
            
            if (rowIndex !== -1) {
                const row = this.rows[rowIndex];
                if (!row.isNew && row.Id) {
                    this.deletedRowIds.push(row.Id);
                }
                this.rows.splice(rowIndex, 1);
                this.rows = [...this.rows]; 
            }
        }
        this.closeDeleteModal();
    }

    /** handleDeleteRow(event) {
        const rowId = event.target.dataset.id;
        const rowIndex = this.rows.findIndex(row => row.tempId === rowId);
        
        if (rowIndex !== -1) {
            const row = this.rows[rowIndex];
            if (!row.isNew && row.Id) {
                this.deletedRowIds.push(row.Id);
            }
            this.rows.splice(rowIndex, 1);
            this.rows = [...this.rows]; 
        }
    } **/

    handleInputChange(event) {
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        let value = event.target.value;

        if (field === 'Asset_Value__c') {
            const numericValue = Number(value);
            
            if (numericValue < 0) {
                // 1. Show a warning toast
                this.showToast('Warning', 'Asset Value cannot be negative. Resetting to 0.', 'warning');
                
                // 2. Force the value to 0
                value = 0;
                
                // 3. Update the UI input field directly to reflect the reset
                event.target.value = 0;
            } else {
                value = numericValue;
            }
        }

        const row = this.rows.find(r => r.tempId === rowId);
        if (row) {
            row[field] = value;
        }
    }

    handleSave() {
        // Basic Validation: Check for empty required fields
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            this.showToast('Error', 'Please fill all required fields.', 'error');
            return;
        }

        this.isLoading = true;
        
        const assetsToSave = this.rows.map(row => {
            const cleanRow = {
                sobjectType: 'Assets__c', // UPDATED Object API Name
                Name: row.Name,
                Asset_Type__c: row.Asset_Type__c,
                Category__c: row.Category__c,
                Asset_Type_Description__c: row.Asset_Type_Description__c, // UPDATED Field API Name
                Asset_Value__c: row.Asset_Value__c
            };
            if (row.Id) cleanRow.Id = row.Id;
            return cleanRow;
        });

        saveAssets({ 
            assetsToSave: assetsToSave, 
            assetIdsToDelete: this.deletedRowIds,
            loanApplicantId: this.loanApplicantId 
        })
        .then(() => {
            this.showToast('Success', 'Assets saved successfully', 'success');
            this.deletedRowIds = []; 
            this.loadData(); 
        })
        .catch(error => {
            console.error('Error saving', error);
            this.showToast('Error', error.body?.message || 'Error saving assets', 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}