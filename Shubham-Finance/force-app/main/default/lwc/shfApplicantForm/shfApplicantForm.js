import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createAccountAndApplicant from '@salesforce/apex/SHF_ApplicantSearchController.createAccountAndApplicant';
import createLoanApplicant from '@salesforce/apex/SHF_ApplicantSearchController.createLoanApplicant';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import getMessageFromMetadata from '@salesforce/apex/SHF_CommonUtil.getMessageFromMetadata';
import getFinancialCoApplicantCount from '@salesforce/apex/SHF_ApplicantSearchController.getFinancialCoApplicantCount';



// Account Fields
import FIRSTNAME_FIELD from '@salesforce/schema/Account.FirstName';
import LASTNAME_FIELD from '@salesforce/schema/Account.LastName';
import MIDDLENAME_FIELD from '@salesforce/schema/Account.MiddleName';
import PAN_FIELD from '@salesforce/schema/Account.PAN_Number__c';
import PRIMARY_MOBILE_FIELD from '@salesforce/schema/Account.Phone';
import ALTERNATE_MOBILE_FIELD from '@salesforce/schema/Account.Alternate_Mobile_Number__c';
import DOB_FIELD from '@salesforce/schema/Account.Date_of_Birth__c';
import EMAIL_FIELD from '@salesforce/schema/Account.Email_id__c';
import EMPLOYMENT_TYPE_FIELD from '@salesforce/schema/Account.Employment_Type__c';
import ENTITY_FIELD from '@salesforce/schema/Account.Entity_Name__c';
import DOI_FIELD from '@salesforce/schema/Account.Date_of_incorporation__c';


// Loan Applicant Fields
import LOAN_APPLICANT_OBJECT from '@salesforce/schema/Loan_Applicant__c';
import GENDER_FIELD from '@salesforce/schema/Loan_Applicant__c.Gender__c';
import RELIGION_FIELD from '@salesforce/schema/Loan_Applicant__c.Religion__c';
import MARITAL_FIELD from '@salesforce/schema/Loan_Applicant__c.Marital_Status__c';
import QUALIFICATION_FIELD from '@salesforce/schema/Loan_Applicant__c.Qualification__c';
import LANGUAGE_FIELD from '@salesforce/schema/Loan_Applicant__c.Preferred_Language__c';
import SALUTATION_FIELD from '@salesforce/schema/Loan_Applicant__c.Salutation__c';
import CASTE_FIELD from '@salesforce/schema/Loan_Applicant__c.Caste_Category__c';
import DISABILITY_FIELD from '@salesforce/schema/Loan_Applicant__c.Person_With_Disabilities__c';
import IMPAIRMENT_FIELD from '@salesforce/schema/Loan_Applicant__c.Type_of_Impairment__c';
import AADHAR_FIELD from '@salesforce/schema/Loan_Applicant__c.Do_You_Want_To_Edit_The_Aadhar_Address__c';
import VERNACULAR_FIELD from '@salesforce/schema/Loan_Applicant__c.Is_Customer_Vernacular__c';
import WHATSAPP_FIELD from '@salesforce/schema/Loan_Applicant__c.Whatsapp_Number_Same_As_Mobile_Number__c';
import SCAVANGER_FIELD from '@salesforce/schema/Loan_Applicant__c.Manual_Scavanger__c';
import CUSTOMER_FIELD from '@salesforce/schema/Loan_Applicant__c.Customer_Type__c';
import OCCUPATION_FIELD from '@salesforce/schema/Loan_Applicant__c.Occupation__c';
import SUBCATEGORY_FIELD from '@salesforce/schema/Loan_Applicant__c.Subcategory__c';
import COMPANYTYPE_FIELDS from '@salesforce/schema/Loan_Applicant__c.Company_Type__c';
import REGISTRATIONTYPE_FIELDS from '@salesforce/schema/Loan_Applicant__c.Registration_Type__c';
import CONSTITUTION_FIELDS from '@salesforce/schema/Loan_Applicant__c.Constitution__c';
import IS_FINANCIAL_FIELDS from '@salesforce/schema/Loan_Applicant__c.IsFinancial_Applicant__c';
import NATIONALITY_FIELDS from '@salesforce/schema/Loan_Applicant__c.Nationality__c';





