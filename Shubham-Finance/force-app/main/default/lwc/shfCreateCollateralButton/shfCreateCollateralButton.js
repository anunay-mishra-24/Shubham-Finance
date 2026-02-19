import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import APPLICATION_STAGE_FIELD from '@salesforce/schema/Application__c.Application_Stage__c';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import getApplicationCollaterals from '@salesforce/apex/SHF_CollateralController.getApplicationCollaterals';

const ROW_ACTIONS = [
{ label: 'Edit', name: 'edit' }            
];

const COLUMNS = [
{
    label: 'Application Collateral Name',
    fieldName: 'applicationCollateralLink',
    type: 'url', wrapText: true, initialWidth: 350,
    typeAttributes: {
        label: { fieldName: 'Name' },
        target: '_blank'
    }
},
{
    label: 'Collateral Address',
    fieldName: 'Collateral_Address__c',
    type: 'text', wrapText: true, initialWidth: 570
    
},
{
    label: 'APF/Non APF/Others',
    fieldName: 'apfNonApf',
    type: 'text', wrapText: true, initialWidth: 250
    
},
{
    type: 'action',                       
    typeAttributes: { rowActions: ROW_ACTIONS }
}
];

export default class ShfCreateCollateralButton extends LightningElement {
@api recordId; 


columns = COLUMNS;
@track collateralRows = [];
isTableLoading = false;
wiredCollateralsResult;


@track showCollateralModal = false;
@track showSellerOwnerModal = false;
@track showLinkModal = false;

@track collateralId;
@track typeOfPurchase;
@track linkedFromExisting = false;
@track newbutton ;
@track isPropertyCostDisabled = false;
@track isEdit = false;   
isEditCollateral = false;    
hideButtonsForNoPI = false; 
@track stageName;    
hasYesCollateral = false;
hasNoCollateral = false;
lockPropertyIdentification = false;  
  defaultPropertyIdentification = null; 
    get isButtonVisible(){
        console.log( 'newbutton',this.newbutton);
     if (this.stageName === 'Applicant Details') return false;
     if (this.hasNoCollateral && !this.hasYesCollateral) return false;
     return true;
}

@wire(getRecord, {
recordId: '$recordId',
fields: [APPLICATION_STAGE_FIELD]
})
wiredApplication({ data, error }) {
if (data) {
    this.stageName = getFieldValue(data, APPLICATION_STAGE_FIELD);
    console.log('Stage => ', this.stageName);
} else if (error) {
    this.showError('Error loading application details', error);
}
}
@wire(getApplicationCollaterals, { applicationId: '$recordId' })
wiredCollaterals(result) {
    this.wiredCollateralsResult = result;

    if (result.data) {
        const piValues = result.data.map(r =>
      r.Collateral__r?.Property_Identification__c ?? r.Property_Identification__c
    );

    this.hideButtonsForNoPI = piValues.includes('No');               
      this.hasYesCollateral = piValues.includes('Yes');
    this.hasNoCollateral  = piValues.includes('No');

    this.defaultPropertyIdentification = this.hasYesCollateral ? 'Yes' : null;
    this.lockPropertyIdentification    = this.hasYesCollateral;
        this.collateralRows = result.data.map(row => {
            this.stageName = row.Application__r.Application_Stage__c;
            const apfValue =
                row.Collateral__r && row.Collateral__r.APF__c
                    ? row.Collateral__r.APF__c
                    : '';
        
            return {
                ...row,
                applicationCollateralLink: '/' + row.Collateral__c,
                Name :row.Collateral__r.Name,
                apfNonApf: apfValue
            };
        });
    } else if (result.error) {
        this.showToast(
            'Error',
            this.getErrorMessage(result.error),
            'error'
        );
    }
}




handleClick() {

this.isEditCollateral = false;
this.collateralId = null;
this.linkedFromExisting = false;
  this.isPropertyCostDisabled = false;

const modal = this.template.querySelector('c-shf-collateral-creation');
if (modal) {
    modal.openForCreate();
}

this.showSellerOwnerModal = false;
this.showCollateralModal = true;
}



handleLinkCollateral() {

    this.showLinkModal = true;
}


handleRowAction(event) {
const actionName = event.detail.action.name;
const row = event.detail.row;
this.newbutton = row.Property_Breakup_type__c=='Break up cost' ? true : false;
console.log('this.newbutton   =   ',this.newbutton);
if (actionName === 'edit') {
    this.isEdit = true;
    this.isEditCollateral=true;
    this.collateralId = row.Collateral__c;
    
    
    this.typeOfPurchase =
        row.Collateral__r && row.Collateral__r.Type_Of_Purchase__c
            ? row.Collateral__r.Type_Of_Purchase__c
            : null;
   
    this.linkedFromExisting = false;

    this.showCollateralModal = true;
    this.showSellerOwnerModal = false;
}
}



handleCollateralClose() {
this.showCollateralModal = false;
this.showSellerOwnerModal = false;
this.collateralId = null;
this.typeOfPurchase = null;
this.linkedFromExisting = false;
this.isPropertyCostDisabled = false;
this.isEditCollateral = false;  
this.refreshCollaterals();
}


handleCollateralSaved(event) {
    const d = event.detail || {};
    const pi = (d.propertyIdentification || '').toString().trim().toLowerCase();
    const isNo = pi === 'no';
    const isYes = pi === 'yes';


    if (isYes) {
        this.hasYesCollateral = true;
        this.lockPropertyIdentification = true;
        this.defaultPropertyIdentification = 'Yes';
    }
    if (isNo) {
        this.hasNoCollateral = true;
    }


    this.showCollateralModal = false;


    if (isNo) {
        this.showSellerOwnerModal = false;
        this.refreshCollaterals();
        return;
    }


    this.collateralId = d.collateralId;
    this.typeOfPurchase = d.typeOfPurchase;
    this.linkedFromExisting = !!d.linkedFromExisting;
    this.isPropertyCostDisabled = !!d.isPropertyCostDisabled;

    this.isEditCollateral = true;
    this.showSellerOwnerModal = true;

    this.refreshCollaterals();
}




handleSellerOwnerClose() {
    this.showSellerOwnerModal = false;
}

handlePrevious() {

this.showSellerOwnerModal = false;
this.showCollateralModal = true;
}



handleLinkClose() {
    this.showLinkModal = false;
}

handleLinkSuccess() {
    this.showLinkModal = false;
    this.refreshCollaterals();
}


refreshCollaterals() {
    if (this.wiredCollateralsResult) {
        this.isTableLoading = true;
        refreshApex(this.wiredCollateralsResult)
            .catch(error => {
                this.showToast(
                    'Error',
                    this.getErrorMessage(error),
                    'error'
                );
            })
            .finally(() => {
                this.isTableLoading = false;
            });
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