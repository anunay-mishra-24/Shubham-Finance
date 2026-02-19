import { LightningElement, wire, api, track } from 'lwc';
//import getCharges from '@salesforce/apex/SHF_ChargeService.getCharges';
import getfees from '@salesforce/apex/SHF_FeeCreationHandler.getFees';
import checkIsBureauInitiatedOrNot from '@salesforce/apex/SHF_FeeCreationHandler.checkIsBureauInitiatedOrNot';
const actions = [
    { label: 'Fee Collection', name: 'Fee_Collection' }
];
export default class ShfFeeAndCharges extends LightningElement {
    @api recordId;
    @track charges = [];
    @track feeObj;

    // columns = [
    //     { label: 'Type of Charge', fieldName: 'typeOfCharge', cellAttributes: { alignment: 'left' } },
    //     { 
    //         label: 'GST (%)', 
    //         fieldName: 'gstDisplay', 
    //         type: 'text', 
    //         cellAttributes: { alignment: 'left' } 
    //     },
    //     { label: 'Charge Sub Type', fieldName: 'chargeSubType', cellAttributes: { alignment: 'left' } },
    //     { label: 'Related To', fieldName: 'relatedTo', cellAttributes: { alignment: 'left' } },
    //     { 
    //         label: 'Amount', 
    //         fieldName: 'amount', 
    //         type: 'currency',
    //         cellAttributes: { alignment: 'left' } 
    //     }
    // ];
    columns = [
        { label: 'Type of Charge', fieldName: 'Fee_Type__c', cellAttributes: { alignment: 'left' } },
        {
            label: 'Tax (%)',
            fieldName: 'Tax__c',
            type: 'text',
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Amount',
            fieldName: 'Amount__c',
            type: 'currency',
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Status',
            fieldName: 'Status__c',
            type: 'text',
            cellAttributes: { alignment: 'left' }
        }, {
            type: 'action',
            typeAttributes: { rowActions: actions },
        }
    ];

    // @wire(getCharges, { applicationId: '$recordId' })
    // wiredCharges({ data, error }) {
    //     if (data) {
    //         // If GST is null, show "N/A"
    //         this.charges = data.map(row => ({
    //             ...row,
    //             gstDisplay: row.gst == null ? 'N/A' : row.gst.toString()
    //         }));
    //     } else if (error) {
    //         console.error('Error loading charges:', error);
    //     }
    // }
    @track isShowModal = false;

    hideModalBox() {
        this.isShowModal = false;
    }
    @wire(getfees, { applicationId: '$recordId' })
    wiredCharges({ data, error }) {
        if (data) {
            console.log('data', data);
            this.charges = data;
        } else if (error) {
            console.error('Error loading charges:', error);
        }
    }

    connectedCallback() {
        getfees({ applicationId: this.recordId }).then(res => {
            console.log('res', res);

        }).catch((err) => {

        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.feeObj = JSON.parse(JSON.stringify(row))
        console.log('actionName', actionName);
        console.log('this.feeObj', this.feeObj);
        if (actionName == 'Fee_Collection') {
            this.selectedApplicantId = row.Loan_Applicant__c;
            console.log('selectedApplicantId : ', this.selectedApplicantId);

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
}