import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveIdentificationDetails from '@salesforce/apex/SHF_CollateralController.saveIdentificationDetails';

const INDIVIDUAL_TYPES = [
    'Aadhaar No.',
    'PAN',
    'Driving Licence',
    'Passport',
    'Ration Card',
    'Sarpanch Letter',
    'Voter ID',
    'Autherisation Letter',
    'UID Token No'
];

const NON_INDIVIDUAL_TYPES = [
    'CIN No',
    'PAN',
    'TIN No.',
    'TAN No.',
    'Service Tax No.'
];

export default class ShfSellerIdentificationForm extends LightningElement {
    @api collateralId;
    @api recordId;
    @api sellerOptions = [];
    @api identificationRecord;
    @api existingIdentificationData = [];
    @track record = {
        Id: null,
        Collateral_Seller_Owner__c: null,
        Identification_Type__c: null,
        Identification_No__c: null,
        Issue_Date__c: null,
        Expiry_Date__c: null,
        Country_of_Issue__c: 'India'
    };

    @track identificationTypeOptions = [];

    isSaving = false;
    get areDatesRequired() {
    const type = this.record?.Identification_Type__c;
    return type === 'Driving Licence' || type === 'Passport';
}
get sellerPicklistOptions() {
    const all = this.sellerOptions || [];
    const existing = this.existingIdentificationData || [];

    const currentId = this.record?.Id;
    const currentSellerId = this.record?.Collateral_Seller_Owner__c;

    
    const usedSellerIds = new Set(
        existing
            .filter(r => r && r.Id !== currentId)
            .map(r => r.Collateral_Seller_Owner__c)
            .filter(Boolean)
    );

    
    return all.filter(o => !usedSellerIds.has(o.value) || o.value === currentSellerId);
}

get today() {
        return new Date().toISOString().split('T')[0];
    }
    get selectedSellerType() {
    const sellerId = this.record?.Collateral_Seller_Owner__c;
    const seller = (this.sellerOptions || []).find(s => s.value === sellerId);
    return seller?.individualType; 
}


    connectedCallback() {
        if (this.identificationRecord) {
            const r = this.identificationRecord;
            this.record = {
                Id: r.Id || null,
                Collateral_Seller_Owner__c: r.Collateral_Seller_Owner__c || null,
                Identification_Type__c: r.Identification_Type__c || null,
                Identification_No__c: r.Identification_No__c || null,
                Issue_Date__c: r.Issue_Date__c || null,
                Expiry_Date__c: r.Expiry_Date__c || null,
                Country_of_Issue__c: 'India' || null
            };
        }
        this.updateIdentificationTypeOptions();
    }

    handleSellerChange(event) {
        const value = event.detail.value;
        this.record = {
            ...this.record,
            Collateral_Seller_Owner__c: value
        };
        this.updateIdentificationTypeOptions();
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.record = {
            ...this.record,
            [field]: value
        };
    }

