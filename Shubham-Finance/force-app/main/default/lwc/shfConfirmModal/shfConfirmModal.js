import { LightningElement, api, track } from 'lwc';

export default class ShfConfirmModal extends LightningElement {
    @track show = false;

    @api
    open() {
        this.show = true;
    }

    close() {
        this.show = false;
    }

    confirm() {
        this.show = false;
        this.dispatchEvent(new CustomEvent('confirm'));
    }
}