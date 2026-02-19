import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getQueriesForVerificationActivity from '@salesforce/apex/shf_QueryController.getQueriesForVerificationActivity';

export default class QueryDataTable extends LightningElement {
    recordId;
    queryData = [];
    error;

    columns = [
        { label: 'Query Name', fieldName: 'Name' },
        { label: 'Subject', fieldName: 'Subject__c' },
        { label: 'Status', fieldName: 'Query_Status__c' },
        { label: 'Type of Query', fieldName: 'Type_of_Query__c' },
        { label: 'Type of User', fieldName: 'Type_of_User__c' },
        { label: 'Assigned To', fieldName: 'Assigned_to__rName', type: 'text' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('CurrentPageReference:', currentPageReference);

        if (currentPageReference) {
            this.recordId = currentPageReference.attributes?.recordId;

            if (!this.recordId && currentPageReference.state?.c__recordId) {
                this.recordId = currentPageReference.state.c__recordId;
            }

            if (!this.recordId) {
                const pathParts = window.location.pathname.split('/');
                const lastSegment = pathParts[pathParts.length - 1];
                if (/^va[a-zA-Z0-9]{6,}$/.test(lastSegment)) {
                    this.recordId = lastSegment;
                }
            }

            if (this.recordId) {
                this.loadQueries();
            }
        }
    }

    loadQueries() {
        getQueriesForVerificationActivity({ verificationActivityId: this.recordId })
            .then((data) => {
                console.log('Query Data:', data);
                this.queryData = data.map(item => ({
                    ...item,
                    Assigned_to__rName: item.Assigned_to__r ? item.Assigned_to__r.Name : ''
                }));
                this.error = undefined;
            })
            .catch((error) => {
                console.error('Error fetching queries:', error);
                this.error = error;
                this.queryData = [];
            });
    }
}