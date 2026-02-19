import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFinancialSheet from '@salesforce/apex/SHF_FinancialSheetController.getFinancialSheet';
import getFinancialData from '@salesforce/apex/SHF_FinancialSheetController.getFinancialData'; 
import saveFinancialData from '@salesforce/apex/SHF_FinancialSheetController.saveFinancialData';
import { publish, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';

export default class ShfSelfEmployedService extends LightningElement {
    @api loanApplicantId;
    @api incomeProgram = 'Self_Employed_Service'; 
    
    @track columns = [];
    @track rows = []; 
    @track values = {}; 
    @track totals = { daily: 0, monthly: 0, expenses: 0, netIncome: 0 };
    
    @track isDeleteModalOpen = false;
    rowToDeleteId = null;
    rowCounter = 0;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.loadMetaData();
    }

    loadMetaData() {
        getFinancialSheet({ incomeProgram: this.incomeProgram })
            .then(data => {
                if (data && data.length > 0) {
                    this.columns = data.filter(item => item.Is_Show_On_UI__c && item.Order__c <= 5);
                    this.fetchExistingData(); 
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

                savedWrappers.forEach(data => {
                    const order = data.order;
                    const rowIndex = data.rowIndex; 
                    const val = data.value;

                    if (order <= 5 && rowIndex !== undefined && rowIndex !== null) {
                        if (rowIndex > maxRowIndex) maxRowIndex = rowIndex;
                        this.values[`row-${rowIndex}_${order}`] = val;
                    } 
                    else {
                        if (order === 6) this.totals.daily = Number(val);
                        if (order === 7) this.totals.monthly = Number(val);
                        if (order === 8) this.totals.expenses = Number(val);
                        if (order === 9) this.totals.netIncome = Number(val);
                    }
                });

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
            // Safe Type Check for default 0 vs ''
            const dataType = col.Data_type__c || col.Data_Type__c;
            const isNumeric = dataType === 'Number' || dataType === 'Currency' || dataType === 'Percentage';
            
            if (this.values[`${newRowId}_${col.Order__c}`] === undefined) {
                this.values[`${newRowId}_${col.Order__c}`] = isNumeric ? 0 : '';
            }
        });
        this.rows = [...this.rows, newRow];
        this.calculateGrandTotals();
    }

    // Modal Logic
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

    handleInputChange(event) {
        const order = Number(event.target.dataset.order);
        const rowId = event.target.dataset.row;
        let val = event.target.value;

        // With formatter="percent-fixed", user input of '10' comes as '0.1'
        // So we just store the number directly.
        this.values[`${rowId}_${order}`] = (event.target.type === 'number') ? Number(val) : val;
        
        this.calculateRowFormulas(rowId);
        this.calculateGrandTotals();
    }

    handleExpenseChange(event) {
        this.totals.expenses = Number(event.target.value) || 0;
        this.calculateGrandTotals();
    }

    calculateRowFormulas(rowId) {
        this.columns.forEach(col => {
            if (col.Formula__c) {
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

    calculateGrandTotals() {
        let totalDaily = 0;
        this.rows.forEach(row => {
            // Assuming Order 5 is the Gross Daily Income column
            totalDaily += Number(this.values[`${row.id}_5`]) || 0; 
        });
        this.totals.daily = totalDaily;
        this.totals.monthly = totalDaily * 26; 
        this.totals.netIncome = this.totals.monthly - this.totals.expenses;
    }

    get isDeleteDisabled() {
        return this.rows.length <= 1;
    }

    // UPDATED: Getter with Metadata mapping for Validation
    get tableData() {
        if (!this.columns.length) return [];
        return this.rows.map(row => ({
            ...row,
            fields: this.columns.map(col => {
                
                // 1. Safe Access to Metadata (Handling Case Sensitivity)
                const dataType = col.Data_type__c || col.Data_Type__c;
                const minVal = col.Min_value__c !== undefined ? col.Min_value__c : col.Min_Value__c;
                const maxVal = col.Max_Value__c !== undefined ? col.Max_Value__c : col.Max_value__c;
                const maxLen = col.Max_length__c !== undefined ? col.Max_length__c : col.Max_Length__c;

                // 2. Determine Formatter
                let fmt = null;
                if (dataType === 'Currency') fmt = 'currency';
                if (dataType === 'Percentage') fmt = 'percent-fixed';

                const isNumeric = dataType === 'Number' || dataType === 'Currency' || dataType === 'Percentage';

                return {
                    order: col.Order__c,
                    type: isNumeric ? 'number' : 'text',
                    value: this.values[`${row.id}_${col.Order__c}`],
                    
                    disabled: col.Is_Disabled__c,
                    
                    // Validation Props
                    minValue: minVal,
                    maxValue: maxVal,
                    maxLength: maxLen,
                    formatter: fmt,
                    
                    // Messages
                    minMessage: minVal ? `Value must be at least ${minVal}` : '',
                    maxMessage: maxVal ? `Value cannot exceed ${maxVal}` : '',
                    lenMessage: maxLen ? `Maximum ${maxLen} characters allowed` : '',

                    key: `${row.id}_${col.Order__c}`
                };
            })
        }));
    }

    handleSave() {
        // --- 1. VALIDATION CHECK ---
        const inputs = [...this.template.querySelectorAll('lightning-input')];
        const allValid = inputs.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity(); 
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (!allValid) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validation Error', message: 'Please correct the highlighted errors.', variant: 'error' }));
            return;
        }

        const payload = [];
        
        this.rows.forEach((row, index) => {
            this.columns.forEach(col => {
                const fieldKey = `${row.id}_${col.Order__c}`;
                const rowItemKey = `${row.id}_1`; 

                // Safe retrieval of label and value
                const itemLabel = this.values[rowItemKey] ? this.values[rowItemKey] : 'Item';
                const cellValue = this.values[fieldKey];
                
                // Determine Data Type for payload (optional, but good for tracking)
                const dataType = col.Data_type__c || col.Data_Type__c;

                payload.push({
                    rowIndex: index, 
                    order: col.Order__c,
                    label: `${itemLabel} - ${col.Label__c}`,
                    formatter: dataType,
                    // Convert to String for safe Apex deserialization
                    value: (cellValue === undefined || cellValue === null) ? '' : String(cellValue)
                });
            });
        });

        // 5. Save Footer Totals
        payload.push({ rowIndex: -1, order: 6, label: 'Gross Daily Income Total', value: String(this.totals.daily) });
        payload.push({ rowIndex: -1, order: 7, label: 'Gross Monthly Income(26 Days)', value: String(this.totals.monthly) });
        payload.push({ rowIndex: -1, order: 8, label: 'Less : Expenses(as per expanse schedule)', value: String(this.totals.expenses) });
        payload.push({ rowIndex: -1, order: 9, label: 'Net Income (Monthly)', value: String(this.totals.netIncome) });

        console.log('Sending Payload:', JSON.stringify(payload));

        saveFinancialData({
            loanApplicantId: this.loanApplicantId,
            applicableCalculator: this.incomeProgram,
            rows: payload,
            netIncome : this.totals.netIncome
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Service Income Data Saved', variant: 'success' }));
            const message = { recordId: this.recordId };
            publish(this.messageContext, CALCULATOR_REFRESH_CHANNEL, message);
            console.log('Refreshed message published');
        })
        .catch(error => {
            console.error(error);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Error saving data', variant: 'error' }));
        });
    }
}