import { LightningElement, track, api } from 'lwc';
import getApplicationDetails from '@salesforce/apex/ShfVAPScreenController.getApplicationDetails';
import saveVAPRecord from '@salesforce/apex/ShfVAPScreenController.saveVAPRecord';
import getApplicantOptions from '@salesforce/apex/ShfVAPScreenController.getApplicantOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPrimaryApplicantNominees from '@salesforce/apex/ShfVAPScreenController.getPrimaryApplicantNominees';

import USER_ID from '@salesforce/user/Id';
export default class ShfVAPScreenComponent extends LightningElement {
    @api recordId;
    hasRendered = false;
    isInsuranceCompleted = false;
    isPrimaryApplicantExist = false;
    userId = USER_ID;
    @track today;
    @track applicantsOption = [];
    @track ownerId = '';
    @track showNomineeDetails = false;
    @track nominees = [];
    @track vapRec = {
        'sobjectType': 'VAP__c',
        VAP_Product__c : 'VAP001',
        VAP_Category__c : 'Insurance',
        VAP_Type__c : 'Life Insurance',
        VAP_Treatment__c : 'Additional Funding',
        VAP_Policy_Amount__c : 0,
        VAP_Amount__c : 0,
        Differential_Amount__c: 0,
        Bought_From__c: 'Insurance Company',
        Policy_Number__c: '',
        Insurance_Term_in_Years__c: 0,
        Insurance_Term_in_Months__c: 0,
        Start_Date__c: '',
        Maturity_Date__c: '',
        Coverage_Type__c: 'Full',
        Coverage_Amount__c: 0,
        Premium_Amount__c: 0,
    };

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
        { label: 'Primary Applicant', value: 'Primary Applicant' },
        { label: 'Co-Applicant', value: 'Co-Applicant' },
        { label: 'Guarantor', value: 'Guarantor' }
    ];

    genderOptions = [
        {label:'Male', value:'Male'}, 
        {label:'Female', value:'Female'},
        { label: 'Transgender', value: 'Transgender' }
    ];

    get isDisabled(){
        return this.ownerId != this.userId;
    }

    connectedCallback() {
        let d = new Date();
        this.today = `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
        console.log('TEST  ', this.recordId, this.today);
        this.getApplicantOptions();
        this.getApplicationDetails();
    }

    /*renderedCallback() {
        if (this.recordId && !this.hasRendered) {
            this.hasRendered = true;
            console.log('recordId available:', this.recordId);
            this.getApplicationDetails();
        }
    }*/

    loadNominees() {
        console.log('>>>>showNomineeDetails',this.showNomineeDetails);
        console.log('>>>>inside loading Nominee');
        getPrimaryApplicantNominees({ applicationId: this.recordId })
            .then(result => {
                if (result && result.length > 0) {
                    this.nominees = result.map(n => ({
                        ...n,
                        isMinorText: n.Is_Minor__c ? 'Yes' : 'No'
                    }));
                    this.showNomineeDetails = true;
                } else {
                    this.nominees = [];
                    this.showNomineeDetails = false;
                }
            })
            .catch(error => {
                console.error('Nominee fetch error', error);
            });
    }


    getApplicantOptions(){
        getApplicantOptions({recordId: this.recordId})
            .then(result => {
                console.log('RESSULT ', result);
                this.applicantsOption = result;
            })
            .catch(error => {
                //this.showErrorToast('Error obtaining access token', error.message);
                console.log('getApplicationDetails() ERROR ', JSON.stringify(error));
            });
    }

    handleChange(event){
        this.vapRec[event.target.name] = event.target.value;
    }

    handleSave(event){
        console.log('Save ', JSON.stringify(this.vapRec));
        if(!this.validateData()){
            return false;
        }else if(!this.isPrimaryApplicantExist){
            this.showToast('Error', 'Please add Primary Applicant before initiating VAP.', 'error');
            return false;
        }else if(!this.isInsuranceCompleted){
            this.showToast('Error', 'Please complete the Insurance Verification for Primary Applicant '+ this.vapRec.Applicant_Name__c +' before initiating VAP.', 'error');
            return false;
        }
        this.saveVAPRecord();
    }

    validateData() {
        let isFocused = false;
        let isValid = true;

        const inputs = this.template.querySelectorAll(
            `[data-field="validation"]`
        );

        inputs.forEach(element => {
            element.reportValidity();
            if (!element.checkValidity()) {
                isValid = false;
                if (!isFocused) {
                    if (typeof element.focus === 'function') {
                        element.focus();
                    }
                    isFocused = true;
                }
            }
        });
        return isValid;
    }

    saveVAPRecord(){
        console.log('TTT');
        saveVAPRecord({vapRecord: this.vapRec})
        .then(result => {
            console.log('RESULT ', result);
            this.showToast('Success', 'VAP details are saved on the loan application.', 'success');
            this.getApplicationDetails();
        })
        .catch(error => {
            console.error('ERROR', error);
        });
    }

    getApplicationDetails(){
        console.log('recordId ', this.recordId);
        getApplicationDetails({recordId: this.recordId})
            .then(result => {
                console.log('getApplicationDetails ', JSON.stringify(result));
                this.ownerId = result.OwnerId;
                this.vapRec.Insured__c = null;
                this.vapRec.Disburse_To__c = '';
                this.isInsuranceCompleted = false;
                this.vapRec.Coverage_Amount__c = 0;
                this.vapRec.Premium_Amount__c = 0 ;

                this.vapRec.Application__c = this.recordId;
                if(result && result.VAP__r && result.VAP__r.length > 0){
                    this.vapRec = result.VAP__r[0];

                    if(result && result.Loan_Applicants__r){
                        this.isPrimaryApplicantExist = true;
                    }
                    if(result && result.Loan_Applicants__r && result.Loan_Applicants__r[0].Insurance_Verification__c){
                        this.isInsuranceCompleted = true;
                    } 
                    /*if (this.isInsuranceCompleted) {
                        console.log('>>>>loading Nominee');
                        this.loadNominees();
                    } else {
                        this.nominees = [];
                        this.showNomineeDetails = false;
                    }*/
                }
                else{

                    /*if(result && result.VAP__r.length > 0){
                        this.vapRec.Id = result.VAP__r[0].Id;
                    }*/
                    if(result && result.Loan_Applicants__r && result.Loan_Applicants__r[0].Id){
                        this.vapRec.Insured__c = result.Loan_Applicants__r[0].Id;
                    }
                    if(result && result.Loan_Applicants__r && result.Loan_Applicants__r[0].Name){
                        this.vapRec.Applicant_Name__c = result.Loan_Applicants__r[0].Name;
                    }
                    if(result && result.Loan_Applicants__r){
                        this.isPrimaryApplicantExist = true;
                    }
                    if(result && result.Loan_Applicants__r && result.Loan_Applicants__r[0].Insurance_Verification__c){
                        this.isInsuranceCompleted = true;
                    }
                    if(result && result.Loan_Applicants__r && result.Loan_Applicants__r[0].Insurance_Verification__r.Insurance_Provider__c){
                        if(result.Loan_Applicants__r[0].Insurance_Verification__r.Insurance_Provider__c == 'ICICI Life Insurance'){
                            this.vapRec.Disburse_To__c = 'ICICI Prudential Life Insurance';
                        }
                        else if(result.Loan_Applicants__r[0].Insurance_Verification__r.Insurance_Provider__c == 'Kotak Life Insurance'){
                            this.vapRec.Disburse_To__c = 'KOTAK Mahindra Life Insurance Ltd';
                        }
                    }
                    if(result && result.Loan_Applicants__r && result.Loan_Applicants__r[0].Insurance_Verification__r.Sum_Insured__c){
                        this.vapRec.Coverage_Amount__c = result.Loan_Applicants__r[0].Insurance_Verification__r.Sum_Insured__c;
                    }
                    if(result && result.Loan_Applicants__r && result.Loan_Applicants__r[0].Insurance_Verification__r.Premium_Amount__c){
                        this.vapRec.Premium_Amount__c =result.Loan_Applicants__r[0].Insurance_Verification__r.Premium_Amount__c;
                    }
                }
                if(result && result.Loan_Applicants__r && result.Loan_Applicants__r[0].Insurance_Verification__c){
                    this.isInsuranceCompleted = true;
                    this.vapRec.Nominee_Name__c = result.Loan_Applicants__r[0].Insurance_Verification__r.Nominee_Name__c;
                    this.vapRec.Nominee_Relationship__c = result.Loan_Applicants__r[0].Insurance_Verification__r.Nominee_Relationship__c;
                    this.vapRec.Date_of_Birth__c = result.Loan_Applicants__r[0].Insurance_Verification__r.Nominee_Date_of_Birth__c;
                    this.vapRec.Nominee_address__c = result.Loan_Applicants__r[0].Insurance_Verification__r.Nominee_Address__c;
                    this.vapRec.Percentage_of_Entitlement__c = result.Loan_Applicants__r[0].Insurance_Verification__r.Percentage_of_Entitlement__c;
                    this.vapRec.Gender__c = result.Loan_Applicants__r[0].Insurance_Verification__r.Nominee_Gender__c;
                }
                if(result && result.Loan_Applicants__r && result.Loan_Applicants__r[0].Customer_Type__c == 'Individual'){
                    this.showNomineeDetails = true;
                }
                if(this.isInsuranceCompleted != true && result && result.Loan_Applicants__r && result.Loan_Applicants__r[0].Customer_Type__c != 'Individual'){
                    this.isInsuranceCompleted = true;
                }
                if ( this.isInsuranceCompleted && result?.Loan_Applicants__r && result.Loan_Applicants__r[0]?.Customer_Type__c === 'Individual') {
                    console.log('>>>>loading Nominee (final)');
                    this.loadNominees();
                } else {
                    this.nominees = [];
                    this.showNomineeDetails = false;
                }
            })
            .catch(error => {
                //this.showErrorToast('Error obtaining access token', error.message);
                console.log('getApplicationDetails() ERROR ', JSON.stringify(error));
            });
    }

    handleCancel(){
        this.getApplicationDetails();
        this.showToast('Success','Cancelled Successfully.','info');
    }

    showToast(subject, msg, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: subject,
                message: msg,
                variant: type
            })
        );
    }

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

    get differentialAmount() {
        const vapAmount = Number(this.vapRec.VAP_Amount__c) || 0;
        const policyAmount = Number(this.vapRec.VAP_Policy_Amount__c) || 0;
        return vapAmount - policyAmount;
    }
}