export default class ShfApplicantForm extends LightningElement {
    @api accountId;
    @api applicationId;
    @api searchParams;
    @api recordType;
    @track isLoading = false;
    @track isSubmitting = false;


    // Account Fields
    @track firstName = '';
    @track middleName = '';
    @track lastName = '';
    @track pan = '';
    @track phone = '';
    @track alternateMobile = '';
    @track email = '';
    @track dob;
    @track employmentType = '';
    @track typeValue = '';

    // Loan Applicant Fields
    @track salutation = '';
    @track gender = '';
    @track religion = '';
    @track maritalStatus = '';
    @track qualification = '';
    @track fatherName = '';
    @track motherName = '';
    @track husbandName = '';
    @track casteCategory = '';
    @track nationality = '';
    @track customerType = '';
    @track personWithDisabilities = '';
    @track typeOfImpairment = '';
    @track typeOfAadharOptions = '';
    @track percentageOfImpairment = '';
    @track udidNumber = '';
    @track manualScavanger = '';
    @track preferredLanguage = '';
    @track numberOfDependents = '';
    @track whatsappNumber = '';
    @track isCustomerVernacular = '';
    @track isWhatsAppChange = false;
    @track totalWorkingExperience = '';
    @track occupationValue = '';
    @track subcategoryValue = '';
    @track occupationOptions = [];
    @track subcategoryOptions = [];
    subcategoryMap = {};
    @track showSubcategory = false;
    @track occupationDescription = '';
    @track showOccupationDescription = false;
    @track pfDeducted = '';
    @track uanNumber = '';

    // Non-Individual fields
    @track entityName = '';
    @track dateOfIncorporation;
    @track companyType = '';
    @track registrationType = '';
    @track businessCommencementDate;
    @track noOfControllingPerson;
    @track registrationNo = '';
    @track registrationExpiryDate;
    @track groupName = '';
    @track subGroupName = '';
    @track constitution = '';
    @track isfinancial = '';

    @track genderOptions = [];
    @track religionOptions = [];
    @track maritalOptions = [];
    @track qualificationOptions = [];
    @track languageOptions = [];
    @track salutationOptions = [];
    @track casteOptions = [];
    @track disabilityOptions = [];
    @track impairmentOptions = [];
    @track aadharOptions = [];
    @track CustomerVernacularOptions = [];
    @track whatsAppOptions = [];
    @track manualScavangerOptions = [];
    @track nationalityOptions = [];
    @track customerTypeOptions = [];
    @track registrationTypeOptions = [];
    @track companyTypeOptions = [];
    @track constitutionOptions = [];
    @track isfinancialOptions = [];

