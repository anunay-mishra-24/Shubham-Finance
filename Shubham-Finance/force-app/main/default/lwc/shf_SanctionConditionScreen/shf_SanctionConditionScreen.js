import { LightningElement, api, track, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class Shf_SanctionConditionScreen extends LightningElement {
    @api recordId;
    @track obligations = [];

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Obligations__r',
        fields: [
            'Obligation__c.Loan_Id__c',
            'Obligation__c.Product__c',
            'Obligation__c.Institution__c',
            'Obligation__c.Considered_for_FOIR__c',
            'Obligation__c.Consider_To_be_Deleted__c'
        ],
        sortBy: 'CreatedDate'
    })
    wiredObligations({ error, data }) {
        if (data) {
            this.obligations = data.records
                .filter(rec => rec.fields.Considered_for_FOIR__c.value !== 'Yes' &&
                               rec.fields.Considered_for_FOIR__c.value !== 'No'  &&
                               rec.fields.Consider_To_be_Deleted__c.value !== true)
                .map((rec, index) => ({
                    srNo: index + 1,
                    description: `The Loan ${rec.fields.Loan_Id__c.value} for ${rec.fields.Product__c.value} from ${rec.fields.Institution__c.value} is requested for ${rec.fields.Considered_for_FOIR__c.value}.`
                }));
        } else if (error) {
            console.error(error);
        }
    }
}