import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOtherIncomeDetails from '@salesforce/apex/SHF_OtherIncomeDetailsController.getOtherIncomeDetails';
import saveOtherIncomeDetails from '@salesforce/apex/SHF_OtherIncomeDetailsController.saveOtherIncomeDetails';
import getPicklistConfig from '@salesforce/apex/SHF_OtherIncomeDetailsController.getPicklistConfig';
import { publish, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';

export default class ShfOtherIncomeDetails extends LightningElement {
    @api recordId; // loanApplicantId
    @track rows = [];
    @track deleteList = [];
    @track isLoading = false;
    
    // Picklist Options
    @track headOptions = [];
    @track sourceOptions = [];
    @track frequencyOptions = [];

    @wire(MessageContext)
    messageContext;

    // Frequency Multiplier Map
    frequencyMap = {
        'Annually': 1,
        'Bi-Monthly': 24,
        'Fortnightly': 26,
        'Half Yearly': 2,
        'Monthly': 12,
        'OneTime': 1,
        'Quarterly': 4,
        'Weekly': 52
    };

    get totalAnnualIncome() {
        return this.rows.reduce((sum, row) => sum + (Number(row.Net_Amount_Annual__c) || 0), 0);
    }

    get totalMonthlyIncome() {
        const annualTotal = this.totalAnnualIncome;
        return annualTotal > 0 ? parseFloat((annualTotal / 12).toFixed(2)) : 0;
    }

    connectedCallback() {
        this.loadPicklists();
        this.loadData();
    }

    // --- LOAD DATA ---
    loadPicklists() {
        getPicklistConfig()
            .then(data => {
                this.headOptions = this.formatOptions(data.Income_Head__c);
                this.sourceOptions = this.formatOptions(data.Income_source__c);
                this.frequencyOptions = this.formatOptions(data.Frequency__c);
            })
            .catch(error => console.error('Error loading picklists', error));
    }

    formatOptions(list) {
        return list ? list.map(val => ({ label: val, value: val })) : [];
    }

    loadData() {
        this.isLoading = true;
        getOtherIncomeDetails({ loanApplicantId: this.recordId })
            .then(result => {
                if (result.length > 0) {
                    this.rows = result.map(rec => ({ ...rec, key: rec.Id }));
                } else {
                    this.handleAddRow(); // Add default empty row
                }
            })
            .catch(error => this.showToast('Error', 'Error fetching data', 'error'))
            .finally(() => this.isLoading = false);
    }

    // --- ROW ACTIONS ---
    handleAddRow() {
        const newRow = {
            key: Date.now(),
            Income_Head__c: '',
            Income_source__c: '', 
            Frequency__c: '',
            Amount__c: '', 
            Percentage__c: '',
            Net_Amount_Annual__c: 0,
            Total_Income_Monthly__c: 0 // Initialize for consistency
        };
        this.rows.push(newRow);
    }

    handleDeleteRow(event) {
        const rowKey = event.target.dataset.id;
        const rowIndex = this.rows.findIndex(row => row.key == rowKey);
        
        if (rowIndex !== -1) {
            const row = this.rows[rowIndex];
            if (row.Id) {
                this.deleteList.push(row.Id);
            }
            this.rows.splice(rowIndex, 1);
            this.rows = [...this.rows]; 
        }
    }

    handleInputChange(event) {
        const rowKey = event.target.dataset.id;
        const field = event.target.dataset.field;
        let value = event.target.value;

        const row = this.rows.find(r => r.key == rowKey);
        if (row) {
            row[field] = value;
            
            // Recalculate Formula
            if (['Amount__c', 'Percentage__c', 'Frequency__c'].includes(field)) {
                this.calculateRow(row);
            }
        }
    }

    calculateRow(row) {
        const amount = Number(row.Amount__c) || 0;
        const percentage = Number(row.Percentage__c) || 0;
        const freqLabel = row.Frequency__c;
        const multiplier = this.frequencyMap[freqLabel] || 0;

        const netAmount = (amount * (percentage / 100)) * multiplier;
        row.Net_Amount_Annual__c = parseFloat(netAmount.toFixed(2));
    }

    handleSave() {
        // --- VALIDATION GATEKEEPER ---
        // This triggers the HTML validation messages (Red Box)
        const allValid = [...this.template.querySelectorAll('lightning-combobox, lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            this.showToast('Error', 'Please correct the errors in the highlighted fields.', 'error');
            return;
        }

        const aggregateMonthlyIncome = this.totalMonthlyIncome;

        const recordsToSave = this.rows.map(row => {
            const { key, ...cleanRow } = row; 
            return { 
                ...cleanRow, 
                sobjectType: 'Income_Details__c',
                Total_Income_Monthly__c: aggregateMonthlyIncome
            };
        });

        this.isLoading = true;
        saveOtherIncomeDetails({
            recordsToSave: recordsToSave,
            recordIdsToDelete: this.deleteList,
            loanApplicantId: this.recordId
        })
        .then(() => {
            this.showToast('Success', 'Other Income Details Saved', 'success');
            this.deleteList = []; 
            this.loadData();
            const message = { recordId: this.recordId };
            publish(this.messageContext, CALCULATOR_REFRESH_CHANNEL, message);            
            console.log('Refreshed message published');

        })
        .catch(error => {
            console.error(error);
            this.showToast('Error', error.body ? error.body.message : error.message, 'error');
        })
        .finally(() => this.isLoading = false);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}