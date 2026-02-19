import { LightningElement, wire, track, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { NavigationMixin } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';
import getPinCodeDetails from '@salesforce/apex/SHF_addressController.getPinCodeDetails';
import getexistingAddresses from '@salesforce/apex/SHF_addressController.getexistingAddresses';
import updateAddressLocation from '@salesforce/apex/SHF_addressController.updateAddressLocation';
import getMsgConfigRecord from '@salesforce/apex/SHF_CommonUtil.getMessageConfigurationsBySource';
import hasCommunicationAddress from '@salesforce/apex/SHF_addressController.hasCommunicationAddress';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ADDRESS_OBJECT from '@salesforce/schema/Address__c';

// Include Is_Address_copied_from_Lead__c from Loan_Applicant__c
const FIELDS = [
    'Loan_Applicant__c.RecordType_Name__c'
   
];

// Only address fields here
const ADDRESS_FIELDS = [
    'Address__c.Mailing_Address__c',
    'Address__c.City__c',
    'Address__c.State__c',
    'Address__c.Country__c',
    'Address__c.Communication_Address__c',
    'Address__c.Address_Category__c',
    'Address__c.Duration_at_Current_City__c',
    'Address__c.Duration_at_current_city_In_Months__c',
    'Address__c.Duration_at_Current_Address__c',
    'Address__c.Is_Address_copied_from_Lead__c' ,// Lead
    'Address__c.Duration_at_current_address_In_Months__c'
];

export default class Shf_AddressComponent extends NavigationMixin(LightningElement) {
    @api isEditAddressFromDRL = false; // NEW: passed from DynamicRelatedList
    @api isCopyAddressDisabled = false;
    @api recordId;
    @api addressRecordId;
    @api isEditAddress;
    @api pincodeId;
    @track isShowModal = false;
    @track isLoading = false;
    @track addressObj = {};
    selectedPincodeId;
    @track isNonIndividual = false;
    @track isIndividual = false;
    @track isDuplicateAddress = false;
    @track permanentAddNotAllowed = false;
    @track isResiSameAsPermanent = false;
    @track showResiEqualPermanent = false;
    @track showCurrentSameAsResidence = false;
    @track showResidenceSameAsPermanent = false;
    @track isResidenceAddressExist = false;
    @track isPermanentAddressExist = false;
    @track isDisableSave = false;
    @track locationChecked = false;
    @track showCopyAddressFrom = false;
    @track isCopyAddressReadOnly = false;
    @track hasCommAddress = false;
    @track isAddressCopiedFromLead = false;
    @track communicationAddressValue = '';
    // store existing addresses and current mailingAddress value
    @track existingAddresses = [];
    @track selectedMailingAddress = '';
    @track copyAddressFromOptions = [];
    @track copyAddressFromValue = '';
    @track showPresentResidentialType = false;
    @track copyAddressValue = 'No';
    @track showPrimaryAddress = false;
    resiSameAsPermanentValue = false;
    @track showResidentialType = false;  
    addressType;
    latitude;
    longitude;
    locationSet = false;
    createdRecorId;
    source = 'address';
    @track messagesMap = {};
    objectInfo;
    isMobile = false;
    // NEW: loanApplicantId from wrapper (for edit mode)
    @api loanApplicantId;

    // New variable to track location availability
    @track isLocationEnabled = false;

     get showNonIndividualAddressFields() {
        return this.copyAddressValue === 'No';
    }
get isCopyAddressYes() {
    return this.copyAddressValue === 'Yes';
}
    // READ-ONLY flag used in HTML
    get fieldsAreReadOnly() {
        return this.isAddressCopiedFromLead;
    }
    get showPrimaryAddress() {
    return this.selectedMailingAddress === 'Permanent Address';
}

    // Always-editable fields (Mailing_Address__c / Address_Type__c)
    get isAlwaysEditable() {
        return false;
    }

    //  use loanApplicantId when present, otherwise recordId
    get applicantIdForWire() {
        return this.loanApplicantId || this.recordId;
    }

    // control field visibility by applicant type
    get hideIndividualOnlyFields() {
        return this.isIndividual; // hide these when Individual
    }

    get hideNonIndividualOnlyFields() {
        return this.isNonIndividual; // hide these when Non-Individual
    }

    get durationLabels() {
    if (!this.objectInfo?.data) return {};

    const fields = this.objectInfo.data.fields;
console.log('## = ',fields);
    return {
        currentAddress: fields.Duration_at_Current_Address__c?.label,
        currentCityMonths: fields.Duration_at_current_city_In_Months__c?.label,
        currentAddressMonths: fields.Duration_at_current_address_In_Months__c?.label,
        currentCity: fields.Duration_at_Current_City__c?.label
    };
}


    //  wire now uses applicantIdForWire instead of recordId
    @wire(getRecord, { recordId: '$applicantIdForWire', fields: FIELDS })
    wiredApplicantRecord({ error, data }) {
        if (error) {
            console.error('wiredApplicantRecord=> ', error);
        }
        if (data) {
            let loanApplicantRecord = data;
            const fields = loanApplicantRecord.fields;

            console.log('recordType> ', fields.RecordType_Name__c.value);
            let recordtype = fields.RecordType_Name__c.value;
            if (recordtype === 'Individual') {
                this.isIndividual = true;
            } else if (recordtype === 'Non-Individual') {
                this.isNonIndividual = true;
            }


            console.log('Is_Address_copied_from_Lead__c => ', this.isAddressCopiedFromLead);
        }
    }

    @wire(getRecord, { recordId: '$addressRecordId', fields: ADDRESS_FIELDS })
    wiredAddressRecord({ error, data }) {
        if (error) {
            console.error('wiredAddressRecord error => ', error);
            return;
        }
        
        if (data) {
            const addressRecord = data;

            if (addressRecord.fields.Mailing_Address__c.value === 'Residential Address') {
                this.showResiEqualPermanent = true;
            }

            this.addressObj = {
                ...this.addressObj,
                City: addressRecord.fields.City__c?.value || '',
                State: addressRecord.fields.State__c?.value || '',
                Country: addressRecord.fields.Country__c?.value || ''
            };

            console.log(
                'Hydrated City/State/Country from existing address:',
                this.addressObj.City,
                this.addressObj.State,
                this.addressObj.Country
            );


            //Communication Address for edit picklist
            const comm = addressRecord.fields.Communication_Address__c
                ? addressRecord.fields.Communication_Address__c.value
                : null;

            this.communicationAddressValue = comm || '';
            console.log('Hydrated Communication_Address__c => ', this.communicationAddressValue);
             // Is_Address_copied_from_Lead__c
        this.isAddressCopiedFromLead = addressRecord.fields.Is_Address_copied_from_Lead__c?.value || false;
        console.log('Is_Address_copied_from_Lead__c → ', this.isAddressCopiedFromLead);

        }
    }//aaaa
    @wire(getObjectInfo, { objectApiName: ADDRESS_OBJECT })
   objectInfo;


    async connectedCallback() {

        //Bug-300 : Fix Modal Size Desktop/Mobile
        this.checkDevice();
        window.addEventListener('resize', this.checkDevice.bind(this));

        if (this.locationChecked) {
            console.log('Skipping duplicate connectedCallback execution.');
            return;
        }
        this.locationChecked = true;

        if (this.addressRecordId) {
            this.isEditAddress = true;
        }

        //  use loanApplicantId if available
        this.addressObj.loanApplicant = this.loanApplicantId || this.recordId;
        console.log('## this.addressObj.loanApplicant =',this.addressObj.loanApplicant);
        try {
            const hasComm = await hasCommunicationAddress({ loanApplicantId: this.addressObj.loanApplicant });
            this.hasCommAddress = hasComm;
            console.log('## hasComm =',this.hasCommAddress);
        } catch (e) {
            console.error('Error checking communication address: ', e);
        }
        this.fetchMetadata();

        // Only handle edit case here (skip GPS)
        if (this.isEditAddress) {
            console.log(' Edit mode detected — skipping GPS check.');
            this.isLocationEnabled = true;
            if (this.pincodeId) {
                await this.getPinCodeDetails(this.pincodeId);
            }
            this.isShowModal = true;

            // also load existing addresses for edit
            await this.loadExistingAddresses();
        }
    }

    checkDevice() {
        this.isMobile = window.innerWidth <= 768;
    }

    get modalClass() {
        // Desktop → keep full
        if (!this.isMobile) {
            return 'slds-modal slds-fade-in-open slds-modal_full';
        }

        // Mobile → remove full
        return 'slds-modal slds-fade-in-open';
    }

    renderedCallback() {
        try {
            console.log('renderedCallback isCopyAddressDisabled => ', this.isCopyAddressDisabled);

            const copyField = this.template.querySelector(
                'lightning-input-field[data-name="CopyAddress"]'
            );

            if (copyField) {
                // Directly control the field via public API
                //copyField.disabled = this.isCopyAddressDisabled;
                copyField.disabled = this.fieldsAreReadOnly || this.isCopyAddressDisabled;
            }
        } catch (e) {
            console.error('Error locking Copy Address field', e);
        }
    }



    //  all existing addresses once for this applicant
    async loadExistingAddresses() {
        try {
            // const result = await getexistingAddresses({ loanApplicantId: this.recordId }) || [];
            const applicantId = this.loanApplicantId || this.recordId;
const result = await getexistingAddresses({ loanApplicantId: applicantId }) || [];
            // Exclude current record in edit mode
            if (this.addressRecordId) {
                this.existingAddresses = result.filter(a => a.Id !== this.addressRecordId);
            } else {
                this.existingAddresses = result;
            }
            console.log('Loaded existing addresses:', JSON.stringify(this.existingAddresses));
        } catch (e) {
            console.error('Error loading existing addresses:', e);
            this.existingAddresses = [];
        }
    }

    buildCopyAddressFromOptions() {
        // For Individuals use Mailing_Address__c, for Non‑Individual use Address_Type__c
        if (this.isNonIndividual) {
            this.copyAddressFromOptions = (this.existingAddresses || [])
                .filter(addr => addr.Address_Type__c && addr.Address_Type__c !== this.selectedMailingAddress)
                .map(addr => ({
                    label: addr.Address_Type__c,
                    value: addr.Address_Type__c   // store address type as value
                }));
        } else {
            this.copyAddressFromOptions = (this.existingAddresses || [])
                .filter(addr => addr.Mailing_Address__c && addr.Mailing_Address__c !== this.selectedMailingAddress)
                .map(addr => ({
                    label: addr.Mailing_Address__c,
                    value: addr.Mailing_Address__c   // store mailing type as value
                }));
        }
    }
   
    async createNewAddress() {
        this.isLoading = true;
        try {
            await this.getCurrentLocation();
            this.isLocationEnabled = true;
            console.log(' Location enabled — opening New Address modal.');
        } catch (error) {
            this.isLocationEnabled = false;
            console.warn('GPS not available:', error.message);
            this.showToast(
                'Warning',
                'GPS is OFF — address will save without location coordinates.',
                'warning'
            );
        } finally {
            // open modal when GPS failed
            this.isShowModal = true;
            await this.loadExistingAddresses();
            await this.initCopyAddressBehavior();
            this.isLoading = false;
        }
    }

    async initCopyAddressBehavior() {
        try {
            if (this.isEditAddress) {
                return;
            }
            const addrCount = this.existingAddresses ? this.existingAddresses.length : 0;
            const copyField = this.template.querySelector(
                'lightning-input-field[data-name="CopyAddress"]'
            );
            if (!copyField) {
                return;
            }

            // If no address or no mailing address selected, disable Copy Address
            if (addrCount < 1 || !this.selectedMailingAddress) {
                copyField.value = 'No';
                copyField.disabled = true;
                this.isCopyAddressReadOnly = true;
                this.showCopyAddressFrom = false;
                this.copyAddressFromValue = null;
            } else {
                copyField.disabled = false;
                this.isCopyAddressReadOnly = false;
            }

        } catch (e) {
            console.error('initCopyAddressBehavior error =>', e);
        }
    }

    handleCopyFromChange(event) {
        this.copyAddressFromValue = event.detail.value;
    }

    async openEditAddress() {
        this.isLoading = true;
        try {
            await this.getCurrentLocation();
            this.isLocationEnabled = true;
            await this.getPinCodeDetails(this.pincodeId);
            this.isShowModal = true;
            await this.loadExistingAddresses();
            await this.initCopyAddressBehavior();
        } catch (error) {
            this.isLocationEnabled = false;
            this.showToast(
                'Error',
                'Location access denied or off. Please enable GPS and retry.',
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    hideCopyAddress = false;

    async handleAddressTypeChange(event) {
        try {
            // Reset flags
            this.isDuplicateAddress = false;
            this.permanentAddNotAllowed = false;
            this.isResiSameAsPermanent = false;
            this.isResidenceAddressExist = false;
            this.isPermanentAddressExist = false;
            const fieldName = event.target.dataset.name;
           // const fieldValue = event.detail.value;
            const fieldValue = event.detail ? event.detail.value : event.target.value;
        console.log('Triggered =>', fieldName, fieldValue);
        if (event.target.fieldName === 'Mailing_Address__c') {
    this.showPrimaryAddress = (event.target.value === 'Permanent Address');
}

        // New Residential Address Logic
        if (fieldName === 'mailingAddress') {
            this.showResidentialType = (fieldValue === 'Residential Address');
            console.log('showResidentialType => ', this.showResidentialType);
        }
           // const fieldValue = event.target.value;   //FIXED TARGET
            console.log('Triggered =>', fieldName, fieldValue);

            // if (fieldName === 'CopyAddress' && fieldValue == 'Yes') {
            //     this.hideCopyAddress = true;
            // }
            // else if (fieldName === 'CopyAddress' && fieldValue !== 'Yes') {
            //     this.hideCopyAddress = false;
            // }
            if (fieldName === 'CopyAddress') {
    this.copyAddressValue = fieldValue;   
}


            //  Communication_Address__c cannot be 'Yes' if one already marked for this applicant
            if (fieldName === 'Communication_Address__c') {
                if (this.hasCommAddress && (fieldValue === 'Yes' || fieldValue === true)) //&& !this.addressRecordId) 
                {
                    event.target.value = 'No';
                    this.showToast('Error', 'Communication address already exists for this applicant.', 'error');
                    return;
                }
            }

            // --- Detect main address type (Mailing / Address Type field)
            if (fieldName === 'addressType' || fieldName === 'mailingAddress') {
                this.selectedMailingAddress = fieldValue;
    // Show only for 'Residential Address'
    this.showPresentResidentialType = (fieldValue === 'Residential Address');
    console.log('showPresentResidentialType => ', this.showPresentResidentialType);
this.showCurrentSameAsResidence = (fieldValue === 'Current Address');
                this.addressType = fieldValue;
                this.selectedMailingAddress = fieldValue;

                // Show/hide dependent picklists
                this.showCurrentSameAsResidence = (fieldValue === 'Current Address');
                this.showResiEqualPermanent = (fieldValue === 'Residential Address');
                this.showResidenceSameAsPermanent = false;

                // After mailing/address type selected, refresh Copy Address enable/disable
                await this.loadExistingAddresses();
                await this.initCopyAddressBehavior();
                this.buildCopyAddressFromOptions();
                this.copyAddressFromValue = '';

                // Reset duplicate flag before checking
                this.isDuplicateAddress = false;

                // Duplicate / restriction checks using already-loaded existingAddresses
                for (const address of this.existingAddresses) {
                    // Individual: duplicate Mailing Address
                    if (
                        this.isIndividual &&
                        this.addressType &&
                        address.Mailing_Address__c === this.addressType
                    ) {
                        this.isDuplicateAddress = true;
                        break;
                    }

                    // Non‑Individual: duplicate Address Type
                    if (
                        this.isNonIndividual &&
                        this.addressType &&
                        address.Address_Type__c === this.addressType
                    ) {
                        this.isDuplicateAddress = true;
                        break;
                    }
                }

                if (this.isDuplicateAddress) {
                    this.showToast('Error', 'Selected address type already used. Please choose another.', 'error');
                    return;
                }

                console.log('Mailing/Address Type set:', this.addressType);
                return;
            }

            if (fieldName === 'CopyAddress') {
                this.showCopyAddressFrom = (fieldValue === 'Yes');
                return;
            }

            // --- Handle "Current Address same as Residence"
            if (fieldName === 'Current_Address_same_as_Residence') {
                const isYes = (fieldValue === 'Yes');
                this.currentSameAsResidence = isYes;
                this.showResidenceSameAsPermanent = isYes;

                if (isYes) {
                    const result = await getexistingAddresses({ loanApplicantId: this.recordId });
                    const resiExists = result.some(addr => addr.Mailing_Address__c === 'Residential Address');
                    if (resiExists) {
                        this.isResidenceAddressExist = true;
                        this.showToast('Error', 'Residence address already exists.', 'error');
                        return;
                    }

                    // Auto-set OVD Flag = true
                    const odvField = this.template.querySelector('lightning-input-field[field-name="OVD__c"]');
                    if (odvField) {
                        odvField.value = true;
                        odvField.disabled = true;
                    }

                    console.log('OVD__c set true as Current=Residence.');
                } else {
                    this.showResidenceSameAsPermanent = false;
                }
                return;
            }

            // --- Handle "Residence same as Permanent"
            if (fieldName === 'Residence_same_as_Permanent_Address') {
                const isYes = (fieldValue === 'Yes');
                this.resiSameAsPermanentValue = isYes;
                if (isYes) {
                    const result = await getexistingAddresses({ loanApplicantId: this.recordId });
                    const permExists = result.some(addr => addr.Mailing_Address__c === 'Permanent Address');
                    if (permExists) {
                        this.isPermanentAddressExist = true;
                        this.showToast('Error', 'Permanent address already exists.', 'error');
                        return;
                    }
                    console.log('Residence copied as Permanent (simulation)');
                }
                return;
            }

        } catch (error) {
            console.error('handleAddressTypeChange error =>', error);
            this.showToast('Error', 'Unexpected error occurred during validation.', 'error');
        }
    }
    
    handleOnLoad(event) {
    const records = event.detail.records;
    console.log('HandleLoad', JSON.stringify(records));
    if(records !== undefined){
    const rec = records[this.addressRecordId];

    if (rec && rec.fields.Mailing_Address__c) {
        const mailing = rec.fields.Mailing_Address__c.value;
        this.showPrimaryAddress = (mailing === 'Permanent Address');
    }
     if (rec && rec.fields.Mailing_Address__c) {
        const mailing = rec.fields.Mailing_Address__c.value;
         //  show Current_Address_same_as_Residence__c on edit
        this.showCurrentSameAsResidence = (mailing === 'Current Address');
        // show on edit when Residential Address
        this.showResidentialType = (mailing === 'Residential Address');
    } 
    }
}

    handleCloseMethod() {
        try {
            
            this.copyAddressFromValue = '';
            //  Clear Copy_Address_From__c field if present
            const copyFromField = this.template.querySelector(
                'lightning-input-field[field-name="Copy_Address_From__c"]'
            );
            if (copyFromField) {
                copyFromField.value = null;  // clears the value in the record-edit-form
            }
            //  separate combobox for Copy Address From clear 
            const copyFromCombo = this.template.querySelector(
                'lightning-combobox[data-name="CopyAddressFrom"]'
            );
            if (copyFromCombo) {
                copyFromCombo.value = null;
            }

            const selectedEvent1 = new CustomEvent('close', {
                detail: false
            });
            this.dispatchEvent(selectedEvent1);
            console.log('selectedEvent1-> ', selectedEvent1);

        } catch (err) {
            console.log('err-> ', err);
        }
        this.isShowModal = false;
        this.isLoading = false;
    }

    async handleSuccess(event) {
        console.log(' onsuccess event recordEditForm', event.detail.id);
        this.createdRecorId = event.detail.id;
        console.log('Created record ID:', this.createdRecorId);

        this.isLoading = true;
        this.isDisableSave = false;

        if (this.createdRecorId) {
            try {
                await this.handleGetLocation();
                console.log(' Location updated successfully for record:', this.createdRecorId);
            } catch (error) {
                console.warn('Location update failed or denied:', error.message || error);
                // no warning toast now to reduce popups
            }
        }

        try {
            const odvField = this.template.querySelector('lightning-input-field[field-name="OVD__c"]');
            if (odvField) {
                odvField.disabled = true;
                console.log('OVD__c locked read-only after save.');
            }
        } catch (e) {
            console.warn('Could not disable OVD__c field:', e);
        }

        // Determine success message
        let successMsg = 'Address saved successfully';
        try {
            if (this.messagesMap && this.messagesMap['Address_updated_successfully']) {
                successMsg = this.messagesMap['Address_updated_successfully'].Message__c;
            }
        } catch (err) {
            console.warn('Message map missing or invalid:', err);
        }

        // Show final success toast
        this.showToast('Success', successMsg, 'success');

        try {
            this.handleCloseMethod();
            setTimeout(() => {
                window.location.reload();
            }, 1000);
        } catch (err) {
            console.error('Error closing modal or reloading:', err);
        }
    }

//Bug-362 - Fix
handleDurationValidation(event) {
    const fieldApiName = event.target.fieldName;
    const value = event.detail.value;
        if (!this.objectInfo?.data) {
            return;
        }

        const fieldLabel = this.objectInfo.data.fields[fieldApiName]?.label || fieldApiName;

        if (value !== null && value !== '') {
            const numericValue = Number(value);

            if (isNaN(numericValue) || numericValue <= 0) {
                this.showToast('Error',`${fieldLabel} must be greater than zero.`,'error');
            }
        }


}

    async handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        this.isDisableSave = true;
        try {
            const fields = event.detail.fields;

            //Bug-362 - Fix
            if (fields.Copy_Address__c === 'No') {
            // ===== Duration Field Validation =====
            const durationFieldNames = [
                'Duration_at_Current_Address__c',
                'Duration_at_current_city_In_Months__c',
                'Duration_at_current_address_In_Months__c',
                'Duration_at_Current_City__c'
            ];

            let invalidFields = [];


            durationFieldNames.forEach(apiName => {
                const value = fields[apiName];
                if (value !== null && value !== '' && (isNaN(Number(value)) || Number(value) <= 0)) {
                    const label = this.objectInfo?.data?.fields?.[apiName]?.label || apiName;
                    invalidFields.push(label);
                }
            });

            if (invalidFields.length > 0) {
                this.isLoading = false;
                this.isDisableSave = false;
                this.showToast('Error',`${invalidFields.join(', ')} must be greater than zero.`,'error');
                return;
            }

           }


            const mailingAddress = fields.Mailing_Address__c;
            const currentSameAsResidence = fields.Current_Address_same_as_Residence__c === 'Yes';

            console.log('Submit triggered for:', mailingAddress, 'CurrentSameAsResidence:', currentSameAsResidence);

             // Make sure mailing address selected
            if (this.isIndividual && !mailingAddress) {
                this.isLoading = false;
                this.isDisableSave = false;
                this.showToast('Error', 'Please select Mailing Address.', 'error');
                return;
            }

            // Final duplicate check before save
            await this.loadExistingAddresses();

            // UNIQUE COMMUNICATION ADDRESS CHECK 
            const commAddress = fields.Communication_Address__c;

            // Only run when user is trying to set Communication = Yes
            if (commAddress === 'Yes' || commAddress === true) {
                let otherYesCount = 0;

                if (this.existingAddresses && this.existingAddresses.length > 0) {

                    if (this.isIndividual) {
                        // INDIVIDUAL: only one YES across all addresses (current record excluded in existingAddresses)
                        otherYesCount = (this.existingAddresses || []).filter(
                            a => a.Communication_Address__c === 'Yes' || a.Communication_Address__c === true
                        ).length;

                    } else if (this.isNonIndividual) {
                        // NON‑INDIVIDUAL: one YES per Address_Type__c in given list
                        const addrType = fields.Address_Type__c;
                        const limitedTypes = [
                            'Additional Address',
                            'Alternate Business Address',
                            'Office/ Business Address',
                            'Rural',
                            'Semi-Urban',
                            'Urban',
                            'Metro'
                        ];

                        if (addrType && limitedTypes.includes(addrType)) {
                            otherYesCount = (this.existingAddresses || []).filter(
                                a =>
                                    (a.Communication_Address__c === 'Yes' || a.Communication_Address__c === true) &&
                                    a.Address_Type__c === addrType
                            ).length;
                        }
                    }
                }

                if (otherYesCount > 0) {
                    this.communicationAddressValue = 'No';  
                    fields.Communication_Address__c = 'No';  

                    this.isLoading = false;
                    this.isDisableSave = false;
                    this.showToastError(
                        'Error',
                        'Communication address already exists for this applicant. Please keep Communication Address as No.',
                        'error'
                    );
                    return;
                }
            }

            this.isDuplicateAddress = false;
            for (const address of this.existingAddresses) {
                if (
                    this.isIndividual &&
                    mailingAddress &&
                    address.Mailing_Address__c === mailingAddress &&
                    !this.addressRecordId        // only for new
                ) {
                    this.isDuplicateAddress = true;
                    break;
                }

                // Non‑Individual: duplicate Address Type
                if (
                    this.isNonIndividual &&
                    fields.Address_Type__c &&
                    address.Address_Type__c === fields.Address_Type__c &&
                    !this.addressRecordId        // only for new
                ) {
                    this.isDuplicateAddress = true;
                    break;
                }
            }

            if (this.isDuplicateAddress) {
                this.isLoading = false;
                this.isDisableSave = false;
                this.showToast('Error', 'Selected address already used. Please choose another.', 'error');
                return;
            }

            if (mailingAddress === 'Current Address' && currentSameAsResidence) {
                const existingAddrs = this.existingAddresses;
                const resiExists = existingAddrs.some(
                    addr => addr.Mailing_Address__c === 'Residential Address'
                );
                if (resiExists) {
                    this.isLoading = false;
                    this.isDisableSave = false;
                    this.showToast('Error', 'Residence address already exist', 'error');
                    return;
                }
                fields.OVD__c = false;
                console.log('OVD__c added to fields:', fields.OVD__c);
            } else {
                fields.OVD__c = true;
            }

            // New Copy Address behaviour (works for Individual & Non‑Individual)
            const copyAddress = fields.Copy_Address__c;          // Yes / No picklist
            const copyAddressFrom = this.copyAddressFromValue;   // value from combobox
            // For NEW records: if user chose to copy, they must pick a source
            if (!this.addressRecordId && copyAddress === 'Yes') {
                if (!copyAddressFrom) {
                    this.isLoading = false;
                    this.isDisableSave = false;
                    this.showToast('Error', 'Please select an address in "Copy Address From".', 'error');
                    return;
                }
            }
            // Perform actual copy only for NEW + Copy = Yes + a selected source
            if (!this.addressRecordId && copyAddress === 'Yes' && copyAddressFrom) {
                let source;

                if (this.isNonIndividual) {
                    // Non‑Individual: match by Address_Type__c
                    source = (this.existingAddresses || []).find(
                        item => item.Address_Type__c === copyAddressFrom
                    );
                } else {
                    // Individual: match by Mailing_Address__c
                    source = (this.existingAddresses || []).find(
                        item => item.Mailing_Address__c === copyAddressFrom
                    );
                }
                if (source) {
                    fields.Copy_Address_From__c = copyAddressFrom; 
                    //fields.Copy_Address_From__c = source.Copy_Address_From__c;
                    fields.Address_Line_1__c = source.Address_Line_1__c;
                    fields.Address_Line_2__c = source.Address_Line_2__c;
                    fields.Pincode__c = source.Pincode__c;
                    fields.City__c = source.City__c;
                    fields.State__c = source.State__c;
                    fields.Country__c = source.Country__c;
                    fields.Landmark__c = source.Landmark__c;
                    // NEW: copy duration fields as well
    fields.Duration_at_Current_City__c = source.Duration_at_Current_City__c;
    fields.Duration_at_current_city_In_Months__c = source.Duration_at_current_city_In_Months__c;
    fields.Duration_at_Current_Address__c = source.Duration_at_Current_Address__c;
    fields.Duration_at_current_address_In_Months__c = source.Duration_at_current_address_In_Months__c;
     fields.Address_Category__c	 = source.Address_Category__c;
      //  FOR NON‑INDIVIDUAL FIELDS
        fields.Flat_Plot_Number__c   = source.Flat_Plot_Number__c;
        fields.Is_Address_Verified__c = source.Is_Address_Verified__c;
        fields.Taluka__c             = source.Taluka__c;
        fields.Village__c            = source.Village__c;
                    console.log('Copied address from ', copyAddressFrom);
                } else {
                    this.isLoading = false;
                    this.isDisableSave = false;
                    this.showToast('Error', 'Selected address to copy from not found.', 'error');
                    return;
                }
            }

            if (this.addressRecordId) {
                const odvField = this.template.querySelector('lightning-input-field[field-name="OVD__c"]');
                if (odvField && odvField.value === true) {
                    fields.OVD__c = true;
                    console.log('OVD__c preserved as true (existing record).');
                }
            }

            if (fields.OVD__c === undefined) {
                fields.OVD__c = false;
                console.log('OVD__c defaulted to false.');
            }

            // >>> NEW: clear fields based on applicant type <<<
            if (this.isIndividual) {
                // For Individual, hide and clear these so they are not saved
                fields.Is_Address_Verified__c = undefined;
               // fields.Is_Primary_Address__c = undefined;
                //fields.Present_Residential_Type__c = undefined;
            }

            if (this.isNonIndividual) {
                // For Non‑Individual, hide and clear these so they are not saved
                //fields.Flat_Plot_Number__c = undefined;
                //fields.Taluka__c = undefined;
                //fields.Village__c = undefined;
            }
            // <<< END NEW >>>

            console.log('Submitting fields ->', JSON.stringify(fields));

            this.template.querySelector('lightning-record-edit-form').submit(fields);

        } catch (error) {
            console.error('handleSubmit error =>', error);
            this.showToast('Error', 'Unexpected error during save.', 'error');
            this.isLoading = false;
            this.isDisableSave = false;
        }
    }


    handleError(event) {
        console.error('Error saving address =>', event.detail);
        this.isLoading = false;
        this.isDisableSave = false;

        let errorMsg = 'Unexpected error occurred during save.';
        if (event.detail && event.detail.detail) {
            errorMsg = event.detail.detail;
        }

        this.showToast('Error', errorMsg, 'error');
    }

    handleChange(event) {
        // if (event.target.name == 'pincode') {
        //     this.selectedPincodeId = event.target.value;
        //     this.getPinCodeDetails(this.selectedPincodeId);
        // }
        const fieldApiName = event.target.fieldName;
    if (fieldApiName === 'Pincode__c') {
        this.selectedPincodeId = event.target.value;
        this.getPinCodeDetails(this.selectedPincodeId);
    }
    }

    async getPinCodeDetails(selectedPincodeId) {
        const pincodeData = await getPinCodeDetails({
            selectedPincodeId: selectedPincodeId
        });

        if (pincodeData && pincodeData.Id) {
            this.addressObj.City = pincodeData.City_Master__r?.Name || '';
            this.addressObj.State = pincodeData.State__c || '';
            this.addressObj.Country = pincodeData.City_Master__r?.Country__c || '';
        } else {
            this.addressObj.City = '';
            this.addressObj.State = '';
            this.addressObj.Country = '';
        }
    }


    async handleGetLocation() {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Geolocation not supported'));
                return;
            }

            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.locationSet = true;

                    this.updateRecordLocation()
                        .then(() => resolve())
                        .catch((error) => reject(error));
                },
                (error) => {
                    let message = '';
                    switch (error.code) {
                        case error.PERMISSION_DENIED:
                            message = 'Location access denied or off.';
                            break;
                        case error.POSITION_UNAVAILABLE:
                            message = 'Unable to retrieve location.';
                            break;
                        case error.TIMEOUT:
                            message = 'Fetching location timed out.';
                            break;
                        default:
                            message = error.message;
                    }
                    reject(new Error(message));
                },
                {
                    enableHighAccuracy: true,
                    timeout: 10000,
                    maximumAge: 0
                }
            );
        });
    }

    updateRecordLocation() {
        console.log('Updating record ID:', this.createdRecorId);
        console.log('longitude>>', this.longitude);
        console.log('latitude>>', this.latitude);
        return updateAddressLocation({
            recordId: this.createdRecorId,
            latitude: this.latitude,
            longitude: this.longitude
        });
    }

    getCurrentLocation() {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Geolocation is not supported by your browser.'));
                return;
            }

            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.timestamp = new Date().toISOString();
                    console.log('## lattitute =',this.latitude, ' and ',this.longitude);
                    resolve();
                },
                (error) => {
                    let message = '';
                    switch (error.code) {
                        case error.PERMISSION_DENIED:
                            message = 'Location permission denied.';
                            break;
                        case error.POSITION_UNAVAILABLE:
                            message = 'Location unavailable.';
                            break;
                        case error.TIMEOUT:
                            message = 'Location request timed out.';
                            break;
                        default:
                            message = error.message;
                    }
                    reject(new Error(message));
                },
                {
                    enableHighAccuracy: false,
                    timeout: 60000,
                    maximumAge: 60000
                }
            );
        });
    }

    async fetchMetadata() {
        console.log('inside fetchmetadata');
        getMsgConfigRecord({ source: this.source })
            .then(result => {
                this.messagesMap = result;
                console.log('Mappings:', this.messagesMap);
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching mappings:', error);
            });
    }

    showToast(title, msg, variant) {
        let event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}