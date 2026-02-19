import { LightningElement, track, api } from 'lwc';
import getQueriesForRCU from '@salesforce/apex/shf_SubmitRCUDecision_Controller.getQueriesForRCU';
import updateRCUDecision from '@salesforce/apex/shf_SubmitRCUDecision_Controller.updateRCUDecision';
import getRCURecord from '@salesforce/apex/shf_SubmitRCUDecision_Controller.getRCURecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Shf_SubmitRCUDecision extends LightningElement {

    _recordId;

    @track isModalOpen = false;
    @track decision = '';
    @track comment = '';
    @track rcuScreen = false;

    decisionOptions = [
        { label: 'Ok', value: 'Ok' },
        { label: 'Not Ok', value: 'Not Ok' }
    ];

    // ✅ RecordId Setter (Fix for undefined issue)
    @api
    set recordId(value) {
        this._recordId = value;
        console.log('recordId received:', value);

        if (value) {
            this.initializeComponent();
        }
    }

    get recordId() {
        return this._recordId;
    }

    // ✅ Initialization Logic
    initializeComponent() {

        getQueriesForRCU({ verificationId: this.recordId })
            .then(result => {
                this.rcuScreen = result;

                // FIXED boolean logic
                this.isModalOpen = this.rcuScreen == true ? true :false 

                console.log('isModalOpen :: ', this.isModalOpen);
                console.log('Result :: ', JSON.stringify(result));

                if (!this.rcuScreen) {
                    this.showToast(
                        'Error!',
                        'A query related to this activity is pending for closure',
                        'error'
                    );
                    this.closeAction();
                }
            })
            .catch(error => {
                const errMsg = error.body?.message || error.message;
                console.log('Error in getQueriesForRCU :: ', errMsg);
            });

        getRCURecord({ verificationId: this.recordId })
            .then(result => {
                console.log('RCU Decision record :: ', result);

                if (result == 'RCU Decision already Submitted') {
                    this.closeAction();
                    this.showToast(
                        'Info!',
                        'Decision Already Submitted.',
                        'info'
                    );
                }
            })
            .catch(error => {
                console.log('Error in getRCURecord :: ', error);
            });
    }

    handleDecisionChange(event) {
        this.decision = event.detail.value;
    }

    handleCommentChange(event) {
        this.comment = event.target.value;
    }

    handleSubmit() {

        if (!this.decision) {
            this.showToast('Error', 'RCU Decision is mandatory', 'error');
            return;
        }

        updateRCUDecision({
            verificationId: this.recordId,
            rcuDecision: this.decision,
            comment: this.comment
        })
            .then(result => {
                if (result === 'Success') {
                    this.showToast(
                        'Success!',
                        'RCU decision submitted successfully',
                        'success'
                    );
                    this.closeAction();
                }
            })
            .catch(error => {
                const errMsg = error.body?.message || error.message;
                console.log('Error in updateRCUDecision :: ', errMsg);
                this.showToast('Error', errMsg, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}