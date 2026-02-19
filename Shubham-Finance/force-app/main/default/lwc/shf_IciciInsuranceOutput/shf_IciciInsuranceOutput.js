import { LightningElement, api, wire, track } from 'lwc';
import { getRecords } from 'lightning/uiRecordApi';

const FIELDS = ['Insurance__c.Name'];
export default class Shf_IciciInsuranceOutput extends LightningElement {
    @api recordId;

    @track insuranceObject = {};

    @wire(getRecords, {recordId: '$recordId', fields: FIELDS})
    wiredRecord({ error, data }) {
        if (error) {
            console.error('Insurance Output Error ', JSON.stringify(error));
        } else if (data) {
            //this.name = data.fields.Name.value;
            //this.phone = data.fields.Phone.value;
        }
    }
}