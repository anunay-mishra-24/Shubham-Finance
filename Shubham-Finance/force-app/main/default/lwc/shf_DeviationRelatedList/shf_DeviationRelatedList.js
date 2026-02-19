import { LightningElement, api, wire, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class Shf_DeviationRelatedList extends LightningElement {
    @api recordId; 

    @track children = [];
    @track error;

    // Columns 
    columns = [
        {label: 'Name', fieldName: 'recordLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        { label: 'Deviation Name', fieldName: 'Deviation_Name__c', type: 'text' },
        { label: 'Decision', fieldName: 'Decision__c', type: 'text' },
        { label: 'Decision By', fieldName: 'Decision_By_Name', type: 'text' } 
    ];

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Deviation_and_Sanction_Conditions__r', 
        fields: [
            'Deviation_and_Sanction_Condition__c.Id',
            'Deviation_and_Sanction_Condition__c.Name',
            'Deviation_and_Sanction_Condition__c.Deviation_Name__c',
            'Deviation_and_Sanction_Condition__c.Decision__c',
            'Deviation_and_Sanction_Condition__c.Decision_By__r.Name' 
        ]
    })
    wiredRelated({ error, data }) {
    if (data) {
        this.children = data.records.map(r => {
            const f = r.fields;
            return {
                Id: r.id,
                recordLink: '/' + r.id,
                Name: f.Name.value,
                Deviation_Name__c: f.Deviation_Name__c.value,
                Decision__c: f.Decision__c.value,
                // Correct way to get User Name
                Decision_By_Name: f.Decision_By__r?.displayValue || f.Decision_By__r?.value?.fields?.Name?.value || ''
            };
        }).filter(r => r.Decision__c !== 'Approved');
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.children = [];
        }
    }

    get hasRecords() {
        return this.children.length > 0;
    }
}