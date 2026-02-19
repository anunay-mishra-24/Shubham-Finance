import { LightningElement, api, track } from 'lwc';
import getApplicantReadOnlyData from '@salesforce/apex/SHF_FinancialCalculatorController.getApplicantReadOnlyData';

export default class ShfFinancialPersonalInformation extends LightningElement {
    @api applicantId;
    @track applicantData = null;

    connectedCallback() {
        if (this.applicantId) {
            this.loadData();
        }
    }

    loadData() {
        getApplicantReadOnlyData({ applicantId: this.applicantId })
            .then(data => {
                this.applicantData = data;
            })
            .catch(error => {
                console.error('Error loading applicant data:', error);
            });
    }
}