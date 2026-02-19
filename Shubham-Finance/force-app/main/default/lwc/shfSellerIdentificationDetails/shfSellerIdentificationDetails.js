import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSellerOwners from '@salesforce/apex/SHF_CollateralController.getSellerOwners';
import getIdentificationDetails from '@salesforce/apex/SHF_CollateralController.getIdentificationDetails';

const ROW_ACTIONS = [
    { label: 'Edit', name: 'edit' }
];

const IDENTIFICATION_COLUMNS = [
    { label: 'Seller', fieldName: 'sellerName',cellAttributes: { alignment: 'left' } , wrapText: true, initialWidth: 250},
    { label: 'Identification Type', fieldName: 'Identification_Type__c',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    { label: 'Identification Number', fieldName: 'Identification_No__c',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    { label: 'Issue Date', fieldName: 'Issue_Date__c', type: 'date',cellAttributes: { alignment: 'left' } , wrapText: true, initialWidth: 250},
    { label: 'Expiry Date', fieldName: 'Expiry_Date__c', type: 'date',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    { label: 'Country of Issue', fieldName: 'Country_of_Issue__c',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    {
        type: 'action',
        typeAttributes: { rowActions: ROW_ACTIONS }
    }
];

export default class ShfSellerIdentificationDetails extends LightningElement {
    @api collateralId;
    @api applicationId;

    @track identificationData = [];
    identificationColumns = IDENTIFICATION_COLUMNS;

    @track sellerOptions = [];

    showIdentificationForm = false;
    selectedIdentificationId;
    @track selectedIdentificationRecord;

    isIdentificationTableLoading = false;
    disableIdentificationNew = true;

    wiredSellerResult;
    wiredIdentificationResult;

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
                value: s.Id,
                individualType: s.individualNonIndividual__c
            }));

            this.disableIdentificationNew = this.sellerOptions.length === 0;
            this.updateDisableIdentificationNew();

        } else if (result.error) {
            this.showToast('Error', 'Error loading sellers', 'error');
        }
    }

    @wire(getIdentificationDetails, { collateralId: '$collateralId' })
    wiredIdentification(result) {
        this.wiredIdentificationResult = result;
        if (result.data) {
            this.identificationData = result.data.map(r => ({
                ...r,
                sellerName:
                    r.Collateral_Seller_Owner__r &&
                    r.Collateral_Seller_Owner__r.Name
                        ? r.Collateral_Seller_Owner__r.Name
                        : null
            }));
            this.updateDisableIdentificationNew();

        } else if (result.error) {
            this.showToast(
                'Error',
                'Error loading identification details',
                'error'
            );
        }
    }

    handleIdentificationNew() {
        if (this.disableIdentificationNew) {
            this.showToast(
                'Error',
                'Please add Seller Details before Identification Details',
                'error'
            );
            return;
        }
        this.selectedIdentificationId = null;
        this.selectedIdentificationRecord = null;
        this.showIdentificationForm = true;
    }
    updateDisableIdentificationNew() {
    const usedSellerIds = new Set(
        (this.identificationData || [])
            .map(r => r.Collateral_Seller_Owner__c)
            .filter(Boolean)
    );

    const availableSellers = (this.sellerOptions || []).filter(
        o => !usedSellerIds.has(o.value)
    );

    this.disableIdentificationNew = availableSellers.length === 0;
}


    handleIdentificationRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'edit') {
            this.selectedIdentificationId = row.Id;
            this.selectedIdentificationRecord = row;
            this.showIdentificationForm = true;
        }
    }

    handleIdentificationFormSuccess() {
        this.showIdentificationForm = false;
        this.refresh();
    }

    handleIdentificationFormCancel() {
        this.showIdentificationForm = false;
    }

    refresh() {
        this.isIdentificationTableLoading = true;

        const promises = [];
        if (this.wiredSellerResult) {
            promises.push(refreshApex(this.wiredSellerResult));
        }
        if (this.wiredIdentificationResult) {
            promises.push(refreshApex(this.wiredIdentificationResult));
        }

        Promise.all(promises)
            .catch(error => {
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isIdentificationTableLoading = false;
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