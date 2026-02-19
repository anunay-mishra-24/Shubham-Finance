import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import TENURE_FIELD from '@salesforce/schema/Application__c.Tenure__c';
import RATE_FIELD from '@salesforce/schema/Application__c.Rate_of_Interest__c';
import AMOUNT_FIELD from '@salesforce/schema/Application__c.Applied_Loan_Amount__c';
import RECOMMEND_AMOUNT from '@salesforce/schema/Application__c.Recommended_Loan_Amount__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveRepaymentDetails from '@salesforce/apex/SHF_RepaymentController.saveRepaymentDetails';
import getPrimaryApplicantName from '@salesforce/apex/SHF_RepaymentController.getPrimaryApplicantName';
import getBankDetails from '@salesforce/apex/SHF_RepaymentController.getBankDetails';
const APPLICATION_FIELDS = [TENURE_FIELD, RATE_FIELD, AMOUNT_FIELD,RECOMMEND_AMOUNT];
import getActiveAnchorMaster from '@salesforce/apex/SHF_RepaymentController.getActiveAnchorMaster';
import getROI from '@salesforce/apex/SHF_RepaymentController.getROIFromRateMaster';



export default class ShfRepaymentDetails extends LightningElement {
    @api recordId;
    @track formData = {};
    @track errorMessage = '';
    @track applicationData = {};
    @track productType = '';
    //@track primaryApplicantName;

    @wire(getRecord, { recordId: '$recordId', fields: APPLICATION_FIELDS })
    wiredApplication({ data, error }) {
        if (data) {
            this.formData.Application_Amount__c = data.fields.Recommended_Loan_Amount__c.value;
            this.formData.Rate__c = data.fields.Rate_of_Interest__c.value;
            this.formData.Tenure__c = data.fields.Tenure__c.value;
            this.formData.Total_Installments__c = data.fields.Tenure__c.value;
            this.applyHardcodedDefaults(); //apply defaults after data load
        } else if (error) {
            console.error('Error fetching Application fields:', error);
        }
    } 

    @wire(getBankDetails, { applicationId: '$recordId' })
    wiredBankDetails({ data, error }) {
        if (data) {
            this.formData = { ...this.formData, ...data };
            this.formData.Total_Discount__c = this.formData.Product_Discount__c;
            this.bankDetailId = data.Id;
            if (!data.Id) {
                // no existing record, apply defaults
                this.applyHardcodedDefaults();
            } else {
                console.log('Existing Bank Details record found:', data.Id);
            }
        } else if (error) {
            console.error('Error fetching bank details:', error);
        }
    }

    /*@wire(getPrimaryApplicantName, { applicationId: '$recordId' })
    wiredPrimaryApplicant({ data, error }) {
        if (data) {
            this.formData.Disbursal_To__c = data;
        } else if (error) {
            console.error('Error fetching primary applicant:', error);
        }
    }*/

    connectedCallback() {
        //Get Anchor MASTER
        getActiveAnchorMaster()
            .then(data => {
                if (data) {
                    console.log('Fetched Anchor Master:', data);
                    this.formData.Anchor_Type__c = data.Anchor_Type__c;
                    this.formData.Anchor_Rate__c = data.Anchor_Rate__c;
                    this.updateSpread();
                }
            })
            .catch(error => {
                console.error('Error fetching anchor master:', error);
            });
        console.log('>>>>>>recordId',this.recordId);
        if (this.recordId) {
        // Fetch primary applicant name once on init
        /*getPrimaryApplicantName({ applicationId: this.recordId })
            .then(name => {
                console.log('>>>>primaryApplicant',name);
                if (name) {
                    this.formData.Disbursal_To__c = name;
                }
            })
            .catch(error => {
                console.error('Error fetching primary applicant:', error);
            });*/
            getPrimaryApplicantName({ applicationId: this.recordId })
            .then(result => {
                console.log('>>>>primaryApplicant',result);
                if (result?.Name) {
                    this.formData.Disbursal_To__c = result.Name;
                }
                if(result?.Application__r?.Product__r?.Product_Type__c){
                    this.productType = result.Application__r.Product__r.Product_Type__c;
                }
            })
            .catch(error => {
                console.error('Error fetching primary applicant:', error);
            });
        }
        getROI({ applicationId: this.recordId })
        .then(roi => {
            console.log('Fetched ROI:', roi);

            if (roi != null) {
                this.formData.Policy_Rate__c = roi; 
                this.updateSpread();
            }
        })
        .catch(error => {
            console.error('Error fetching ROI:', error);
        });
            
    }

