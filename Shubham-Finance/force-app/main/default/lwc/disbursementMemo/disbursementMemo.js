import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getDisbursementData from '@salesforce/apex/DisbursementMemoController.getDisbursementData';
import saveDisbursement from '@salesforce/apex/DisbursementMemoController.saveDisbursement';
import deletePayeeDetail from '@salesforce/apex/DisbursementMemoController.deletePayeeDetail';
import getChequeMasters from '@salesforce/apex/DisbursementMemoController.getChequeMasters';
import getBankMasters from '@salesforce/apex/DisbursementMemoController.getBankMasters';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import FEES_OBJECT from '@salesforce/schema/Fees__c';
import FEE_TYPE_FIELD from '@salesforce/schema/Fees__c.Fee_Type__c';
import STATUS_FIELD from '@salesforce/schema/Fees__c.Status__c';
import CHARGE_SUB_TYPE_FIELD from '@salesforce/schema/Fees__c.Charge_Sub_Type__c';

export default class DisbursementMemo extends LightningElement {
    @api recordId;
    @track applicationId;
    @track application = {};
    @track disbursement = {
        sobjectType: 'Disbursement__c'
    };
    @track payeeDetails = [];
    @track feeDetails = [];
    @track primaryApplicantPayee = {
        sobjectType: 'Payee_Details__c',
        Payment_Amount__c: 0,
        Account_Number__c: '',
        InFavourOf__c: ''
    };
    @track isLoading = false;
    @track primaryApplicantName = '';
    @track processingFee = 0;
    @track constructionCost = 'Hardcoded for now';
    @track chequeOptions = [];
    @track disbursementBankOptions = [];
    @track customerBankOptions = [];
    @track feeTypeOptions = [];
    @track feeStatusOptions = [];
    @track chargeSubTypeOptions = [];

    paymentModeOptions = [
        { label: 'Cheque', value: 'Cheque' },
        { label: 'NEFT', value: 'NEFT' },
        { label: 'RTGS', value: 'RTGS' }
    ];

    dealingDisbursementFilter = {
        criteria: [
            {
                fieldPath: "RecordType.DeveloperName",
                operator: "eq",
                value: "Dealing_Disbursement_Bank_Master",
            },
        ]
    };

    nonDealingDisbursementFilter = {
        criteria: [
            {
                fieldPath: "RecordType.DeveloperName",
                operator: "eq",
                value: "Bank_Master",
            },
        ]
    };

