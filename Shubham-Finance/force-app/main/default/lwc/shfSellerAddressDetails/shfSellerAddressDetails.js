import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSellerOwners from '@salesforce/apex/SHF_CollateralController.getSellerOwners';
import getSellerAddresses from '@salesforce/apex/SHF_CollateralController.getSellerAddresses';

const ROW_ACTIONS = [
    { label: 'Edit', name: 'edit' }
];

const ADDRESS_COLUMNS = [
    { label: 'Address Type', fieldName: 'Address_Type__c',cellAttributes: { alignment: 'left' } , wrapText: true, initialWidth: 250},
    { label: 'Flat/Plot Number', fieldName: 'Flat_Plot_Number__c',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    { label: 'PinCode', fieldName: 'PincodeDisplay',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    { label: 'Full Address', fieldName: 'Full_Address__c' ,cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250},
    {
        type: 'action',
        typeAttributes: { rowActions: ROW_ACTIONS }
    }
];

export default class ShfSellerAddressDetails extends LightningElement {
    @api collateralId;
    @api applicationId;

    @track addressData = [];
    addressColumns = ADDRESS_COLUMNS;

    showAddressForm = false;
    selectedAddressId;
    selectedAddressRecord;

    isTableLoading = false;
    disableNew = true;

    sellerOptions = [];

    wiredSellerResult;
    wiredAddressResult;

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

            const sellers = rows.filter(r => r._rt === 'Seller');

            this.sellerOptions = sellers.map(s => ({
                label: s.Name,
                value: s.Id
            }));

            this.disableNew = this.sellerOptions.length === 0;
        } else if (result.error) {
            this.showToast('Error', 'Error loading sellers', 'error');
        }
    }

    @wire(getSellerAddresses, { collateralId: '$collateralId' })
    wiredAddresses(result) {
        this.wiredAddressResult = result;

        if (result.data) {
            this.addressData = result.data.map(r => ({
                ...r,
                PincodeDisplay:
                    r.Pincode__r && r.Pincode__r.Name ? r.Pincode__r.Name : null
            }));
        } else if (result.error) {
            this.showToast('Error', 'Error loading addresses', 'error');
        }
    }

    handleNew() {
        this.selectedAddressId = null;
        this.selectedAddressRecord = null;
        this.showAddressForm = true;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'edit') {
            this.selectedAddressId = row.Id;
            this.selectedAddressRecord = row;
            this.showAddressForm = true;
        }
    }

    handleFormSuccess() {
        this.showAddressForm = false;
        this.refresh();
    }

    handleFormCancel() {
        this.showAddressForm = false;
    }

    refresh() {
        this.isTableLoading = true;

        const promises = [];
        if (this.wiredSellerResult) {
            promises.push(refreshApex(this.wiredSellerResult));
        }
        if (this.wiredAddressResult) {
            promises.push(refreshApex(this.wiredAddressResult));
        }

        Promise.all(promises)
            .catch(error => {
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isTableLoading = false;
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