    updateSpread() {
        const anchorRate = parseFloat(this.formData.Anchor_Rate__c) || 0;
        const policyRate = parseFloat(this.formData.Policy_Rate__c) || 0;
        this.formData.Spread__c = anchorRate - policyRate;
        this.formData = { ...this.formData }; // refresh UI
    }


    /** Hardcoded defaults from sheet **/
    applyHardcodedDefaults() {
        this.formData = {
            ...this.formData,
            //Disbursal_To__c: 'Customer Name (Primary Applicant)',
            Recovery_Type__c: 'Installment/Rental',
            Recovery_Sub_Type__c: 'Non Revolving',
            Repayment_Type__c: 'Principal & Interest',
            Repayment_Frequency__c: 'Monthly',
            Tenure_In__c: 'Months',
            Installment_Type__c: 'Equated Installment / Rentals',
            Installment_Based_On__c: 'Rate Based',
            Installment_Mode__c: 'Arrears',
            Advanced_Installments__c: 0,
            Interest_Charge_Method__c: 'APR',//this.formData.Interest_Charge_Method__c || 'APR',
            Interest_Rate_Type__c: this.formData.Interest_Rate_Type__c || 'Floating',
            Interest_Charge_Type__c: 'Charge Separately',
            Moratorium_Handling__c: 'Exclusive',
            Moratorium_Type__c: 'Moratorium in Days',
            //Anchor_Type__c: 'PLR',
            //Anchor_Rate__c: '18.5',
        };
    }