    updateIdentificationTypeOptions() {
        const sellerId = this.record.Collateral_Seller_Owner__c;
        let sellerType = null;

        if (sellerId && this.sellerOptions && this.sellerOptions.length) {
            const seller = this.sellerOptions.find(s => s.value === sellerId);
            sellerType = seller ? seller.individualType : null;
        }

        let values = [];

        if (sellerType === 'Individual') {
            values = INDIVIDUAL_TYPES;
        } else if (
            sellerType === 'Non Individual' ||
            sellerType === 'Non-Individual'
        ) {
            values = NON_INDIVIDUAL_TYPES;
        } else {
            values = [];
        }

        this.identificationTypeOptions = values.map(v => ({
            label: v,
            value: v
        }));

        if (!values.includes(this.record.Identification_Type__c)) {
            this.record = {
                ...this.record,
                Identification_Type__c: null
            };
        }
    }
    get identificationNumberHelpText() {
    const type = this.record?.Identification_Type__c;
console.log(type);
   switch (type) {
    case 'Aadhaar No.':
        return 'Enter a valid 12-digit Aadhaar Number (e.g., 1234 5678 9012).';

    case 'PAN': {
            const st = this.selectedSellerType;
            if (st === 'Individual') return "Enter Individual PAN (4th letter must be 'P') e.g. ABCP D1234F.";
            if (st === 'Non Individual' || st === 'Non-Individual') return "Enter Non-Individual PAN (4th letter C/H/F/A/T/B/L/J/G) e.g. ABCC D1234F.";
            return 'Enter a valid PAN (e.g., ABCDE1234F).';
        }

    case 'Driving Licence':
        return 'Enter a valid Driving Licence Number (e.g., MH1420110067890).';

    case 'Passport':
        return 'Enter a valid Passport Number (e.g., A1234567).';

    case 'Ration Card':
        return 'Enter a valid Ration Card Number (e.g., RC123456789).';

    case 'Sarpanch Letter':
        return 'Enter the reference number from the Sarpanch Letter (e.g., SL/2024/015).';

    case 'Autherisation Letter':
    case 'Authorisation Letter': 
        return 'Enter the reference number of the Authorisation Letter (e.g., AUTH/2024/001).';

    case 'UID Token No':
    case 'UID Token No.':
        return 'Enter a valid UID Token Number (e.g., UIDTKN987654).';

    case 'CIN No':
        return 'Enter a valid Corporate Identification Number (CIN), e.g., U12345MH2010PTC098765.';

    case 'TIN No.':
        return 'Enter a valid Tax Identification Number (TIN), e.g., 27890123456.';

    case 'TAN No.':
        return 'Enter a valid TAN, e.g., MUMA12345B.';

    case 'Service Tax No.':
        return 'Enter a valid Service Tax Registration Number (e.g., AABCU1234DST001).';

    default:
        return 'Enter the identification number exactly as it appears on the document.';
}

}
get identificationNumberPattern() {
    const type = this.record?.Identification_Type__c;

    switch (type) {
        case 'Aadhaar No.':

            return '^([0-9]{12}|[0-9]{4}\\s[0-9]{4}\\s[0-9]{4})$';

        case 'PAN':

            const st = this.selectedSellerType;

            if (st === 'Individual') {
                return '^[A-Z]{3}P[A-Z][0-9]{4}[A-Z]$';
            }
            if (st === 'Non Individual' || st === 'Non-Individual') {
                return '^[A-Z]{3}[CHFATBLJG][A-Z][0-9]{4}[A-Z]$';
            }
           
            return '^[A-Z]{5}[0-9]{4}[A-Z]$';

        case 'Driving Licence':

            return '^[A-Z]{2}[0-9]{2}[0-9A-Z]{11}$';

        case 'Passport':

            return '^[A-Z][0-9]{7}$';

        case 'Ration Card':

            return '^[A-Z0-9]{5,20}$';

        case 'Sarpanch Letter':

            return '^[A-Z0-9\\/\\-]{3,30}$';

        case 'Voter ID':

            return '^[A-Z]{3}[0-9]{7}$';

        case 'Autherisation Letter':  
        case 'Authorisation Letter':

            return '^[A-Z0-9\\/\\-]{3,30}$';

        case 'UID Token No':
        case 'UID Token No.':

            return '^[A-Z0-9]{6,20}$';

        case 'CIN No':

            return '^[LU][0-9]{5}[A-Z]{2}[0-9]{4}[A-Z]{3}[0-9]{6}$';

        case 'TIN No.':

            return '^[0-9]{11}$';

        case 'TAN No.':

            return '^[A-Z]{4}[0-9]{5}[A-Z]$';

        case 'Service Tax No.':

            return '^[A-Z]{5}[0-9]{4}[A-Z]ST[0-9]{3}$';

        default:

            return '^[A-Z0-9\\/\\-]{3,30}$';
    }
}

get identificationNumberPatternMessage() {
    const type = this.record?.Identification_Type__c;
console.log(type);
    switch (type) {
        case 'Aadhaar No.':
            return 'Aadhaar number must be exactly 12 digits (e.g. 123456789012 or 1234 5678 9012).';

        case 'PAN':
             const st = this.selectedSellerType;

            if (st === 'Individual') {
                return "For an Individual PAN, the fourth character should be 'P' (for example: ABCPD1234F).";
            }
            if (st === 'Non Individual' || st === 'Non-Individual') {
                return "For a Non-Individual PAN, the fourth character must be one of C/H/F/A/T/B/L/J or G (e.g., ABCCD1234F).";
            }
            return 'PAN must be 10 characters in the format AAAAA9999A.';

        case 'Driving Licence':
            return 'Driving Licence number should follow  Driving Licence format, e.g. MH1420110067890 ';

        case 'Passport':
            return 'Passport number should be 1 uppercase letter followed by 7 digits (e.g. A1234567).';

        case 'Ration Card':
            return 'Ration Card number should be 5 to 20 uppercase letters or digits (e.g. RC123456789).';

        case 'Sarpanch Letter':
            return 'Enter the reference number from the Sarpanch Letter e.g. SL/2024/015.';

        case 'Voter ID':
            return 'Voter ID should be 3 uppercase letters followed by 7 digits (e.g. ABC1234567).';

        case 'Autherisation Letter': 
        case 'Authorisation Letter':
            return 'Enter the reference number of the Authorisation Letter e.g. AUTH/2024/001.';

        case 'UID Token No':
        case 'UID Token No.':
            return 'UID Token Number should be 6 to 20 uppercase letters or digits (e.g. UIDTKN987654).';

        case 'CIN No':
            return 'CIN must be a valid 21-character Corporate Identification Number (e.g. U12345MH2010PTC098765).';

        case 'TIN No.':
            return 'TIN must be an 11-digit Taxpayer Identification Number (e.g. 27890123456).';

        case 'TAN No.':
            return 'TAN must be 10 characters in the format AAAA99999A ';

        case 'Service Tax No.':
            return 'Service Tax number must be in the format AAAAA9999AST999 .';

        default:
            return 'Please enter a valid identification number exactly as it appears on the document.';
    }
}



