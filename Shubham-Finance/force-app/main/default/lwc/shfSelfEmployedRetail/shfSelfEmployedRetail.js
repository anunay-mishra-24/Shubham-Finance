import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFinancialSheet from '@salesforce/apex/SHF_FinancialSheetController.getFinancialSheet';
import getFinancialData from '@salesforce/apex/SHF_FinancialSheetController.getFinancialData'; 
import saveFinancialData from '@salesforce/apex/SHF_FinancialSheetController.saveFinancialData';
import { publish, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';

export default class ShfSelfEmployedRetail extends LightningElement {
    @api loanApplicantId;
    incomeProgram = 'Self_Employed_Retail';
    
    
    @track columns = [];
    @track rows = []; 
    @track values = {}; 
    @track totals = { daily: 0, monthly: 0, expenses: 0, netIncome: 0 };
    
    @wire(MessageContext)
    messageContext;

    // Modal & Delete tracking
    @track isDeleteModalOpen = false;
    rowToDeleteId = null;
    rowCounter = 0;


    connectedCallback() {
        this.loadMetaData();
    }

    loadMetaData() {
        getFinancialSheet({ incomeProgram: this.incomeProgram })
            .then(data => {
                console.log('Raw Data:', JSON.stringify(data)); 
                
                if (data) { 
                    this.columns = data.filter(item => item.Is_Show_On_UI__c); 
                    this.fetchExistingData();
                } else {
                    console.warn('No metadata returned from Apex');
                }
            })
            .catch(error => {
                console.error('Error loading metadata:', JSON.parse(JSON.stringify(error)));
            });
    }

    fetchExistingData() {
        getFinancialData({ 
            loanApplicantId: this.loanApplicantId, 
            incomeProgram: this.incomeProgram 
        })
        .then(savedWrappers => {
            if (savedWrappers && savedWrappers.length > 0) {
                this.rows = []; 
                this.values = {}; 
                let maxRowIndex = -1;

                // Loop through the WRAPPERS directly (Apex already parsed them)
                savedWrappers.forEach(data => {
                    const order = data.order;
                    const rowIndex = data.rowIndex; 
                    const val = data.value;

                    console.log(val);

                    // 1. Handle Table Rows
                    if (order <= 10 && rowIndex !== undefined && rowIndex !== null) {
                        if (rowIndex > maxRowIndex) maxRowIndex = rowIndex;
                        this.values[`row-${rowIndex}_${order}`] = val;
                    } 
                    // 2. Handle Footer Totals
                    else {
                        if (order === 11) this.totals.daily = Number(val);
                        if (order === 12) this.totals.monthly = Number(val);
                        if (order === 13) this.totals.expenses = Number(val);
                        if (order === 14) this.totals.netIncome = Number(val);
                    }
                });

                // Rebuild the rows
                for (let i = 0; i <= maxRowIndex; i++) {
                    this.rows.push({ id: `row-${i}` });
                }
                this.rowCounter = maxRowIndex + 1; 

            } else {
                this.handleAddRow();
            }
        })
        .catch(error => {
            console.error('Error loading existing data', error);
            this.handleAddRow();
        });
    }

    handleAddRow() {
        const newRowId = `row-${this.rowCounter++}`;
        const newRow = { id: newRowId };
        
        this.columns.forEach(col => {
            this.values[`${newRowId}_${col.Order__c}`] = col.Data_Type__c === 'Number' ? 0 : '';
        });

        this.rows = [...this.rows, newRow];
        this.calculateGrandTotals();
    }

    handleOpenDeleteModal(event) {
        this.rowToDeleteId = event.target.dataset.row;
        this.isDeleteModalOpen = true;
    }

    closeModal() {
        this.isDeleteModalOpen = false;
        this.rowToDeleteId = null;
    }

    confirmDelete() {
        if (this.rowToDeleteId && this.rows.length > 1) {
            this.rows = this.rows.filter(row => row.id !== this.rowToDeleteId);
            this.columns.forEach(col => delete this.values[`${this.rowToDeleteId}_${col.Order__c}`]);
            this.calculateGrandTotals();
            this.closeModal();
        }
    }

    /* 
    handleDeleteRow(event) {
        const rowId = event.target.dataset.row;
        if (this.rows.length > 1) {
            this.rows = this.rows.filter(row => row.id !== rowId);
            // Clean up values map
            this.columns.forEach(col => delete this.values[`${rowId}_${col.Order__c}`]);
            this.calculateGrandTotals();
        }
    }
    */

    handleInputChange(event) {
        const order = event.target.dataset.order;
        const rowId = event.target.dataset.row;
        let value = event.target.value;
        
        this.values[`${rowId}_${order}`] = event.target.type === 'number' ? Number(value) : value;
        
        this.calculateRowFormulas(rowId);
        this.calculateGrandTotals();
    }
    calculateRowFormulas(rowId) {
        this.columns.forEach(col => {
            if (col.Formula__c && col.Order__c <= 10) { 
                let expr = col.Formula__c;
                this.columns.forEach(c => {
                    const regex = new RegExp(`!${c.Order__c}\\b`, 'g');
                    const val = this.values[`${rowId}_${c.Order__c}`] || 0;
                    expr = expr.replace(regex, val);
                });
                try {
                    const result = eval(expr);
                    this.values[`${rowId}_${col.Order__c}`] = Number.isFinite(result) ? result : 0;
                } catch (e) { this.values[`${rowId}_${col.Order__c}`] = 0; }
            }
        });
        this.values = { ...this.values };
    }
    handleExpenseChange(event) {
        const val = Number(event.target.value);
        this.totals.expenses = val;
        this.calculateGrandTotals();
    }

    calculateGrandTotals() {
        
        let totalDaily = 0;
        this.rows.forEach(row => {
            totalDaily += Number(this.values[`${row.id}_10`]) || 0;
        });

        this.totals.daily = totalDaily;
        
        this.totals.monthly = totalDaily * 26;

        this.totals.netIncome = this.totals.monthly - (this.totals.expenses || 0);
    }

    get isDeleteDisabled() {
        return this.rows.length <= 1;
    }

    get tableData() {
        return this.rows.map(row => ({
            ...row,
            fields: this.columns.filter(col => col.Order__c <= 10).map(col => {
                
                const isNumeric = col.Data_type__c === 'Number' || col.Data_type__c === 'Currency';
                
                let fmt = null;
                if (col.Data_type__c === 'Currency') fmt = 'currency';

                const minVal = col.Min_value__c; 
                const maxVal = col.Max_Value__c; 
                const maxLen = col.Max_length__c; 

                return {
                    order: col.Order__c,
                    
                    type: isNumeric ? 'number' : 'text', 
                    
                    value: this.values[`${row.id}_${col.Order__c}`],
                    disabled: col.Is_Disabled__c,
                    isCostParent: col.Label__c === 'Cost',
                    
                    minValue: minVal,
                    maxValue: maxVal,
                    maxLength: maxLen,
                    formatter: fmt,

                    minMessage: minVal ? `Value must be at least ${minVal}` : '',
                    maxMessage: maxVal ? `Value cannot exceed ${maxVal}` : '',
                    lenMessage: maxLen ? `Maximum ${maxLen} characters allowed` : '',

                    key: `${row.id}_${col.Order__c}`
                };
            })
        }));
    }

    handleSave() {

        const inputs = [...this.template.querySelectorAll('lightning-input')];
        const allValid = inputs.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity(); 
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (!allValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: 'Please resolve the highlighted errors in the table.',
                    variant: 'error'
                })
            );
            return; 
        }

        const payload = [];

        this.rows.forEach((row, index) => {
            this.columns.forEach(col => {
                if (col.Order__c <= 10) { 
                    const fieldKey = `${row.id}_${col.Order__c}`;
                    const rowItemKey = `${row.id}_1`; 

                    const itemLabel = this.values[rowItemKey] ? this.values[rowItemKey] : 'Item';
                    const cellValue = this.values[fieldKey];

                    payload.push({
                        rowIndex: index,
                        order: col.Order__c,
                        formatter : col.Data_type__c,

                        label: `${itemLabel} - ${col.Label__c}`,
                        value: (cellValue === undefined || cellValue === null) ? '' : String(cellValue)
                    });
                    console.log(col.Order__c);
                    console.log(`${this.values[row.id + '_1'] || 'Item'} - ${col.Label__c}`);
                    console.log(this.values[`${row.id}_${col.Order__c}`]);
                }
            });
        });

        // We push these based on the `totals` object
        payload.push({ order: 11, label: 'Gross Daily Income Total', value: this.totals.daily });
        payload.push({ order: 12, label: 'Gross Monthly Income(26 Days)', value: this.totals.monthly });
        payload.push({ order: 13, label: 'Less : Expenses', value: this.totals.expenses });
        payload.push({ order: 14, label: 'Net Income (Monthly)', value: this.totals.netIncome });

        console.log('Sending Payload:', JSON.stringify(payload));

        saveFinancialData({
            loanApplicantId: this.loanApplicantId,
            applicableCalculator: this.incomeProgram, 
            rows: payload, 
            netIncome : this.totals.netIncome
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Success', message: 'Financial details saved successfully', variant: 'success' })
            );
            const message = { recordId: this.recordId };
            publish(this.messageContext, CALCULATOR_REFRESH_CHANNEL, message);
            console.log('Refreshed message published');
        }).catch(error => {
            console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Error', message: 'Error saving data', variant: 'error' })
            );
        });
    }
}