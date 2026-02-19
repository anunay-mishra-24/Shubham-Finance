import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSellerOwners from '@salesforce/apex/SHF_CollateralController.getSellerOwners';

const ROW_ACTIONS = [
    { label: 'Edit', name: 'edit' }
];

const OWNER_COLUMNS = [
    { label: 'Owner Name', fieldName: 'Name', initialWidth: 150,cellAttributes: { alignment: 'left' } },
    { label: 'Owner Type', fieldName: 'ownerType__c' , initialWidth: 150,cellAttributes: { alignment: 'left' }},
    { label: 'Ownership Status', fieldName: 'ownershipStatus__c', initialWidth: 150,cellAttributes: { alignment: 'left' } },
    { label: 'Percent Share', fieldName: 'Percent_Share__c', type: 'number', initialWidth: 150,cellAttributes: { alignment: 'left' } },
    { label: 'Ownership Dates', fieldName: 'ownershipDates__c', type: 'number', initialWidth: 150,cellAttributes: { alignment: 'left' } },
    { label: 'Linked Applicant', fieldName: 'Linked_Applicant__c' , initialWidth: 150,cellAttributes: { alignment: 'left' }},
    { label: 'To Date', fieldName: 'To_Date__c' , initialWidth: 150,cellAttributes: { alignment: 'left' }},
    { label: 'From Date', fieldName: 'From_Date__c' , initialWidth: 150,cellAttributes: { alignment: 'left' }},
    {
        type: 'action',
        typeAttributes: { rowActions: ROW_ACTIONS }
    }
];

export default class ShfCollateralOwnerDetails extends LightningElement {
    @api collateralId;
    @api applicationId;

    @track ownerData = [];
    ownerColumns = OWNER_COLUMNS;

    showOwnerForm = false;
    selectedOwnerId;
    isOwnerTableLoading = false;

    wiredOwnerResult;

    @wire(getSellerOwners, { collateralId: '$collateralId' })
    wiredOwners(result) {
        this.wiredOwnerResult = result;

        if (result.data) {
            const rows = result.data.map(r => ({
                ...r,
                _rt:
                    r.RecordType && r.RecordType.DeveloperName
                        ? r.RecordType.DeveloperName
                        : null
            }));

            this.ownerData = rows.filter(r => r._rt === 'Owner');
            console.log('this.ownerData  ',this.ownerData)
        } else if (result.error) {
            this.showToast('Error', this.getErrorMessage(result.error), 'error');
        }
    }

   handleOwnerNew() {
    
    if (this.disableOwnerNew) {
        this.showToast('Warning', this.singleOwnerWarningText, 'warning');
        return;
    }
    this.selectedOwnerId = null;
    this.showOwnerForm = true;
}



    handleOwnerRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'edit') {
            this.selectedOwnerId = row.Id;
            this.showOwnerForm = true;
        }
    }

    handleOwnerFormSuccess() {
        this.showOwnerForm = false;
        this.refresh();
    }

    handleOwnerFormCancel() {
        this.showOwnerForm = false;
    }
    handleOwnerFooterSave() {
    const form = this.template.querySelector(
        'c-shf-collateral-seller-owner-form'
    );
    if (form && typeof form.handleExternalSave === 'function') {
        form.handleExternalSave();
    }
}


    refresh() {
        this.isOwnerTableLoading = true;

        const promises = [];
        if (this.wiredOwnerResult) {
            promises.push(refreshApex(this.wiredOwnerResult));
        }

        Promise.all(promises)
            .catch(error => {
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isOwnerTableLoading = false;
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

    getErrorMessage(error) {
        let message = 'Unknown error';
        if (Array.isArray(error?.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (error?.body?.message) {
            message = error.body.message;
        }
        return message;
    }
}