    @track accountLoadedFields = {
        firstName: false,
        middleName: false,
        lastName: false,
        email: false,
        employmentType: false,
        alternateMobile: false,
        employmentType: false,
        dateOfIncorporation: false
    };
    @track typeOptions = [
        { label: 'Guarantor', value: 'Guarantor' },
        { label: 'Co-Applicant', value: 'Co-Applicant' }
    ];
    @track employmentOptions = [
        { label: 'Salaried', value: 'Salaried' },
        { label: 'Self-Employed', value: 'Self-Employed' }
    ];
    @track pfDeductedOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];


    today = new Date().toISOString().split('T')[0];
    tomorrowDate = (() => {
        let d = new Date();
        d.setDate(d.getDate() + 1);
        return d.toISOString().split('T')[0];
    })();

    yesterDayDate = (() => {
        let d = new Date();
        d.setDate(d.getDate() - 1);
        return d.toISOString().split('T')[0];
    })();

    connectedCallback() {
        if (!this.accountId && this.searchParams) {
            if (this.searchParams.phone) this.phone = this.searchParams.phone;
            if (this.searchParams.pan) this.pan = this.searchParams.pan;
            if (this.searchParams.dob) this.dob = this.searchParams.dob;
        }
        if (this.isIndividual) {
            this.customerType = 'Individual';
        } else if (this.isNonIndividual) {
            this.customerType = 'Non-Individual';
            this.employmentType = 'Self-Employed';
        }
    }

    // Wire Account details
    @wire(getRecord, {
        recordId: '$accountId',
        fields: [FIRSTNAME_FIELD, MIDDLENAME_FIELD, LASTNAME_FIELD, PAN_FIELD, PRIMARY_MOBILE_FIELD, ALTERNATE_MOBILE_FIELD, DOB_FIELD, EMAIL_FIELD, EMPLOYMENT_TYPE_FIELD, ENTITY_FIELD, DOI_FIELD]
    })
    wiredAccount({ data, error }) {
        if (data) {
            this.firstName = data.fields.FirstName.value || '';
            this.middleName = data.fields.MiddleName.value || '';
            this.lastName = data.fields.LastName.value || '';
            this.pan = data.fields.PAN_Number__c.value || '';
            this.phone = data.fields.Phone.value || '';
            this.alternateMobile = data.fields.Alternate_Mobile_Number__c.value || '';
            this.dob = data.fields.Date_of_Birth__c.value || '';
            this.email = data.fields.Email_id__c.value || '';
            this.employmentType = data.fields.Employment_Type__c?.value || '';
            this.entityName = data.fields.Entity_Name__c?.value || '';
            this.dateOfIncorporation = data.fields.Date_of_incorporation__c?.value || '';

            this.accountLoadedFields.firstName = !!this.firstName;
            this.accountLoadedFields.middleName = !!this.middleName;
            this.accountLoadedFields.lastName = !!this.lastName;
            this.accountLoadedFields.pan = !!this.pan;
            this.accountLoadedFields.phone = !!this.phone;
            this.accountLoadedFields.dob = !!this.dob;
            this.accountLoadedFields.email = !!this.email;
            this.accountLoadedFields.employmentType = !!this.employmentType;
            this.accountLoadedFields.alternateMobile = !!this.alternateMobile;
            this.accountLoadedFields.entityName = !!this.entityName;
            this.accountLoadedFields.dateOfIncorporation = !!this.dateOfIncorporation;


        } else if (error) {
            console.error('Error fetching account:', error);
        }
    }

    get isIndividual() {
        return this.recordType === 'Individual';
    }
    get isNonIndividual() {
        return this.recordType === 'Non_Individual';
    }
    get isAccountSelected() {
        return !!this.accountId;
    }
    get isFirstNameDisabled() {
        return this.accountId && this.accountLoadedFields.firstName;
    }
    get isLastNameDisabled() {
        return this.accountId && this.accountLoadedFields.lastName;
    }

    get isEntityNameDisabled() {
        return this.accountId && this.accountLoadedFields.entityName;
    }
    get isDOIDisabled() {
        return this.accountId && this.accountLoadedFields.dateOfIncorporation;
    }

    get disablePhoneField() {
        const phoneFromAccount = this.accountLoadedFields?.phone;
        const phoneFromSearch = this.searchParams?.phone;
        return (this.accountId && !!phoneFromAccount) || !!phoneFromSearch;
    }

    get disablePanField() {
        const panFromAccount = this.accountLoadedFields?.pan;
        const panFromSearch = this.searchParams?.pan;
        return (this.accountId && !!panFromAccount) || !!panFromSearch;
    }

    get disableDobField() {
        const dobFromAccount = this.accountLoadedFields?.dob;
        const dobFromSearch = this.searchParams?.dob;
        return (this.accountId && !!dobFromAccount) || !!dobFromSearch;
    }


    get showHusbandField() {
        return this.gender === 'Female' &&
            (this.maritalStatus === 'Married' || this.maritalStatus === 'Widow');
    }
    get isHusbandRequired() {
        return this.showHusbandField;
    }
    get showRelatedImpairmentField() {
        return this.personWithDisabilities === 'Yes';
    }
    get showWhatsappNumber() {
        return !this.isWhatsAppChange;
    }
    handleWhatsappCheckboxChange(event) {
    this.isWhatsAppChange = event.target.checked;

        if (this.isWhatsAppChange) {
            // Auto-copy mobile number
            this.whatsappNumber = this.phone;
        } else {
            // Clear if unchecked
            this.whatsappNumber = '';
        }
    }

    get recordTypeLabelValue() {
        if (this.isIndividual) {
            return 'Individual';
        } else if (this.isNonIndividual) {
            return 'Non-Individual';
        }
        return '';
    }

    get disableEmploymentType() {
        return this.isNonIndividual;   
    }

    get showUanField() {
        return this.pfDeducted === 'Yes';
    }


