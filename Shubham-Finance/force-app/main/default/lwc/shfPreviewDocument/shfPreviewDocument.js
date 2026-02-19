import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPreviewUrl from '@salesforce/apex/SHF_DMSController.getPreviewUrl';

export default class ShfPreviewDocument extends LightningElement {
    @track showSpinner = false;
    @api documentId;

    @api preview(documentId) {
        if (!documentId) {
            this.showToast('Error', 'Document Id is required for preview.', 'error');
            return;
        }

        this.showSpinner = true;

        getPreviewUrl({ documentId: documentId })
            .then(url => {
                this.showSpinner = false;
                if (url) {
                    window.open(url, '_blank'); // Opens new tab
                } else {
                    this.showToast('Error', 'Unable to generate preview URL.', 'error');
                }
            })
            .catch(error => {
                this.showSpinner = false;
                this.showToast('Error', error.body?.message || 'Failed to preview document.', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}