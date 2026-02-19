import { LightningElement, api, track, wire } from 'lwc';
import savePersonalDetails from '@salesforce/apex/SHF_CreaditPDController.savePersonalDetails';
import getPersonalDetails from '@salesforce/apex/SHF_CreaditPDController.getPersonalDetails';
import saveDetails from '@salesforce/apex/SHF_CreaditPDController.saveDetails';
import getLoanApplicantCreditPd from '@salesforce/apex/SHF_CreaditPDController.getLoanApplicantCreditPd';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class Shf_FinancialExpenseCalculator extends LightningElement {
    @api recordId;
    @track isDisabled = false;
    @track isDisabledSave = false;
    @track payload;
    @track pdRecordId;
    @track isFormalSalaried = false;
    @track isCashSalaried = false;
    @track isSenp = false;
    @track totalExpenseValue;
    @track isCreditPDCreated = true;
    @track isFiancialExpenseCalculator = true;
    @track getdata ={}
    @track pdRec = {
        Id: null,
        food_expense__c: 0,
        clothing_expense__c: 0,
        rent__c: 0,
        water_electricity__c: 0,
        telephone__c: 0,
        transport__c: 0,
        education__c: 0,
        medical_expenditure__c: 0,
        entertainment__c: 0,
        insurance__c: 0,
        chits_pigmy__c: 0,
        total__c: 0,
        Loan_Applicant__c: null,
        totalExpense: 0,
        expensesConsidered: 0
    };
    expenseFields = [
        'food_expense__c',
        'clothing_expense__c',
        'rent__c',
        'water_electricity__c',
        'telephone__c',
        'transport__c',
        'education__c',
        'medical_expenditure__c',
        'entertainment__c',
        'insurance__c',
        'chits_pigmy__c',
        'other__c'
    ];
    resetTemplateFlags() {
  this.isFormalSalaried = false;
  this.isCashSalaried = false;
  this.isSenp = false;
  this.isDisabled = false;
  this.isDisabledSave = false;
  this.isCreditPDCreated = true;
}

    @wire(getLoanApplicantCreditPd, { loanApplicantId: '$recordId' })
    wiredLoanApplicants({ data, error }) {
        if (data) {
            console.log('loanApplicantMap expense', data);            
            console.log('loanApplicantMap', data[0].Expense__c);
            const expenseVal = data[0].Expense__c;
            this.totalExpenseValue = expenseVal != null ? Number(expenseVal).toFixed(2) : null;
            this.pdRec.totalExpense = expenseVal != null ? Number(expenseVal).toFixed(2) : null;
            console.log('this.pdRec.totalExpense:', this.pdRec.totalExpense);
            console.log('this.totalExpenseValue:', this.totalExpenseValue);
        } else if (error) {
            console.error('Error fetching loan applicants:', error);
        }
    }

    @wire(getPersonalDetails, { loanApplicantId: '$recordId' })
    wiredRecord({ data, error }) {
        this.resetTemplateFlags();

        // if (error || !data) {
        //     console.log('error expense', error);
        //     this.isCreditPDCreated = false;
        //     return;
        // }
        if (error) {
            console.log('error expense', error);
            this.isCreditPDCreated = false;
            return;
        }
        if (data) {
            this.getdata = data;
            const profile = data.customerProfile;
            console.log('data', data);
            //this.isDisabled = true;
            if (profile === 'Formal Salaried'  && data?.sfId ) {
                this.isFormalSalaried = true;
                 this.isCashSalaried = false;
                this.isSenp = false;
                this.isDisabled = true;
                this.isDisabledSave = true;
                console.log('data', profile);
            }
            else if(profile === 'Formal Salaried'){
                this.isFormalSalaried = true;
                 this.isCashSalaried = false;
                this.isSenp = false;
                this.isDisabled = false;
                this.isDisabledSave = false;
            }
            else if( (profile == 'Informal Salaried- Bank Credit'|| profile == 'Informal Salaried- Cash') && data?.sfId){
                this.isFormalSalaried = false;
                this.isDisabled = true;
                this.isDisabledSave = true;
                this.isCashSalaried = true
                 console.log('data', profile);
            } 
            else if((profile === 'Self Employed- Informal'|| profile === 'Self Employed- Banking Surrogate' || profile === 'Self Employed- GST/ITR') && data?.sfId){
                this.isSenp = true;
                this.isFormalSalaried = false;
                this.isDisabled = true;
                this.isDisabledSave = true;
                this.isCashSalaried = false;
                 console.log('data', profile);
            }
            else {
                this.isCreditPDCreated = false;
                 console.log('data', profile);
            }

            this.pdRec = {
                food_expense__c: data.foodExpense || 0,
                clothing_expense__c: data.clothingExpense || 0,
                rent__c: data.rent || 0,
                water_electricity__c: data.waterElectricity || 0,
                telephone__c: data.telephone || 0,
                transport__c: data.transport || 0,
                education__c: data.education || 0,
                medical_expenditure__c: data.medicalExpenditure || 0,
                entertainment__c: data.entertainment || 0,
                insurance__c: data.insurance || 0,
                chits_pigmy__c: data.chitsPigmy || 0,
                total__c: data.total || 0,
                expensesConsidered: data.expense || 0,
                totalExpense: data.totalExpense || 0,
                other__c: data.other || 0
            };
        }
        if (!data) {
            this.isFormalSalaried = false;
        }
    }
    connectedCallback() {
        console.log('recordId expense: ',this.recordId);
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        const name = event.target.name;
        console.log('field  => ', field);
        console.log('value  => ', value);
        console.log('name  => ', name);

        this.pdRec = { ...this.pdRec, [field]: value };
        const updatedRec = {
            ...this.pdRec,
            [field]: value
        };
        this.pdRec = updatedRec;

        this.calculateTotal(updatedRec);
        console.log('updatedRec : ', updatedRec);
    }

    handleAllData(event) {
        const { sectionName, rows, grossDaily, grossMonthly } = event.detail;

        console.log('Section:', sectionName);
        this.payload = rows;
        // if (sectionName === 'House Hold') {
        //     const newVal = Number(grossDaily) || 0;
        //     this.pdRec.total__c =
        //         (Number(this.pdRec.total__c) || 0) + (newVal - this.previousGrossDaily);
        //     this.previousGrossDaily = newVal;
        //     this.payload = rows;
        // }
        // else if (sectionName === 'Business Expenses') {
        //     this.payloadBuseness = rows;
        // }

        console.log('Rows:', rows);
        console.log('Gross Daily:', grossDaily);
        console.log('Gross Monthly:', grossMonthly);

    }

    handlSave() {
        this.finalArray = [...this.payload];
        console.log('TEST!@# ', this.finalArray);
        saveDetails({ details: JSON.stringify(this.finalArray), recordId: this.pdRecordId })
            .then(() => {
                console.log('TESTcccc');
                //this.showToast('Success', 'Records saved successfully', 'success');
            })
            .catch(err => {
                console.error('ERROORRR123 ', err);
                this.showToast(
                    'Error',
                    err?.body?.message || 'Save failed',
                    'error'
                );
            });
    }

    calculateTotal(record) {
        let total = 0;
        this.expenseFields.forEach(f => {
            total += Number(record[f]) || 0;
        });
        const expensesConsidered =
            total > Number(this.pdRec.totalExpense || 0)
                ? total
                : Number(this.pdRec.totalExpense || 0);

        this.pdRec = {
            ...record,
            total__c: total,
            expensesConsidered
        };
    }

    async handleSave() {
        try {
            console.log('Test1 ', this.recordId);
            
            this.pdRec.Loan_Applicant__c = this.recordId;
            console.log('Test2 ', this.recordId);
            await savePersonalDetails({ pdRec: this.pdRec })
            .then(result => {
                if (result) {
                    console.log('Test3 ', result);
                    this.pdRecordId = result;
                    this.pdRec.Id = this.pdRecordId;
                   // this.isDisabledSave = true;
                    console.log('this.pdRecordId 123 ',this.pdRecordId);
                    if(this.getdata?.customerProfile !== 'Formal Salaried'){
                        this.handlSave();
                    }
                    
                }
            })
            .catch(error => {
                console.error('EEERRRR1 ', JSON.stringify(error));
                this.customers = [this.newRow('Customer')];
                this.showToast(
                    'Error',
                    'Failed to load customers: ' + this._getErrorMessage(error),
                    'error'
                );
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Household expenses saved',
                    variant: 'success'
                })
            );
        } catch (e) {
            console.error('ERRORRR=> ', JSON.stringify(e));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: e.body?.message || 'Save failed',
                    variant: 'error'
                })
            );
        }
    }
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}