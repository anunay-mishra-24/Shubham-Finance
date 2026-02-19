import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApplicantFinancialRows from '@salesforce/apex/SHF_UWApplicantFinancialTableController.getApplicantFinancialRows';

const COLUMNS = [
    {
        label: 'Applicant Name',
        fieldName: 'applicantLink',
        type: 'url', initialWidth: 600,
        typeAttributes: {
            label: { fieldName: 'applicantName' },
            target: '_blank'
        },
        wraptext: false
    },
    {
        label: 'Appraised Income',
        fieldName: 'appraisedIncome',
        wraptext: false, initialWidth: 600,
        type: 'number',
        cellAttributes: { alignment: 'left' },
        typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 }
    },
    { label: 'Income Program', fieldName: 'incomeProgram', type: 'text', wraptext: false, initialWidth: 600 }
];

export default class ShfUnderwriterDecisionApplicantFinancialTable extends LightningElement {
    @api recordId; // Application Id

    columns = COLUMNS;
    @track rows = [];
    isLoading = true;

    get noData() {
        return !this.isLoading && (!this.rows || this.rows.length === 0);
    }

    @wire(getApplicantFinancialRows, { applicationId: '$recordId' })
    wiredRows({ data, error }) {
        this.isLoading = false;

        if (data) {
            // normalize for UI
            this.rows = (data || []).map(r => ({
                ...r,
                applicantLink: '/' + r.applicantId,
                incomeProgram: r.incomeProgram ? r.incomeProgram : '-',
                appraisedIncome: r.appraisedIncome ?? 0
            }));
        } else if (error) {
            this.rows = [];
            this.showToast('Error', this.reduceErrors(error).join(', '), 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        return (
            errors
                .filter(e => !!e)
                .map(e => {
                    if (Array.isArray(e.body)) {
                        return e.body.map(err => err.message);
                    } else if (e.body && typeof e.body.message === 'string') {
                        return e.body.message;
                    } else if (typeof e.message === 'string') {
                        return e.message;
                    }
                    return 'Unknown error';
                })
                .reduce((prev, curr) => prev.concat(curr), [])
                .filter(message => !!message)
        );
    }
}