import { LightningElement, api, track, wire } from 'lwc';
import loadRiskData from '@salesforce/apex/SHF_RiskCalculation.loadRiskData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';

export default class Shf_RiskCalculation extends LightningElement {
    @api recordId;
    emptyInput = [];
    @track errorMessages = [];
    @track showErrorModal = false;
    @track isLoading = false;

    @wire(CurrentPageReference)
    getAddressId(currentPageReference) {
        if (currentPageReference.state.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference.attributes.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }
        console.log('recordId-> ', this.recordId);
    }

    connectedCallback() {
        this.isLoading = true;

        this.fetchRiskData();
    }

    fetchRiskData() {
        this.dispatchEvent(new CloseActionScreenEvent());
        console.log('recordId?? ', this.recordId);
        loadRiskData({ applicationId: this.recordId })
            .then((data) => {
                console.log('Risk Data:', data);

                if (data) {
                    console.log('this.emptyInput ', data);

                    if (data.startsWith('ERROR')) {
                        // Split multiple error lines if any (using semicolon or newline)
                        const cleanMsg = data.replace('ERROR: ', '');
                        this.errorMessages = cleanMsg
                            .split(/[\n;]+/)
                            .map((msg) => msg.trim())
                            .filter((msg) => msg);

                        this.showErrorModal = true;
                    } else {
                        this.showToast('Success : ', 'Risk Calculation done successfully', 'success');
                        this.dispatchEvent(new CloseActionScreenEvent());
                        window.setTimeout(() => {
                            window.location.reload();
                        }, 1000);
                        // Call risk calculation method
                        //this.callCalculateRisk();
                    }
                    this.isLoading = false;
                }
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Error fetching risk data:', error);
            });
    }

    showToast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleCloseModal() {
        this.showErrorModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());

    }
}