import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

import VERIFICATION_OBJECT from '@salesforce/schema/Verification_Activity__c';
import TYPE_FIELD from '@salesforce/schema/Verification_Activity__c.Type__c';
import PICKUP_CRITERIA_FIELD from '@salesforce/schema/Verification_Activity__c.Pickup_up_Criteria__c';
import RCU_ACTIVITY_STATUS_FIELD from '@salesforce/schema/Verification_Activity__c.RCU_Activity_Status__c';
import OVERALL_STATUS_FIELD from '@salesforce/schema/Verification_Activity__c.Overall_Status__c';
import OVERALL_REMARKS_FIELD from '@salesforce/schema/Verification_Activity__c.Overall_Remarks__c';

import getData from '@salesforce/apex/SHF_VerificationActivityReportSvc.getData';
import saveData from '@salesforce/apex/SHF_VerificationActivityReportSvc.saveData';
import fetchApplicants from '@salesforce/apex/SHF_VerificationActivityReportSvc.fetchApplicants';

export default class Shf_VerificationActivityReportForm extends LightningElement {
    @track resolvedRecordId;
    @track input;

    @api
    get recordId() {
        return this.resolvedRecordId;
    }
    set recordId(value) {
        if (value && value !== this.resolvedRecordId) {
            this.resolvedRecordId = value;
            this.loadFromApex();
        }
    }

    @wire(CurrentPageReference)
    wiredPageRef(pr) {
        this.pageRef = pr;
        this.resolveRecordIdFromPageRef();
    }

    pageRef;

    @track isModalOpen = false;


    @track isLoading = false;
    @track isSaving = false;


    _isFetching = false;


    @track rcuReportDate;
    @track rcuAgencyName;
    @track applicationNo;
    @track branchName;
    @track state;
    @track region;
    @track product;
    @track program;
    @track sourcingChannel;
    @track sourcingOfficerName;
    @track sourcingOfficerEmpId;
    @track pickupDate;
    @track reportedDate;
    @track tat;
    @track loanAmount;
    @track timestamp;


    @track typeValue;
    @track documentName;
    @track pickupCriteriaValue;
    @track rcuActivityStatusValue;
    @track totalDocsSampled;
    @track overallStatusValue;
    @track overallRemarksValue;
    @track isRcuEditable;


    @track tempTypeValue;
    @track tempPickupDate;
    @track tempReportedDate;
    @track tempDocumentName;
    @track tempPickupCriteriaValue;
    @track tempRcuActivityStatusValue;
    @track tempTotalDocsSampled;
    @track tempOverallStatusValue;
    @track tempOverallRemarksValue;
    @track isRcuEditable = true;

    @track typeOptions = [];
    @track pickupCriteriaOptions = [];
    @track rcuActivityStatusOptions = [];
    @track overallStatusOptions = [];
    @track overallRemarksOptions = [];


    @track applicantName;
    @track coApplicants = [];
    @track coApplicantsWithLabels = [];
    @track applicationId;

    connectedCallback() {
        this.setDates();
        this.resolveRecordIdFromUrlFallback();
        this.loadFromApex();
    }

