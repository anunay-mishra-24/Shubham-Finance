import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {notifyRecordUpdateAvailable} from 'lightning/uiRecordApi';

import loadScreen from '@salesforce/apex/SHF_NegotiationScreenController.loadScreen';
import saveNegotiationDraft from '@salesforce/apex/SHF_NegotiationScreenController.saveNegotiationDraft';
import resetRequestedValues from '@salesforce/apex/SHF_NegotiationScreenController.resetRequestedValues';

import callNegotiationApproval from '@salesforce/apex/SHF_NegotiationApprovalController.callNegotiationApproval'; // added by mansur

const APP_MAP = {
sanctionAmount: {
    requestedApi: 'Negotiate_Sanctioned_Loan_Amount__c',
    reasonApi: 'Sanction_Loan_Amount_Reason_for_Change__c',
    label: 'Sanctioned Loan Amount'
},
tenure: {
    requestedApi: 'Negotiate_Tenure__c',
    reasonApi: 'Tenure_Reason_for_Change__c',
    label: 'Tenure'
},
roi: {
    requestedApi: 'Negotiation_Rate_of_Interest_ROI__c',
    reasonApi: 'ROI_Reason_for_Change__c',
    label: 'Rate of Interest (ROI)'
},
processingFee: {
    requestedApi: 'Negotiation_Processing_Fee__c',
    reasonApi: 'Processing_Fee_Reason_For_Change__c',
    label: 'Processing Fee'
},
processingFeePercent: {
    requestedApi: 'Negotiation_Processing_Fee_Percent__c',
    reasonApi: 'Processing_Fee_Percent_Reason_For_Change__c',
    label: 'Processing Fee Percent'
}
};

const INS_MAP = {
insured: {
    requestedApi: 'Negotiation_Insured_Amount__c',
    reasonApi: 'Insurance_Amount_Reason_for_Change__c',
    label: 'Insurance Amount'
},
premium: {
    requestedApi: 'Negotiation_Insurance_Premium__c',
    reasonApi: 'Insurance_Premium_Reason_for_Change__c',
    label: 'Insurance Premium'
},
tenure: {
    requestedApi: 'Negotiation_Insurance_Tenure__c',
    reasonApi: 'Insurance_Tenure_Reason_for_Change__c',
    label: 'Insurance Tenure'
}
};

