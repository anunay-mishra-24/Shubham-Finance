import { LightningElement, track } from 'lwc';
import searchCustomer from '@salesforce/apex/SearchCustomerController.searchCustomer';

export default class SearchCustomer extends LightningElement {
    @track loanAppName = '';
    @track mobileNumber = '';
    @track results;
    
    columns = [
    { label: 'Application Name', fieldName: 'Name' },
    { label: 'Mobile Number', fieldName: 'Phone' },
    { label: 'Account Name', fieldName: 'AccountName' },
    { label: 'Type', fieldName: 'RecordType' }
    ];

    handleLoanAppChange(event) {
        this.loanAppName = event.target.value;
    }

    handleMobileChange(event) {
        this.mobileNumber = event.target.value;
    }

    handleClear() {
        this.loanAppName = '';
        this.mobileNumber = '';
        this.results = undefined;
    }

    handleSearch() {
        searchCustomer({ 
            loanAppName: this.loanAppName, 
            mobileNumber: this.mobileNumber 
        })
        .then(data => {
            this.results = data;
        })
        .catch(error => {
            console.error(error);
            this.results = [];
        });
    }
}