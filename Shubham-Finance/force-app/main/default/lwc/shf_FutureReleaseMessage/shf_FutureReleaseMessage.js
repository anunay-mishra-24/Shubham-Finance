import { LightningElement } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Shf_FutureReleaseMessage extends LightningElement {
    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}