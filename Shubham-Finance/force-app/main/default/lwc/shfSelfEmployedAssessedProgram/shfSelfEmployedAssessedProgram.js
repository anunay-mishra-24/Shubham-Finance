import { LightningElement, api, track } from 'lwc';
import getSavedIncomeProgram from '@salesforce/apex/SHF_FinancialCalculatorController.getSavedIncomeProgram';

export default class ShfSelfEmployedAssessedProgram extends LightningElement {
    @api recordId;      
    @api loanApplicantId; 
    @api incomeProgram = 'Self_Employed_Assessed';   

    @track selectedCalculator = '';

    // Picklist Options
    get calculatorOptions() {
        return [
            { label: 'Retail', value: 'Self_Employed_Retail' },
            { label: 'Service', value: 'Self_Employed_Service' },
            { label: 'Contract', value: 'Self_Employed_Contract' },
            { label: 'Manual', value: 'Self_Employed_Manual' }
        ];
    }

    get isRetail() { return this.selectedCalculator === 'Self_Employed_Retail'; }
    get isService() { return this.selectedCalculator === 'Self_Employed_Service'; }
    get isContract() { return this.selectedCalculator === 'Self_Employed_Contract'; }
    get isManual() { return this.selectedCalculator === 'Self_Employed_Manual'; }

    connectedCallback() {
        if (this.loanApplicantId) {
            this.checkForExistingData();
        }
    }

    checkForExistingData() {
        getSavedIncomeProgram({ loanApplicantId: this.loanApplicantId })
            .then(savedProgram => {
                if (savedProgram) {
                    console.log('Found saved sub-program:', savedProgram);
                    
                    const validOptions = ['Self_Employed_Retail', 'Self_Employed_Service', 'Self_Employed_Contract', 'Self_Employed_Manual'];
                    
                    if (validOptions.includes(savedProgram)) {
                        this.selectedCalculator = savedProgram;
                    }
                }
            })
            .catch(error => {
                console.error('Error fetching saved program', error);
            });
    }

    handleCalculatorChange(event) {
        this.selectedCalculator = event.detail.value;
    }
}