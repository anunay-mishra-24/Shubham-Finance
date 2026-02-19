import { LightningElement, api } from 'lwc';
import getDuplicateLeads from '@salesforce/apex/SHF_DuplicateLeadController.getDuplicateLeads';

export default class ShfLeadDuplicateTileView extends LightningElement {
    leads = [];
    isLoading = true;

    _recordId;

    @api
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadDuplicates();
        }
    }

    get recordId() {
        return this._recordId;
    }

    loadDuplicates() {
        getDuplicateLeads({ leadId: this.recordId })
            .then(result => {
                this.leads = result.map(rec => ({
                    ...rec,
                    createdDateFormatted: new Date(rec.CreatedDate).toLocaleString()
                }));
            })
            .catch(error => {
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get hasRecords() {
        return this.leads.length > 0;
    }

    get totalRecords() {
        return this.leads.length;
    }

    get duplicateLabel() {
        return `Duplicate Records (${this.totalRecords})`;
    }
}