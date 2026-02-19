import { LightningElement, api,wire } from 'lwc';
import getExpense from '@salesforce/apex/ExpenseCalculatorController.getExpense';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';

export default class ExpenseCalculator extends LightningElement {
    @api recordId; // Loan_Applicant__c Id

    dto;
    errorMessage;
    isLoading = false;

    columns = [
        { label: 'Field', fieldName: 'label', type: 'text', wrapText: true },
        { label: 'Value', fieldName: 'value', type: 'text', wrapText: true }
    ];
    subscription = null;
    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        console.error('Expense Calculator Record ID:', this.recordId);
        this.recordId = this.recordId ?? this.getAttribute('recordId');
        this.fetchData();
        this.subscribeToMessageChannel();
    }
     disconnectedCallback() {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
     subscribeToMessageChannel() {
            if (!this.subscription) {
                this.subscription = subscribe(
                    this.messageContext,
                    CALCULATOR_REFRESH_CHANNEL,
                    (message) => this.handleMessage(message),
                    { scope: APPLICATION_SCOPE }
                );
            }
        }
    
        handleMessage(message) {
            if(message.recordId !== this.recordId) {
                console.error('ID Mismatch! Message ID:', message.recordId, 'Current ID:', this.recordId);
                console.warn(`ID Mismatch! Message ID: ${message.recordId}, Current ID: ${this.recordId}`);
            }
            this.handleRefresh();
        }

    async fetchData() {
        
        if (!this.recordId) return;

        this.isLoading = true;
        this.errorMessage = null;

        try {
            const res = await getExpense({ loanApplicantId: this.recordId });
            this.dto = res;
        } catch (e) {
            this.dto = null;
            this.errorMessage = this.normalizeError(e);
        } finally {
            this.isLoading = false;
        }
    }

    handleRefresh() {
        this.fetchData(); // force call again
    }

    get showTable() {
        return !!(this.dto && this.dto.showCalculator);
    }

    get tableData() {
        if (!this.showTable) return [];

        const d = this.dto;

        return [
            { id: 'branch', label: 'Branch', value: d.branchName ?? '' },
            { id: 'totalIncome', label: 'Total Income', value: this.fmt(d.totalIncome) },
            { id: 'familyMembers', label: '# Family Members (Loan Applicants Count)', value: String(d.familyMembers ?? 0) },
            { id: 'residence', label: 'Residence Type (Is Without Rent)', value: d.residenceTypeYesNo ?? '' },
            { id: 'emi', label: 'Existing Loan EMI', value: this.fmt(d.existingLoanEmi) },
            { id: 'insurance', label: 'Insurance Premium', value: this.fmt(d.insurancePremium) },
            { id: 'total', label: 'Total Expenses', value: this.fmt(d.totalExpenses) }
        ];
    }

    fmt(val) {
        const num = Number(val ?? 0);
        return new Intl.NumberFormat('en-IN', { maximumFractionDigits: 2 }).format(num);
    }

    normalizeError(error) {
        try {
            if (Array.isArray(error?.body)) {
                return error.body.map(e => e.message).join(', ');
            }
            if (typeof error?.body?.message === 'string') {
                return error.body.message;
            }
            if (typeof error?.message === 'string') {
                return error.message;
            }
            return 'Unknown error occurred.';
        } catch (e) {
            return 'Unknown error occurred.';
        }
    }
}