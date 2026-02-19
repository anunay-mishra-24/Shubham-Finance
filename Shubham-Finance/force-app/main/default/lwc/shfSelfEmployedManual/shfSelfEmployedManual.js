import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFinancialSheet from '@salesforce/apex/SHF_FinancialSheetController.getFinancialSheet';
import getFinancialData from '@salesforce/apex/SHF_FinancialSheetController.getFinancialData'; 
import saveFinancialData from '@salesforce/apex/SHF_FinancialSheetController.saveFinancialData';
import { publish, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';

export default class ShfSelfEmployedManual extends LightningElement {
    @api loanApplicantId;
    @api incomeProgram = 'Self_Employed_Manual';
    
    @track fieldList = [];
    @track values = {};

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.loadSheet();
    }

    loadSheet() {
        getFinancialSheet({ incomeProgram: this.incomeProgram })
            .then(data => {
                this.fieldList = data.filter(item => item.Is_Show_On_UI__c);
                
                this.fieldList.forEach(f => {
                    this.values[f.Order__c] = ''; 
                });

                this.fetchExistingData();
            })
            .catch(err => console.error('Error loading metadata:', err));
    }

    fetchExistingData() {
        getFinancialData({ 
            loanApplicantId: this.loanApplicantId, 
            incomeProgram: this.incomeProgram 
        })
        .then(savedWrappers => {
            if (savedWrappers && savedWrappers.length > 0) {
                const newValues = { ...this.values };
                
                savedWrappers.forEach(data => {
                    const order = data.order;
                    const val = data.value; 
                    newValues[order] = val;
                });

                this.values = newValues;
                this.calculateFormulas();
            }
        })
        .catch(error => {
            console.error('Error loading existing data', error);
        });
    }

    handleInputChange(event) {
        const order = event.target.dataset.order;
        const value = event.target.value;
        
        this.values[order] = value;
        
        this.calculateFormulas();
    }

    calculateFormulas() {
        const currentValues = { ...this.values };

        this.fieldList.forEach(field => {
            if (field.Formula__c) {
                let expr = field.Formula__c;
                
                this.fieldList.forEach(f => {
                    const token = `!${f.Order__c}`;
                    if (expr.includes(token)) {
                        let val = Number(currentValues[f.Order__c]) || 0;
                        expr = expr.split(token).join(val);
                    }
                });

                try {
                    const result = eval(expr);
                    currentValues[field.Order__c] = Number.isFinite(result) ? result : 0;
                } catch (e) { 
                    console.error('Calc Error', e);
                    currentValues[field.Order__c] = 0; 
                }
            }
        });
        
        this.values = currentValues;
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
                    title: 'Attention Required',
                    message: 'Please resolve the highlighted errors in the table before saving.',
                    variant: 'error'
                })
            );
            return; 
        }

        const payload = this.fieldList.map(f => ({
            rowIndex: 0, 
            order: f.Order__c,
            label: f.Label__c,
            value: (this.values[f.Order__c] !== undefined && this.values[f.Order__c] !== null)
                   ? String(this.values[f.Order__c]) 
                   : ''
        }));

        const netIncomeField = this.fieldList.find(f => f.Label__c === 'Net Income (Monthly)'); 
        const netIncomeValue = netIncomeField ? (Number(this.values[netIncomeField.Order__c]) || 0) : 0;

        saveFinancialData({
            loanApplicantId: this.loanApplicantId,
            applicableCalculator: this.incomeProgram,
            rows: payload,
            netIncome: netIncomeValue
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Manual Income Saved', variant: 'success' }));
            const message = { recordId: this.recordId };
            publish(this.messageContext, CALCULATOR_REFRESH_CHANNEL, message);
            console.log('Refreshed message published');
        })
        .catch(error => {
            console.error(error);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Error saving data', variant: 'error' }));
        });
    }
    
    get dataFields() {

        return this.fieldList.map(field => {
            let fmt = null;
            if (field.Data_type__c === 'Currency') fmt = 'currency';
            if (field.Data_type__c === 'Percentage') fmt = 'percent-fixed';

            return {
                ...field,
                value: this.values[field.Order__c],
                key: field.Order__c,
                formatter: fmt,
                minValue: field.Min_value__c,
                maxLength: field.Max_length__c,
                minMessage: `Value cannot be less than ${field.Min_value__c}`,
                lengthMessage: `Maximum ${field.Max_length__c} characters allowed`
            };
        });
    }
}