import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

export default class ShfAccountForm extends LightningElement {
    @track customerRecordTypeId;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    getObjectInfoHandler({ data, error }) {
        if (data) {
            const rtis = data.recordTypeInfos;
            // Find record type where name is Customer
            const customerRT = Object.values(rtis).find(rti => rti.name === 'Customer');
            if (customerRT) {
                this.customerRecordTypeId = customerRT.recordTypeId;
            } else {
                console.error('❌ Customer RecordType not found');
            }
        } else if (error) {
            console.error('Error fetching object info: ', error);
        }
    }

    handleSuccess(event) {
        const accountId = event.detail.id;
        console.log('✅ Account created with Id: ', accountId);

        // Show toast
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Account created successfully!',
                variant: 'success'
            })
        );

        // Fire event to parent (to open applicant modal next)
        this.dispatchEvent(new CustomEvent('accountcreated', {
            detail: { accountId }
        }));

        // Close the account modal
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    /*handleCancel() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }*/

    handleError(event) {
        console.error('Error creating account', event.detail);
    }
}