import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSellerOwners from '@salesforce/apex/SHF_CollateralController.getSellerOwners';

const ROW_ACTIONS = [
    { label: 'Edit', name: 'edit' }
];

const SELLER_COLUMNS = [
    { label: 'Seller Name', fieldName: 'Name' ,cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250},
    { label: 'Present Registered Owner', fieldName: 'presentRegistered__c',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    {
        label: 'Percentage Share',
        fieldName: 'Percentage_Share__c',
       cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250
    },
    {
        label: 'Individual/Non-Individual',
        fieldName: 'individualNonIndividual__c',
        cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250
    },
    {
        type: 'action',
        typeAttributes: { rowActions: ROW_ACTIONS }
    }
];

export default class ShfSellerDetails extends LightningElement {
    @api collateralId;
    @api applicationId;

    @track sellerData = [];
    sellerColumns = SELLER_COLUMNS;

    showSellerForm = false;
    selectedSellerId;

    isSellerTableLoading = false;

    wiredSellerResult;

    @wire(getSellerOwners, { collateralId: '$collateralId' })
    wiredSellerOwners(result) {
        this.wiredSellerResult = result;

        if (result.data) {
            const rows = result.data.map(r => ({
                ...r,
                _rt:
                    r.RecordType && r.RecordType.DeveloperName
                        ? r.RecordType.DeveloperName
                        : null
            }));

            this.sellerData = rows.filter(r => r._rt === 'Seller');
        } else if (result.error) {
            this.showToast('Error', 'Error loading sellers', 'error');
        }
    }

    handleSellerNew() {
        const maxSellers = 5;
        const currentSellerCount = (this.sellerData || []).length;

        if (currentSellerCount >= maxSellers) {
            this.showToast(
                'Error',
                'Only 5 sellers are allowed to be added',
                'error'
            );
            return;
        }

        this.selectedSellerId = null;
        this.showSellerForm = true;
    }

    handleSellerRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'edit') {
            this.selectedSellerId = row.Id;
            this.showSellerForm = true;
        }
    }

    handleSellerFormSuccess() {
        this.showSellerForm = false;
        this.refresh();
    }

    handleSellerFormCancel() {
        this.showSellerForm = false;
    }
    handleSellerFooterSave() {
    const form = this.template.querySelector(
        'c-shf-collateral-seller-owner-form'
    );
    if (form && typeof form.handleExternalSave === 'function') {
        form.handleExternalSave();
    }
}


    refresh() {
        this.isSellerTableLoading = true;

        const promises = [];
        if (this.wiredSellerResult) {
            promises.push(refreshApex(this.wiredSellerResult));
        }

        Promise.all(promises)
            .catch(error => {
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isSellerTableLoading = false;
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