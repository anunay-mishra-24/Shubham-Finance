import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import saveFinancialData from '@salesforce/apex/SHF_FinancialSheetController.saveFinancialData';
import getFinancialData from '@salesforce/apex/SHF_FinancialSheetController.getFinancialData';
import ALLOWED_BT_TOPUP_INSTITUTIONS_LABEL from '@salesforce/label/c.SHF_Allowed_BT_TopUp_Institutions_Internal_Loans';

const APPLICATION_FIELDS = [
    'Application__c.Rate_of_Interest__c',
    'Application__c.Tenure__c',
    'Application__c.Product__r.Policy_FOIR__c', 
    'Application__c.Product__r.LTV__c'
];

export default class ShfFinalEligibilityCalculator extends LightningElement {
    @api recordId; 
    
    @track isLoading = false;
    CALCULATOR_NAME = 'Final_Eligibility_Calculator';

    @track totalAppraisedIncome = 0;
    @track sumDeductions = 30000; // Default Hardcoded
    @track obligationsEmiSum = 0;
    @track policyFOIR = 0; 
    @track roi = 0;
    @track tenure = 0;
    @track policyLTV = 0; 
    @track technicalAcceptedValuation = 2400000; // Default Hardcoded
    @track propertyCost = 0;

    isDataLoaded = false;
    
    allowedInstitutions = ALLOWED_BT_TOPUP_INSTITUTIONS_LABEL.split(',').map(i => i.trim());

    connectedCallback() {
        this.loadSavedData();
    }

    // === 1. Load Saved Data (Priority 1) ===
    loadSavedData() {
        this.isLoading = true;
        getFinancialData({ loanApplicantId: this.recordId, incomeProgram: this.CALCULATOR_NAME })
            .then(result => {
                if (result && result.length > 0) {
                    this.isDataLoaded = true; // Mark as loaded so wires don't overwrite
                    result.forEach(row => {
                        const val = parseFloat(row.value) || 0;
                        switch (row.label) {
                            case 'Sum of Monthly Income': this.totalAppraisedIncome = val; break;
                            case 'Monthly Deductions': this.sumDeductions = val; break;
                            case 'Monthly Obligations': this.obligationsEmiSum = val; break;
                            case 'Policy FOIR': this.policyFOIR = val; break;
                            case 'ROI': this.roi = val; break;
                            case 'Tenure': this.tenure = val; break;
                            case 'Policy LTV': this.policyLTV = val; break;
                            case 'Technical Accepted Valuation': this.technicalAcceptedValuation = val; break;
                            case 'Property Cost': this.propertyCost = val; break;
                        }
                    });
                }
            })
            .catch(error => console.error('Error loading saved data', error))
            .finally(() => {
                this.isLoading = false;
            });
    }

    // === 2. Wired Data (Priority 2 - Only if not saved) ===
    
    // Application Data (ROI, Tenure, Policy Defaults)
    @wire(getRecord, { recordId: '$recordId', fields: APPLICATION_FIELDS })
    wiredApplication({ data, error }) {
        if (data && !this.isDataLoaded) {
            this.roi = data.fields.Rate_of_Interest__c?.value || 0;
            this.tenure = data.fields.Tenure__c?.value || 0;
            
            // Product Defaults
            if (data.fields.Product__r?.value) {
                this.policyFOIR = data.fields.Product__r.value.fields.Policy_FOIR__c?.value || 0.55;
                
                this.policyLTV = data.fields.Product__r.value.fields.LTV__c?.value || 0.80;
            }
        }
    }

