import { LightningElement,api } from 'lwc';
export default class GenericFormLwc extends LightningElement {
    objectApiName = 'Employemnt__c';
    recordTypeId = '012C1000001Cup3IAC';
    @api accountId;
    handleSuccess(event) {
        const evt = new CustomEvent("done", { detail: event.detail.id });
        this.dispatchEvent(evt);
    }

}