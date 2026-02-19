import { LightningElement, api, track } from 'lwc';
import getTabVisibilityFlags from '@salesforce/apex/SHF_FinancialCalculatorController.getTabVisibilityFlags';

export default class ShfFinancialCalculatorTabs extends LightningElement {
    @api recordId;
    @track selectedBorrowerId;
    @track selectedIncomeProgram;
    @track showTabs = false;
    @track showExpenseCalculator = false;

    get isGSTProgram() {
        return this.selectedIncomeProgram && this.selectedIncomeProgram === 'GST_Program';
    }
    get isITRProgram() {
        return this.selectedIncomeProgram && this.selectedIncomeProgram === 'ITR';
    }
    get isSelfEmployedAssessedProgram(){
        return this.selectedIncomeProgram && this.selectedIncomeProgram === 'Self_Employed_Assessed';
    }
    get isAbbSurrogateProgram(){
        return this.selectedIncomeProgram && this.selectedIncomeProgram === 'ABB_Surrogate';
    }
    get isShfFinalEligibilityProgram(){
        return this.selectedIncomeProgram && this.selectedIncomeProgram === 'Final_Eligibility_Calculator';
    }
    
    get isEligibilityProgram() {
        return this.selectedIncomeProgram === 'Final_Eligibility_Calculator';
    }

    get showIncomeCalculatorTab() {
        return !this.isEligibilityProgram;
    }


    connectedCallback() {
        console.log('recordId',this.recordId);
    }

    handleSelected(event) {
        console.log('Parent received borrower from child:', event.detail);
        this.showTabs = false;
        this.selectedBorrowerId = event.detail.borrowerId;
        this.selectedIncomeProgram = event.detail.incomeProgram;
        this.checkExpenseTabVisibility(event.detail.borrowerId);
        setTimeout(() => {
            this.showTabs = true;
        }, 0);
    }
    
    handleClear() {
        this.showTabs = false;
        this.selectedBorrowerId = null;
        this.selectedIncomeProgram = null;
        this.showExpenseCalculator = false;
    }

    checkExpenseTabVisibility(borrowerId) {
        getTabVisibilityFlags({ loanApplicantId: borrowerId })
            .then(result => {
                this.showExpenseCalculator = result.showExpenseTab;
            })
            .catch(error => {
                console.error('Error fetching visibility flags', error);
                this.showExpenseCalculator = false;
            });
    }
}