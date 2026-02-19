import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getCollateralAgreements from '@salesforce/apex/SHF_CollateralController.getCollateralAgreements';

const ROW_ACTIONS = [
    { label: 'Edit', name: 'edit' }
];

const AGREEMENT_COLUMNS = [
    { label: 'Registration Number', fieldName: 'Registration_Number__c',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    { label: 'Agreement Type', fieldName: 'Agreement_Type__c',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    { label: 'Registration Date', fieldName: 'Registration_Date__c', type: 'date',cellAttributes: { alignment: 'left' } , wrapText: true, initialWidth: 250},
    { label: 'Agreement Value (INR)', fieldName: 'Agreement_Value_INR__c', type: 'currency' ,cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250},
    {
        type: 'action',
        typeAttributes: { rowActions: ROW_ACTIONS }
    }
];

export default class ShfPropertyRegistrationDetails extends LightningElement {
    @api collateralId;
    @api applicationId;

    @track agreementData = [];
    agreementColumns = AGREEMENT_COLUMNS;

    showAgreementForm = false;
    selectedAgreementId;
    selectedAgreementRecord;

    isTableLoading = false;

    wiredAgreementResult;

    @wire(getCollateralAgreements, { collateralId: '$collateralId' })
    wiredAgreements(result) {
        this.wiredAgreementResult = result;

        if (result.data) {
            this.agreementData = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Error loading agreements', 'error');
        }
    }

    handleNew() {
        this.selectedAgreementId = null;
        this.selectedAgreementRecord = null;
        this.showAgreementForm = true;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'edit') {
            this.selectedAgreementId = row.Id;
            this.selectedAgreementRecord = row;
            this.showAgreementForm = true;
        }
    }

    handleFormSuccess() {
        this.showAgreementForm = false;
        this.refresh();
    }

    handleFormCancel() {
        this.showAgreementForm = false;
    }

    refresh() {
        this.isTableLoading = true;

        const promises = [];
        if (this.wiredAgreementResult) {
            promises.push(refreshApex(this.wiredAgreementResult));
        }

        Promise.all(promises)
            .catch(error => {
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isTableLoading = false;
            });
    }
    handleFooterSave() {
    const form = this.template.querySelector(
        'c-shf-property-registration-form'
    );
    if (form && typeof form.handleExternalSave === 'function') {
        form.handleExternalSave();
    }
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