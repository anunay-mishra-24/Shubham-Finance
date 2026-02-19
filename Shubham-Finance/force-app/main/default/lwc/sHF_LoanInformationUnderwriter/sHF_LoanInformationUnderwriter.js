import { LightningElement, api, wire } from 'lwc';
import getSummary from '@salesforce/apex/SHF_LoanInformationUnderwriterController.getSummary';

export default class SHF_LoanInformationUnderwriter extends LightningElement {
    @api recordId; // Application__c Id

    rows = [];
    error;

    columns = [
        { label: 'Sanction Amount', fieldName: 'sanctionAmount', type: 'currency', initialWidth: 200 },
        { label: 'ROI', fieldName: 'roi', type: 'number', typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 }, initialWidth: 150 },
        { label: 'Tenure', fieldName: 'tenure', type: 'number', typeAttributes: { maximumFractionDigits: 0 }, initialWidth: 150 },
        { label: 'Loan Amount', fieldName: 'loanAmount', type: 'currency', initialWidth: 150 },
        { label: 'Loan Purpose', fieldName: 'loanPurpose', type: 'text', wrapText: true, initialWidth: 250 },
        { label: 'Insurance', fieldName: 'insuranceTotal', type: 'currency', initialWidth: 150 },
        { label: 'Loan Amount (Including Insurance)', fieldName: 'sanctionIncludingInsurance', type: 'currency', initialWidth: 350 }
    ];

    @wire(getSummary, { applicationId: '$recordId' })
    wiredSummary({ data, error }) {
        if (data) {
            this.rows = data;
            this.error = undefined;
        } else if (error) {
            this.rows = [];
            this.error = error?.body?.message || 'Failed to load summary.';
        }
    }
}