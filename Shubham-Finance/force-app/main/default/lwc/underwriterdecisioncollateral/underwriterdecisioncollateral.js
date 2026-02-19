import { LightningElement, api, wire, track } from 'lwc';
import getCollaterals from '@salesforce/apex/UnderwriterDecisionCollateral.getCollaterals';

const COLUMNS = [
    {
        label: 'Collateral Address',
        fieldName: 'Collateral_Address__c',
        type: 'text',
        wrapText: true
    },
    {
        label: 'Net LTV',
        fieldName: 'LTV__c',
        type: 'number',
        cellAttributes: { alignment: 'right' },
        typeAttributes: { maximumFractionDigits: 2 }
    },
    {
        label: 'Cost of Property',
        fieldName: 'Cost_of_property__c',
        type: 'currency',
        cellAttributes: { alignment: 'right' },
        typeAttributes: { currencyCode: 'INR', maximumFractionDigits: 2 }
    },
    {
        label: 'Market Value',
        fieldName: 'Market_Value__c',
        type: 'currency',
        cellAttributes: { alignment: 'right' },
        typeAttributes: { currencyCode: 'INR', maximumFractionDigits: 2 }
    }
];

export default class Underwriterdecisioncollateral extends LightningElement {
    @api applicationId;

    columns = COLUMNS;

    @track rows = [];
    errorMessage = '';
    isLoading = false;

    @wire(getCollaterals, { applicationId: '$applicationId' })
    wiredCollaterals({ data, error }) {
        this.isLoading = true;
        this.errorMessage = '';

        if (data) {
            this.rows = data;
        } else if (error) {
            this.rows = [];
            this.errorMessage = this.normalizeError(error);
        }

        this.isLoading = false;
    }

    get hasData() {
        return Array.isArray(this.rows) && this.rows.length > 0;
    }

    normalizeError(err) {
    const messages = [];

    try {
        if (!err) return '';
        const body = err.body;

        //  Array of errors       @AnunayKumar
        if (Array.isArray(body)) {
            messages.push(...body.map(e => e?.message).filter(Boolean));
        }

        //  Single error object         @AnunayKumar
        if (body && !Array.isArray(body)) {
            if (body.message) messages.push(body.message);

            // UI API / LDS style errors       @AnunayKumar
            const output = body.output;
            if (output) {
                if (Array.isArray(output.errors) && output.errors.length) {
                    messages.push(...output.errors.map(e => e?.message).filter(Boolean));
                }

                const fieldErrors = output.fieldErrors || {};
                Object.values(fieldErrors).forEach(errArr => {
                    if (Array.isArray(errArr)) {
                        messages.push(...errArr.map(e => e?.message).filter(Boolean));
                    }
                });

                if (Array.isArray(output.pageErrors) && output.pageErrors.length) {
                    messages.push(...output.pageErrors.map(e => e?.message).filter(Boolean));
                }
            }
        }

        // 3) Generic JS error fields       @AnunayKumar
        if (err.message) messages.push(err.message);
        if (err.statusText) messages.push(err.statusText);

        // Remove duplicates + blanks     @AnunayKumar
        const unique = [...new Set(messages.filter(m => m && m.trim()))];
        if (unique.length) return unique.join(' | ');

        // Last fallback: show raw object     @AnunayKumar
        try {
            return JSON.stringify(err);
        } catch (e) {
            return String(err);
        }
    } catch (e) {
        // Even if parsing fails       @AnunayKumar
        try {
            return JSON.stringify(err);
        } catch (ex) {
            return 'Error object could not be parsed';
        }
    }
}

}