    // === Field Configuration ===
    fieldConfig = [
        { label: 'Application Amount', name: 'Application_Amount__c', type: 'number', required: true, disabled: true },

        { label: 'Disbursal Type', name: 'Disbursal_Type__c', type: 'picklist', required: true,
          options: [ { label:'Single', value:'Single' }, { label:'Multiple', value:'Multiple' } ] },

        { label: 'Number of Disbursals', name: 'Number_Of_Disbursals__c', type: 'text', required: true,
          conditional: { field: 'Disbursal_Type__c', value: 'Multiple' } },

        { label: 'Disbursal To', name: 'Disbursal_To__c', type: 'text', required: true, disabled: true },

        { label: 'Recovery Type', name: 'Recovery_Type__c', type: 'text', required: true, disabled: true },
        { label: 'Recovery Sub Type', name: 'Recovery_Sub_Type__c', type: 'text', required: true, disabled: true },
        { label: 'Repayment Type', name: 'Repayment_Type__c', type: 'text', required: true, disabled: true },
        { label: 'Repayment Frequency', name: 'Repayment_Frequency__c', type: 'text', required: true, disabled: true },

        { label: 'Tenure', name: 'Tenure__c', type: 'text', required: true, disabled: true },
        { label: 'Tenure In', name: 'Tenure_In__c', type: 'text', required: true, disabled: true },

        { label: 'Installment Type', name: 'Installment_Type__c', type: 'text', required: true, disabled: true },
        { label: 'Installment Based On', name: 'Installment_Based_On__c', type: 'text', required: true, disabled: true },
        { label: 'Installment Mode', name: 'Installment_Mode__c', type: 'text', required: true, disabled: true },

        { label: 'Number of Advanced Installments', name: 'Advanced_Installments__c', type: 'text', required: false, disabled: true },
        { label: 'Total Number of Installments', name: 'Total_Installments__c', type: 'text', required: true, disabled: true },

        { label: 'Anchor Type', name: 'Anchor_Type__c', type: 'lookup', required: true, disabled: true },
        { label: 'Anchor Rate', name: 'Anchor_Rate__c', type: 'number', required: false, disabled: true, formatter: 'percent-fixed' },

        { label: 'Interest Charge Method', name: 'Interest_Charge_Method__c', type: 'picklist', required: true, disabled: true,
          options: [ { label:'APR', value:'APR' }, { label:'Flat', value:'Flat' } ] },

        { label: 'Interest Rate Type', name: 'Interest_Rate_Type__c', type: 'picklist', required: true,
          options: [ { label:'Fixed', value:'Fixed' }, { label:'Floating', value:'Floating' } ] },

        { label: 'Policy Rate', name: 'Policy_Rate__c', type: 'number', required: false, disabled: true, formatter: 'percent-fixed' },
        { label: 'Rate (%)', name: 'Rate__c', type: 'number', required: true, disabled: true, formatter: 'percent-fixed' },

        { label: 'Revised Rate', name: 'Revised_Policy_Rate__c', type: 'number', required: false, formatter: 'percent-fixed', disabled: true, helpText: 'Rate (%) - ROI Deviation (in percentage)' },
        { label: 'Spread', name: 'Spread__c', type: 'number', required: false, disabled: true, formatter: 'percent-fixed' },
        { label: 'ROI Deviation (in percentage)', name: 'Product_Discount__c', type: 'number', required: false, disabled: true, formatter: 'percent-fixed', helpText: 'Same as Package Discount' },
        { label: 'Package Discount', name: 'Package_Discount__c', type: 'number', required: false, formatter: 'percent-fixed' },
        { label: 'Total Discount', name: 'Total_Discount__c', type: 'number', required: false, disabled: true, formatter: 'percent-fixed' },

        { label: 'Due Day', name: 'Due_Day__c', type: 'picklist', required: true,
          options: [ { label:'4', value:'4' }, { label:'10', value:'10' } ] },

        { label: 'Interest Start Date', name: 'Interest_Start_Date__c', type: 'date', required: true },
        { label: 'First Installment Date', name: 'First_Installment_Date__c', type: 'date', required: true, disabled: true },

        { label: 'Broken Period Adjustment', name: 'Broken_Period_Adjustment__c', type: 'picklist', required: true,
          options: [ { label:'Yes', value:'Yes' }, { label:'No', value:'No' } ] },

        { label: 'Interest Charge Type', name: 'Interest_Charge_Type__c', type: 'text', required: true, disabled: true },
        { label: 'Interest Charged', name: 'Interest_Charged__c', type: 'picklist', required: true,
          options: [ { label:'Yes', value:'Yes' }, { label:'No', value:'No' } ] },

        { label: 'Actual Date', name: 'Actual_Date__c', type: 'date', required: false, disabled: true },

        { label: 'Moratorium', name: 'Moratorium__c', type: 'picklist', required: true,
          options: [ { label:'Yes', value:'Yes' }, { label:'No', value:'No' } ] },

        { label: 'Moratorium Handling', name: 'Moratorium_Handling__c', type: 'text', required: false, disabled: true },
        { label: 'Moratorium Type', name: 'Moratorium_Type__c', type: 'text', required: false, disabled: true },
        { label: 'Moratorium Days', name: 'Moratorium_Days__c', type: 'text', required: false }
    ];

    get fieldConfigWithVisibility() {
        return this.fieldConfig.map(f => {
            let isVisible = true;
            if (f.conditional) {
                isVisible = this.formData[f.conditional.field] === f.conditional.value;
            }
            return { 
                ...f, 
                isVisible,
                value: this.formData[f.name] !== undefined && this.formData[f.name] !== null
                ? this.formData[f.name]
                : '',
                isLookup: f.type === 'lookup',
                isDate: f.type === 'date',
                isNumber: f.type === 'number',
                isText: f.type === 'text',
                isPicklist: !!f.options
            };
        });
    }

    formatDateToISO(d) {
        const yy = d.getFullYear();
        const mm = String(d.getMonth() + 1).padStart(2, '0');
        const dd = String(d.getDate()).padStart(2, '0');
        return `${yy}-${mm}-${dd}`;
    }

    
    computeFirstInstallmentDate(interestStartDateStr, dueDay) {
        if (!interestStartDateStr || !dueDay) return null;

        const interestDate = new Date(interestStartDateStr);
        if (isNaN(interestDate)) return null;

        const today = new Date();
        const interestDay = interestDate.getDate();
        const interestMonth = interestDate.getMonth();
        const interestYear = interestDate.getFullYear();
        const due = Number(dueDay);

        let targetMonth = interestMonth;
        let targetYear = interestYear;

        // Step 1: Determine base month for EMI
        if (interestDay > due) {
            // Interest date after due day → next month
            targetMonth += 1;
            if (targetMonth > 11) {
                targetMonth = 0;
                targetYear += 1;
            }
        }

        // Step 2: Compute tentative EMI date
        let emiDate = new Date(targetYear, targetMonth, due);

        // Step 3: If EMI date has already passed as of today → move to next month
        if (emiDate < today) {
            targetMonth += 1;
            if (targetMonth > 11) {
                targetMonth = 0;
                targetYear += 1;
            }
            emiDate = new Date(targetYear, targetMonth, due);
        }

        // Step 4: Return formatted date (yyyy-mm-dd)
        return this.formatDateToISO(emiDate);
    }