    setDates() {
        const now = new Date();
        this.rcuReportDate = now.toISOString().split('T')[0];
        this.timestamp = now.toLocaleString('en-IN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: false
        });
    }


    get showSpinner() {
        return this.isLoading || this.isSaving;
    }

    isSfId(val) {
        return typeof val === 'string' && /^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/.test(val);
    }

    resolveRecordIdFromPageRef() {
        if (this.isSfId(this.resolvedRecordId)) return;

        const pr = this.pageRef;
        const candidate =
            pr?.attributes?.recordId ||
            pr?.state?.recordId ||
            pr?.state?.c__recordId ||
            pr?.state?.id;

        if (this.isSfId(candidate)) {
            this.resolvedRecordId = candidate;
            console.log('Resolved recordId from pageRef ', this.resolvedRecordId);
            this.loadFromApex();
            return;
        }

        this.resolveRecordIdFromUrlFallback();
    }

    resolveRecordIdFromUrlFallback() {
        if (this.isSfId(this.resolvedRecordId)) return;
        try {
            const path = window.location?.pathname || '';
            const search = window.location?.search || '';

            let match = path.match(/([a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?)/);
            if (!match) {
                match = search.match(/([a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?)/);
            }
            if (match && this.isSfId(match[1])) {
                this.resolvedRecordId = match[1];
                console.log('Resolved recordId from URL ', this.resolvedRecordId);
                this.loadFromApex();
            }
        } catch (e) {

        }
    }

    @wire(getObjectInfo, { objectApiName: VERIFICATION_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: TYPE_FIELD
    })
    wiredType({ data, error }) {
        if (data) this.typeOptions = data.values;
        if (error) console.error('Type picklist error', error);
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: PICKUP_CRITERIA_FIELD
    })
    wiredPickupCriteria({ data, error }) {
        if (data) this.pickupCriteriaOptions = data.values;
        if (error) console.error('PickupCriteria picklist error', error);
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: RCU_ACTIVITY_STATUS_FIELD
    })
    wiredRcuActivityStatus({ data, error }) {
        if (data) this.rcuActivityStatusOptions = data.values;
        if (error) console.error('RCU Activity picklist error', error);
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: OVERALL_STATUS_FIELD
    })
    wiredOverallStatus({ data, error }) {
        if (data) this.overallStatusOptions = data.values;
        if (error) console.error('OverallStatus picklist error', error);
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: OVERALL_REMARKS_FIELD
    })
    wiredOverallRemarks({ data, error }) {
        if (data) this.overallRemarksOptions = data.values;
        if (error) console.error('OverallRemarks picklist error', error);
    }


    async loadFromApex() {
        if (!this.isSfId(this.resolvedRecordId)) {
            console.log('recordId not available yet...');
            return;
        }
        if (this._isFetching) return;

        this._isFetching = true;
        this.isLoading = true;

        try {
            console.log('Loading from Apex for recordId =>', this.resolvedRecordId);

            const res = await getData({ recordId: this.resolvedRecordId });

            this.rcuAgencyName = res?.rcuAgencyName;
            this.applicationNo = res?.applicationNo;
            this.branchName = res?.branchName;
            this.state = res?.state;
            this.region = res?.region;
            this.product = res?.productName;
            this.program = res?.programName;
            this.sourcingChannel = res?.sourcingChannel;
            this.sourcingOfficerName = res?.sourcingOfficerName;
            this.sourcingOfficerEmpId = res?.sourcingOfficerEmpId;
            this.loanAmount = res?.loanAmount;
            this.tat = res?.tat;
            this.applicationId = res?.applicationId;

            this.typeValue = res?.typeValue;
            this.pickupDate = res?.pickupDate;
            this.reportedDate = res?.reportedDate;
            this.documentName = res?.documentName;
            this.pickupCriteriaValue = res?.pickupCriteriaValue;
            this.rcuActivityStatusValue = res?.rcuActivityStatusValue;
            this.totalDocsSampled = res?.totalDocsSampled;
            this.overallStatusValue = res?.overallStatusValue;
            this.overallRemarksValue = res?.overallRemarksValue;
            this.isRcuEditable = res?.isRcuEditable;

            await this.loadApplicants(); 
        } catch (e) {
            console.error('getData failed ', e);
            this.toast('Error', e?.body?.message || 'Failed to load data', 'error');
        } finally {
            this.isLoading = false;
            this._isFetching = false;
        }
    }

    async loadApplicants() {
        if (!this.applicationId) {
            this.applicantName = '';
            this.coApplicants = [];
            this.coApplicantsWithLabels = [];
            return;
        }

        try {
            const res = await fetchApplicants({ applicationId: this.applicationId });
            this.applicantName = res?.primaryApplicant || '';
            this.coApplicants = res?.coApplicants || [];
            this.coApplicantsWithLabels = this.coApplicants.map((name, index) => ({
                name,
                label: `Name of Co-Applicant ${index + 1}`,
                key: index
            }));
        } catch (err) {
            console.error('fetchApplicants error', err);
        }
    }
    get canEditRcuStatus() {
    const isBlank = this.tempRcuActivityStatusValue == null || this.tempRcuActivityStatusValue === '';
    return (this.isRcuEditable === true) || isBlank;
    }

    get isRCUStatusDisabled() {
        return !this.canEditRcuStatus;
    }

    get isRequired() {
        return this.canEditRcuStatus;
    }

    toast(title, message, variant) {
        try {
            this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
        } catch (e) {
            alert(`${title}: ${message}`);
        }
    }

    validateModal() {
        const modal = this.template.querySelector('.slds-modal');
        const inputs = modal
            ? modal.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')
            : this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');

        let allValid = true;
        inputs.forEach((cmp) => {
            if (typeof cmp.reportValidity === 'function') {
                const ok = cmp.reportValidity();
                if (!ok) allValid = false;
            }
        });
        return allValid;
    }


    openModal() {
        if (!this.isSfId(this.resolvedRecordId)) {
            this.toast('Error', 'Record Id not found on this page.', 'error');
            return;
        }

        this.tempTypeValue = this.typeValue;
        this.tempPickupDate = this.pickupDate;
        this.tempReportedDate = this.reportedDate;
        this.tempDocumentName = this.documentName;
        this.tempPickupCriteriaValue = this.pickupCriteriaValue;
        this.tempRcuActivityStatusValue = this.rcuActivityStatusValue;
        this.tempTotalDocsSampled = this.totalDocsSampled;
        this.tempOverallStatusValue = this.overallStatusValue;
        this.tempOverallRemarksValue = this.overallRemarksValue;

        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleChange(event) {
        const field = event.target.dataset.id;
        const value = event.target.value;

        switch (field) {
            case 'type':
                this.tempTypeValue = value;
                break;
            case 'pickupDate':
                this.tempPickupDate = value;
                break;
            case 'reportedDate':
                this.tempReportedDate = value;
                break;
            case 'documentName': {
                                    const regex = /^[a-zA-Z0-9 _-]+$/;

                                    if (value && !regex.test(value)) {
                                        event.target.setCustomValidity(
                                            'Only letters, numbers, hyphen (-), spaces and underscore (_) are allowed'
                                        );
                                    } else {
                                        event.target.setCustomValidity('');
                                        this.tempDocumentName = value;
                                    }
                                    event.target.reportValidity();
                                    break;
                                }
            case 'pickupCriteria':
                this.tempPickupCriteriaValue = value;
                break;
            case 'rcuActivityStatus':
                this.tempRcuActivityStatusValue = value;
                break;
            case 'totalDocsSampled': {
                                        const numVal = Number(value);

                                        if (value !== '' && (isNaN(numVal) || numVal < 0)) {
                                            event.target.setCustomValidity(
                                                'Value must be 0 or a positive number'
                                            );
                                        } else {
                                            event.target.setCustomValidity('');
                                            this.tempTotalDocsSampled = value;
                                        }

                                        event.target.reportValidity();
                                        break;
                                    }
            case 'overallStatus':
                this.tempOverallStatusValue = value;
                break;
            case 'overallRemarks':
                this.tempOverallRemarksValue = value;
                break;
            default:
                break;
        }
    }


    async saveChanges() {
        if (!this.isSfId(this.resolvedRecordId)) {
            this.toast('Error', 'Record Id not found on this page.', 'error');
            return;
        }
        if (this.isSaving) return;

        if (!this.validateModal()) {
            this.toast('Error', 'Some fields have invalid or missing values. Please correct them and try again.', 'error');
            return;
        }

        this.isSaving = true;
        try {
            const payloadObj = {
                id: this.resolvedRecordId,
                typeValue: this.tempTypeValue || null,
                pickupDate: this.tempPickupDate || null,
                reportedDate: this.tempReportedDate || null,
                documentName: this.tempDocumentName || null,
                pickupCriteriaValue: this.tempPickupCriteriaValue || null,
                rcuActivityStatusValue: this.tempRcuActivityStatusValue || null,
                totalDocsSampled:
                    (this.tempTotalDocsSampled === '' || this.tempTotalDocsSampled == null)
                        ? null
                        : Number(this.tempTotalDocsSampled),
                overallStatusValue: this.tempOverallStatusValue || null,
                overallRemarksValue: this.tempOverallRemarksValue || null
            };

            await saveData({ payload: JSON.stringify(payloadObj) });

            this.isModalOpen = false;
            this.toast('Success', 'Record updated successfully', 'success');

            await this.loadFromApex(); 
        } catch (e) {
            console.error('save failed', e);
            this.toast('Error', e?.body?.message || 'Update failed', 'error');
        } finally {
            this.isSaving = false;
        }
    }
}