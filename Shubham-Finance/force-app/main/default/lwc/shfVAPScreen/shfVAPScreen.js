/**
 


 * We Are Not Using This,
 * We Are Using shfVAPScreenComponnet


 */






import { LightningElement, track, api } from 'lwc';
import getPrimaryApplicantName from '@salesforce/apex/ShfVAPScreenController.getPrimaryApplicantName';
import saveVAPRecord from '@salesforce/apex/ShfVAPScreenController.saveVAPRecord';
import getPremiumAmount from '@salesforce/apex/ShfVAPScreenController.getPremiumAmount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class ShfVAPScreen extends LightningElement {
    @api recordId;
    @track vapRec = {
        VAP_Product__c: 'VAP001',
        Application__c: '',
        Applicant_Name__c: '',
        VAP_Category__c: 'Insurance',
        VAP_Type__c: 'Life Insurance',
        VAP_Treatment__c: 'Additional Funding',
        VAP_Policy_Amount__c: 0,
        VAP_Amount__c: 0,
        Differential_Amount__c: 0,
        Bought_From__c: 'Insurance Company',
        Disburse_To__c: '',
        Policy_Number__c: '',
        Insurance_Term_in_Years__c: 0,
        Insurance_Term_in_Months__c: 0,
        Start_Date__c: '',
        Maturity_Date__c: '',
        Coverage_Type__c: 'Full',
        Coverage_Amount__c: 0,
        Premium_Amount__c: 0,
        Insured__c: '',
        Date_of_Birth__c:'',
        Is_Minor__c:'',
        Nominee_address__c:'',
        Nominee_Name__c:'',
        Nominee_Relationship__c:'',
        Gender__c:'',
        Percentage_of_Entitlement__c:'',
    };

    
    // Picklist options
    yesNoOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    VAPProduct = [
        { label: 'VAP001', value: 'VAP001' }
    ];

    VAPCategory = [
        { label: 'Insurance', value: 'Insurance' }
    ];

    VAPType = [
        { label: 'Life Insurance', value: 'Life Insurance' }
    ];

    VAPTreatment = [
        { label: 'Additional Funding', value: 'Additional Funding' }
    ];

    DisburseTo = [
        { label: 'KOTAK Mahindra Life Insurance Ltd', value: 'KOTAK Mahindra Life Insurance Ltd' },
        { label: 'ICICI Prudential Life Insurance', value: 'ICICI Prudential Life Insurance' }
    ];

    InsuredOptions = [
        { label: 'Name of Applicant', value: 'Name of Applicant' },
        { label: 'Co-Applicant', value: 'Co-Applicant' },
        { label: 'Guarantor', value: 'Guarantor' }
    ];

    genderOptions = [
        {label:'Male', value:'Male'}, 
        {label:'Female', value:'Female'}
        ];
    
     
    //Handle Chnage
   handleChange(event) {
    const fieldName = event.target.name;
    let fieldValue = event.target.value;
    // Clear previous error
    event.target.setCustomValidity("");

    // Numeric validations
    if (fieldName === 'VAP_Policy_Amount__c' || fieldName === 'VAP_Amount__c' || fieldName === 'Nominee_Percentage__c') {
        fieldValue = Number(fieldValue);
        if (fieldName === 'VAP_Policy_Amount__c' && fieldValue === 0) {
            event.target.setCustomValidity("Policy Amount cannot be 0");
        } else if (fieldName === 'VAP_Amount__c' && fieldValue === 0) {
            event.target.setCustomValidity("VAP Amount cannot be 0");
        } else if (fieldName === 'Nominee_Percentage__c' && (fieldValue < 0 || fieldValue > 100)) {
            event.target.setCustomValidity("Percentage must be between 0 and 100");
        }
    }
    // Text validations
        else if (fieldName === 'Nominee_Name__c' || fieldName === 'Nominee_Relationship__c') {
            const regex = /^[A-Za-z\s]+$/;
            if (!regex.test(fieldValue)) {
                event.target.setCustomValidity("Only alphabets allowed, no numbers or special characters");
            }
        }

        // ✅ Insurance Term validations (max 2 digits)
        else if (fieldName === 'Insurance_Term_in_Years__c' || fieldName === 'Insurance_Term_in_Months__c') {
            const regex = /^\d{1,2}$/; // only 1 or 2 digits allowed
            if (!regex.test(fieldValue)) {
                event.target.setCustomValidity("Maximum 2 digits allowed (0–99)");
            }
        }

        // Date fields → keep as string
        else if (fieldName === 'Date_of_Birth__c' || fieldName === 'Start_Date__c' || fieldName === 'Maturity_Date__c') {
            // no conversion, keep YYYY-MM-DD string
        }


    

    

    // Stamp value if valid
    if (!event.target.validationMessage) {
        this.vapRec = { ...this.vapRec, [fieldName]: fieldValue };
    }

    event.target.reportValidity();
}

   

   
    // Getter to calculate Differential Amount
    get differentialAmount() {
        const vapAmount = Number(this.vapRec.VAP_Amount__c) || 0;
        const policyAmount = Number(this.vapRec.VAP_Policy_Amount__c) || 0;
        return vapAmount - policyAmount;
    }

    get startDateDisplay() {
    // If Start_Date__c has a value, return it; otherwise return empty string
    return this.vapRec.Start_Date__c ? this.vapRec.Start_Date__c : '';
    }

    get maturityDateDisplay() {
    // If Maturity_Date__c has a value, return it; otherwise return empty string
    return this.vapRec.Maturity_Date__c ? this.vapRec.Maturity_Date__c : '';
    }
    
    // Getter for displaying Date of Birth
    get dateOfBirth() {
        // If Nominee_DOB__c has a value, return it; otherwise return empty string
        return this.vapRec.Date_of_Birth__c ? this.vapRec.Date_of_Birth__c : '';
    }


    

    // Getter for Is Minor
    get isMinorHandling() {
        if (this.vapRec.Date_of_Birth__c) {
            const dob = new Date(this.vapRec.Date_of_Birth__c);
            const today = new Date();

            let age = today.getFullYear() - dob.getFullYear();
            const monthDiff = today.getMonth() - dob.getMonth();

            if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
                age--;
            }

            return age < 18 ? 'Yes' : 'No';
        }
        return '';
    }

    //Clear Button Handling
    handleClear() {
        this.vapRec = {
            sobjectType: 'VAP__c',
            Application__c: this.recordId,
            Applicant_Name__c: '',
            VAP_Product__c: 'VAP001',
            VAP_Category__c: 'Insurance',
            VAP_Type__c: 'Life Insurance',
            VAP_Treatment__c: 'Additional Funding',
            VAP_Policy_Amount__c: 0,
            VAP_Amount__c: 0,
            Differential_Amount__c: 0,
            Bought_From__c: 'Insurance Company',
            Disburse_To__c: '',
            Policy_Number__c: '',
            Insurance_Term_in_Years__c: 0,
            Insurance_Term_in_Months__c: 0,
            Start_Date__c: '',
            Maturity_Date__c: '',
            Coverage_Type__c: 'Full',
            Coverage_Amount__c: 0,
            Premium_Amount__c: 0,
            Insured__c: '',
            Date_of_Birth__c: '',
            Is_Minor__c: '',
            Nominee_address__c: '',
            Nominee_Name__c: '',
            Nominee_Relationship__c: '',
            Gender__c: ''
        };
        console.log('Form cleared:', JSON.stringify(this.vapRec));
    }



    connectedCallback() {
        // Stamp Application Id into vapRec
        this.vapRec.Application__c = this.recordId;
        console.log('Application  id:', this.recordId);
        
    }

    async handleSave() {
    try {
        // 1. Validate all inputs first
        const allInputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
        let isValid = true;
        allInputs.forEach(input => {
            input.reportValidity();
            if (!input.checkValidity()) {
                isValid = false;
            }
        });

        if (!isValid) {
            this.showErrorToast('Please fix validation errors before saving.');
            return; 
        }

        // 2. Check Primary Applicant & Insurance Verification
        const applicantCheck = await getPrimaryApplicantName({ applicationId: this.vapRec.Application__c });
        
        // Premium_Amount Fetch
        const insVerPremium = await getPremiumAmount({ applicationId: this.vapRec.Application__c });
        this.vapRec.Premium_Amount__c = insVerPremium;

        // Coverage_Amount Fetch
        const CoverageAmount = await getPremiumAmount({ applicationId: this.vapRec.Application__c });
        this.vapRec.Coverage_Amount__c = CoverageAmount;

       

        if (applicantCheck === 'No Primary Applicant found') {
            this.showErrorToast('Primary Applicant missing. You cannot create VAP record.');
            return;
        }

        if (applicantCheck === 'INSURANCE_REQUIRED') {
            this.showErrorToast('Please complete the Insurance Verification for Primary Applicant before initiating VAP.');
            return;
        }

        // 3. Stamp Applicant Name
        this.vapRec.Applicant_Name__c = applicantCheck;

        // 4. Save VAP record
        console.log('VAP Rec before save:', JSON.stringify(this.vapRec));
        const recordId = await saveVAPRecord({ vapRec: this.vapRec });
        console.log('VAP record created with Id:', recordId);

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'VAP details are saved on the loan application',
                variant: 'success'
            })
        );

    } catch (error) {
        this.showErrorToast(error.body ? error.body.message : error.message);
    }
}

    /*
    async handleSave() {
        try {
            const applicantCheck = await getPrimaryApplicantName({ applicationId: this.vapRec.Application__c });
            console.log('Applicant Check Value:', applicantCheck);

            if (applicantCheck === 'No Primary Applicant found') {
                this.showErrorToast('Primary Applicant missing. You cannot create VAP record.');
                return;
            }

            if (applicantCheck === 'INSURANCE_REQUIRED') {
                this.showErrorToast('Insurance missing. You cannot create VAP record.');
                return;
            }

            // ✅ Only update Applicant Name, don’t rebuild vapRec
            this.vapRec.Applicant_Name__c = applicantCheck;

            console.log('VAP Rec before save:', JSON.stringify(this.vapRec));

            const recordId = await saveVAPRecord({ vapRec: this.vapRec });
            console.log('VAP record created with Id:', recordId);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'VAP record created successfully.',
                    variant: 'success'
                })
            );

        } catch (error) {
            console.error('Error:', JSON.stringify(error));
            this.showErrorToast(error.body ? error.body.message : error.message);
        }
    } */



    showErrorToast(msg) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: msg,
                variant: 'error'
            })
        );
    }



}