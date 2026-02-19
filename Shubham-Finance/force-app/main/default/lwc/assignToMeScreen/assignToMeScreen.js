// assignToMeModal.js
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import assignToCurrentUser from '@salesforce/apex/SHF_DMSController.assignToCurrentUser';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';

export default class AssignToMeScreen extends LightningElement {
    @api recordIds = [];
    @track isOpen = true;
    currentUser = USER_ID; // or pass user name from Apex if needed

    closeModal() {
        this.isOpen = false;
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSave() {
        assignToCurrentUser({ recordIds: this.recordIds })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Records assigned successfully',
                        variant: 'success'
                    })
                );
                this.closeModal();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}