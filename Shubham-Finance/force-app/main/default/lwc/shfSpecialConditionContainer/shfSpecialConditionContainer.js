import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import PARENT_ID from '@salesforce/schema/Verification__c.Application__c';
export default class ShfSpecialConditionContainer extends LightningElement {
    @api recordId;
    @track applicationId;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [PARENT_ID]
    })
    wiredApplication({ data, error }) {
        console.log('data = ', this.recordId, data);
        if (data) {
            this.applicationId = data.fields.Application__c.value;
        } else if (error) {
            console.error('Error loading application', error);
        }
    }
}