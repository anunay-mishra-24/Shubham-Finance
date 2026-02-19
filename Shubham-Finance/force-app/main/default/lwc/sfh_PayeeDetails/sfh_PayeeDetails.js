import { LightningElement, track, api, wire } from 'lwc';
import createPayee from '@salesforce/apex/PayeeController.createPayee';
import updatePayee from '@salesforce/apex/PayeeController.updatePayee';
import softDeletePayee from '@salesforce/apex/PayeeController.softDeletePayee';
import getPayeeList from '@salesforce/apex/PayeeController.getPayeeList';
import getDataToLoad from '@salesforce/apex/PayeeController.getDataToLoad';
import getBankDetails from '@salesforce/apex/PayeeController.getBankDetails';
import getApplicants from '@salesforce/apex/PayeeController.getApplicants';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import LightningConfirm from 'lightning/confirm';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';


import DISB_APPLICATION from '@salesforce/schema/Disbursement__c.Application__c';
import DISB_STATUS from '@salesforce/schema/Disbursement__c.Status__c';
import APP_STAGE from '@salesforce/schema/Disbursement__c.Application__r.Application_Stage__c';

const FIELDS = [DISB_APPLICATION, DISB_STATUS, APP_STAGE];

export default class Sfh_PayeeDetails extends LightningElement {
    @api recordId; // Disbursement Id

    @track showModal = false;
    @track applicantOptions = [];
    @track payeeDetailList = [];
    @track containerClass = '';

    applicationId;
    applicationStage;
    disbursementStatus;

    isLoading = false;

    maxDisbursementAmount = null;
    originalEditDisbursalAmount = 0; 
    isFormDisabled = false;


    get isEditDeleteEnabled() {
        console.log('isEditDeleteEnabled', this.isFormDisabled ,'status', this.disbursementStatus );
        return !this.isFormDisabled && this.disbursementStatus === 'Tranche Request Initiation';
    }

    selectedPayeeId;
    selectedPayeeRow;
    isEdit = false;

    showApplicantDropdown = false;
    showApplicantText = false;

    isEFT = false;
    isCheque = false;

    payeeWrapper = this.getEmptyWrapper();

    bankName = '';
    branchName = '';

