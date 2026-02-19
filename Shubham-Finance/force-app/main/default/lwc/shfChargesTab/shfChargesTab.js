import { LightningElement, wire, api, track } from 'lwc';
import getCharges from '@salesforce/apex/SHF_ChargeService.getFees';
import checkIsBureauInitiatedOrNot from '@salesforce/apex/SHF_FeeCreationHandler.checkIsBureauInitiatedOrNot';
const actions = [
    { label: 'Fee Collection', name: 'Fee_Collection' }
];
export default class ShfChargesTable extends LightningElement {
    @api recordId;
    @track charges = [];
    @track feeObj;
    @track isShowModal = false;

    columns = [
        { label: 'Type of Charge', fieldName: 'typeOfCharge', cellAttributes: { alignment: 'left' } },
        {
            label: 'GST (%)',
            fieldName: 'gstDisplay',
            type: 'text',
            cellAttributes: { alignment: 'left' }
        },
        { label: 'Charge Sub Type', fieldName: 'chargeSubType', cellAttributes: { alignment: 'left' } },
        { label: 'Related To', fieldName: 'relatedTo', cellAttributes: { alignment: 'left' } },
        { label: 'Status', fieldName: 'status', cellAttributes: { alignment: 'left' } },
        {
            label: 'Amount',
            fieldName: 'amount',
            type: 'currency',
            cellAttributes: { alignment: 'left' }
        }, {
            type: 'action',
            typeAttributes: { rowActions: actions },
        }
    ];

    @wire(getCharges, { applicationId: '$recordId' })
    wiredCharges({ data, error }) {
        if (data) {
            this.charges = data.map(row => ({
                id: row.Id,
                typeOfCharge: row.Fee_Type__c,
                gst: row.Tax__c,
                gstDisplay: row.Tax__c == null ? 'N/A' : row.Tax__c.toString(),
                chargeSubType: row.Charge_Sub_Type__c,
                relatedTo: row.Related_To__c,
                amount: row.Amount__c,
                status: row.Status__c,
                type: row.Charge_Master__c ? row.Charge_Master__r.Charge_Sub_Type__c : 'Deductible'
            }));
        } else if (error) {
            console.error('Error loading charges:', error);
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        console.log('actionName', actionName);
        const row = event.detail.row;
        console.log('actionName', row);
        this.feeObj = JSON.parse(JSON.stringify(row))
        if (this.feeObj && this.feeObj.type != 'Collectible' && this.feeObj.status != 'Pending')
            return;
        if (actionName == 'Fee_Collection') {
            checkIsBureauInitiatedOrNot({ applicationId: this.recordId }).then(res => {
                if (!res) {
                    this.showToastMsg('Error', 'Bureau check must be completed before initiating fee collection.', 'error');
                    return;
                } else {
                    this.isShowModal = true;
                }
            })
        }
    }

    hideModalBox() {
        this.isShowModal = false;
    }
}