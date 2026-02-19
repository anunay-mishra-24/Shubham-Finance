import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getRepaymentSchedule from '@salesforce/apex/SHF_RepaymentScheduleLMSService.getLoanDetails';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = ['Case.Application__r.Loan_Agreement_No__c'];

export default class FetchRepaymentScheduleDetails extends LightningElement {
    @api recordId;

    loanApplicationName;
    repaymentData = [];

    isLoading = true;
    showModal = true;
    error = null;

    columns = [
        { label: 'Installment Number', fieldName: 'installmentNumber', type: 'number', cellAttributes: { alignment: 'center' }},
        { label: 'Due Date', fieldName: 'dueDate', type: 'date', cellAttributes: { alignment: 'center' }},
        { label: 'Days', fieldName: 'days', type: 'number', cellAttributes: { alignment: 'center' }},
        { label: 'Opening Balance', fieldName: 'openingBalance', type: 'currency', cellAttributes: { alignment: 'center' }},
        { label: 'Principal', fieldName: 'principal', type: 'currency', cellAttributes: { alignment: 'center' }},
        { label: 'Interest', fieldName: 'interest', type: 'currency', cellAttributes: { alignment: 'center' }},
        { label: 'Installment', fieldName: 'installment', type: 'currency', cellAttributes: { alignment: 'center' }},
        { label: 'Effective Rate (%)', fieldName: 'effectiveRate', type: 'text', cellAttributes: { alignment: 'center' }}
    ];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    async wiredCase({ error, data }) {
        if (data) {
            try {
                const app = data.fields.Application__r?.value?.fields?.Loan_Agreement_No__c?.value;
                console.log('app ',app);
                if (app) {
                    this.loanApplicationName = app;
                    await this.fetchLMSData();
                    console.log('Loan Application ',this.loanApplicationName);
                } else {
                    this.handleError('Loan Application Name not found');
                }
            } catch (err) {
                this.handleError('Error reading Application Name');
                console.error(err);
            }
        } else if (error) {
            this.handleError('Error loading Case record');
            console.error(error);
        }
    }

    async fetchLMSData() {
        try {
            const result = await getRepaymentSchedule({ loanApplicationName: this.loanApplicationName });
            if (Array.isArray(result) && result.length > 0) {
                this.repaymentData = result;
                this.error = null;
            } else {
                this.repaymentData = [];
                this.handleError('No repayment data found for this application.');
            }
        } catch (err) {
            this.handleError('Failed to fetch repayment schedule.');
            console.error(err);
        } finally {
            this.isLoading = false;
        }
    }

    handleError(message) {
        this.error = message;
        this.showErrorToast(message);
        this.isLoading = false;
    }

    showErrorToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message,
            variant: 'error'
        }));
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}