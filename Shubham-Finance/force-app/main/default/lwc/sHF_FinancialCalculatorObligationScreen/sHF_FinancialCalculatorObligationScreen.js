import { LightningElement, track, wire, api } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getFieldSetDescribe from '@salesforce/apex/SHF_FinancialCalObligationController.getFieldSetDescribe';
import getObligations from '@salesforce/apex/SHF_FinancialCalObligationController.getObligations';
import getDeletedObligations from '@salesforce/apex/SHF_FinancialCalObligationController.getDeletedObligations';
import saveObligations from '@salesforce/apex/SHF_FinancialCalObligationController.saveObligations';
import deleteObligation from '@salesforce/apex/SHF_FinancialCalObligationController.deleteObligation';
import getLoanTypeOptions from '@salesforce/apex/SHF_FinancialCalObligationController.getLoanTypeOptions';
import CONSIDERED_FOR_FOIR_FIELD from "@salesforce/schema/Obligation__c.Considered_for_FOIR__c";
import SANCTION_OBJECT from '@salesforce/schema/Obligation__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ALLOWED_BT_PRODUCTS_LABEL from '@salesforce/label/c.SHF_Allowed_BT_Products';
import ALLOWED_BT_TOPUP_INSTITUTIONS_LABEL from '@salesforce/label/c.SHF_Allowed_BT_TopUp_Institutions_Internal_Loans';
import { getRecord } from 'lightning/uiRecordApi';
import IS_CURRENT_USER_FIELD from '@salesforce/schema/Application__c.Is_Current_User__c';


const CUSTOM_LABEL_MAP = {
    'Product__c': 'Loan Type'
};

const MAX_BT_COUNT = 4;

const ALLOWED_BT_PRODUCTS = ALLOWED_BT_PRODUCTS_LABEL.split(',').map(item => item.trim());
const ALLOWED_BT_TOPUP_INSTITUTIONS = ALLOWED_BT_TOPUP_INSTITUTIONS_LABEL.split(',').map(item => item.trim());




export default class SHF_FinancialCalculatorObligationScreen extends LightningElement {

    @api recordId;
    @track obligationList = [];
    @track obligationCibilDeletedList = [];
    @track activeSpinner = false;
    @track showSaveButton = false;
    loanTypeOptions = [];
    @track consideredForFOIROptoins = [];
    @track isCurrentUser = false;


