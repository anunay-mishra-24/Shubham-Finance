import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveSellerAddress from '@salesforce/apex/SHF_CollateralController.saveSellerAddress';
import getPincodeDetailsById from '@salesforce/apex/SHF_CollateralController.getPincodeDetailsById';
import getAddressTypeValues from '@salesforce/apex/SHF_CollateralController.getAddressTypeValues';

export default class ShfSellerAddressForm extends LightningElement {
    @api collateralId;
    @api recordId;
    @api sellerOptions = [];
    @api addressRecord;

    @track record = {
        Address_Type__c: null,
        Flat_Plot_Number__c: null,
        Address_Line_2__c: null,
        Address_Line_3__c: null,
        Landmark__c: null,
        Residence_Status__c: null,
        Residence_Type__c: null,
        Mobile_Phone__c: null,
        Pincode__c: null,
        State__c: null,
        City__c: null,
        Country__c: null,
        District__c: null,
        Taluka__c: null,
        Village__c: null,
        Duration_at_Current_Address__c:null,
        Duration_at_Current_City__c:null
    };

    @track addressTypeOptions = [];
    @track residenceStatusOptions = [];
    @track residenceTypeOptions = [];

    selectedSellerId;
    isSaving = false;
    pincodeName = '';

    connectedCallback() {
        if (this.addressRecord) {
            const r = this.addressRecord;
            this.record = {
                Address_Type__c: r.Address_Type__c || null,
                Flat_Plot_Number__c: r.Flat_Plot_Number__c || null,
                Address_Line_2__c: r.Address_Line_2__c || null,
                Address_Line_3__c: r.Address_Line_3__c || null,
                Landmark__c: r.Landmark__c || null,
                Residence_Status__c: r.Residence_Status__c || null,
                Residence_Type__c: r.Residence_Type__c || null,
                Mobile_Phone__c: r.Mobile_Phone__c || null,
                Pincode__c: r.Pincode__c || null,
                State__c: r.State__c || null,
                City__c: r.City__c || null,
                Country__c: r.Country__c || null,
                District__c: r.District__c || null,
                Taluka__c: r.Taluka__c || null,
                Village__c: r.Village__c || null,
                Duration_at_Current_Address__c: r.Duration_at_Current_Address__c || null,
                Duration_at_Current_City__c: r.Duration_at_Current_Address__c || null
            };
            this.selectedSellerId = r.Collateral_Seller_Owner__c || null;
            if (r.Pincode__c && r.Pincode__r && r.Pincode__r.Name) {
                this.pincodeName = r.Pincode__r.Name;
            }
        }
        this.loadPicklists();
    }

    loadPicklists() {
        getAddressTypeValues()
            .then(data => {
                const toOptions = list =>
                    (list || []).map(v => ({ label: v, value: v }));
                this.addressTypeOptions = toOptions(data.Address_Type__c);
                this.residenceStatusOptions = toOptions(
                    data.Residence_Status__c
                );
                this.residenceTypeOptions = toOptions(
                    data.Residence_Type__c
                );
            })
            .catch(error => {
                this.showToast('Error', this.getErrorMessage(error), 'error');
            });
    }

    get fullAddress() {
        const r = this.record || {};
        const parts = [];
        const add = v => {
            if (v) {
                parts.push(v);
            }
        };
        add(r.Flat_Plot_Number__c);
        add(r.Address_Line_2__c);
        add(r.Address_Line_3__c);
        add(r.Village__c);
        add(r.Taluka__c);
        add(r.City__c);
        add(r.State__c);
        add(r.Country__c);
        let base = parts.join(', ');
        if (this.pincodeName) {
            if (base) {
                return base + ' - ' + this.pincodeName;
            }
            return this.pincodeName;
        }
        return base;
    }

    handleSellerChange(event) {
        this.selectedSellerId = event.detail.value;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value =
            event.detail && event.detail.value !== undefined
                ? event.detail.value
                : event.target.value;
        if (!field) {
            return;
        }
        this.record = {
            ...this.record,
            [field]: value
        };
    }

    handlePincodeChange(event) {
        const pincodeId = event.detail.recordId || event.detail.value || null;
        this.record = {
            ...this.record,
            Pincode__c: pincodeId
        };
        if (!pincodeId) {
            this.pincodeName = '';
            this.record = {
                ...this.record,
                State__c: null,
                City__c: null,
                Country__c: null,
                District__c: null
            };
            return;
        }
        getPincodeDetailsById({ pincodeId })
            .then(result => {
                if (result) {
                    this.pincodeName = result.name;
                    this.record = {
                        ...this.record,
                        Pincode__c: result.pincodeId,
                        State__c: result.state,
                        City__c: result.city,
                        Country__c: result.country,
                        District__c: result.district
                    };
                } else {
                    this.pincodeName = '';
                    this.record = {
                        ...this.record,
                        State__c: null,
                        City__c: null,
                        Country__c: null,
                        District__c: null
                    };
                }
            })
            .catch(error => {
                this.pincodeName = '';
                this.showToast('Error', this.getErrorMessage(error), 'error');
            });
    }

    validateForm() {
        let isValid = true;
        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-record-picker'
        );
        inputs.forEach(input => {
            input.reportValidity();
            if (!input.checkValidity()) {
                isValid = false;
            }
        });
        if (!this.selectedSellerId) {
            this.showToast('Error', 'Seller is required', 'error');
            isValid = false;
        }
        if (!this.record.Pincode__c) {
            this.showToast('Error', 'PinCode is required', 'error');
            isValid = false;
        }
        return isValid;
    }

    handleSave() {
        if (!this.validateForm()) {
            return;
        }
        this.isSaving = true;
        const payload = {
            ...this.record,
            Id: this.recordId,
            Collateral_Seller_Owner__c: this.selectedSellerId,
            Collateral__c: this.collateralId
        };
        saveSellerAddress({
            addressJson: JSON.stringify(payload)
        })
            .then(() => {
                this.showToast('Success', 'Address saved', 'success');
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(error => {
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
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