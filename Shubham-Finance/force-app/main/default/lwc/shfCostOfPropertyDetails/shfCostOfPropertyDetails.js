import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getCostOfPropertyRecords from '@salesforce/apex/SHF_CollateralController.getCostOfPropertyRecords';
import getBreakUpHeadPicklistValues from '@salesforce/apex/SHF_CollateralController.getBreakUpHeadPicklistValues';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PROPERTY_BREAKUP_TYPE_FIELD from '@salesforce/schema/Collateral__c.Property_Breakup_type__c';

const BREAKUP_COST_VALUES = new Set([
    'break up cost',
    'breakup cost',
    'break_up_cost',
    'breakup_cost'
]);
const normalize = v => (v || '').toString().trim().toLowerCase();
const isBreakupCost = v => BREAKUP_COST_VALUES.has(normalize(v));


const ROW_ACTIONS = [{ label: 'Edit', name: 'edit' }];


const COST_COLUMNS = [
    { label: 'Break Up Head', fieldName: 'Break_Up_Head__c',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250 },
    {label: 'Break Up Cost', fieldName: 'Break_Up_Cost__c',type: 'currency',cellAttributes: { alignment: 'left' }, wrapText: true, initialWidth: 250},
    { label: 'Break Up Description', fieldName: 'Break_Up_Description__c',cellAttributes: { alignment: 'left' } , wrapText: true, initialWidth: 250},
    {
        type: 'action',
        typeAttributes: { rowActions: ROW_ACTIONS }
    }
];

export default class ShfCostOfPropertyDetails extends LightningElement {
    @api collateralId;
    @api applicationId;
    
    @track costData = [];
    costColumns = COST_COLUMNS;

    showCostForm = false;
    selectedCostId;
    selectedCostRecord;

    isTableLoading = false;
    wiredCostResult;

    propertyBreakupType;
    @api isPropertyCostDisabled;
    @track breakUpHeadOptions = [];
    @track usedBreakUpHeadByValue  = [];
    defaultBreakUpHead = null;

    isPicklistLoading = true;
    wiredPicklistResult;

    
_norm(v) { return (v || '').toString().trim().toLowerCase(); }
get isNewDisabled() {
   
    return !this.isPropertyCostDisabled;
}

    _collateralId;


get collateralId() {
    return this._collateralId;
}
set collateralId(v) {
    this._collateralId = v;

   
    this.propertyBreakupType = null;
    this.isBreakupTypeLoading = !!v; 
}
@wire(getBreakUpHeadPicklistValues)
wiredBreakUpHeads(result) {
    this.wiredPicklistResult = result;

    if (result.data) {
        this.breakUpHeadOptions = (result.data || []).map(v => ({ label: v, value: v }));
        this.isPicklistLoading = false;
    } else if (result.error) {
        this.isPicklistLoading = false;
        this.breakUpHeadOptions = [];
        this.showToast('Error', 'Error loading Break Up Head picklist', 'error');
    }
}


@wire(getRecord, { recordId: '$collateralId', fields: [PROPERTY_BREAKUP_TYPE_FIELD] })
wiredCollateral({ data, error }) {
    this.isBreakupTypeLoading = false;

    if (data) {
        this.propertyBreakupType = getFieldValue(data, PROPERTY_BREAKUP_TYPE_FIELD);
    } else if (error) {
        this.propertyBreakupType = null; // keep disabled
    }
}



get remainingBreakUpHeadOptions() {
    const used = new Set(Object.keys(this.usedBreakUpHeadByValue || {}));
    return (this.breakUpHeadOptions || []).filter(opt => !used.has(this._norm(opt.value)));
}


get isNewDisabled() {
    if (!this.isPropertyCostDisabled) return true;   
    if (this.isPicklistLoading) return true;        
    return this.remainingBreakUpHeadOptions.length === 0; 
}



    @wire(getCostOfPropertyRecords, { collateralId: '$collateralId' })
    wiredCost(result) {
        this.wiredCostResult = result;

        if (result.data) {
    this.costData = result.data;

    const map = {};
    (this.costData || []).forEach(r => {
        if (r.Break_Up_Head__c) {
            map[this._norm(r.Break_Up_Head__c)] = r.Id;
        }
    });
    this.usedBreakUpHeadByValue = map;

    const rem = this.remainingBreakUpHeadOptions;
    this.defaultBreakUpHead = rem.length ? rem[0].value : null;
}

    }

    handleNew() {
        if (this.isNewDisabled) {
        this.showToast(
            'Info',
            'New Cost of Property can be added only when Property Breakup type is set to Break up cost.',
            'info'
        );
        return;
    }
        this.selectedCostId = null;
        this.selectedCostRecord = null;
        this.showCostForm = true;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'edit') {
            this.selectedCostId = row.Id;
            this.selectedCostRecord = row;
            this.showCostForm = true;
        }
    }

    handleFormSuccess() {
        this.showCostForm = false;
        this.refresh();
    }

    handleFormCancel() {
        this.showCostForm = false;
    }

    handleFooterSave() {
        const form = this.template.querySelector('c-shf-cost-of-property-form');
        if (form && typeof form.handleExternalSave === 'function') {
            form.handleExternalSave();
        }
    }

    refresh() {
        this.isTableLoading = true;

        const promises = [];
        if (this.wiredCostResult) {
            promises.push(refreshApex(this.wiredCostResult));
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