    validateForm() {
    let isValid = true;

    const inputs = this.template.querySelectorAll(
        'lightning-input, lightning-combobox'
    );
    inputs.forEach(input => {
        input.setCustomValidity('');
        isValid =
            input.reportValidity() && input.checkValidity() && isValid;
    });

    const type = this.record.Identification_Type__c;
    const requireDates = this.areDatesRequired;

    const issueInput = this.template.querySelector(
        'lightning-input[data-field="Issue_Date__c"]'
    );
    const expiryInput = this.template.querySelector(
        'lightning-input[data-field="Expiry_Date__c"]'
    );


    if (requireDates) {
        if (issueInput) {
            if (!issueInput.value) {
                issueInput.setCustomValidity('Complete this field.');
                issueInput.reportValidity();
                isValid = false;
            } else {
                issueInput.setCustomValidity('');
                issueInput.reportValidity();
            }
        }

        if (expiryInput) {
            if (!expiryInput.value) {
                expiryInput.setCustomValidity('Complete this field.');
                expiryInput.reportValidity();
                isValid = false;
            } else {
                expiryInput.setCustomValidity('');
                expiryInput.reportValidity();
            }
        }
    } else {
        if (issueInput) {
            issueInput.setCustomValidity('');
            issueInput.reportValidity();
        }
        if (expiryInput) {
            expiryInput.setCustomValidity('');
            expiryInput.reportValidity();
        }
    }


    if (
        requireDates &&
        issueInput &&
        expiryInput &&
        issueInput.value &&
        expiryInput.value
    ) {
        const issueDate = new Date(issueInput.value);
        const expiryDate = new Date(expiryInput.value);

        if (expiryDate <= issueDate) {
            expiryInput.setCustomValidity(
                'Expiry Date must be greater than Issue Date.'
            );
            expiryInput.reportValidity();
            isValid = false;
        } else {
            expiryInput.setCustomValidity('');
            expiryInput.reportValidity();
        }
    }
   
const currentId = this.record?.Id;
const existing = (this.existingIdentificationData || []).filter(r => r && r.Id !== currentId);


const sellerId = this.record?.Collateral_Seller_Owner__c;
if (sellerId && existing.some(r => r.Collateral_Seller_Owner__c === sellerId)) {
    const sellerInput = this.template.querySelector('lightning-combobox[name="seller"]');
    if (sellerInput) {
        sellerInput.setCustomValidity('This Seller already has Identification details. Please select another Seller.');
        sellerInput.reportValidity();
    }
    isValid = false;
}


const normalize = (v) => (v || '').toString().trim().toUpperCase().replace(/\s+/g, '');
const currentNo = normalize(this.record?.Identification_No__c);

if (currentNo) {
    const isDupNo = existing.some(r => normalize(r.Identification_No__c) === currentNo);
    if (isDupNo) {
        const idInput = this.template.querySelector('lightning-input[data-field="Identification_No__c"]');
        if (idInput) {
            idInput.setCustomValidity('This Identification Number already exists for another Seller.');
            idInput.reportValidity();
        }
        isValid = false;
    }
}


    return isValid;
}


    handleSave() {
        if (!this.validateForm()) {
            return;
        }

        const payload = { ...this.record };

        this.isSaving = true;

        saveIdentificationDetails({
            identificationJson: JSON.stringify(payload)
        })
            .then(() => {
                this.showToast(
                    'Success',
                    'Identification details saved successfully',
                    'success'
                );
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