    // Loan Applicants (Income)
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Loan_Applicants__r',
        fields: ['Loan_Applicant__c.Appraised_Income__c', 'Loan_Applicant__c.IsFinancial_Applicant__c']
    })
    wiredApplicants({ data, error }) {
        if (data && !this.isDataLoaded) {
            this.totalAppraisedIncome = data.records.reduce((sum, rec) => {
                const isFinancial = rec.fields.IsFinancial_Applicant__c.value;
                const income = rec.fields.Appraised_Income__c.value || 0;
                return isFinancial === 'Yes' ? sum + income : sum;
            }, 0); 
        }
    }

    // Obligations
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Obligations__r',
        fields: [
            'Obligation__c.Outstanding_Amount__c',
            'Obligation__c.Consider_To_be_Deleted__c',
            'Obligation__c.Considered_for_FOIR__c',
            'Obligation__c.Institution__c',
            'Obligation__c.EMI__c'
        ]
    })
    wiredObligations({ data, error }) {
        if (data && !this.isDataLoaded) {
            let emiSum = 0;
            data.records.forEach(rec => {
                const isDeleted = rec.fields.Consider_To_be_Deleted__c.value;
                const foir = rec.fields.Considered_for_FOIR__c.value;
                const emiVal = rec.fields.EMI__c?.value || 0;

                if (!isDeleted && foir === 'Yes') {
                    emiSum += emiVal;
                }
            });
            this.obligationsEmiSum = emiSum;
        }
    }

    // Collaterals (Property Cost, Valuation)
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Collaterals__r', 
        fields: ['Collateral__c.Accepted_Valuation_INR__c', 'Collateral__c.Property_cost_INR__c'] 
    })
    wiredCollaterals({ data, error }) {
        if (data && data.records.length > 0 && !this.isDataLoaded) {
            const col = data.records[0]; 
            this.technicalAcceptedValuation = col.fields.Accepted_Valuation_INR__c.value || 2400000; 
            this.propertyCost = col.fields.Property_cost_INR__c.value || 0;
        }
    }

    // === Calculations ===
    
    get grossMonthlySalary() {
        return (this.totalAppraisedIncome - this.sumDeductions).toFixed(2);
    }

    get initialServiceableEMI() {
        const foirDecimal = this.policyFOIR / 100;
        return (this.grossMonthlySalary * foirDecimal).toFixed(2);
    }

    get finalServiceableEMI() {
        return (this.initialServiceableEMI - this.obligationsEmiSum).toFixed(2);
    }

    get eligibleFundableValueIncome() {
        const monthlyRate = (this.roi / 100) / 12;
        const finalEMI = parseFloat(this.finalServiceableEMI);
        
        let value = 0;
        if (monthlyRate > 0 && this.tenure > 0) {
            value = (finalEMI * (1 - Math.pow(1 + monthlyRate, -this.tenure))) / monthlyRate;
        } else if (this.tenure > 0) {
            value = finalEMI * this.tenure;
        }
        return Math.abs(Number(value)).toFixed(2);
    }

    get eligibleFundableValueLTV() {
        let minValue = 0;
        if(this.technicalAcceptedValuation > 0 && this.propertyCost > 0){
             minValue = Math.min(this.technicalAcceptedValuation, this.propertyCost);
        } else {
             minValue = Math.max(this.technicalAcceptedValuation, this.propertyCost);
        }
        const ltvDecimal = this.policyLTV / 100;
        return (minValue * ltvDecimal).toFixed(2);
    }

    get finalEligibleFundableValue() {
        const incomeBased = parseFloat(this.eligibleFundableValueIncome) || 0;
        const ltvBased = parseFloat(this.eligibleFundableValueLTV) || 0;
        return Math.min(incomeBased, ltvBased).toFixed(2);
    }

    // === Handlers ===
    handleChange(event) {
        const fieldName = event.target.name;
        const value = parseFloat(event.target.value) || 0;
        this[fieldName] = value;
    }

    handleSave() {
        this.isLoading = true;
        const rowsToSave = [
            { rowIndex: 1, order: 1, label: 'Sum of Monthly Income', value: String(this.totalAppraisedIncome) },
            { rowIndex: 2, order: 2, label: 'Monthly Deductions', value: String(this.sumDeductions) },
            { rowIndex: 3, order: 3, label: 'Monthly Obligations', value: String(this.obligationsEmiSum) },
            { rowIndex: 4, order: 4, label: 'Gross Monthly Salary', value: String(this.grossMonthlySalary) },
            { rowIndex: 5, order: 5, label: 'Policy FOIR', value: String(this.policyFOIR) },
            { rowIndex: 6, order: 6, label: 'Initial Serviceable EMI', value: String(this.initialServiceableEMI) },
            { rowIndex: 7, order: 7, label: 'Final Serviceable EMI', value: String(this.finalServiceableEMI) },
            { rowIndex: 8, order: 8, label: 'ROI', value: String(this.roi) },
            { rowIndex: 9, order: 9, label: 'Tenure', value: String(this.tenure) },
            { rowIndex: 10, order: 10, label: 'Eligible Fundable Value (Income)', value: String(this.eligibleFundableValueIncome) },
            { rowIndex: 11, order: 11, label: 'Policy LTV', value: String(this.policyLTV) },
            { rowIndex: 12, order: 12, label: 'Technical Accepted Valuation', value: String(this.technicalAcceptedValuation) },
            { rowIndex: 13, order: 13, label: 'Property Cost', value: String(this.propertyCost) },
            { rowIndex: 14, order: 14, label: 'Eligible Fundable Value (LTV)', value: String(this.eligibleFundableValueLTV) },
            { rowIndex: 15, order: 15, label: 'Maximum Eligible Loan Amount', value: String(this.finalEligibleFundableValue) }
        ];

        saveFinancialData({ 
            loanApplicantId: this.recordId, 
            applicableCalculator: this.CALCULATOR_NAME, 
            rows: rowsToSave 
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Data saved successfully', variant: 'success' }));
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body ? error.body.message : error.message, variant: 'error' }));
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
}