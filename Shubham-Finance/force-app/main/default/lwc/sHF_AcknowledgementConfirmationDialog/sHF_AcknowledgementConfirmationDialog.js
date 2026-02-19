import { LightningElement,track,api } from 'lwc';
export default class SHF_AcknowledgementConfirmationDialog extends LightningElement {

    @api isOpen = false;
    @api statusOptions = [];

    @track selectedStatus = '';
    @track comments = '';
    @api title;
    
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }

    handleCommentChange(event) {
        this.comments = event.detail.value;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleConfirm() {
        const allInputs = this.template.querySelectorAll('lightning-combobox, lightning-textarea');
        let isValid = true;

        allInputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });

        if (!isValid) {
            return;
        }
        this.dispatchEvent(new CustomEvent('confirm', {
            detail: {
                status: this.selectedStatus,
                comments: this.comments
            }
        }));
    }



}