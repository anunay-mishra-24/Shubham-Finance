import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getIncomeDetails from '@salesforce/apex/SHF_IncomeDetailsController.getIncomeDetails';
import saveIncomeDetails from '@salesforce/apex/SHF_IncomeDetailsController.saveIncomeDetails';
import getPicklistConfig from '@salesforce/apex/SHF_IncomeDetailsController.getPicklistConfig';
import MAX_ROWS_LABEL from '@salesforce/label/c.Maximum_income_details'; 
import { publish, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';

export default class ShfIncomeDetails extends LightningElement {
    @api recordId; 
    @track rows = [];
    @track deleteList = [];
    @track isLoading = false;
    
    @track headOptions = [];
    @track sourceOptions = [];
    @track frequencyOptions = [];

    @wire(MessageContext)
    messageContext;

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

    get maxRows() {
        return parseInt(MAX_ROWS_LABEL) || 2;
    }

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
        getIncomeDetails({ loanApplicantId: this.recordId })
            .then(result => {
                if (result.length > 0) {
                    this.rows = result.map(rec => ({ ...rec, key: rec.Id }));
                } else {
                    this.handleAddRow(); 
                }
            })
            .catch(error => this.showToast('Error', 'Error fetching data', 'error'))
            .finally(() => this.isLoading = false);
    }

    handleAddRow() {
        if (this.rows.length >= this.maxRows) {
            this.showToast('Warning', `Maximum ${this.maxRows} records allowed.`, 'warning');
            return;
        }

        const newRow = {
            key: Date.now(),
            Income_Head__c: '',
            Income_source__c: '',
            Frequency__c: '',
            Amount__c: 0,
            Percentage__c: 0,
            Net_Amount_Annual__c: 0
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
        if (this.rows.length === 0) {
            this.showToast('Error', 'At least one income detail is mandatory.', 'error');
            return;
        }

        const heads = this.rows.map(r => r.Income_Head__c).filter(h => h);
        const uniqueHeads = new Set(heads);
        if (heads.length !== uniqueHeads.size) {
            this.showToast('Error', 'Same Income Head cannot be used twice.', 'error');
            return;
        }

        if (this.rows.length > this.maxRows) {
            this.showToast('Error', `You cannot save more than ${this.maxRows} records.`, 'error');
            return;
        }

        const isValid = [...this.template.querySelectorAll('lightning-combobox, lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!isValid) {
            this.showToast('Error', 'Please correct the highlighted errors.', 'error');
            return;
        }

        const aggregateMonthlyIncome = this.totalMonthlyIncome;

        const recordsToSave = this.rows.map(row => {
            const { key, ...cleanRow } = row; 
            
            return { 
                ...cleanRow, 
                sobjectType: 'Income_Details__c',
                Net_Amount_Annual__c: cleanRow.Net_Amount_Annual__c,
                Total_Income_Monthly__c: aggregateMonthlyIncome
            };
        });

        this.isLoading = true;
        saveIncomeDetails({
            recordsToSave: recordsToSave,
            recordIdsToDelete: this.deleteList,
            loanApplicantId: this.recordId
        })
        .then(() => {
            this.showToast('Success', 'Income Details Saved Successfully', 'success');
            this.deleteList = []; 
            this.loadData(); 
            const message = { recordId: this.recordId };
            publish(this.messageContext, CALCULATOR_REFRESH_CHANNEL, message);
        })
        .catch(error => {
            console.error(error);
            let err = error?.body?.message || error;
            this.showToast('Error', err, 'error');
        })
        .finally(() => this.isLoading = false);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}