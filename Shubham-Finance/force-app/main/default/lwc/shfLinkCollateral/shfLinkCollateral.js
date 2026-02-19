import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import linkExistingCollateralToApplication from '@salesforce/apex/SHF_CollateralController.linkExistingCollateralToApplication';
import isCollateralAlreadyLinked from '@salesforce/apex/SHF_CollateralController.isCollateralAlreadyLinked';
import searchCollaterals from '@salesforce/apex/SHF_CollateralController.searchCollaterals';

const SEARCH_COLUMNS = [
    {
        label: 'Collateral Name',
        fieldName: 'collateralName',
        type: 'text', wrapText: true, initialWidth: 250
    },
    {
        label: 'Collateral Address',
        fieldName: 'Collateral_Address__c',
        type: 'text',
        initialWidth: 500
    },
    {
        label: 'APF/Non APF/Others',
        fieldName: 'apfNonApf',
        type: 'text',
         initialWidth: 170
    },
    {
        type: 'button',
        typeAttributes: {
            label: 'Link',
            name: 'link',
            variant: 'brand'
        },initialWidth: 170
    }
];

export default class ShfLinkCollateral extends LightningElement {
    @api applicationId;


    @track collateralName = '';
    @track applicationKey = '';   


    @track searchResults = [];
    @track isSearching = false;
    @track hasSearched = false;
    @track isLinking = false;

    searchColumns = SEARCH_COLUMNS;

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleCollateralNameChange(event) {
        this.collateralName = event.target.value;
    }

    handleApplicationKeyChange(event) {
        this.applicationKey = event.target.value;
    }

    get isSearchDisabled() {
        const name = (this.collateralName || '').trim();
        const app  = (this.applicationKey || '').trim();
        const noCriteria = !name && !app;
        return this.isSearching || noCriteria;
    }

    async handleSearch() {
        const name = (this.collateralName || '').trim();
        const app  = (this.applicationKey || '').trim();

        this.hasSearched = true;
        this.searchResults = [];

        if (!name && !app) {
            this.showToast(
                'Error',
                'Please enter Collateral Name or Application Id.',
                'error'
            );
            return;
        }

        this.isSearching = true;

        try {
            const result = await searchCollaterals({
                collateralName: name,
                applicationKey: app      
            });

            this.searchResults = (result || []).map(r => {
                const parts = [];
                if (r.Flat_Plot_Number__c) parts.push(r.Flat_Plot_Number__c);
                if (r.Address_Line_2__c) parts.push(r.Address_Line_2__c);
                if (r.Address_Line_3__c) parts.push(r.Address_Line_3__c);
                if (r.City__c) parts.push(r.City__c);
                if (r.State__c) parts.push(r.State__c);
                if (r.Country__c) parts.push(r.Country__c);

                const addr = parts.join(', ');

                return {
                    Id: r.Id,
                    collateralId: r.Id,
                    collateralName: r.Name,
                    Collateral_Address__c: addr,
                    apfNonApf: r.APF__c || ''
                };
            });
        } catch (error) {
            this.searchResults = [];
            this.showToast('Error', this.getErrorMessage(error), 'error');
        } finally {
            this.isSearching = false;
        }
    }

    get hasSearchResults() {
        return (this.searchResults || []).length > 0;
    }

    get showNoResultsMessage() {
        return this.hasSearched && !this.isSearching && !this.hasSearchResults;
    }

    handleSearchRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'link') {
            const collateralId = row.collateralId;
            if (!collateralId) {
                this.showToast(
                    'Error',
                    'Collateral Id not found for this row.',
                    'error'
                );
                return;
            }
            this.doLink(collateralId);
        }
    }

    async doLink(collateralId) {
        this.isLinking = true;
        try {
            const alreadyLinked = await isCollateralAlreadyLinked({
                collateralId,
                applicationId: this.applicationId
            });

            if (alreadyLinked) {
                this.showToast(
                    'Info',
                    'Collateral is already linked with Application.',
                    'info'
                );
                this.isLinking = false;
                return;
            }

            await linkExistingCollateralToApplication({
                collateralId,
                applicationId: this.applicationId
            });

            this.showToast(
                'Success',
                'Collateral linked to application successfully.',
                'success'
            );

            this.dispatchEvent(new CustomEvent('success'));
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        } finally {
            this.isLinking = false;
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