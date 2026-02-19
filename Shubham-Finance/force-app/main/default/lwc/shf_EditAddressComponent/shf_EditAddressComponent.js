import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';


const FIELDS = ['Address__c.Loan_Applicant__c','Address__c.Pincode__c'];

export default class Shf_EditAddressComponent extends LightningElement {
    @api recordId;
    @track isShowAddress = false;
    addressId;
    pincodeId;
    isEditAdd = true;
    loanApplicantId;

    @wire(CurrentPageReference)
    getAddressId(currentPageReference) {
        if (currentPageReference.state.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference.attributes.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }
        console.log('recordId-> ', this.recordId);
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAddressRecord({ error, data }) {
        if (error) {
            console.error('wiredAddressRecord=> ', error);
        } if (data) {
            let addressRecord = data;
            console.log('wiredAddressRecord= ', addressRecord);
            this.loanApplicantId = addressRecord.fields.Loan_Applicant__c.value;
            this.pincodeId = addressRecord.fields.Pincode__c.value;
            console.log('inside edit pinId ', this.pincodeId);
            this.isShowAddress = true;
        }
    }

    handleAddressClose(event) {
        console.log('in dynamicList Handle Close', event.detail);
        this.isShowAddress = event.detail;
         this.dispatchEvent(new CloseActionScreenEvent());
    }
    handleCloseMethod(event){
        console.log('close parent method', event);
    }

}