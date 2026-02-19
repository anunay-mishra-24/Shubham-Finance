import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFinancialSheet from '@salesforce/apex/SHF_FinancialSheetController.getFinancialSheet';
import getFinancialData from '@salesforce/apex/SHF_FinancialSheetController.getFinancialData'; 
import saveFinancialData from '@salesforce/apex/SHF_FinancialSheetController.saveFinancialData';
import { publish, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';

export default class ShfAbbSurrogateProgram extends LightningElement {
    @api loanApplicantId;
    @api recordId;
    @api incomeProgram = 'ABB Surrogate'; 
    
    @track selectedBanks = [];
    @track rows = [];
    @track dynamicColumns = [];
    @track columnMinimums = [];
    
    @track totals = {
        annualABB: 0,
        multiplier: 0.0, 
        eligibleEMI: 0
    };
    @wire(MessageContext)
    messageContext;

    labelAnnualABB = 'Annual ABB From All Accounts';
    labelMultiplier = 'ABB Program Multiplier';
    labelEligibleEMI = 'Eligible EMI as per ABB';

    ORDER_SELECTION = 1;
    ORDER_ACCOUNTS = [4, 5, 6, 7]; // Orders for Acc 1, 2, 3, 4
    ORDER_ANNUAL_ABB = 8;
    ORDER_MULTIPLIER = 9;
    ORDER_EMI = 10;

    get bankOptions() {
        let opts = [];
        opts.push({ label: `HDFC`, value: `HDFC` });
        opts.push({ label: `IDFC`, value: `IDFC` });
        opts.push({ label: `ICICI`, value: `ICICI` });
        opts.push({ label: `SBI`, value: `SBI` });
        opts.push({ label: `AU`, value: `AU` });
        opts.push({ label: `Kotak`, value: `Kotak` });
        opts.push({ label: `Shubham`, value: `Shubham` });
        opts.push({ label: `Utkarsh`, value: `Utkarsh` });
        opts.push({ label: `Indusind`, value: `Indusind` });
        opts.push({ label: `Cred`, value: `Cred` });
        return opts;
    }

    get maxBanks() { return 4; }
    get minBanks() { return 1; }
    get isTableVisible() { return this.selectedBanks.length > 0; }

    connectedCallback() {
        this.generateMonths();
        // Load Metadata to get Labels, then Load Data
        this.loadMetadata();
    }

    // 1. Generate Last 12 Months
    generateMonths() {
        const monthNames = ["January", "February", "March", "April", "May", "June",
                            "July", "August", "September", "October", "November", "December"];
        
        const today = new Date();
        let d = new Date(today.getFullYear(), today.getMonth() - 1, 1); // Start from previous month

        let newRows = [];
        for (let i = 0; i < 12; i++) {
            newRows.push({
                index: i,
                id: `row-${i}`,
                month: monthNames[d.getMonth()],
                year: d.getFullYear(),
                cells: [] // Will populate based on selected banks
            });
            d.setMonth(d.getMonth() - 1);
        }
        this.rows = newRows;
    }

    // 2. Load Metadata 
    loadMetadata() {
        getFinancialSheet({ incomeProgram: this.incomeProgram })
            .then(data => {
                if(data) {
                    // Update Labels from Metadata if present
                    const annual = data.find(d => d.Order__c === this.ORDER_ANNUAL_ABB);
                    if(annual) this.labelAnnualABB = annual.Label__c;
                    
                    const multi = data.find(d => d.Order__c === this.ORDER_MULTIPLIER);
                    if(multi) this.labelMultiplier = multi.Label__c;

                    const emi = data.find(d => d.Order__c === this.ORDER_EMI);
                    if(emi) this.labelEligibleEMI = emi.Label__c;
                }
                this.fetchExistingData();
            })
            .catch(err => console.error(err));
    }

    // 3. Fetch Existing Data
    fetchExistingData() {
        getFinancialData({ 
            loanApplicantId: this.loanApplicantId, 
            incomeProgram: this.incomeProgram 
        })
        .then(savedWrappers => {
            if (savedWrappers && savedWrappers.length > 0) {
                // 1. Restore Bank Selection (Stored in Order 1)
                const selectionRow = savedWrappers.find(w => w.order === this.ORDER_SELECTION);
                if (selectionRow && selectionRow.value) {
                    this.selectedBanks = selectionRow.value.split(';'); // Dual listbox uses array
                    this.updateTableStructure();
                }

                // 2. Restore Footer Totals
                const multRow = savedWrappers.find(w => w.order === this.ORDER_MULTIPLIER && w.rowIndex === -1);
                if (multRow) this.totals.multiplier = Number(multRow.value);

                // 3. Restore Grid Values
                savedWrappers.forEach(w => {
                    // Skip config/footer rows
                    if (w.rowIndex === -1 || w.order === this.ORDER_SELECTION) return;

                    const row = this.rows[w.rowIndex];
                    if (row) {
                        // Find the cell corresponding to this order
                        const cell = row.cells.find(c => c.order === w.order);
                        if (cell) {
                            cell.value = Number(w.value);
                        }
                    }
                });

                this.calculateTotals();

            } else {
                // Default if no data
                this.selectedBanks = [];
            }
        })
        .catch(error => console.error('Error loading data', error));
    }

    // 4. Handle Bank Selection Change
    handleBankSelection(event) {
        this.selectedBanks = event.detail.value;
        this.updateTableStructure();
        this.calculateTotals();
    }

    // Dynamically rebuilds columns based on selection
    updateTableStructure() {
        // Map selected banks to Orders 4, 5, 6, 7
        this.dynamicColumns = this.selectedBanks.map((bankName, index) => {
            return {
                label: bankName,
                order: this.ORDER_ACCOUNTS[index] // 4, 5, 6, 7
            };
        });

        // Update cells in each row
        this.rows.forEach(row => {
            // Re-map cells. Preserve value if order matches, else reset.
            const oldCells = row.cells;
            
            row.cells = this.dynamicColumns.map(col => {
                const existing = oldCells.find(c => c.order === col.order);
                return {
                    key: `${row.id}-${col.order}`,
                    order: col.order,
                    value: existing ? existing.value : 0
                };
            });
        });
    }

    // 5. Handle Input Change
    handleInputChange(event) {
        const rowIndex = event.target.dataset.rowIndex;
        const colOrder = Number(event.target.dataset.colOrder);
        const value = Number(event.target.value);

        const row = this.rows[rowIndex];
        const cell = row.cells.find(c => c.order === colOrder);
        if (cell) cell.value = value;

        this.calculateTotals();
    }

    handleFooterChange(event) {
    let val = Number(event.target.value);

        this.totals.multiplier = val; 
        
        this.calculateTotals();
    }

    calculateTotals() {
        let annualSumOfMins = 0;
        let newColumnMinimums = [];

        const rowsToConsider = this.rows.slice(0, 6); 

        this.dynamicColumns.forEach(col => {
            let minVal = Infinity;
            let hasData = false;

            rowsToConsider.forEach(row => {
                const cell = row.cells.find(c => c.order === col.order);
                const val = cell ? (Number(cell.value) || 0) : 0;
                
                if (val < minVal) minVal = val;
                hasData = true;
            });

            if (!hasData || minVal === Infinity) minVal = 0;
            
            newColumnMinimums.push({
                order: col.order,
                value: minVal
            });

            annualSumOfMins += minVal;
        });

        this.columnMinimums = newColumnMinimums;
        this.totals.annualABB = annualSumOfMins;

        // EMI Calculation
        const mult = this.totals.multiplier || 1;
        this.totals.eligibleEMI = (mult !== 0) ? (this.totals.annualABB / mult) : 0;
        this.totals.eligibleEMI = parseFloat(this.totals.eligibleEMI.toFixed(2));
    }

    // 7. Save Data
    handleSave() {

        const inputs = [...this.template.querySelectorAll('lightning-input, lightning-combobox')];
        const allValid = inputs.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity(); 
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (!allValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please complete all required fields.',
                    variant: 'error'
                })
            );
            return;
        }

        const payload = [];

        payload.push({
            rowIndex: -1, // Use -1 for config/footer
            order: this.ORDER_SELECTION,
            label: 'Bank Accounts Selection',
            value: this.selectedBanks.join(';')
        });

        // B. Save Grid Data -> Rows 0-11
        this.rows.forEach(row => {
            row.cells.forEach(cell => {
                payload.push({
                    rowIndex: row.index,
                    order: cell.order,
                    label: `Row ${row.index} - Order ${cell.order}`, // Label doesn't matter much for internal logic
                    value: String(cell.value)
                });
            });
        });

        // C. Save Footer Totals -> Row -1
        payload.push({ rowIndex: -1, order: this.ORDER_ANNUAL_ABB, label: this.labelAnnualABB, value: String(this.totals.annualABB) });
        payload.push({ rowIndex: -1, order: this.ORDER_MULTIPLIER, label: this.labelMultiplier, value: String(this.totals.multiplier) });
        payload.push({ rowIndex: -1, order: this.ORDER_EMI, label: this.labelEligibleEMI, value: String(this.totals.eligibleEMI) });

        saveFinancialData({
            loanApplicantId: this.loanApplicantId,
            applicableCalculator: this.incomeProgram,
            rows: payload,
            netIncome : this.totals.annualABB
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'ABB Data Saved', variant: 'success' }));
            const message = { recordId: this.recordId };
            publish(this.messageContext, CALCULATOR_REFRESH_CHANNEL, message);
            console.log('Refreshed message published');
        })
        .catch(error => {
            console.error(error);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message || 'Error saving', variant: 'error' }));
        });
    }
}