import { LightningElement, api } from 'lwc';
export default class ShfEnachModal extends LightningElement {

    @api recordId;
    customerName = '';
    accountNo = '';
    mobile = '';
    email = '';
    debitAmount = '';
    startDate = '';
    expiryDate = '';
    debitFrequency = '';
    sequenceType = '';

    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleProceedClick() {
        console.log('click on proceed button==>');
        this.dispatchEvent(
            new CustomEvent('proceed', {
                detail: {
                    customerName: this.customerName,
                    accountNo: this.accountNo,
                    mobile: this.mobile,
                    email: this.email,
                    debitAmount: this.debitAmount,
                    startDate: this.startDate,
                    expiryDate: this.expiryDate,
                    debitFrequency: this.debitFrequency,
                    sequenceType: this.sequenceType
                }
            })
        );
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}