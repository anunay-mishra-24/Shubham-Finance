import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFinancialSheet from '@salesforce/apex/SHF_FinancialSheetController.getFinancialSheet';
import getFinancialData from '@salesforce/apex/SHF_FinancialSheetController.getFinancialData';
import saveFinancialData from '@salesforce/apex/SHF_FinancialSheetController.saveFinancialData';
import { publish, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';

export default class ShfITRIncomeProgram extends LightningElement {

    @api loanApplicantId;
    @api incomeProgram = 'ITR';
    @api recordId;

    @track fieldList = [];
    @track values = {};

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.loadMetadata();
    }

    loadMetadata() {
        getFinancialSheet({ incomeProgram: this.incomeProgram })
            .then(data => {
                const fyOptions = this.getLastTwoFYs();

                this.fieldList = data.map(r => {
                    const label = r.Label__c;
                    const is44ADRow = label === 'FINANCIALS ARE FILED UNDER 44AD?';
                    const isFYSelector = label === 'SELECT FINANCIAL YEAR';
                    const isDualValue = [
                        'DATE OF FILLING',
                        'ANNUAL SALES',
                        'NET PROFIT FROM BUSINESS'
                    ].includes(label);

                    const isSingleValue = !is44ADRow && !isFYSelector && !isDualValue;

                    return {
                        order: r.Order__c,
                        label,
                        formatter : r.Data_type__c,
                        formula: r.Formula__c,
                        is44ADRow,
                        isRequired : r.Is_Required__c,
                        isFYSelector,
                        isDualValue,
                        isSingleValue,
                        inputType: label === 'DATE OF FILLING' ? 'date' : 'number',
                        picklistOptions: is44ADRow
                            ? [{ label: 'Yes', value: 'Yes' }, { label: 'No', value: 'No' }]
                            : isFYSelector ? fyOptions : null,
                        disableFy1: false,
                        isVisible: true,
                        value: { fy1: null, fy2: null }
                    };
                });

                this.orderByLabel = {};
                this.fieldList.forEach(f => {
                    this.orderByLabel[f.label] = f.order;
                });

                this.fieldList.forEach(f => {
                    this.values[f.order] = { fy1: null, fy2: null };
                });

                const fyRow = this.fieldList.find(f => f.isFYSelector);
                if (fyRow && fyRow.picklistOptions?.length >= 2) {
                    this.values[fyRow.order] = {
                        fy1: fyRow.picklistOptions[0].value,
                        fy2: fyRow.picklistOptions[1].value
                    };
                }

                this.fetchExistingData();
            })
            .catch(error => console.error(error));
    }

    fetchExistingData() {
        getFinancialData({
            loanApplicantId: this.loanApplicantId,
            incomeProgram: this.incomeProgram
        })
        .then(savedWrappers => {
            if (savedWrappers && savedWrappers.length > 0) {
                savedWrappers.forEach(data => {
                    try {
                        if (data.value) {
                            this.values[data.order] = JSON.parse(data.value);
                        }
                    } catch (e) {
                        console.error('Error parsing value for order ' + data.order, e);
                    }
                });
                
                this.calculateFormulas();
            }
        })
        .catch(error => console.error('Error loading data', error));
    }

    getLastTwoFYs() {
        const year = new Date().getFullYear();
        return [
            { label: `FY ${year - 1}-${year}`, value: `FY ${year - 1}-${year}` },
            { label: `FY ${year - 2}-${year - 1}`, value: `FY ${year - 2}-${year - 1}` }
        ];
    }

    handleChange(event) {
        const order = Number(event.target.dataset.order);
        const col = event.target.dataset.col || 'fy1';
        const value = event.target.value;
        
        if (!this.values[order]) {
            this.values[order] = { fy1: null, fy2: null };
        }

        const field = this.fieldList.find(f => f.order === order);
        if (field && field.label === 'DATE OF FILLING') {
            const currentVals = { ...this.values[order] };
            currentVals[col] = value;

            if (currentVals.fy1 && currentVals.fy2) {
                const dateFrom = new Date(currentVals.fy1);
                const dateTo = new Date(currentVals.fy2);

                if (dateTo < dateFrom) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Validation Error',
                            message: 'To (2nd) Date cannot be earlier than From Date for Date of Filling.',
                            variant: 'error'
                        })
                    );
                    event.target.value = null;
                    this.values[order][col] = null;
                    return; 
                }
            }
        }
        
        if (!this.values[order]) {
            this.values[order] = { fy1: null, fy2: null };
        }
        
        this.values[order][col] = event.target.value;

        this.calculateFormulas();
    }

    parseNumber(val) {
        if (val === null || val === undefined || val === '') return 0;
        return Number(String(val).replace(/,/g, '')) || 0;
    }

    calculateFormulas() {
        const ad44Order = this.orderByLabel['FINANCIALS ARE FILED UNDER 44AD?'];
        const ad44Value = this.values[ad44Order]?.fy1;

        this.fieldList.forEach(f => {
            if (f.label === 'DEPRECIATION' || f.label === 'INTEREST ON TERM LOANS') {
                if (ad44Value === 'Yes') {
                    if (!this.values[f.order]) this.values[f.order] = { fy1: 0, fy2: 0 };
                    this.values[f.order].fy1 = 0;
                    this.values[f.order].fy2 = 0;
                    
                    f.isVisible = false; 
                } else {
                    f.isVisible = true;
                }
            }
        });

        const policyField = this.fieldList.find(f => f.label === 'NET PROFIT AS PER POLICY');
        if (policyField) {
            const baseOrder = this.orderByLabel['NET PROFIT FROM BUSINESS'];
            const base = this.values[baseOrder];
            const fy1 = this.parseNumber(base?.fy1);
            const fy2 = this.parseNumber(base?.fy2);
            
            if (!this.values[policyField.order]) this.values[policyField.order] = {};
            
            this.values[policyField.order].fy1 = (fy1 + fy2) / 2;
            policyField.disableFy1 = true;
        }

        this.fieldList.forEach(f => {
            if (f.formula) {
                let expr = f.formula;
                Object.keys(this.values).forEach(key => {
                    const val = this.parseNumber(this.values[key]?.fy1);
                    const regex = new RegExp(`!${key}\\b`, 'g');
                    expr = expr.replace(regex, val);
                });

                try {
                    const result = eval(expr);
                    if (!this.values[f.order]) this.values[f.order] = {};
                    this.values[f.order].fy1 = Number.isFinite(result) ? result : 0;
                    f.disableFy1 = true;
                } catch (e) {
                    this.values[f.order].fy1 = 0;
                }
            }
        });

        this.fieldList = this.fieldList.map(f => ({
            ...f,
            value: this.values[f.order] || { fy1: null, fy2: null }
        }));
    }

    handleSave() {

        const allValid = [
        ...this.template.querySelectorAll('lightning-input'),
        ...this.template.querySelectorAll('lightning-combobox')
        ].reduce((validSoFar, inputCmp) => {
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

        const payload = this.fieldList.map(f => {
            const valObj = this.values[f.order] || { fy1: null, fy2: null };
            
            return {
                rowIndex: 0, 
                order: f.order,
                label: f.label,
                value: JSON.stringify(valObj)
            };
        });

        const netIncomeField = this.fieldList.find(f => 
            f.label.toUpperCase() === 'NET MONTHLY PROFIT' || 
            f.label.toUpperCase() === 'NET PROFIT' 
        ); 
        
        let netIncomeValue = 0;

        if (netIncomeField) {
            const valObj = this.values[netIncomeField.order];
            
            if (valObj && valObj.fy1) {
                netIncomeValue = Number(valObj.fy1) || 0;
            }
        }

        console.log('Final Net Income to Save:', netIncomeValue); 

        saveFinancialData({
            loanApplicantId: this.loanApplicantId,
            applicableCalculator: this.incomeProgram,
            rows: payload,
            netIncome: netIncomeValue 
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({ 
                title: 'Success', 
                message: 'ITR details saved successfully', 
                variant: 'success' 
            }));
            const message = { recordId: this.recordId };
            publish(this.messageContext, CALCULATOR_REFRESH_CHANNEL, message);
            console.log('Refreshed message published');
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
}