//     convertPanToUppercase(event) {
//     // event.target is the actual lightning-input element wrapper input
//     const input = event.target;
//     // current raw typed value
//     const raw = input.value || '';
//     const upper = raw.toUpperCase();

//     // only update if different (avoids extra reflows)
//     if (raw !== upper) {
//         // update the visible value immediately
//         input.value = upper;
//     }

//     // update tracked property so value={pan} stays in sync
//     this.pan = upper;
// }




    // Object info and picklist values
    @wire(getObjectInfo, { objectApiName: LOAN_APPLICANT_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: GENDER_FIELD })
    wiredGender({ data }) { if (data) this.genderOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: RELIGION_FIELD })
    wiredReligion({ data }) { if (data) this.religionOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: MARITAL_FIELD })
    wiredMarital({ data }) { if (data) this.maritalOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: QUALIFICATION_FIELD })
    wiredQualification({ data }) { if (data) this.qualificationOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LANGUAGE_FIELD })
    wiredLanguage({ data }) { if (data) this.languageOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SALUTATION_FIELD })
    wiredSalutation({ data }) { if (data) this.salutationOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CASTE_FIELD })
    wiredCaste({ data }) { if (data) this.casteOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: DISABILITY_FIELD })
    wiredDisability({ data }) { if (data) this.disabilityOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: IMPAIRMENT_FIELD })
    wiredImpairment({ data }) { if (data) this.impairmentOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: AADHAR_FIELD })
    wiredAadhar({ data }) { if (data) this.aadharOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: VERNACULAR_FIELD })
    wiredCustomerVernacular({ data }) { if (data) this.CustomerVernacularOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: WHATSAPP_FIELD })
    wiredWhatsapp({ data }) { if (data) this.whatsAppOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SCAVANGER_FIELD })
    wiredScavenger({ data }) { if (data) this.manualScavangerOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: NATIONALITY_FIELDS })
    wiredNationality({ data }) { if (data) this.nationalityOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CUSTOMER_FIELD })
    wiredCustomerType({ data }) { if (data) this.customerTypeOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: COMPANYTYPE_FIELDS })
    wiredcompanyType({ data }) { if (data) this.companyTypeOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CONSTITUTION_FIELDS })
    wiredconstitution({ data }) { if (data) this.constitutionOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: IS_FINANCIAL_FIELDS })
    wiredfinancial({ data }) { if (data) this.isfinancialOptions = data.values; }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: REGISTRATIONTYPE_FIELDS })
    wiredregistrationType({ data }) { if (data) this.registrationTypeOptions = data.values; }

    @wire(getPicklistValuesByRecordType, { objectApiName: LOAN_APPLICANT_OBJECT, recordTypeId: '$objectInfo.data.defaultRecordTypeId' })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.error = null;
            this.picklistValuesObj = data.picklistFieldValues;

            // Occupation options
            this.occupationOptions = data.picklistFieldValues[OCCUPATION_FIELD.fieldApiName].values.map(opt => ({
                label: opt.label,
                value: opt.value
            }));
            console.log('Occupation Options:', JSON.stringify(this.occupationOptions));
        } else if (error) {
            console.error('Error loading picklist values', error);
        }
    }

    handleOccupationChange(event) {
        this.occupationValue = event.detail.value;
        // Show Description field if Occupation is "Others"
        this.showOccupationDescription = this.occupationValue === 'Others';

        // Reset description if not Others
        if (!this.showOccupationDescription) {
            this.occupationDescription = '';
        }
        console.log('Selected Occupation:', this.occupationValue);
        this.showSubcategory = false;

        if (this.occupationValue && this.picklistValuesObj) {
            const subcategoryField = this.picklistValuesObj[SUBCATEGORY_FIELD.fieldApiName];
            const controllerIndex = subcategoryField.controllerValues[this.occupationValue];
            const allSubcategoryValues = subcategoryField.values;

            let dependentOptions = [];

            allSubcategoryValues.forEach(sub => {
                for (let i = 0; i < sub.validFor.length; i++) {
                    if (sub.validFor[i] === controllerIndex) {
                        dependentOptions.push({
                            label: sub.label, value: sub.value
                        });
                    }
                }
            });

            this.subcategoryOptions = dependentOptions;
            this.subcategoryValue = '';
            if (this.subcategoryOptions.length > 0) {
                this.showSubcategory = true;
            } else {
                this.showSubcategory = false;
            }
            console.log('Dependent Options:', JSON.stringify(this.subcategoryOptions));
        }
    }

    handleSubcategoryChange(event) {
        this.subcategoryValue = event.detail.value;
    }

    handleFieldChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
        if (field === 'pan') {
        this.pan = (event.target.value || '').toUpperCase();
        }
        if (field === 'pan' && this.isIndividual) {
            const panInput = event.target;
            panInput.setCustomValidity(''); // reset

            // Check if PAN is 10 characters
            if (this.pan && this.pan.length === 10) {
                const fourthChar = this.pan.charAt(3); // 0-indexed
                if (fourthChar !== 'P') {
                    panInput.setCustomValidity('4th character of PAN must be "P"');
                }
            }

            panInput.reportValidity();
        }

        if (field === 'pfDeducted') {
            this.pfDeducted = event.target.value;

            if (this.pfDeducted !== 'Yes') {
                this.uanNumber = '';
            }
        }

        if (field === 'uanNumber') {
            const input = event.target;
            input.setCustomValidity('');

            if (this.uanNumber && !/^[0-9]{12}$/.test(this.uanNumber)) {
                input.setCustomValidity('UAN must be exactly 12 digits');
            }
        }

        if (field === 'percentageOfImpairment') {
            const input = event.target;
            input.setCustomValidity(''); 

            const value = this.percentageOfImpairment?.trim();

            if (!value) {
                input.setCustomValidity('');
            }
            else if (!/^-?\d+$/.test(value)) {
                input.setCustomValidity('Only numeric values are allowed.');
            }
            else {
                const num = Number(value);

                if (num < 1) {
                    input.setCustomValidity('Percentage of Impairment must be greater than 0.');
                }
                else if (num > 100) {
                    input.setCustomValidity('Percentage of Impairment cannot exceed 100.');
                }
            }

            input.reportValidity();
        }

        if (field === 'isfinancial') {
            const input = event.target;

            // Always reset validation first
            input.setCustomValidity('');

            if (this.isfinancial === 'Yes') {
                getFinancialCoApplicantCount({ applicationId: this.applicationId })
                    .then(count => {
                        if (count >= 4) {
                            input.setCustomValidity('Cannot select as financial applicant. Maximum 4 co-applicants allowed.');
                        }
                        input.reportValidity();
                    })
                    .catch(error => {
                        this.showToast('Error', error.body?.message || error.message, 'error');
                    });
            } else {
                // If user selects 'No', just clear validation
                input.reportValidity();
            }
        }

    }

    handleDobChange(event) {
        this.dob = event.target.value;

        const dobInput = event.target;
        dobInput.setCustomValidity('');

        if (this.dob) {
            const dobDate = new Date(this.dob);
            const today = new Date();
            today.setHours(0, 0, 0, 0);

            if (dobDate >= today) {
                dobInput.setCustomValidity('Date of Birth cannot be in the future');
            } else {
                const min18 = new Date(today.getFullYear() - 18, today.getMonth(), today.getDate());
                if (dobDate > min18) {
                    dobInput.setCustomValidity('Applicant must be at least 18 years old');
                }
            }
        }
        dobInput.reportValidity();
    }


    handleEmploymentChange(event) {
        this.employmentType = event.detail.value;
    }

    handleTypeChange(event) {
        this.typeValue = event.detail.value;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    handlePrevious() {
        this.dispatchEvent(new CustomEvent('previousstep'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleSubmit() {

        if (this.isSubmitting) {
            return;
        }

        this.isSubmitting = true;

        let allValid = true;
        const inputFields = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea'
        );

        inputFields.forEach(field => {
            if (!field.disabled && !field.checkValidity()) {
                field.reportValidity();
                allValid = false;
            }
        });

        if (!allValid) {
            this.showMetadataToast('REQUIRED_FIELDS_ERROR');
            this.isSubmitting = false;
            return;
        }

        const fields = {
            FirstName: this.firstName,
            MiddleName: this.middleName,
            LastName: this.lastName,
            PAN_Number__c: this.pan,
            PF_Deducted__c: this.pfDeducted,
            UAN_Number__c: this.uanNumber,
            Primary_Mobile_Number__c: this.phone,
            Alternate_Mobile__c: this.alternateMobile,
            Email: this.email,
            Entity_Name__c: this.entityName,
            Date_of_incorporation__c: this.dateOfIncorporation,
            EmploymentType: this.employmentType,
            Type_of_Applicant__c: this.typeValue,
            DOB: this.dob || null,
            Salutation__c: this.salutation,
            Gender__c: this.gender,
            Group_Name__c: this.groupName,
            Sub_Group_Name__c: this.subGroupName,
            Religion__c: this.religion,
            Marital_Status__c: this.maritalStatus,
            Qualification__c: this.qualification,
            Father_Name__c: this.fatherName,
            Mother_Name__c: this.motherName,
            Husband_Name__c: this.husbandName,
            Caste_Category__c: this.casteCategory,
            Nationality__c: this.nationality,
            Registration_No__c: this.registrationNo,
            Registration_Expiry_Date__c: this.registrationExpiryDate,
            Person_with_Disabilities__c: this.personWithDisabilities,
            Type_of_Impairment__c: this.typeOfImpairment,
            Do_You_Want_To_Edit_The_Aadhar_Address__c: this.typeOfAadharOptions,
            Percentage_of_Impairment__c: this.percentageOfImpairment,
            UDID_Number__c: this.udidNumber,
            Commencement_Date__c: this.businessCommencementDate,
            No_Of_Controlling_Person__c: this.noOfControllingPerson,
            Manual_Scavanger__c: this.manualScavanger,
            Preferred_Language__c: this.preferredLanguage,
            No_of_dependents__c: this.numberOfDependents,
            Whatsapp_Number__c: this.whatsappNumber,
            Customer_Type__c: this.customerType,
            Is_Customer_Vernacular__c: this.isCustomerVernacular,
            Registration_Type__c: this.registrationType,
            Company_Type__c: this.companyType,
            Whatsapp_Number_Same_As_Mobile_Number__c: this.isWhatsAppChange,
            Subcategory__c: this.subcategoryValue,
            Occupation__c: this.occupationValue,
            Total_Working_Experience__c: this.totalWorkingExperience,
            Constitution__c: this.constitution,
            IsFinancial_Applicant__c: this.isfinancial,
            Description__c: this.occupationDescription,
            RecordType: this.recordType
        };

        this.isLoading = true;


        if (!this.accountId) {
            createAccountAndApplicant({ applicantData: fields, applicationId: this.applicationId })
                .then(result => {
                    this.showMetadataToast('CREATE_ACCOUNT_APPLICANT_SUCCESS');
                    this.dispatchEvent(new CustomEvent('applicantsaved', { detail: { applicantId: result } }));
                    this.dispatchEvent(new CustomEvent('closemodal'));
                    this.isLoading = false;
                    setTimeout(() => { window.location.reload(); }, 500);
                })
                .catch(error => { this.showToast('Error', error.body?.message || error.message, 'error'); });

        } else {
            createLoanApplicant({ accountId: this.accountId, applicationId: this.applicationId, applicantData: fields })
                .then(result => {
                    this.showMetadataToast('CREATE_APPLICANT_SUCCESS');
                    this.dispatchEvent(new CustomEvent('applicantsaved', { detail: { applicantId: result } }));
                    this.dispatchEvent(new CustomEvent('closemodal'));
                    this.isLoading = false;
                    setTimeout(() => { window.location.reload(); }, 1000);
                })
                .catch(error => { this.showToast('Error', error.body?.message || error.message, 'error'); })
                .finally(() => {
                    this.isSubmitting = false;
                    this.isLoading = false;
                });

        }
    }


    // Fetch message from metadata and show toast
    showMetadataToast(recordDevName) {
        getMessageFromMetadata({ recordDevName })
            .then(res => {
                const variant = res.MessageType?.toLowerCase() === 'error' ? 'error' :
                    res.MessageType?.toLowerCase() === 'success' ? 'success' : 'info';
                this.showToast(res.MessageType || variant, res.Message || 'Message not found', variant);
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }

}