export default class ShfNegotiationScreen extends LightningElement {
@api recordId; 

isLoading = false;
isSubmitted = false;


//_loadTimer;
//_loadedOnce = false;


applicationActual = { sanctionAmount: '', tenure: '', roi: '', processingFee: '', processingFeePercent: '' };
applicationRequestedServer = { sanctionAmount: '', tenure: '', roi: '', processingFee: '', processingFeePercent: '' };
applicationRequestedDraft = { sanctionAmount: '', tenure: '', roi: '', processingFee: '', processingFeePercent: '' };
applicationUiDraft = { sanctionAmount: '', tenure: '', roi: '', processingFee: '', processingFeePercent: '' };
applicationOriginal = { sanctionAmount: '', tenure: '', roi: '', processingFee: '', processingFeePercent: '' };

insuranceRows = [];


cboApprovalStatus = '';
reSanctionStatus = '';
applicationStage = '';
canEdit = false;
showReasonModal = false;
reasonModalItems = [];
reasonByKey = {};

showSubmitConfirmModal = false;
showSubmitSuccessMessage = false;
activeSections = [];
collateralRows = [];

collateralColumns = [
    { label: 'Collateral Name', fieldName: 'collateralName', type: 'text', wrapText: true, initialWidth: 200, cellAttributes: { alignment: 'left' } },
    { label: 'Market Value', fieldName: 'marketValue', type: 'currency', wrapText: true,  typeAttributes: { currencyCode: "INR", step: "0.001" } ,initialWidth: 200, cellAttributes: { alignment: 'left' } },
    { label: 'Agreement Value', fieldName: 'agreementValue', type: 'currency', wrapText: true, typeAttributes: { currencyCode: "INR", step: "0.001" } ,initialWidth: 200,cellAttributes: { alignment: 'left' }} , 
    { label: 'Property Address', fieldName: 'propertyAddress', type: 'text', wrapText: true,initialWidth: 450 , cellAttributes: { alignment: 'left' }  }, 
    { label: 'LTV', fieldName: 'ltv', type: 'number', wrapText: true, initialWidth: 200 , cellAttributes: { alignment: 'left' }} 
];

get isUserEditLocked() {
return !this.canEdit;
}
get isSaveDisabled() {
return this.isLoading || this.isSubmitted || this.isApprovalPendingLock || this.isUserEditLocked || !this.hasAnyRequestedChange();
}

get isResetDisabled() {
return this.isLoading || this.isSubmitted || this.isApprovalPendingLock || this.isUserEditLocked || !this.hasRequestedOnServer();
}

get isSubmitDisabled() {
return this.isLoading || this.isSubmitted || this.isApprovalPendingLock || this.isUserEditLocked || !this.hasRequestedOnServer() || this.hasAnyRequestedChange();
}
get isApprovalPendingLock() {
return this.normalize(this.cboApprovalStatus) === 'Pending'
    || this.normalize(this.reSanctionStatus) === 'Pending' || this.normalize(this.applicationStage) !== 'Negotiation';
}
get isFieldDisabled() {
return this.isSubmitted || this.isApprovalPendingLock || this.isUserEditLocked;
}
get disableSanctionAmount() {
return this.isFieldDisabled || this.isAppOriginalLocked('sanctionAmount');
}
get disableRoi() {
return this.isFieldDisabled || this.isAppOriginalLocked('roi');
}
get disableTenure() {
return this.isFieldDisabled || this.isAppOriginalLocked('tenure');
}
get disableProcessingFee() {
return this.isFieldDisabled || this.isAppOriginalLocked('processingFee');
}
get disableProcessingFeePercent() {
return this.isFieldDisabled || this.isAppOriginalLocked('processingFeePercent');
}




connectedCallback() {
    console.error('CONNECTED');
    console.error('recordId =', this.recordId);
    console.error('host =', this.template.host?.tagName);
    this.loadData();
}



async loadData() {
    this.isLoading = true;
    try {
        const dto = await loadScreen({ applicationId: this.recordId });
        if (dto) this.applyServerData(dto);
    } catch (e) {
        this.toast('Error', this.reduceError(e), 'error');
    } finally {
        this.isLoading = false;
    }
}

applyServerData(dto) {
    console.log('--- applyServerData called ---', dto);
    this.canEdit = !!dto.canEdit;
    this.cboApprovalStatus = dto.cboApprovalStatus || '';
    this.reSanctionStatus  = dto.reSanctionStatus || '';
    this.applicationStage = dto.applicationStage || '';
    if (!this.canEdit) {
this.toast('Info', 'Only Branch Manager role or Admin can edit this screen.', 'info');
}

    if (this.isApprovalPendingLock) {
      //  this.toast('Info', 'This record is in pending approval. Editing is disabled.', 'info');
    }
    this.applicationActual = {
        sanctionAmount: this.toUi(dto.actualSanctionAmount),
        tenure: this.toUi(dto.actualTenure),
        roi: this.toUi(dto.actualRoi),
        processingFee: this.toUi(dto.actualProcessingFee),
        processingFeePercent: this.toUi(dto.actualProcessingFeePercent)
    };
    this.applicationOriginal = {
    sanctionAmount: this.toUi(dto.originalSanctionAmount),
    tenure: this.toUi(dto.originalTenure),
    roi: this.toUi(dto.originalRoi),
    processingFee: this.toUi(dto.originalProcessingFee),
    processingFeePercent: this.toUi(dto.originalProcessingFeePercent)
    };

        this.collateralRows = (dto.collateralRows || []).map(r => ({
    collateralId: r.collateralId,
    collateralName: r.collateralName || '',
    marketValue: r.marketValue,
    ltv: r.ltv,
    propertyAddress: r.propertyAddress || '',
    agreementValue: r.agreementValue
}));

    this.applicationRequestedServer = {
        sanctionAmount: this.toUi(dto.requestedSanctionAmount),
        tenure: this.toUi(dto.requestedTenure),
        roi: this.toUi(dto.requestedRoi),
        processingFee: this.toUi(dto.requestedProcessingFee),
        processingFeePercent: this.toUi(dto.requestedProcessingFeePercent)
    };
    this.applicationRequestedDraft = { ...this.applicationRequestedServer };


    this.applicationUiDraft = { ...this.applicationActual };


    const src = dto.insuranceRows || [];
    const rows = [];
    for (let i = 0; i < src.length; i++) {
        const r = src[i];
        const actualInsured = this.toUi(r.actualInsuredAmount);
        const actualPrem = this.toUi(r.actualInsurancePremium);
        const actualTen = this.toUi(r.actualInsuranceTenure);

        const reqIns = this.toUi(r.requestedInsuredAmount);
        const reqPrem = this.toUi(r.requestedInsurancePremium);
        const reqTen = this.toUi(r.requestedInsuranceTenure);

        const origIns  = this.toUi(r.originalInsuredAmount);
        const origPrem = this.toUi(r.originalInsurancePremium);
        const origTen  = this.toUi(r.originalInsuranceTenure);
        rows.push({
            loanApplicantId: r.loanApplicantId,
            applicantName: r.applicantName || '',
            insuranceVerificationId: r.insuranceVerificationId,

            actualInsuredAmount: actualInsured,
            actualPremiumAmount: actualPrem,
            actualTenure: actualTen,

            requestedInsuredServer: reqIns,
            requestedPremiumServer: reqPrem,
            requestedTenureServer: reqTen,

            requestedInsuredDraft: reqIns,
            requestedPremiumDraft: reqPrem,
            requestedTenureDraft: reqTen,


            uiInsuredAmount: actualInsured,
            uiPremiumAmount: actualPrem,
            uiTenure: actualTen,

            originalInsuredAmount: origIns,
            originalPremiumAmount: origPrem,
            originalTenure: origTen,

            disableInsured: this.isSubmitted || this.isFieldDisabled || this.isApprovalPendingLock || !r.insuranceVerificationId || !!this.normalize(origIns) || this.isUserEditLocked,
            disablePremium: this.isSubmitted || this.isFieldDisabled || this.isApprovalPendingLock || !r.insuranceVerificationId || !!this.normalize(origPrem) || this.isUserEditLocked,
            disableTenure:  this.isSubmitted || this.isFieldDisabled || this.isApprovalPendingLock || !r.insuranceVerificationId || !!this.normalize(origTen) || this.isUserEditLocked
        });
    }
    this.insuranceRows = rows;
    this.refreshInsuranceDisableFlags();
    


    this.showReasonModal = false;
    this.reasonModalItems = [];
    this.reasonByKey = {};
}


get insuranceUiRows() {
    return this.insuranceRows;
}

isAppOriginalLocked(key) {
return !!this.normalize(this.applicationOriginal?.[key]);
}

handleApplicationChange(event) {
    const key = event.target.dataset.field;
    const val = event.detail.value;


    if (!this.validatePositive(event.target, val)) return;
    if (key === 'roi' && !this.validateMax100(event.target, val)) return;
    if (key === 'tenure' && !this.validateMin1(event.target, val)) return;
    if (key === 'processingFeePercent' && !this.validateMax100(event.target, val)) return;
    if (key === 'processingFee' && !this.validatePositive(event.target, val)) return;
    if (key === 'sanctionAmount' && !this.validatePositive(event.target, val)) return;



    this.applicationUiDraft = { ...this.applicationUiDraft, [key]: this.toUi(val) };



    const actual = this.applicationActual[key];
    const clearReq = this.normalize(val) === this.normalize(actual);

    this.applicationRequestedDraft = {
        ...this.applicationRequestedDraft,
        [key]: clearReq ? '' : this.toUi(val)
    };
}
hasRequestedOnServer() {
if (this.normalize(this.applicationRequestedServer.sanctionAmount)) return true;
if (this.normalize(this.applicationRequestedServer.tenure)) return true;
if (this.normalize(this.applicationRequestedServer.roi)) return true;
if (this.normalize(this.applicationRequestedServer.processingFee)) return true;
if (this.normalize(this.applicationRequestedServer.processingFeePercent)) return true;

for (let i = 0; i < this.insuranceRows.length; i++) {
    const r = this.insuranceRows[i];
    if (this.normalize(r.requestedInsuredServer)) return true;
    if (this.normalize(r.requestedPremiumServer)) return true;
    if (this.normalize(r.requestedTenureServer)) return true;
}
return false;
}

handleInsuranceChange(event) {
        const laId = event.target.dataset.laId;
    //  const insId = event.target.dataset.insId;
    const field = event.target.dataset.insField; 
    const val = event.detail.value;

    if (!laId) return;

    if (field === 'tenure') {
        if (!this.validateMin1(event.target, val)) return;
    } else {
        if (!this.validatePositive(event.target, val)) return;
    }

    const updated = [];
    for (let i = 0; i < this.insuranceRows.length; i++) {
        const row = this.insuranceRows[i];
        if (row.loanApplicantId !== laId) {
        updated.push(row);
        continue;
    }


        const nextRow = { ...row };
        if (field === 'insured') nextRow.uiInsuredAmount = this.toUi(val);
        if (field === 'premium') nextRow.uiPremiumAmount = this.toUi(val);
        if (field === 'tenure') nextRow.uiTenure = this.toUi(val);


        const actual =
            field === 'insured' ? row.actualInsuredAmount :
            field === 'premium' ? row.actualPremiumAmount :
            row.actualTenure;

        const clearReq = this.normalize(val) === this.normalize(actual);

        if (field === 'insured') nextRow.requestedInsuredDraft = clearReq ? '' : this.toUi(val);
        if (field === 'premium') nextRow.requestedPremiumDraft = clearReq ? '' : this.toUi(val);
        if (field === 'tenure') nextRow.requestedTenureDraft = clearReq ? '' : this.toUi(val);

        updated.push(nextRow);
    }
    this.insuranceRows = updated;
}

refreshInsuranceDisableFlags() {
    const fieldDisabled = this.isFieldDisabled; // isSubmitted / approval lock / user lock included

    this.insuranceRows = (this.insuranceRows || []).map(r => {
        const common = fieldDisabled || !r.insuranceVerificationId;

        return {
            ...r,
            disableInsured: common || !!this.normalize(r.originalInsuredAmount),
            disablePremium: common || !!this.normalize(r.originalPremiumAmount),
            disableTenure:  common || !!this.normalize(r.originalTenure)
        };
    });
}


validateAllInputsBeforeSave() {
    let ok = true;

    const inputs = this.template.querySelectorAll('lightning-input');
    for (let i = 0; i < inputs.length; i++) {
        const inp = inputs[i];

       
        if (inp.disabled) continue;

        const val = inp.value;

       
        const appKey = inp.dataset.field;
        if (appKey) {
            if (appKey === 'tenure') {
                ok = this.validateMin1(inp, val) && ok;
                continue;
            }
            if (appKey === 'roi' || appKey === 'processingFeePercent') {
                const v1 = this.validatePositive(inp, val);
                const v2 = v1 ? this.validateMax100(inp, val) : false; 
                ok = v1 && v2 && ok;
                continue;
            }
            ok = this.validatePositive(inp, val) && ok;
            continue;
        }

       
        const insField = inp.dataset.insField;
        if (insField) {
            if (insField === 'tenure') ok = this.validateMin1(inp, val) && ok;
            else ok = this.validatePositive(inp, val) && ok;
            continue;
        }

       
        ok = inp.reportValidity() && ok;
    }

    return ok;
}



handleSaveClick() {
     if (!this.validateAllInputsBeforeSave()) {
        this.toast('Validation Error', 'Please fill all required fields.', 'error');
        return;
    }
    if (!this.validateInsuranceNotBlank()) {
        this.toast('Validation Error', 'Insurance details cannot be blank.', 'error');
        return;
    }

    const changedItems = this.getChangedItemsForReasons();
    if (changedItems.length === 0) {
        this.toast('No Changes', 'No changes detected.', 'info');
        return;
    }


    this.reasonModalItems = changedItems.map((x) => ({
        key: x.key,
        label: x.label,
        reason: this.reasonByKey[x.key] || ''
    }));
    this.showReasonModal = true;
}

closeReasonModal() {
    this.showReasonModal = false;
}

handleReasonTextChange(event) {
    const key = event.target.dataset.reasonKey;
    const val = event.detail.value;
    this.reasonByKey = { ...this.reasonByKey, [key]: val };
    this.reasonModalItems = this.reasonModalItems.map((i) => (i.key === key ? { ...i, reason: val } : i));
}

async proceedSave() {

    const areas = this.template.querySelectorAll('lightning-textarea');
    let ok = true;
    for (let i = 0; i < areas.length; i++) {
        if (!areas[i].checkValidity()) {
            areas[i].reportValidity();
            ok = false;
        }
    }
    if (!ok) {
        this.toast('Validation Error', 'Please provide reason for each changed field.', 'error');
        return;
    }

    const buildPayload = this.buildSavePayload();
    if (!buildPayload) {
        this.toast('No Changes', 'No changes detected.', 'info');
        return;
    }

    this.isLoading = true;
    try {
        const payloadSave = JSON.stringify(buildPayload);
        const resp = await saveNegotiationDraft({ payloadSave });
        if (resp === 'Success') {
            this.toast('Success', 'Negotiation values saved successfully.', 'success');
            this.showReasonModal = false;
            await this.loadData(); 
        } else {
            this.toast('Error', String(resp || 'Save failed.'), 'error');
        }
    } catch (e) {
        this.toast('Error', this.reduceError(e), 'error');
    } finally {
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        this.isLoading = false;
    }
}


async handleResetClick() {
    this.isLoading = true;
    try {
        await resetRequestedValues({ applicationId: this.recordId });
        this.toast('Success', 'Negotiation values cleared.', 'success');
        await this.loadData();
    } catch (e) {
        this.toast('Error', this.reduceError(e), 'error');
    } finally {
        this.isLoading = false;
    }
}

handleSectionToggle(event) {

const open = event.detail.openSections;
this.activeSections = Array.isArray(open) ? open : (open ? [open] : []);
}
handleSubmitClick() {
    console.log('--- handleSubmitClick called ---',this.isSubmitted);
if (this.isSubmitted) return;


if (!this.hasRequestedOnServer()) {
    this.toast('Error', 'No negotiation values found. Please update and save before submitting for approval.', 'error');
    return;
}


if (this.hasAnyRequestedChange()) {
    this.toast('Error', 'Please save your changes before submitting for approval.', 'error');
    return;
}

this.showSubmitConfirmModal = true;
}


closeSubmitConfirmModal() {
    this.showSubmitConfirmModal = false;
}

confirmSubmit() {
    this.isLoading = true;
        // For now UI only (Apex/flow mapping later)
    this.showSubmitConfirmModal = false;

            //Added by mansur 
     callNegotiationApproval({applicationId: this.recordId })
         .then(async result => {
             this.isLoading = false;
             console.log('call callNegotiationApproval ', result);
             if (result.startsWith('success')) {
                 this.isSubmitted = true; 
                 this.refreshInsuranceDisableFlags();
                 console.log('success ');
                 this.toast('Success', 'Submitted for approval successfully.', 'success');
                  notifyRecordUpdateAvailable([{recordId: this.recordId}]);
             }else if(result.startsWith('unavailableCreditSanctionUser')){
                  this.toast('Error', 'Last Sanctioned user not available', 'error');
            
             }else if(result.startsWith('unavailableCBO')){
                 this.toast('Error', 'CBO User not available', 'error');
             }
         }).catch(error => {
              this.isLoading = false;
             this.toast('Error', 'error in negotiotion approval', 'error');
         })  
}


hasAnyRequestedChange() {
    const keys = Object.keys(APP_MAP);
    for (let i = 0; i < keys.length; i++) {
        const k = keys[i];
        if (this.normalize(this.applicationRequestedDraft[k]) !== this.normalize(this.applicationRequestedServer[k])) return true;
    }

    for (let i = 0; i < this.insuranceRows.length; i++) {
        const r = this.insuranceRows[i];
        if (this.normalize(r.requestedInsuredDraft) !== this.normalize(r.requestedInsuredServer)) return true;
        if (this.normalize(r.requestedPremiumDraft) !== this.normalize(r.requestedPremiumServer)) return true;
        if (this.normalize(r.requestedTenureDraft) !== this.normalize(r.requestedTenureServer)) return true;
    }
    return false;
}

getChangedItemsForReasons() {
    const items = [];


    const keys = Object.keys(APP_MAP);
    for (let i = 0; i < keys.length; i++) {
        const k = keys[i];
        if (this.normalize(this.applicationRequestedDraft[k]) !== this.normalize(this.applicationRequestedServer[k])) {
            items.push({ key: `APP::${k}`, label: `${APP_MAP[k].label} - Reason for Change` });
        }
    }


    for (let i = 0; i < this.insuranceRows.length; i++) {
        const r = this.insuranceRows[i];
        const insId = r.insuranceVerificationId;
        const laId  = r.loanApplicantId;
        if (!insId || !laId) continue;

        if (this.normalize(r.requestedInsuredDraft) !== this.normalize(r.requestedInsuredServer)) {
        items.push({ key: `INS::${laId}::insured`, label: `${r.applicantName} - ${INS_MAP.insured.label} - Reason for Change` });
        }
        if (this.normalize(r.requestedPremiumDraft) !== this.normalize(r.requestedPremiumServer)) {
        items.push({ key: `INS::${laId}::premium`, label: `${r.applicantName} - ${INS_MAP.premium.label} - Reason for Change` });
        }
        if (this.normalize(r.requestedTenureDraft) !== this.normalize(r.requestedTenureServer)) {
        items.push({ key: `INS::${laId}::tenure`, label: `${r.applicantName} - ${INS_MAP.tenure.label} - Reason for Change` });
        }

    }

    return items;
}

buildSavePayload() {
    console.log('--- buildSavePayload called ---',this.recordId);
    const payload = {
        applicationId: this.recordId,
        applicationRequestedUpdates: {},
        applicationReasonUpdates: {},
        insuranceUpdates: []
    };

    console.log('--- applicationRequestedDraft ---',this.applicationRequestedDraft);
    console.log('--- applicationRequestedServer ---',this.applicationRequestedServer);
    console.log('--- reasonByKey ---',payload);
    const keys = Object.keys(APP_MAP);
    for (let i = 0; i < keys.length; i++) {
        const k = keys[i];
        console.log('--- processing key ---',k);
        const draft = this.normalize(this.applicationRequestedDraft[k]);
        const server = this.normalize(this.applicationRequestedServer[k]);
        console.log('--- draft ---',draft);
        console.log('--- server ---',server);
        if (draft !== server) {
            payload.applicationRequestedUpdates[APP_MAP[k].requestedApi] = draft;
            payload.applicationReasonUpdates[APP_MAP[k].reasonApi] = (this.reasonByKey[`APP::${k}`] || '').trim();
        }
    }
        console.log('--- after application loop ---',payload);

    for (let i = 0; i < this.insuranceRows.length; i++) {
        const r = this.insuranceRows[i];
        const insId = r.insuranceVerificationId;
        const laId = r.loanApplicantId;

        if (!insId) continue;

        const item = { insuranceVerificationId: insId, requestedUpdates: {}, reasonUpdates: {} };

        const di = this.normalize(r.requestedInsuredDraft), si = this.normalize(r.requestedInsuredServer);
        if (di !== si) {
            item.requestedUpdates[INS_MAP.insured.requestedApi] = di;
            item.reasonUpdates[INS_MAP.insured.reasonApi] = (this.reasonByKey[`INS::${laId}::insured`] || '').trim();
        }

        const dp = this.normalize(r.requestedPremiumDraft), sp = this.normalize(r.requestedPremiumServer);
        if (dp !== sp) {
            item.requestedUpdates[INS_MAP.premium.requestedApi] = dp;
            item.reasonUpdates[INS_MAP.premium.reasonApi] = (this.reasonByKey[`INS::${laId}::premium`] || '').trim();
        }

        const dt = this.normalize(r.requestedTenureDraft), st = this.normalize(r.requestedTenureServer);
        if (dt !== st) {
            item.requestedUpdates[INS_MAP.tenure.requestedApi] = dt;
            item.reasonUpdates[INS_MAP.tenure.reasonApi] = (this.reasonByKey[`INS::${laId}::tenure`] || '').trim();
        }

        if (Object.keys(item.requestedUpdates).length > 0) payload.insuranceUpdates.push(item);
    }

    const hasAny =
        Object.keys(payload.applicationRequestedUpdates).length > 0 ||
        payload.insuranceUpdates.length > 0;

    return hasAny ? payload : null;
}


validateInsuranceNotBlank() {
    let ok = true;

    for (let i = 0; i < this.insuranceRows.length; i++) {
        const r = this.insuranceRows[i];
        if (!r.insuranceVerificationId) continue;

        const effInsured = this.normalize(r.requestedInsuredDraft) || this.normalize(r.actualInsuredAmount);
        const effPrem = this.normalize(r.requestedPremiumDraft) || this.normalize(r.actualPremiumAmount);
        const effTen = this.normalize(r.requestedTenureDraft) || this.normalize(r.actualTenure);

        ok = this.validateRequiredInsuranceInput(r.loanApplicantId, 'insured', effInsured) && ok;
        ok = this.validateRequiredInsuranceInput(r.loanApplicantId, 'premium', effPrem) && ok;
        ok = this.validateRequiredInsuranceInput(r.loanApplicantId, 'tenure', effTen) && ok;

    }

    return ok;
}

validateRequiredInsuranceInput(laId, field, effectiveValue) {
    const input = this.template.querySelector(
        `lightning-input[data-la-id="${laId}"][data-ins-field="${field}"]`
    );
    if (!input) return true;

    if (!effectiveValue) {
        input.setCustomValidity('This field is required.');
        input.reportValidity();
        return false;
    }

    const n = Number(effectiveValue);
    if (Number.isNaN(n) || n <= 0) {
        input.setCustomValidity('Value must be greater than 0.');
        input.reportValidity();
        return false;
    }

    input.setCustomValidity('');
    input.reportValidity();
    return true;
}


validatePositive(input, val) {
    const s = this.normalize(val);

    if (!s) {
        const msg = input?.required ? 'This field is required.' : '';
        input.setCustomValidity(msg);
        input.reportValidity();
        return !input?.required;
    }

    const n = Number(s);
    const ok = !Number.isNaN(n) && n > 0;

    input.setCustomValidity(ok ? '' : 'Value must be greater than 0.');
    input.reportValidity();
    return ok;
}


validateMin1(input, val) {
    const s = this.normalize(val);

    if (!s) {
        const msg = input?.required ? 'This field is required.' : '';
        input.setCustomValidity(msg);
        input.reportValidity();
        return !input?.required;
    }

    const n = Number(s);
    const ok = !Number.isNaN(n) && n >= 1;

    input.setCustomValidity(ok ? '' : 'Value must be 1 or greater.');
    input.reportValidity();
    return ok;
}


validateMax100(input, val) {
    const s = this.normalize(val);
    if (!s) {
        const msg = input?.required ? 'This field is required.' : '';
        input.setCustomValidity(msg);
        input.reportValidity();
        return !input?.required;
    }

    const n = Number(s);
    const ok = !Number.isNaN(n) && n <= 100;

    input.setCustomValidity(ok ? '' : 'Value must be less than or equal to 100.');
    input.reportValidity();
    return ok;
}



normalize(v) {
    if (v === null || v === undefined) return '';
    return String(v).trim();
}

toUi(v) {
    if (v === null || v === undefined) return '';
    return String(v);
}

toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
}

reduceError(err) {
    try {
        if (!err) return 'Unknown error occurred.';
        if (typeof err === 'string') return err;
        if (Array.isArray(err.body)) return err.body.map(e => e.message).join(', ');
        if (err.body?.message) return err.body.message;
        return err.message || 'Unknown error occurred.';
    } catch (e) {
        return 'Unknown error occurred.';
    }
}
}