    updateDiscounts() {
        /*const policyRate = parseFloat(this.formData.Policy_Rate__c) || 0;
        const revisedRate = parseFloat(this.formData.Revised_Policy_Rate__c) || 0;

        const productDiscount = policyRate - revisedRate;
        this.formData.Product_Discount__c = productDiscount >= 0 ? productDiscount : 0;

        this.formData.Total_Discount__c = productDiscount >= 0 ? productDiscount : 0;*/

        this.formData.Product_Discount__c = this.formData.Package_Discount__c;
        this.formData.Revised_Policy_Rate__c = this.formData.Rate__c - this.formData.Product_Discount__c;

        this.formData.Total_Discount__c = this.formData.Product_Discount__c;

        this.formData = { ...this.formData };
    }


    handleChange(event) {
        this.formData[event.target.name] = event.target.value;
        const value = event.target.value;
        this.formData[event.target.name] = value;
        this.errorMessage = '';

        if (event.target.name === 'Package_Discount__c' /*event.target.name === 'Revised_Policy_Rate__c'*/) {
            this.updateDiscounts();
        }

        if (event.target.name === 'Interest_Start_Date__c' || event.target.name === 'Due_Day__c') {
            const interestStart = this.formData.Interest_Start_Date__c;
            const dueDay = this.formData.Due_Day__c;
            const firstInstallment = this.computeFirstInstallmentDate(interestStart, dueDay);
            if (firstInstallment) {
                this.formData.First_Installment_Date__c = firstInstallment;
            } else {
                this.formData.First_Installment_Date__c = null;
            }
        }
    }
    

    validateForm() {
        let missing = [];
        let futureDateErrors = [];

        this.fieldConfigWithVisibility.forEach(f => {
            const value = this.formData[f.name]; 
            // Required field check
            if (f.required && f.isVisible && !value) {
                missing.push(f.label);
            }

            // Future date validation (only for date fields)
            if (f.isDate && value) {
                const inputDate = new Date(value);
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                if (inputDate <= today) {
                    futureDateErrors.push(f.label);
                }
            }
        });

        let errorMessages = [];
        if (missing.length > 0) {
            errorMessages.push('Mandatory fields missing: ' + missing.join(', '));
        }
        if (futureDateErrors.length > 0) {
            errorMessages.push('Dates must be future dates: ' + futureDateErrors.join(', '));
        }

        if (errorMessages.length > 0) {
            this.errorMessage = errorMessages.join('. ');
            if(this.errorMessage){
                this.showToast('Error', this.errorMessage, 'error');
            }
            return false;
        }

        this.errorMessage = '';
        return true;
    }

    handleSave() {
        console.log('Saving repayment details:', JSON.stringify(this.formData));
        if(this.formData.Revised_Policy_Rate__c > 24){
            this.showToast('Error', 'The offered ROI cannot exceed 24%', 'error');
            return;
        }
        if(this.productType == 'Home Loan' && this.formData.Revised_Policy_Rate__c < 10.25){
            this.showToast('Error', 'The offered ROI is below the acceptable limit 10.25%.', 'error');
            return;
        }
        if(this.productType == 'Loan Against Property' && this.formData.Revised_Policy_Rate__c < 11.99){
            this.showToast('Error', 'The offered ROI is below the acceptable limit 11.99%.', 'error');
            return;
        }
        if (!this.validateForm()) {
            return;
        }
        console.log('Saving repayment details:', JSON.stringify(this.formData));
        saveRepaymentDetails({ 
            applicationId: this.recordId,
            recordId: this.bankDetailId || null, 
            repaymentData: this.formData 
        })
        .then((resultId) => {
            this.formData.Id = resultId;
            // Show toast regardless of insert or update
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Repayment details saved successfully',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error saving repayment details',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        });
    }

    showToast(subject, msg, type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: subject,
                message: msg,
                variant: type
            })
        );
    }
}