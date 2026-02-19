import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getSellerOwners from '@salesforce/apex/SHF_CollateralController.getSellerOwners';
import getBankDetails from '@salesforce/apex/SHF_CollateralController.getBankDetails';

const ROW_ACTIONS = [{ label: 'Edit', name: 'edit' }];

const BANK_COLUMNS = [
    { label: 'Account No', fieldName: 'Account_No__c',cellAttributes: { alignment: 'left' } , wrapText: true, initialWidth: 250},
    { label: 'Type of Account', fieldName: 'Type_of_Account__c',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    { label: 'Bank Name', fieldName: 'bankNameDisplay',cellAttributes: { alignment: 'left' } , wrapText: true, initialWidth: 250},
    { label: 'Branch Name', fieldName: 'branchNameDisplay',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    { label: 'IFSC', fieldName: 'ifscDisplay' ,cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250},
    {
        type: 'action',
        typeAttributes: { rowActions: ROW_ACTIONS }
    }
];



export default class ShfSellerBankDetails extends LightningElement {
    @api collateralId;
    @api applicationId;

    @track bankData = [];
    bankColumns = BANK_COLUMNS;

    showBankForm = false;
    selectedBankId;
    selectedBankRecord;

    isTableLoading = false;
    disableNew = true;

    sellerOptions = [];

    wiredSellerResult;
    wiredBankResult;


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

    renderedCallback() {
  if (this.showBankForm) {
    document.body.classList.add('slds-modal_open');
  } else {
    document.body.classList.remove('slds-modal_open');
  }
}

        @wire(getBankDetails, { collateralId: '$collateralId' })
        wiredBanks(result) {
            this.wiredBankResult = result;

    if (result.data) {
        this.bankData = result.data.map(rec => ({
            ...rec,
            bankNameDisplay:
                rec.IFSC_Code_Master__r && rec.IFSC_Code_Master__r.Bank_Name__c
                    ? rec.IFSC_Code_Master__r.Bank_Name__c
                    : null,
            branchNameDisplay:
                rec.Branch_Name__c
                    ? rec.Branch_Name__c
                    : null,
            ifscDisplay:
                rec.IFSC_Code_Master__r && rec.IFSC_Code_Master__r.Name
                    ? rec.IFSC_Code_Master__r.Name
                    : null
        }));
    } else if (result.error) {
        this.showToast('Error', 'Error loading bank details', 'error');
    }
}


    handleNew() {
        this.selectedBankId = null;
        this.selectedBankRecord = null;
        this.showBankForm = true;
        this.template.host.classList.add('bank-modal-open');
        document.body.classList.add('slds-modal_open');
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'edit') {
            this.selectedBankId = row.Id;
            this.selectedBankRecord = row;
            this.showBankForm = true;
        }
    }

    handleFormSuccess() {
        this.showBankForm = false;
        this.template.host.classList.add('bank-modal-open');
        document.body.classList.add('slds-modal_open');
        this.refresh();
    }

    handleFormCancel() {
        this.showBankForm = false;
         this.template.host.classList.remove('bank-modal-open');
        document.body.classList.remove('slds-modal_open');
    }

    refresh() {
        this.isTableLoading = true;

        const promises = [];
        if (this.wiredSellerResult) {
            promises.push(refreshApex(this.wiredSellerResult));
        }
        if (this.wiredBankResult) {
            promises.push(refreshApex(this.wiredBankResult));
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