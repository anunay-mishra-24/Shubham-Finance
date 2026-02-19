import { LightningElement, api, wire, track } from 'lwc';
import getNextBranchManager from '@salesforce/apex/SHF_LeadBranchAssignmentController.getNextBranchManager';
import assignLeadToUser from '@salesforce/apex/SHF_LeadBranchAssignmentController.assignLeadToUser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

export default class SHF_LeadSubmitAction extends NavigationMixin(LightningElement) {

    @api recordId;
    @track userName;
    userId;
    isLoading = true;

    @wire(getNextBranchManager, { leadId: '$recordId' })
    wiredUser({ error, data }) {
        this.isLoading = false;

        if (data) {
            this.userName = data.Name;
            this.userId = data.Id;
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    handleSave() {
        this.isLoading = true;

        assignLeadToUser({
            leadId: this.recordId,
            userId: this.userId
        })
        .then(() => {
            this.isLoading = false;
            this.showToast(
                'Success',
                'The Lead has been assigned successfully',
                'success'
            );
            this.dispatchEvent(new CloseActionScreenEvent());

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Lead__c', 
                    actionName: 'view'
                }
            });
        })
        .catch(error => {
            this.isLoading = false;
            this.showToast('Error', error.body.message, 'error');
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
}