    connectedCallback() {
        this.fetchObligations();
        this.fetchLoanTypeOptions();
        this.fetchColumns();
        this.fetchDeletedColumns();
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CONSIDERED_FOR_FOIR_FIELD })
    getApprovalStatus({ data, error }) {
        if (data) {
            this.consideredForFOIROptoins = data.values;
            console.log('consideredForFOIROptoins==>', this.consideredForFOIROptoins)
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getObjectInfo, { objectApiName: SANCTION_OBJECT })
    objectInfo;

    fetchLoanTypeOptions() {
        getLoanTypeOptions()
            .then(result => {
                this.loanTypeOptions = result.map(item => {
                    return { label: item, value: item };
                });
            })
            .catch(error => {
                console.error('Error fetching loan type options: ', error);
            });
    }

    
    @wire(getRecord, { recordId: '$recordId', fields: [IS_CURRENT_USER_FIELD] })
    wiredApplication({ data, error }) {
        if (data) {
            this.isCurrentUser = data.fields.Is_Current_User__c.value;
            console.log('Is Current User:', this.isCurrentUser);
        } else if (error) {
            console.error('Error fetching Is_Current_User__c:', error);
        }
    }

    fetchColumns() {
        getFieldSetDescribe({ fieldSetName: 'Obligation_Screen_Fields' })
            .then(result => {
                const dynamicColumns = result.map(field => {
                    return {
                        label: CUSTOM_LABEL_MAP[field.apiName] || field.label,
                        fieldName: field.apiName
                    };
                });

                const staticColumns = [
                    { label: 'Sr No.', fieldName: 'srNo' },
                    //{ label: 'Index', fieldName: 'cibiliIndex' }
                ];

                this.dynamicColumns = [...staticColumns, ...dynamicColumns];
            })
            .catch(error => {
                console.error('Error fetching columns: ', error);
            });
    }


    fetchDeletedColumns() {
        getFieldSetDescribe({ fieldSetName: 'Obligation_Deleted_Screen_Filelds' })
            .then(result => {
                const dynamicColumns = result.map(field => {
                    return {
                        label: CUSTOM_LABEL_MAP[field.apiName] || field.label,
                        fieldName: field.apiName
                    };
                });

                const staticColumns = [
                    { label: 'Sr No.', fieldName: 'srNo' },
                    //{ label: 'Index', fieldName: 'cibiliIndex' }
                ];

                this.cibilDeletedTableColumns = [...staticColumns, ...dynamicColumns];
            })
            .catch(error => {
                console.error('Error fetching deleted columns: ', error);
            });
    }



    fetchObligations() {

        console.log('In FetchObligation');
        this.obligationList = [];
        this.activeSpinner = true;
        getObligations({ applicationId: this.recordId })
            .then(result => {
                this.obligationList = result.map((item, index) => {
                    
                    const disableFlags = this.computeFieldDisableFlags(item);
                    let consideredForFOIR = item.Considered_for_FOIR__c;
                    let consideredForFOIRDisabled = false;

                    // Loan Closed: FOIR = No & freezed
                    if (item.Loan_Status__c === 'Closed') {
                        consideredForFOIR = 'No';
                        consideredForFOIRDisabled = true;
                    }

                    // Loan Status Active + CRIF : default Yes
                    if (
                        item.Loan_Status__c === 'Active' &&
                        item.Source__c === 'CRIF' &&
                        !consideredForFOIR
                    ) {
                        consideredForFOIR = 'Yes';
                    }

                    disableFlags.consideredForFOIR = consideredForFOIRDisabled;
                    return {
                        showDelete: item.Source__c == 'Manual',
                        srNo: index + 1,
                        id: item.Id,
                        //cibiliIndex: item.Cibi_Index__c,
                        source: item.Source__c,
                        loanId: item.Loan_Id__c,
                        loanType: item.Product__c,
                        nameOfLendingInstution: item.Institution__c,
                        loanStatus: item.Loan_Status__c,
                        outstandingAmount: item.Outstanding_Amount__c,
                        amountSanctioned: item.Sanctioned_Amount__c,
                        tenureOutstanding: item.Tenor_Outstanding__c,
                        tenureOutstandingInMonths: item.Tenor__c,
                        emi: item.EMI__c,
                        consideredForFOIR,
                        createdDate: item.CreatedDate,
                        remarks: item.Remarks__c,
                        Consider_To_be_Deleted__c: item.Consider_To_be_Deleted__c,
                        errorMessage: '',
                        disableFlags
                    };
                });


                this.fetchDeletedObligations();
            })
            .catch(error => {
                this.showToast('Error', 'Error fetching obligations', 'error');
                this.activeSpinner = false;
            });
    }

    fetchDeletedObligations() {
        this.obligationCibilDeletedList = [];
        getDeletedObligations({ applicationId: this.recordId })
            .then(result => {
                this.obligationCibilDeletedList = result.map((item, index) => ({
                    srNo: index + 1,
                    id: item.Id,
                    //cibiliIndex: item.Cibi_Index__c,
                    source: item.Source__c,
                    loanId: item.Loan_Id__c,
                    loanType: item.Product__c,
                    nameOfLendingInstution: item.Institution__c,
                    loanStatus: item.Loan_Status__c,
                    outstandingAmount: item.Outstanding_Amount__c,
                    amountSanctioned: item.Sanctioned_Amount__c,
                    tenureOutstanding: item.Tenor_Outstanding__c,
                    tenureOutstandingInMonths: item.Tenor__c,
                    emi: item.EMI__c,
                    consideredForFOIR: item.Considered_for_FOIR__c,
                    createdDate: item.CreatedDate,
                    remarks: item.Remarks__c,
                    deletedOn: item.Cibil_Data_Deleted_On__c
                }));
                this.activeSpinner = false;
            })
            .catch(error => {
                this.showToast('Error', 'Error fetching deleted obligations', 'error');
                this.activeSpinner = false;
            });
    }

    handleAddrow() {
        this.showSaveButton = true;

        let index = this.obligationList && this.obligationList.length ? this.obligationList.length + 1 : 1;

        let record = {
            srNo: index,
            id: '',
            cibiliIndex: 'N/A',
            source: 'Manual',
            loanId: null,
            loanType: '',
            nameOfLendingInstution: '',
            loanStatus: null,
            outstandingAmount: null,
            amountSanctioned: null,
            tenureOutstanding: null,
            tenureOutstandingInMonths: null,
            emi: null,
            consideredForFOIR: '',
            remarks: '',
            applicationId: this.recordId,
            Consider_To_be_Deleted__c: false,
            errorMessage: '',

            disableFlags: {
                consideredForFOIR: false,
                loanId: false,
                loanStatus: false,
                nameOfLendingInstution: false,
                loanType: false,
                outstandingAmount: false,
                amountSanctioned: false,
                tenureOutstanding: false,
                tenureOutstandingInMonths: false,
                emi: false
            }
        };

        let data = [...this.obligationList];
        data.push(record);
        this.obligationList = data;
    }


    validateBTForRow(rowIndex, rows) {
        const row = rows[rowIndex];
        row.errorMessage = '';

        if (row.consideredForFOIR !== 'BT' && row.consideredForFOIR !== 'BT and Top-up') return;
        if (row.consideredForFOIR === 'BT') {
        if (!ALLOWED_BT_PRODUCTS.includes(row.loanType)) {
            row.errorMessage = 'This Product Type is not allowed for BT as per Policy.';
            return;
        }
        }
        const btCount = rows.filter(
            r => r.consideredForFOIR === 'BT' && !r.Consider_To_be_Deleted__c
        ).length;

        if (btCount > MAX_BT_COUNT) {
            row.errorMessage = `Maximum Products allowed for BT are ${MAX_BT_COUNT}.`;
        }

        if (row.consideredForFOIR === 'BT and Top-up') {
        if (!ALLOWED_BT_TOPUP_INSTITUTIONS.includes(row.nameOfLendingInstution)) {
            row.errorMessage = 'Only Internal Loans can be considered for BT with Top-up.';
        }
    }
    }
    
    validateForm() {
        let isValid = true;
        const updatedList = [...this.obligationList];

        updatedList.forEach((row) => {
            row.errorMessage = '';
            // Mandatory FOIR validation
            if (!row.consideredForFOIR) {
                row.errorMessage = 'Considered for FOIR is mandatory.';
                isValid = false;
            }
            // Fields that must be >= 0 if they have a value
            const numericFields = [
                { field: 'outstandingAmount', label: 'Outstanding Amount' },
                { field: 'amountSanctioned', label: 'Amount Sanctioned' },
                { field: 'tenureOutstanding', label: 'Tenure Outstanding' },
                { field: 'tenureOutstandingInMonths', label: 'Tenure Outstanding (Months)' },
                { field: 'emi', label: 'EMI' }
            ];

            numericFields.forEach(f => {
                const val = row[f.field];
                if (val !== null && val !== undefined && val !== '' && Number(val) < 0) {
                    row.errorMessage = `${f.label} cannot be negative.`;
                    isValid = false;
                }
            });
        });

        this.obligationList = updatedList;

        if (!isValid) {
            this.showToast('Validation Error', 'Please ensure all numeric values are non-negative.', 'error');
        }

        return isValid;
    }


    handleChange(event) {
        this.showSaveButton = true;
        const index = Number(event.target.dataset.index);
        const field = event.target.name;
        const value = event.target.value;

        const data = [...this.obligationList];
        data[index][field] = value;

        data[index].errorMessage = '';

        if (field === 'consideredForFOIR' || field === 'loanType') {
            this.validateBTForRow(index, data);
        }
        // Auto handling when Loan Status changes
        if (field === 'loanStatus') {

            // Loan Closed : FOIR = No & disable
            if (value === 'Closed') {
                data[index].consideredForFOIR = 'No';
                data[index].disableFlags.consideredForFOIR = true;
            } 
            else {
                data[index].disableFlags.consideredForFOIR = false;

                // Active + CRIF : default Yes
                if (
                    value === 'Active' &&
                    data[index].source === 'CRIF' &&
                    !data[index].consideredForFOIR
                ) {
                    data[index].consideredForFOIR = 'Yes';
                }
            }
        }

        this.obligationList = data;
    }

    handledeleteRow(event) {
        const index = this.obligationList.findIndex(item => item.srNo == event.target.dataset.index);
        const recordId = event.target.dataset.id;

        console.log('Record ID to delete:', recordId);
        console.log('Row index:', index);

        if (recordId) {
            this.activeSpinner = true;

            deleteObligation({ obligationId: recordId })
                .then(() => {
                    console.log('Record deleted successfully on server');
                    this.fetchObligations();
                    this.showToast('Success', 'Obligation deleted successfully', 'success');
                })
                .catch(error => {
                    console.error('Error while deleting:', error);
                    this.showToast('Error', 'Error deleting obligation', 'error');
                    this.activeSpinner = false;
                });
        } else {
            console.log('Deleting unsaved record from local list only');
            this.obligationList.splice(index - 1, 1);
            this.obligationList = [...this.obligationList];
        }
    }


    prepareObligationListForSave() {
        return this.obligationList.map(item => ({
            Id: item.id || null,
            //Cibi_Index__c: item.cibiliIndex,
            Source__c: item.source,
            Loan_Id__c: item.loanId,
            Product__c: item.loanType,
            Institution__c: item.nameOfLendingInstution,
            Loan_Status__c: item.loanStatus,
            Outstanding_Amount__c: item.outstandingAmount,
            Sanctioned_Amount__c: item.amountSanctioned,
            Tenor_Outstanding__c: item.tenureOutstanding,
            Tenor__c: item.tenureOutstandingInMonths,
            EMI__c: item.emi,
            Considered_for_FOIR__c: item.consideredForFOIR,
            Remarks__c: item.remarks,
            Application__c: this.recordId
        }));
    }

    get hasInlineErrors() {
        return this.obligationList.some(r => r.errorMessage && r.errorMessage.trim() !== '');
    }



    handleSave() {
        console.log('In HandleSave');
        const rows = [...this.obligationList];
        rows.forEach((_, i) => this.validateBTForRow(i, rows));
        this.obligationList = rows;
        
        if (!this.validateForm()) {
            this.activeSpinner = false;
            return;
        }
        if (this.hasInlineErrors) {
            this.activeSpinner = false;
            return;
        }
        this.activeSpinner = true;
        const finalObligationList = this.prepareObligationListForSave();
        saveObligations({ obligationList: finalObligationList })
            .then(() => {
                this.fetchObligations();
                this.fetchDeletedObligations();
                this.showToast('Success', 'Obligations saved successfully', 'success');
                this.showSaveButton = false;
            })
            .catch(error => {
                this.showToast('Error', 'Error saving obligations', 'error');
                this.activeSpinner = false;
            });

    }

    computeFieldDisableFlags(item) {
        const flags = {};

        // ConsideredForFOIR → Always editable
        flags.consideredForFOIR = false;

        flags.loanId = !(item.Source__c === 'Manual' || !item.Loan_Id__c);

        // Loan Status
        flags.loanStatus = !(item.Source__c === 'Manual' || !item.Loan_Status__c);

        // Institution
        flags.nameOfLendingInstution = !(item.Source__c === 'Manual' || !item.Institution__c);

        // Loan Type
        flags.loanType = !(item.Source__c === 'Manual' || !item.Product__c);

        // Outstanding Amount
        flags.outstandingAmount = !(item.Source__c === 'Manual' || !item.Outstanding_Amount__c);

        // Amount Sanctioned
        flags.amountSanctioned = !(item.Source__c === 'Manual' || !item.Sanctioned_Amount__c);

        // Tenure
        flags.tenureOutstanding = !(item.Source__c === 'Manual' || !item.Tenor_Outstanding__c);
        flags.tenureOutstandingInMonths = !(item.Source__c === 'Manual' || !item.Tenor__c);

        // EMI
        flags.emi = !(item.Source__c === 'Manual' || !item.EMI__c);

        return flags;
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}