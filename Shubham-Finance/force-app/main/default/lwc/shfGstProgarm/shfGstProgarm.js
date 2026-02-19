import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFinancialSheet from '@salesforce/apex/SHF_FinancialSheetController.getFinancialSheet';
import getFinancialData from '@salesforce/apex/SHF_FinancialSheetController.getFinancialData'; 
import saveFinancialData from '@salesforce/apex/SHF_FinancialSheetController.saveFinancialData';
import { publish, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';

export default class ShfGstProgarm extends LightningElement {
    @api loanApplicantId;
    @api recordId;
    incomeProgram = 'GST Program'; 
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
                this.fieldList = data
                    .filter(item => item.Is_Show_On_UI__c)
                    .map(item => {
                        const label = item.Label__c;
                        const isGSTType = label === 'Type of GST';
                        const isHeader = label === 'Business Expense Head(Monthly)';

                        console.log('Data type: ', item.Data_type__c);

                        return {
                            order: item.Order__c, 
                            label,
                            type: item.Data_type__c,
                            formatter : item.Data_type__c,
                            disabled: item.Is_Disabled__c,
                            required: isGSTType ? true : item.Is_Required__c,
                            formula: item.Formula__c,
                            isHeader,
                            isGSTType,
                            gstTypeOptions: isGSTType
                                ? [
                                    { label: 'Purchase', value: 'Purchase' },
                                    { label: 'Sales', value: 'Sales' }
                                ]
                                : null,
                            picklistOptions: null 
                        };
                    });

                this.fieldList.forEach(f => {
                    this.values[f.order] = f.isGSTType ? null : 0;
                });

                this.fetchExistingData();
            })
            .catch(err => console.error(err));
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
                    const val = data.value;
                    const isNumber = !isNaN(Number(val)) && val !== '' && val !== null && val !== 'Purchase' && val !== 'Sales';
                    newValues[data.order] = isNumber ? Number(val) : val;
                });

                this.values = newValues;
                this.calculateFormulaFields();
            } else {
                this.calculateFormulaFields();
            }
        })
        .catch(error => {
            console.error('Error loading data', error);
        });
    }

    handleChange(event) {
        const order = Number(event.target.dataset.order);
        const value = event.target.value;
        const field = this.fieldList.find(f => f.order === order);

        if (field.isGSTType) {
            this.values[order] = value;
            
            // RESET Logic: Clear all other fields when GST Type changes
            this.fieldList.forEach(f => {
                if (f.order !== order && !f.isHeader) {
                    this.values[f.order] = 0; 
                }
            });
            console.log('GST Type changed. All other values reset to 0.');

        } else if (field.type === 'Picklist') {
            this.values[order] = value;
        } else {
            this.values[order] = Number(value) || 0;
        }

        this.calculateFormulaFields();
    }

    calculateFormulaFields() {
        const gstType = this.values[1] || 'Purchase'; 

        const field5 = this.fieldList.find(f => f.order === 5);
        if (field5) {
            if (gstType === 'Purchase') {
                field5.formula = '(!3) * ((!4/100) + 1)';
            } else if (gstType === 'Sales') {
                field5.formula = '(!3) / ((!4/100) + 1)';
            }
        }
        
        const profitField = this.fieldList.find(f => f.label && f.label.toUpperCase() === 'GROSS MONTHLY PROFIT');
        if (profitField) {
            if (gstType === 'Purchase') {
                profitField.formula = '(!5) - (!3)';
            } else if (gstType === 'Sales') {
                profitField.formula = '(!3) - (!5)';
            }
        }

        this.fieldList.forEach(field => {
            if (field.formula) {
                let expr = field.formula;
                
                Object.keys(this.values).forEach(key => {
                    const regex = new RegExp(`!${key}\\b`, 'g');
                    let val = this.values[key];

                    if (val === 'Purchase' || val === 'Sales' || val === null || val === undefined) {
                        val = 0;
                    }
                    
                    expr = expr.replace(regex, val);
                });

                try {
                    const result = eval(expr);
                    // Round to 2 decimals logic
                    this.values[field.order] = Number.isFinite(result) 
                        ? Number(result.toFixed(2)) 
                        : 0;
                } catch (e) {
                    this.values[field.order] = 0;
                }
            }
        });

        this.fieldList = this.fieldList.map(field => ({
            ...field,
            value: this.values[field.order] ?? null
        }));
    }

    handleSave() {
        // Validation Check
        if (!this.isValidInputs()) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please fill all required fields.',
                variant: 'error'
            }));
            return;
        }

        const payload = this.fieldList.map(f => ({
            rowIndex: 0, 
            order: f.order,
            label: f.label,
            value: (this.values[f.order] === undefined || this.values[f.order] === null) 
                   ? '' 
                   : String(this.values[f.order])
        }));

        const netIncomeField = this.fieldList.find(f => 
            f.label.toUpperCase() === 'NET MONTHLY PROFIT' || 
            f.label.toUpperCase() === 'NET MONTHLY INCOME'
        ); 
        
        const netIncomeValue = netIncomeField ? (Number(this.values[netIncomeField.order]) || 0) : 0;

        saveFinancialData({
            loanApplicantId: this.loanApplicantId,
            applicableCalculator: this.incomeProgram, 
            rows: payload,
            netIncome: netIncomeValue
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({ 
                title: 'Success', 
                message: 'Financial details saved successfully', 
                variant: 'success' 
            }));

            // PUBLISH LMS Message
            const message = { recordId: this.recordId };
            publish(this.messageContext, CALCULATOR_REFRESH_CHANNEL, message);
            
            console.log('Refresh message published');
        })
        .catch(error => {
            console.error(error);
            this.dispatchEvent(new ShowToastEvent({ 
                title: 'Error', 
                message: error.body?.message || 'Error saving data', 
                variant: 'error' 
            }));
        });
    }

    isValidInputs() {
        const allValid = [...this.template.querySelectorAll('lightning-combobox, lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return allValid;
    }

    getValue(order) {
        return this.values[order] ?? null;
    }
}