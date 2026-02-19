import { LightningElement, api, wire, track } from 'lwc';
import getBranchUsers from '@salesforce/apex/SHF_VerificationReassignController.getBranchUsers';
import reassignVerification from '@salesforce/apex/SHF_VerificationReassignController.reassignVerification';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Shf_VerificationReassignAction extends LightningElement {
    @api recordId;
    @track userOptions = [];
    @track selectedUser;
    @track comments;
    disableButton = true;

    @wire(getBranchUsers, { verificationId: '$recordId' })
    wiredUsers({ data, error }) {
        if (data) {
            this.userOptions = data.map(user => ({
                label: user.Name,
                value: user.Id
            }));
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    handleChange(event) {
        this.selectedUser = event.detail.value;
        this.disableButton = false;
    }

    handleCommentChange(event) {
        this.comments = event.detail.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleReassign() {
        reassignVerification({
            verificationId: this.recordId,
            newOwnerId: this.selectedUser,
            comments: this.comments
        })
        .then(() => {
            this.showToast('Success', 'Verification reassigned successfully', 'success');
            this.dispatchEvent(new CloseActionScreenEvent());

            setTimeout(() => {
                window.location.reload();
            }, 500);

        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}