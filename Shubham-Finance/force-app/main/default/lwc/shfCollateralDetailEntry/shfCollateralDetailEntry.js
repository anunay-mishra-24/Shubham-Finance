import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSellerOwner from '@salesforce/apex/SHF_CollateralController.getSellerOwner';
import getIdentificationDetails from '@salesforce/apex/SHF_CollateralController.getIdentificationDetails';
import getAvailableOwnerApplicants  from '@salesforce/apex/SHF_CollateralController.getAvailableOwnerApplicants';
const ROW_ACTIONS = [{ label: 'Edit', name: 'edit' }];

const OWNER_COLUMNS = [
    { label: 'Owner Name', fieldName: 'ownerName__c',cellAttributes: { alignment: 'left' } },
    { label: 'Owner Type', fieldName: 'ownerType__c' },
    { label: 'Ownership Status', fieldName: 'ownershipStatus__c',cellAttributes: { alignment: 'left' } },
    { label: 'Percent Share', fieldName: 'Percent_Share__c', type: 'number',cellAttributes: { alignment: 'left' } },
    { label: 'Ownership Dates', fieldName: 'ownershipDates__c', type: 'date',cellAttributes: { alignment: 'left' } },
    { label: 'Linked Applicant', fieldName: 'Linked_Applicant__c' ,cellAttributes: { alignment: 'left' }},
    { type: 'action', typeAttributes: { rowActions: ROW_ACTIONS } }
];

const SELLER_COLUMNS = [
    { label: 'Seller Name', fieldName: 'Name',cellAttributes: { alignment: 'left' } },
    { label: 'Present Registered Owner', fieldName: 'presentRegistered__c' ,cellAttributes: { alignment: 'left' }},
    {
        label: 'Percentage Share',
        fieldName: 'Percentage_Share__c',
        type: 'number',cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Individual/Non-Individual',
        fieldName: 'individualNonIndividual__c',cellAttributes: { alignment: 'left' }
    },
    { type: 'action', typeAttributes: { rowActions: ROW_ACTIONS } }
];

const IDENTIFICATION_COLUMNS = [
    { label: 'Seller', fieldName: 'sellerName',cellAttributes: { alignment: 'left' } },
    { label: 'Identification Type', fieldName: 'Identification_Type__c' ,cellAttributes: { alignment: 'left' }},
    { label: 'Identification Number', fieldName: 'Identification_No__c',cellAttributes: { alignment: 'left' } },
    { label: 'Issue Date', fieldName: 'Issue_Date__c', type: 'date',cellAttributes: { alignment: 'left' } },
    { label: 'Expiry Date', fieldName: 'Expiry_Date__c', type: 'date',cellAttributes: { alignment: 'left' } },
    { label: 'Country of Issue', fieldName: 'Country_of_Issue__c',cellAttributes: { alignment: 'left' } },
    { type: 'action', typeAttributes: { rowActions: ROW_ACTIONS } }
];

export default class ShfCollateralDetailEntry extends LightningElement {
    @api collateralId;
    @api applicationId;
    @api typeOfPurchase;
    @api isPropertyCostDisabled;

    @track ownerData = [];
    @track sellerData = [];
    @track identificationData = [];

    ownerColumns = OWNER_COLUMNS;
    sellerColumns = SELLER_COLUMNS;
    identificationColumns = IDENTIFICATION_COLUMNS;

    showOwnerForm = false;
    showSellerForm = false;
    showIdentificationForm = false;

    selectedOwnerId;
    selectedSellerId;
    selectedIdentificationId;
    selectedIdentificationSellerId;
    selectedIdentificationRecord;

    isOwnerTableLoading = false;
    isSellerTableLoading = false;
    isIdentificationTableLoading = false;

    disableIdentificationNew = true;

    sellerOptions = [];

    wiredSellerResult;
    wiredIdentificationResult;


    hasSingleOwner = false;
    hasJointOwner = false;
     get singleOwnerWarningText() {
    return 'Ownership Status is Single. Only one owner is allowed for this collateral.';
}

    get hideSellerSections() {
        if (!this.typeOfPurchase) {
            return false;
        }
        return this.typeOfPurchase.toUpperCase() === 'NEW';
    }


    get isOwnerNewDisabled() {
        return this.hasSingleOwner;
    }

    get showSingleOwnerWarning() {
        return this.hasSingleOwner;
    }


    @wire(getAvailableOwnerApplicants, {
  applicationId: '$applicationId',
  collateralId: '$collateralId',
  currentApplicantId: null,
  refreshNonce :null
  
    }) availableOwnerPool;

    get isOwnerNewDisabled() {
  const arr = this.availableOwnerPool?.data || [];
  return arr.length === 0; 
}
    @wire(getSellerOwner, { collateralId: '$collateralId' })
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

            const ownerRows = rows.filter(r => r._rt === 'Owner');
            const sellerRows = rows.filter(r => r._rt === 'Seller');

            this.ownerData = ownerRows;
            this.sellerData = sellerRows;


            this.sellerOptions = sellerRows.map(s => ({
                label: s.Name,
                value: s.Id,
                individualType: s.individualNonIndividual__c
            }));

            this.disableIdentificationNew = sellerRows.length === 0;

            
            this.hasSingleOwner = (this.ownerData || []).some(
                                    r => (r.ownershipStatus__c || '').toLowerCase() === 'single'
            );
            this.disableOwnerNew = this.hasSingleOwner;
        } else if (result.error) {
            this.showToast('Error', 'Error loading seller/owner data', 'error');
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
        } else if (result.error) {
            this.showToast(
                'Error',
                'Error loading identification details',
                'error'
            );
        }
    }



    handleOwnerNew() {

        if (this.hasSingleOwner) {
            this.showToast(
                'Warning',
                'Ownership Status is Single. Only one owner is allowed for this collateral.',
                'warning'
            );
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



    handleIdentificationNew() {
        this.selectedIdentificationId = null;
        this.selectedIdentificationSellerId = null;
        this.selectedIdentificationRecord = null;
        this.showIdentificationForm = true;
    }

    handleIdentificationRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'edit') {
            this.selectedIdentificationId = row.Id;
            this.selectedIdentificationSellerId =
                row.Collateral_Seller_Owner__c;
            this.selectedIdentificationRecord = row;
            this.showIdentificationForm = true;
        }
    }



    handleOwnerFormSuccess() {
        this.showOwnerForm = false;
        this.refresh();
    }
    handleOwnerFormCancel() {
        this.showOwnerForm = false;
    }

    handleSellerFormSuccess() {
        this.showSellerForm = false;
        this.refresh();
    }
    handleSellerFormCancel() {
        this.showSellerForm = false;
    }

    handleIdentificationFormSuccess() {
        this.showIdentificationForm = false;
        this.refresh();
    }
    handleIdentificationFormCancel() {
        this.showIdentificationForm = false;
    }



    refresh() {
        this.isOwnerTableLoading = true;
        this.isSellerTableLoading = true;
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
                this.isOwnerTableLoading = false;
                this.isSellerTableLoading = false;
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