    initColumns(){ this.columns = [
        {
            label: 'Payee Id',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        { label: 'Business Partner Type/ Applicant Type', fieldName: 'BusinessPartnerTypeApplicantType__c' },
        { label: 'Business Partner Name/ Applicant Name', fieldName: 'BusinessPartnerNameApplicantName__c' },
        { label: 'Payment Mode', fieldName: 'TypeOfPaymentMode__c' },
        { label: 'Disbursal Amount', fieldName: 'DisbursalAmount__c', type: 'currency' },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions.bind(this) }
        }
    ];
    }

    getRowActions = (row, doneCallback) => {
      
        const disabled = !this.isEditDeleteEnabled;
        doneCallback([
            { label: 'Edit', name: 'edit', disabled },
            { label: 'Delete', name: 'delete', disabled }
        ]);
    };

    applicantTypeOptions = [
        { label: 'Primary Applicant', value: 'Primary Applicant' },
        { label: 'Co applicant', value: 'Co applicant' },
        { label: 'Others', value: 'Others' }
    ];

    paymentModeOptions = [
        { label: 'Cheque', value: 'Cheque' },
        { label: 'EFT', value: 'EFT' }
    ];

    subPaymentModeOptions = [
        { label: 'NEFT', value: 'NEFT' },
        { label: 'RTGS', value: 'RTGS' }
    ];

    beneficiaryAccountTypeOptions = [
        { label: 'Current Account', value: 'Current Account' },
        { label: 'Saving Account', value: 'Saving Account' },
        { label: 'Cash Credit', value: 'Cash Credit' },
        { label: 'OverDraft', value: 'OverDraft' }
    ];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (data) {
            this.applicationId = getFieldValue(data, DISB_APPLICATION);
            this.disbursementStatus = getFieldValue(data, DISB_STATUS);
            this.applicationStage = getFieldValue(data, APP_STAGE);

            this.isFormDisabled = (this.applicationStage === 'Disbursement Maker');
            this.containerClass = this.isFormDisabled ? 'read-only-container' : '';

            this.loadPayees();
        } else if (error) {

            console.error('wiredRecord error', error);
        }
    }

    connectedCallback() {
        this.initColumns();
    }
    loadPayees() {
        this.isLoading = true;
        getPayeeList({ disbursementId: this.recordId })
            .then(result => {
                this.payeeDetailList = (result || []).map(row => ({
                    ...row,
                    recordUrl: '/' + row.Id,
                    Name: row.Name ? row.Name : row.Id
                }));
            })
            .catch(error => {
                console.error('getPayeeList error', error);
                this.showToast('Error', 'Failed to load payee list', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }


    openAddModal = () => {
        if (this.isFormDisabled) return;

        this.isEdit = false;
        this.selectedPayeeId = null;
        this.selectedPayeeRow = null;
        this.originalEditDisbursalAmount = 0; 
        this.resetModalState();
        this.openModalInternal(true);
    };
    getCurrentPayeeSum() {
    // payeeDetailList already excludes Is_Deleted__c if selector filter is applied
    return (this.payeeDetailList || []).reduce((sum, r) => {
        const v = Number(r.DisbursalAmount__c);
        return sum + (Number.isFinite(v) ? v : 0);
    }, 0);
}

validateTotalDisbursal(inputEl) {
    const max = Number(this.maxDisbursementAmount);
    const newVal = Number(this.payeeWrapper.disbursalAmount);

    const total = this.getCurrentPayeeSum();
    const oldVal = this.isEdit ? (Number(this.originalEditDisbursalAmount) || 0) : 0;

    const base = total - oldVal;                  // sum excluding current row in edit
    const proposed = base + (Number.isFinite(newVal) ? newVal : 0);

    if (!Number.isFinite(max)) {
        inputEl.setCustomValidity('');
        inputEl.reportValidity();
        return true;
    }

    
    if (Number.isFinite(newVal) && newVal > max) {
        inputEl.setCustomValidity(`Disbursal Amount cannot exceed ${max}.`);
        inputEl.reportValidity();
        return false;
    }

    if (proposed > max) {
        const remaining = max - base; 
        inputEl.setCustomValidity(
            `Total Payee Disbursal Amount cannot exceed ${max}. Remaining allowed for this payee: ${remaining}.`
        );
        inputEl.reportValidity();
        return false;
    }

    inputEl.setCustomValidity('');
    inputEl.reportValidity();
    return true;
}

    openEditModal(row) {
        if (!this.isEditDeleteEnabled) {
            this.showToast('Info', "Edit/Delete allowed only when Status is 'Tranche Request Initiation'", 'info');
            return;
        }
        this.isEdit = true;
        this.selectedPayeeId = row.Id;
        this.selectedPayeeRow = row;
        this.originalEditDisbursalAmount = Number(row.DisbursalAmount__c) || 0;

    this.resetModalState();
        this.resetModalState();
        this.openModalInternal(false);
    }

    openModalInternal(resetManualFields) {
        this.isLoading = true;
        getDataToLoad({ disbursementId: this.recordId, applicationId: this.applicationId })
            .then(res => {

                this.autoFetchPayeeData(res, resetManualFields);


                if (this.isEdit && this.selectedPayeeRow) {
                    this.populateFromRow(this.selectedPayeeRow);
                }

                this.showModal = true;
            })
            .catch(err => {
                console.error('getDataToLoad error', err);
                this.showModal = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    autoFetchPayeeData(p, resetManualFields) {
        if (!p) return;

        this.maxDisbursementAmount = (p.disbursalAmount ?? null);
        this.payeeWrapper.disbursalAmount = (p.disbursalAmount ?? null);
        this.payeeWrapper.adjustmentAmount = p.adjustmentAmount ?? null;
        this.payeeWrapper.paymentAmount = p.paymentAmount ?? null;
        this.payeeWrapper.effectivePaymentDate = p.effectivePaymentDate ?? null;
        this.payeeWrapper.instrumentDate = p.instrumentDate ?? null;
        this.payeeWrapper.printingBranch = p.printingBranch ?? null;

        if (resetManualFields) {
            this.maxDisbursementAmount = (p.disbursalAmount ?? null);
            this.payeeWrapper.applicantType = '';
            this.payeeWrapper.applicantName = '';
            this.payeeWrapper.typeOfPaymentMode = '';
            this.payeeWrapper.payeeName = '';
            this.payeeWrapper.customerBank = '';
            this.payeeWrapper.accountNumber = '';
            this.payeeWrapper.inFavourOf = '';
            this.payeeWrapper.instrumentNumber = '';
            this.payeeWrapper.bankValidationStatus = '';

            this.payeeWrapper.subPaymentMode = '';
            this.payeeWrapper.beneficiaryName = '';
            this.payeeWrapper.beneficiaryAccountType = '';
            this.payeeWrapper.beneficiaryAccountNumber = '';
            this.payeeWrapper.ifscCode = '';

            this.bankName = '';
            this.branchName = '';
        }

        this.payeeWrapper = { ...this.payeeWrapper };
    }

    populateFromRow(row) {
        this.payeeWrapper = {
            ...this.payeeWrapper,
            applicantType: row.BusinessPartnerTypeApplicantType__c || '',
            applicantName: row.BusinessPartnerNameApplicantName__c || '',
            disbursalAmount: row.DisbursalAmount__c ?? this.payeeWrapper.disbursalAmount,
            adjustmentAmount: row.AdjustmentAmount__c ?? this.payeeWrapper.adjustmentAmount,
            paymentAmount: row.Payment_Amount__c ?? this.payeeWrapper.paymentAmount,
            effectivePaymentDate: row.EffectivePaymentDate__c ?? this.payeeWrapper.effectivePaymentDate,

            typeOfPaymentMode: row.TypeOfPaymentMode__c || '',
            payeeName: row.Payee_Name__c || row.BusinessPartnerNameApplicantName__c || '',
            customerBank: row.Customer_Bank__c || '',
            accountNumber: row.Account_Number__c || '',
            inFavourOf: row.InFavourOf__c || '',
            instrumentNumber: row.Instrument_Number__c || '',
            instrumentDate: row.InstrumentDate__c ?? this.payeeWrapper.instrumentDate,
            printingBranch: row.Printing_Branch__c ?? this.payeeWrapper.printingBranch,
            bankValidationStatus: row.BankValidationStatus__c || '',


            subPaymentMode: row.SubPaymentMode__c || '',
            beneficiaryName: row.BeneficiaryName__c || '',
            beneficiaryAccountType: row.BeneficiaryAccountType__c || '',
            beneficiaryAccountNumber: row.BeneficiaryAccountNumber__c != null ? String(row.BeneficiaryAccountNumber__c) : '',
            ifscCode: row.IFSC_Code__c || ''
        };


        this.isCheque = this.payeeWrapper.typeOfPaymentMode === 'Cheque';
        this.isEFT = this.payeeWrapper.typeOfPaymentMode === 'EFT';


        this.applyApplicantUiForEdit();


        if (this.isEFT && this.payeeWrapper.ifscCode) {
            getBankDetails({ bankId: this.payeeWrapper.ifscCode })
                .then(res => {
                    this.bankName = res?.Name || '';
                    this.branchName = res?.Branch_name__c || '';
                })
                .catch(e => console.error(e));
        }
    }

    applyApplicantUiForEdit() {
        const type = this.payeeWrapper.applicantType;

        if (type === 'Others') {
            this.showApplicantText = true;
            this.showApplicantDropdown = false;
            this.payeeWrapper = { ...this.payeeWrapper };
            return;
        }

        this.showApplicantDropdown = true;
        this.showApplicantText = false;


        getApplicants({ applicantType: type, applicationId: this.applicationId })
            .then(result => {
                const selected = this.payeeWrapper.applicantName;
                const opts = (result || []).map(i => ({ label: i.Account_Name__c, value: i.Account_Name__c }));
                if (selected && !opts.some(o => o.value === selected)) {
                    opts.unshift({ label: selected, value: selected });
                }
                this.applicantOptions = opts;
                this.payeeWrapper = { ...this.payeeWrapper };
            })
            .catch(e => console.error(e));
    }


    closeModal() {
        this.showModal = false;
        this.isEdit = false;
        this.selectedPayeeId = null;
        this.selectedPayeeRow = null;
        this.resetModalState();
        this.payeeWrapper = this.getEmptyWrapper();
    }

    resetModalState() {
        this.isCheque = false;
        this.isEFT = false;
        this.showApplicantDropdown = false;
        this.showApplicantText = false;
        this.applicantOptions = [];
        this.bankName = '';
        this.branchName = '';
    }


    handleChange(event) {
        const field = event.target.dataset.id;
        if (!field) return;

        let value = event.target.value;


        if (event.target.type === 'number') {
            value = (value === '' || value === null || value === undefined) ? null : Number(value);
        }

        this.payeeWrapper[field] = value;
        if (field === 'disbursalAmount') {
        this.validateTotalDisbursal(event.target);
    }

         if (field === 'applicantName') {
            this.payeeWrapper.payeeName = value;
             this.payeeWrapper.accountNumber = '';
              this.payeeWrapper.inFavourOf = '';
        }


        if (field === 'accountNumber') {
            const name = this.payeeWrapper.applicantName || '';
            this.payeeWrapper.inFavourOf = name ? `${name} A/C ${value || ''}` : `A/C ${value || ''}`;
        }

        this.payeeWrapper = { ...this.payeeWrapper };
    }

    handleApplicantTypeChange(event) {
        const type = event.detail.value;
        this.payeeWrapper.applicantType = type;

        if (type === 'Others') {
            this.showApplicantText = true;
            this.showApplicantDropdown = false;
            this.applicantOptions = [];
            this.payeeWrapper.applicantName = '';
            this.payeeWrapper = { ...this.payeeWrapper };
            return;
        }

        this.showApplicantDropdown = true;
        this.showApplicantText = false;

        getApplicants({ applicantType: type, applicationId: this.applicationId })
            .then(result => {
                this.applicantOptions = (result || []).map(item => ({
                    label: item.Account_Name__c,
                    value: item.Account_Name__c
                }));
            })
            .catch(e => console.error(e));
    }

    handlePaymentModeChange(event) {
        const paymentMode = event.detail.value;
        this.payeeWrapper.typeOfPaymentMode = paymentMode;

        this.isCheque = (paymentMode === 'Cheque');
        this.isEFT = (paymentMode === 'EFT');

        this.payeeWrapper = { ...this.payeeWrapper };
    }


    bankDisplayInfo = { primaryField: 'Name', additionalFields: ['IFSC_code__c'] };
    bankMatchingInfo = { primaryField: { fieldPath: 'Name' }, additionalFields: [{ fieldPath: 'IFSC_code__c' }] };

    bankFilter = {
        criteria: [{ fieldPath: 'RecordType.Name', operator: 'eq', value: 'Bank Master' }]
    };

    handleBankChange(event) {
        const bankId = event.detail.recordId;
        const fieldName = event.target.dataset.id;

        if (fieldName === 'customeBank') {
            this.payeeWrapper.customerBank = bankId;
        } else if (fieldName === 'ifscCode') {
            this.payeeWrapper.ifscCode = bankId;

            if (bankId) {
                getBankDetails({ bankId })
                    .then(res => {
                        this.bankName = res?.Name || '';
                        this.branchName = res?.Branch_name__c || '';
                    })
                    .catch(error => console.error('getBankDetails error', error));
            } else {
                this.bankName = '';
                this.branchName = '';
            }
        }

        this.payeeWrapper = { ...this.payeeWrapper };
    }


    instrumentDisplayInfo = { primaryField: 'Name', additionalFields: ['Hub_Region__c'] };
    instrumentMatchingInfo = { primaryField: { fieldPath: 'Name' }, additionalFields: [{ fieldPath: 'Hub_Region__c' }] };

    handleInstrumentNumber(event) {
        const chequeId = event.detail.recordId;
        this.payeeWrapper.instrumentNumber = chequeId;
        this.payeeWrapper = { ...this.payeeWrapper };
    }


    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'edit') {
            this.openEditModal(row);
        } else if (actionName === 'delete') {
            this.deletePayee(row.Id);
        }
    }

    async deletePayee(payeeId) {
        if (!this.isEditDeleteEnabled) {
            this.showToast('Info', "Delete allowed only when Status is 'Tranche Request Initiation'", 'info');
            return;
        }

        const ok = await LightningConfirm.open({
            message: 'Are you sure you want to delete this payee? (Soft delete)',
            variant: 'header',
            label: 'Confirm Delete'
        });

        if (!ok) return;

        this.isLoading = true;
        softDeletePayee({ payeeId })
            .then(() => {
                this.showToast('Success', 'Payee deleted (soft delete)', 'success');
                return this.loadPayees();
            })
            .catch(err => {
                console.error('softDeletePayee error', err);
                this.showToast('Error', 'Delete failed', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }


    savePayee() {
        let isValid = true;
        
        const disbInput = this.template.querySelector('lightning-input[data-id="disbursalAmount"]');
        const allInputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        console.error('All input elements', allInputs);
        allInputs.forEach(el => {
            if (!el.checkValidity()) {
                el.reportValidity();
                isValid = false;
            }
            
        });
        console.error('Input validity', isValid);
        if (disbInput && !this.validateTotalDisbursal(disbInput)) {
          
        this.showToast('Error', 'Please correct Disbursal Amount before saving.', 'error');
        return;
    }

    console.error('All inputs valid:', isValid);
        console.error('isCheque', this.isCheque);
        console.error('isEFT', this.isEFT);
        if (this.isCheque) {
            if (!this.payeeWrapper.customerBank) isValid = false;
            if (!this.payeeWrapper.instrumentNumber) isValid = false;
        }
        if (this.isEFT) {
            if (!this.payeeWrapper.ifscCode) isValid = false;
        }

        if (!isValid) {
            this.showToast('Error', 'Please fill all mandatory fields', 'error');
            return;
        }

        const wrapperToSend = { ...this.payeeWrapper };
        console.error('Wrapper to send', wrapperToSend);

        Object.keys(wrapperToSend).forEach(k => {
            if (wrapperToSend[k] === '') wrapperToSend[k] = null;
        });

        this.isLoading = true;

        const action = this.isEdit
            ? updatePayee({ wrap: wrapperToSend, payeeId: this.selectedPayeeId })
            : createPayee({ wrap: wrapperToSend, applicationId: this.applicationId, disbursementId: this.recordId });
            console.error('Apex action promise', action);

        action
            .then(() => {
                console.error(this.isEdit ? 'Payee updated' : 'Payee created');
                this.showToast('Success', this.isEdit ? 'Payee Updated' : 'Payee Created', 'success');
                this.closeModal();
                return this.loadPayees();
            })
            .catch(err => {
                const msg = err?.body?.message || err?.message || 'Unknown error';
                this.showToast('Error', msg, 'error');
            })
            .finally(() => {
                this.loadPayees();
                this.isLoading = false;
            });
    }


    getEmptyWrapper() {
        return {
            applicantType: '',
            applicantName: '',
            disbursalAmount: null,
            adjustmentAmount: null,
            paymentAmount: null,
            subPaymentMode: '',
            typeOfPaymentMode: '',
            effectivePaymentDate: null,
            payeeName: '',
            customerBank: '',
            accountNumber: '',
            inFavourOf: '',
            instrumentNumber: '',
            instrumentDate: null,
            printingBranch: '',
            bankValidationStatus: '',
            beneficiaryName: '',
            beneficiaryAccountType: '',
            beneficiaryAccountNumber: '',
            ifscCode: ''
        };
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }
}