    @wire(getObjectInfo, { objectApiName: FEES_OBJECT })
    feesObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$feesObjectInfo.data.defaultRecordTypeId', fieldApiName: FEE_TYPE_FIELD })
    wiredFeeTypeOptions({ error, data }) {
        if (data) {
            this.feeTypeOptions = data.values;
        } else if (error) {
            console.error('Error fetching fee type picklist', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$feesObjectInfo.data.defaultRecordTypeId', fieldApiName: CHARGE_SUB_TYPE_FIELD })
    wiredChargeSubTypeOptions({ error, data }) {
        if (data) {
            this.chargeSubTypeOptions = data.values;
        } else if (error) {
            console.error('Error fetching charge sub type picklist', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$feesObjectInfo.data.defaultRecordTypeId', fieldApiName: STATUS_FIELD })
    wiredFeeStatusOptions({ error, data }) {
        if (data) {
            this.feeStatusOptions = data.values;
        } else if (error) {
            console.error('Error fetching fee status picklist', error);
        }
    }

    get programName() {
        return this.application?.Product__r?.Name || '';
    }

    get chequeFilter() {
        return {
            criteria: [
                {
                    fieldPath: 'Status__c',
                    operator: 'eq',
                    value: 'Available'
                },
                {
                    fieldPath: 'Hub_Region__c',
                    operator: 'eq',
                    value: this.application?.BranchName || ''
                }
            ]
        };
    }

    get tenureInYears() {
        if (this.application && this.application.Tenure__c) {
            return (this.application.Tenure__c / 12).toFixed(1);
        }
        return 0;
    }

    get tenureInMonths() {
        if (this.application && this.application.Tenure__c != null) {
            return parseFloat(this.application.Tenure__c).toFixed(1);
        }
        return '0.0';
    }


    connectedCallback() {
        this.fetchData();
        this.loadBankMasters();
    }

    fetchData() {
        this.isLoading = true;
        getDisbursementData({ disbursementId: this.recordId })
            .then(result => {
                this.application = result.application || {};
                this.applicationId = this.application.Id;
                if (this.application.Branch__r) {
                     this.application.BranchName = this.application.Branch__r.Name;
                     this.loadChequeMasters(this.application.BranchName);
                }
                
                this.disbursement = result.disbursement || { sobjectType: 'Disbursement__c' };
                this.primaryApplicantName = result.primaryApplicantName || '';
                this.processingFee = result.processingFee || 0;
                this.currentUserName = result.currentUserName;
                this.currentUserEmployeeNumber = result.currentUserEmployeeNumber;
                
                const allPayees = result.payeeDetails || [];

                if (allPayees.length > 0) {
                    this.payeeDetails = allPayees.map((item, index) => ({
                        ...item, 
                        key: item.Id || Date.now(),
                        sNo: index + 1,
                        isCheque: item.TypeOfPaymentMode__c === 'Cheque',
                        Instrument_Number__c: item.Instrument_Number__c || null,
                        Customer_Bank__c: item.Customer_Bank__c || null
                    }));
                } else {
                    this.payeeDetails = [];
                }

                this.primaryApplicantPayee = {
                    sobjectType: 'Payee_Details__c',
                    Payment_Amount__c: 0,
                    Account_Number__c: '',
                    InFavourOf__c: this.primaryApplicantName
                };

                if (result.feeDetails && result.feeDetails.length > 0) {
                    this.feeDetails = result.feeDetails.map((item, index) => ({
                        ...item,
                        key: item.Id || Date.now(),
                        sNo: index + 1
                    }));
                } else {
                    this.feeDetails = [];
                }
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.showToast('Error', 'Error loading data: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadChequeMasters(branchName) {
        getChequeMasters({ branchName: branchName })
            .then(result => {
                if (result) {
                    this.chequeOptions = result.map(record => ({
                        label: record.Name,
                        value: record.Id 
                    }));
                }
            })
            .catch(error => {
                console.error('Error fetching cheque masters', error);
            });
    }

    loadBankMasters() {
        // Fetch Dealing Disbursement Banks (For Header)
        getBankMasters({ isDealingBank: true })
            .then(result => {
                if (result) {
                    this.disbursementBankOptions = result.map(record => ({
                        label: record.Name,
                        value: record.Id 
                    }));
                }
            })
            .catch(error => {
                console.error('Error fetching dealing banks', error);
            });

        // Fetch Customer Banks (For Payee Rows)
        getBankMasters({ isDealingBank: false })
            .then(result => {
                if (result) {
                    this.customerBankOptions = result.map(record => ({
                        label: record.Name,
                        value: record.Id 
                    }));
                }
            })
            .catch(error => {
                console.error('Error fetching customer banks', error);
            });
    }

    createEmptyPayeeRow() {
        return {
            key: Date.now(), 
            sobjectType: 'Payee_Details__c',
            DisbursalAmount__c: 0,
            TypeOfPaymentMode__c: '',
            Instrument_Number__c: null,
            InFavourOf__c: '',
            BeneficiaryAccountNumber__c: '',
            Customer_Bank__c: null,
            isCheque: false,
            sNo: this.payeeDetails.length + 1
        };
    }

    createEmptyFeeRow() {
        return {
            key: Date.now(),
            sobjectType: 'Fees__c',
            Fee_Type__c: '',
            Status__c: '',
            Amount__c: 0,
            Tax__c: 0, // Default to 0? Or '' if text? Assuming Number/Currency
            Charge_Sub_Type__c: '',
            Application__c: this.applicationId,
            sNo: this.feeDetails.length + 1
        };
    }

    handleAddRow() {
        this.payeeDetails = [...this.payeeDetails, this.createEmptyPayeeRow()];
    }

    handleAddFeeRow() {
        this.feeDetails = [...this.feeDetails, this.createEmptyFeeRow()];
    }

    handleRemoveRow(event) {
        const index = parseInt(event.target.dataset.index);
        const row = this.payeeDetails[index];

        if (row && row.Id) {
            // Saved record: call Apex to delete and release cheque
            this.isLoading = true;
            deletePayeeDetail({ payeeDetailId: row.Id })
                .then(() => {
                    this.showToast('Success', 'Payee detail deleted successfully', 'success');
                    this.fetchData(); // Refresh all data including cheque options
                })
                .catch(error => {
                    this.showToast('Error', error.body?.message || 'Error deleting payee detail', 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            // Unsaved row: just remove from local array
            this.payeeDetails.splice(index, 1);
            this.payeeDetails = this.payeeDetails.map((item, idx) => ({ ...item, sNo: idx + 1 }));
        }
    }

    handleRemoveFeeRow(event) {
        const index = event.target.dataset.index;
        this.feeDetails.splice(index, 1);
        this.feeDetails = this.feeDetails.map((item, idx) => ({ ...item, sNo: idx + 1 }));
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const index = event.target.dataset.index;
        // Use event.detail.value for LWC components (input, combobox, input-field)
        // Fallback to event.target.value just in case
        let value = event.detail.value;
        if (event.detail.recordId !== undefined) {
             value = event.detail.recordId;
        } else if (value === undefined && event.target.value !== undefined) {
            value = event.target.value;
        }
        // For lightning-input-field lookup, value might be array, but record-picker gives string or null
        if (Array.isArray(value)) value = value[0]; 

        if (index !== undefined) {
            let row = { ...this.payeeDetails[index] };
            row[field] = value;
            
            if (field === 'TypeOfPaymentMode__c') {
                row.isCheque = value === 'Cheque';
                // Reset cheque number if not cheque? Optional.
                if (!row.isCheque) row.Instrument_Number__c = null;
            }

            this.payeeDetails = [
                ...this.payeeDetails.slice(0, parseInt(index)),
                row,
                ...this.payeeDetails.slice(parseInt(index) + 1)
            ];

            if (field === 'DisbursalAmount__c') {
                // Trigger reactivity if needed, getter will handle it
            }
        } else {
            this.disbursement[field] = value;
        }
    }

    handleFeeInputChange(event) {
        const field = event.target.dataset.field;
        const index = event.target.dataset.index;
        let value = event.detail.value;
        if (value === undefined && event.target.value !== undefined) {
            value = event.target.value;
        }

        let row = { ...this.feeDetails[index] };
        row[field] = value;
        
        this.feeDetails = [
            ...this.feeDetails.slice(0, parseInt(index)),
            row,
            ...this.feeDetails.slice(parseInt(index) + 1)
        ];
    }

    handlePrimaryApplicantChange(event) {
        // Since fields are read-only, this handler might not be needed for Amount/Name/Account but keep for now in case logic changes
        // Or remove if purely read-only. But user might want to edit Account Number? 
        // User said "primary applicant details shoule be read only (all three columns)".
        // So no handler needed really. But let's leave it no-op or just log.
    }

    get primaryApplicantAmount() {
        return parseFloat(this.disbursement.Actual_Payment_Amount__c) || 0;
    }

    get totalDisbursalAmount() {
        const payeesTotal = this.payeeDetails.reduce((sum, item) => sum + (parseFloat(item.DisbursalAmount__c) || 0), 0);
        const feesTotal = this.feeDetails.reduce((sum, item) => sum + (parseFloat(item.Amount__c) || 0), 0);
        const primaryTotal = this.primaryApplicantAmount;
        
        return (payeesTotal + primaryTotal - feesTotal).toFixed(2);
    }
    
    // Getter to ensure field values are reflected in the view if needed
    // But @track should handle it.

    handleSave() {
        this.isLoading = true;
        

        // Clean up keys/UI props before sending to Apex
        const cleanPayees = this.payeeDetails.map(item => {
            const { key, sNo, isCheque, ...rest } = item;
            return rest;
        });

        saveDisbursement({ 
            disbursement: this.disbursement, 
            payeeDetails: cleanPayees,
            feeDetails: [] 
        })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Disbursement Memo saved successfully',
                        variant: 'success'
                    })
                );
                // Refresh data
                this.fetchData();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title, message, variant
        }));
    }
}