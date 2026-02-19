import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getLMSWrapperData from '@salesforce/apex/SHF_ServiceConsoleLMSControllerWrapper.getLMSWrapperData';
import { CloseActionScreenEvent } from 'lightning/actions';

const FIELDS = ['Case.Application__r.Loan_Agreement_No__c'];

export default class FetchLMSLoanDetail extends LightningElement {
    @api recordId; // Case Id
    loanApplicationName;
    wrapperData;
    error;
    showModal = true;
    isLoading = true;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            try {
                this.loanApplicationName = data.fields.Application__r?.value?.fields?.Loan_Agreement_No__c?.value;

                if (!this.loanApplicationName) {
                    let missingFields = [];
                    if (!this.loanApplicationName) missingFields.push('Application Name');

                    this.handleError(
                        'Required Case fields missing.',
                        {}
                    );
                    return;
                }

                this.fetchLMSData();
            } catch (err) {
                this.handleError('Error extracting field data from Case record.');
            }
        } else if (error) {
            this.handleError('Error retrieving Case record.');
        }
    }


    async fetchLMSData() {
        try {
            this.isLoading = true;
            this.error = null;
            this.wrapperData = null;

            const response = await getLMSWrapperData({
                loanApplicationName: this.loanApplicationName
            });

            if (!response || Object.keys(response).length === 0) {
                // No data received
                this.handleError('No loan data found for this case.');
                return;
            }

            this.wrapperData = response;
        } catch (err) {
            this.handleError('Error fetching loan data from Apex.');
        } finally {
            this.isLoading = false;
        }
    }


    

    handleError(message) {
        this.error = message;
        this.isLoading = false;
        this.wrapperData = null;
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}