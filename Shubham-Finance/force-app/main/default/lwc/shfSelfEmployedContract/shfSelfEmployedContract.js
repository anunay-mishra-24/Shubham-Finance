import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFinancialSheet from '@salesforce/apex/SHF_FinancialSheetController.getFinancialSheet';
import getFinancialData from '@salesforce/apex/SHF_FinancialSheetController.getFinancialData'; 
import saveFinancialData from '@salesforce/apex/SHF_FinancialSheetController.saveFinancialData';
import { publish, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';

export default class ShfSelfEmployedContract extends LightningElement {
    @api loanApplicantId;
    @api incomeProgram = 'Self_Employed_Contract';
    
    @track columns = [];
    @track rows = []; 
    @track values = {}; 
    @track grandTotals = { 
        totalPeriod: 0, 
        grossReceipts: 0, 
        margin: 0, 
        totalIncome: 0, 
        avgMonthly: 0 ,
        expenses: 0,    
        netIncome: 0
    };
    
    @track isDeleteModalOpen = false;
    rowToDeleteId = null;
    rowCounter = 0;

    @wire(MessageContext)
    messageContext;

    get statusOptions() {
        return [
            { label: 'Pending', value: 'Pending' },
            { label: 'Running', value: 'Running' },
            { label: 'Completed', value: 'Completed' }
        ];
    }

    connectedCallback() {
        this.loadMetaData();
    }

    loadMetaData() {
        getFinancialSheet({ incomeProgram: this.incomeProgram })
            .then(data => {
                if (data && data.length > 0) {
                    this.columns = data.filter(item => item.Is_Show_On_UI__c && item.Order__c !== 3 && item.Order__c <= 9);
                    this.fetchExistingData(); 
                }
            })
            .catch(error => console.error('Error loading metadata:', error));
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

                    if (order <= 10 && rowIndex !== undefined && rowIndex !== null) {
                        if (rowIndex > maxRowIndex) maxRowIndex = rowIndex;
                        this.values[`row-${rowIndex}_${order}`] = val; 
                    } 
                    else {
                        if (order === 11) this.grandTotals.grossReceipts = Number(val);
                        if (order === 12) this.grandTotals.margin = Number(val);
                        if (order === 13) this.grandTotals.totalIncome = Number(val);
                        if (order === 14) this.grandTotals.avgMonthly = Number(val);
                        if (order === 15) this.grandTotals.expenses = Number(val);
                        if (order === 16) this.grandTotals.netIncome = Number(val);
                    }
                });

                for (let i = 0; i <= maxRowIndex; i++) {
                    this.rows.push({ id: `row-${i}` });
                }
                this.rowCounter = maxRowIndex + 1; 
                
                
            } else {
                this.handleAddRow(); // Default empty row
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
            // Initialize only if not already loaded
            if (this.values[`${newRowId}_${col.Order__c}`] === undefined) {
                this.values[`${newRowId}_${col.Order__c}`] = '';
            }
        });
        this.rows = [...this.rows, newRow];
    }

    handleInputChange(event) {
        const order = Number(event.target.dataset.order);
        const rowId = event.target.dataset.row;
        let val = event.target.value;

        this.values[`${rowId}_${order}`] = (event.target.type === 'number') ? Number(val) : val;

        if (order === 4 || order === 5) {
            const fromDateInput = this.template.querySelector(`[data-row="${rowId}"][data-order="4"]`);
            const toDateInput = this.template.querySelector(`[data-row="${rowId}"][data-order="5"]`);

            if (order === 4 && toDateInput) {
                toDateInput.min = val; 
            }
            
            if (toDateInput.value && fromDateInput.value) {
                if (new Date(toDateInput.value) < new Date(fromDateInput.value)) {
                    toDateInput.setCustomValidity("To date cannot be earlier than From date");
                } else {
                    toDateInput.setCustomValidity(""); 
                }
                toDateInput.reportValidity();
            }
            this.calculateMonths(rowId);
        }

        this.calculateGrandTotals();
    }

    calculateMonths(rowId) {
        const startStr = this.values[`${rowId}_4`]; 
        const endStr = this.values[`${rowId}_5`];  

        if (startStr && endStr) {
            const start = new Date(startStr);
            const end = new Date(endStr);
            
            let months = (end.getFullYear() - start.getFullYear()) * 12;
            months -= start.getMonth();
            months += end.getMonth();
            
            const totalMonths = months < 0 ? 0 : months + 1;
            
            this.values[`${rowId}_10`] = totalMonths; 
        } else {
            this.values[`${rowId}_10`] = 0;
        }
    }

    handleMarginChange(event) {
        let val = event.target.value;
        this.grandTotals.margin = val ? Number(val) : 0;
        this.calculateGrandTotals();
    }

    handleExpenseChange(event) {
        this.grandTotals.expenses = event.target.value ? Number(event.target.value) : 0;
        this.calculateGrandTotals();
    }

    calculateGrandTotals() {
        let totalReceipts = 0;
        let totalMonths = 0;

        this.rows.forEach(row => {
            totalReceipts += Number(this.values[`${row.id}_8`] || 0);
            const rowMonths = Number(this.values[`${row.id}_10`] || 0);
            totalMonths += rowMonths;
        });

        this.grandTotals.grossReceipts = totalReceipts.toFixed(2);
        this.grandTotals.totalPeriod = totalMonths;
        this.grandTotals.totalIncome = totalReceipts * (this.grandTotals.margin / 100);
        this.grandTotals.totalIncome = this.grandTotals.totalIncome.toFixed(2);


        let baseAvgMonthly = this.grandTotals.totalPeriod > 0 ? (this.grandTotals.totalIncome / this.grandTotals.totalPeriod) : 0;
        this.grandTotals.avgMonthly = baseAvgMonthly;
        this.grandTotals.netIncome = baseAvgMonthly - this.grandTotals.expenses;
        console.log('average monthly income: ', baseAvgMonthly.toFixed(2));
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

    get isDeleteDisabled() {
        return this.rows.length <= 1;
    }

    get tableData() {
        if (!this.columns || this.columns.length === 0) return [];

        return this.rows.map(row => ({
            ...row,
            fields: this.columns.map(col => {
                const val = this.values[`${row.id}_${col.Order__c}`];
                const order = col.Order__c;

                let formatterValue = null;
                if (col.Data_type__c === 'Currency') {
                    formatterValue = 'currency';
                } else if (col.Data_type__c === 'Percentage') {
                    formatterValue = 'percent-fixed';
                }

                return {
                    
                    order: order,
                    value: val === undefined || val === null ? '' : val,

                    maxValue: col.Max_Value__c,
                    minValue: col.Min_value__c,
                    maxLength: col.Max_length__c,
                    formatter: formatterValue,

                    isPicklist: order === 2,
                    isDate: order === 4 || order === 5,
                    isTextarea: order === 6 || order === 7 || order === 9,
                    isNumber: order === 8,
                    isText: order === 1, 
                    key: `${row.id}_${order}`
                };
            })
        }));
    }

    handleSave() {

        const allInputsValid = [
        ...this.template.querySelectorAll('lightning-input'),
        ...this.template.querySelectorAll('lightning-combobox'),
        ...this.template.querySelectorAll('lightning-textarea')
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (!allInputsValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: 'Please check the values in the table for errors.',
                    variant: 'error'
                })
            );
            return; 
        }

        const payload = [];
        
        this.rows.forEach((row, index) => {
            this.columns.forEach(col => {
                const fieldKey = `${row.id}_${col.Order__c}`;
              
                const rowItemKey = `${row.id}_1`; 
                const itemLabel = this.values[rowItemKey] ? this.values[rowItemKey] : 'Site';
                const cellValue = this.values[fieldKey];

                payload.push({
                    rowIndex: index, 
                    order: col.Order__c,
                    label: `${itemLabel} - ${col.Label__c}`,
                    value: (cellValue === undefined || cellValue === null) ? '' : String(cellValue)
                });
            });
        });

        payload.push({ rowIndex: -1, order: 11, label: 'Gross Receipts for the Period', value: String(this.grandTotals.grossReceipts) });
        payload.push({ rowIndex: -1, order: 12, label: 'Gross Margin On Total Income', value: String(this.grandTotals.margin) });
        payload.push({ rowIndex: -1, order: 13, label: 'Gross Total Income for Period', value: String(this.grandTotals.totalIncome) });
        payload.push({ rowIndex: -1, order: 14, label: 'Average Monthly Income', value: String(this.grandTotals.avgMonthly) });
        payload.push({ rowIndex: -1, order: 15, label: 'Less : Expenses(as per expanse schedule)', value: String(this.grandTotals.expenses) });
        payload.push({ rowIndex: -1, order: 16, label: 'Net Income (Monthly)', value: String(this.grandTotals.netIncome) });

        saveFinancialData({
            loanApplicantId: this.loanApplicantId,
            applicableCalculator: this.incomeProgram,
            rows: payload,
            netIncome : this.grandTotals.netIncome
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Data saved successfully', variant: 'success' }));
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