import { LightningElement, track, wire, api  } from 'lwc';
export default class Shf_CreateManualDeviation extends LightningElement {
    @track isFlowInvoked = false;
    @track inputVariables = [];
    @api recordId;
    
    connectedCallback() {
        console.log('recordId-> ', this.recordId);
    }

    handleClick(event) {
         this.inputVariables = [];
        this.inputVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: this.recordId
                }
           ];
        this.isFlowInvoked = true;
    }

    handleStatusChange(event){
         if (event.detail.status === 'FINISHED') {
        this.isFlowInvoked = false;
         window.setTimeout(() => {
                     window.location.reload();
                }, 100);
    }
}
    
    handleClose(event){
        this.isFlowInvoked = false;
    }

}