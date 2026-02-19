import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import ALLOWED_BT_TOPUP_INSTITUTIONS_LABEL from '@salesforce/label/c.SHF_Allowed_BT_TopUp_Institutions_Internal_Loans';
import getCollaterals from '@salesforce/apex/SHF_EligibilityController.getCollaterals'; 
import getApplicationPolicyDetails from '@salesforce/apex/SHF_EligibilityController.getApplicationPolicyDetails'; 
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import CALCULATOR_REFRESH_CHANNEL from '@salesforce/messageChannel/calculatorRefresh__c';
import getEligibilityData from '@salesforce/apex/SHF_EligibilityController.getEligibilityData';
import getApplicationData from '@salesforce/apex/SHF_EligibilityController.getApplicationData';
import getObligationsData from '@salesforce/apex/SHF_EligibilityController.getObligationsData';



const APPLICATION_FIELDS = [
    'Application__c.Applied_Loan_Amount__c',
    'Application__c.EMI__c',
    'Application__c.Rate_of_Interest__c',
    'Application__c.Tenure__c',
    'Application__c.Sanction_Amount__c',
    'Application__c.Recommended_Loan_Amount__c'
];

export default class ShfUnderwriterDecisions extends LightningElement {
    @api recordId;

    @track activeSections = ['eligibilitySummary', 'ratiosCalculations', 'finalEligibility'];
    @track applicationObj = {};

    incomeProgram = '';
    applicantList = '';
    appliedLoanAmount = 0;
    totalAppraisedIncome = 0;
    totalObligations = 0;
    btAmount = 0;
    exposureObligationSum = 0;
    emi = 0;
    obligationsEmiSum = 0;
    roi = 0;
    tenure = 0;
    sanctionedLoanAmount = 0;
    recommendedLoanAmount = 0;

    // === Hardcoded values for now ===
    marketValue = 0;
    acceptedMarketValue = 0;
    propertyCost = 0;
   @track policyFOIR = 0.00; 
    sumDeductions = 0;
    technicalAcceptedValuation = 2400000;
    policyLTV = 0.75 + '%';

    allowedInstitutions = ALLOWED_BT_TOPUP_INSTITUTIONS_LABEL.split(',').map(i => i.trim());

    // connectedCallback() {
    //     this.applicationObj.Id = this.recordId;
        
    // }
    subscription = null;
    @wire(MessageContext)
    messageContext;
     connectedCallback() {
        this.applicationObj.Id = this.recordId;
       

        this.fetchObligations();
        this.fetchApplication();

        this.fetchCollaterals();
        this.fetchPolicyDetails(); 
        this.fetchApplicants(); 
        this.subscribeToMessageChannel();
    }
     disconnectedCallback() {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    
        subscribeToMessageChannel() {
            if (!this.subscription) {
                this.subscription = subscribe(
                    this.messageContext,
                    CALCULATOR_REFRESH_CHANNEL,
                    (message) => this.handleMessage(message),
                    { scope: APPLICATION_SCOPE }
                );
            }
        }
    
        handleMessage(message) {
            if(message.recordId !== this.recordId) {
                console.warn(`ID Mismatch! Message ID: ${message.recordId}, Current ID: ${this.recordId}`);
            }
            this.refreshAllData();
        }

    refreshAllData() {
            this.fetchCollaterals();
            this.fetchPolicyDetails();
            this.fetchObligations();
            this.fetchApplication().then(() => {
                this.calculateEMI();
            });
            this.fetchApplicants();
        }

    fetchObligations() {
            return getObligationsData({ applicationId: this.recordId })
                .then(data => {
                    if (data) {
                        let totalCount = 0, btSum = 0, exposureSum = 0, emiSum = 0;
                        
                        data.forEach(rec => {
                            const isDeleted = rec.Consider_To_be_Deleted__c;
                            const amount = rec.Outstanding_Amount__c || 0;
                            const foir = rec.Considered_for_FOIR__c;
                            const inst = rec.Institution__c;
                            const emiVal = rec.EMI__c || 0;
    
                            if (isDeleted === false) {
                                totalCount++;
                                if (foir === 'BT'|| foir === 'BT and Top-up') btSum += amount;
                                if (this.allowedInstitutions.includes(inst)) exposureSum += amount;
                                if (foir === 'Yes') emiSum += emiVal;
                            }
                        });
    
                        this.totalObligations = totalCount;
                        this.btAmount = btSum;
                        this.exposureObligationSum = exposureSum;
                        this.obligationsEmiSum = emiSum;
                    }
                })
                .catch(error => console.error('Error fetching obligations:', error));
        }
     fetchApplication() {
            return getApplicationData({ applicationId: this.recordId })
                .then(data => {
                    if (data) {
                        const applied = data.Applied_Loan_Amount__c || 0;
                        const recommended = data.Recommended_Loan_Amount__c ?? applied;
                        const sanctioned = data.Sanction_Amount__c ?? recommended;
    
                        const standardRate = data.Rate_of_Interest__c || 0;
                        const revisedRate = data.Revised_Rate__c;
                        const effectiveRoi = revisedRate ? revisedRate : standardRate;
    
                        this.applicationObj = {
                            Id: this.recordId,
                            Applied_Loan_Amount__c: applied,
                            Recommended_Loan_Amount__c: recommended,
                            Sanction_Amount__c: sanctioned,
                            Rate_of_Interest__c: effectiveRoi, 
                            Tenure__c: data.Tenure__c || 0
                        };
    
                        this.appliedLoanAmount = applied;
                        this.recommendedLoanAmount = recommended;
                        this.sanctionedLoanAmount = sanctioned;
                        this.roi = effectiveRoi;
                        this.tenure = this.applicationObj.Tenure__c;
    
                        this.calculateEMI();
                    }
                })
                .catch(error => console.error('Error fetching application:', error));
        }
         fetchApplicants() {
                console.log('Fetching applicants for application ID: ', this.recordId);
                getEligibilityData({ applicationId: this.recordId })
                    .then(data => {
                        console.log('Eligibility data received: ', data);
                        if (!data) {
                        console.error('No data returned');
                        return;
                    }
        
                    if (data.errorMessage && data.errorMessage !== 'Calculation Succeeded') {
                        console.error('Apex error message:', data.errorMessage);
                        this.showToast("Error", "An error occurred during calculation: " + data.errorMessage, "error");
                        
                        this.totalAppraisedIncome = 0;
                        this.totalExpenses = 0;
                        this.sumDeductions = 0;
                    } 
                    else {
                        this.totalAppraisedIncome = parseFloat((data.totalAppraisedIncome || 0).toFixed(2));
                        this.totalExpenses = parseFloat((parseFloat(data.totalExpenses)).toFixed(2));
                        this.sumDeductions = this.totalExpenses;
                    }
                    })
                    .catch(error => {
                        console.error('Error fetching eligibility data:', error);
                        let errorMessage = 'Unknown error';
                        if (error && error.body && error.body.message) {
                            errorMessage = error.body.message;
                        }
                        console.error('Error fetching eligibility data:', errorMessage);
                        console.error('Full error object:', JSON.stringify(error));
                        this.totalAppraisedIncome = 0;
                        this.totalExpenses = 0;
                        this.sumDeductions = 0;
                    });
            }

            fetchCollaterals() {
                    getCollaterals({ applicationId: this.recordId })
                        .then(result => {
                            if (result && result.length > 0) {
                                const col = result[0];
                                this.marketValue = col.Market_Value_INR__c || 0;
            
                                this.propertyCost = col.Property_Cost__c 
                                    ? col.Property_Cost__c 
                                    : (col.Property_cost_INR__c || 0);
            
                                this.acceptedMarketValue = col.Accepted_Value_Valuation_Value_INR__c || 0;
                                this.technicalAcceptedValuation = 2400000; 
                            }
                        })
                        .catch(error => console.error('Error fetching collaterals:', error));
                }
            fetchPolicyDetails() {
                    getApplicationPolicyDetails({ applicationId: this.recordId })
                        .then(data => {
                            if (data && data.Product__r) {
                                const foirVal = data.Product__r.Policy_FOIR__c;
                                const ltvVal = data.Product__r.LTV__c;
                                this.policyFOIR = (foirVal != null) ? (foirVal / 100) : 0.55;
                                this.policyLTV = (ltvVal != null) ? (ltvVal / 100) : 0.80;
                            } else {
                                this.policyFOIR = 0.55;
                                this.policyLTV = 0.80;
                            }
                        })
                        .catch(error => {
                            console.error('Error fetching policy details:', error);
                            this.policyFOIR = 0.55;
                            this.policyLTV = 0.80;
                        });
                }
            calculateEMI() {
                const principal = parseFloat(this.sanctionedLoanAmount) || 0;
                const rateAnnual = parseFloat(this.roi) || 0;
                const months = parseFloat(this.tenure) || 0;

                if (principal <= 0 || months <= 0) {
                    this.emi = 0;
                    return;
                }

                if (rateAnnual === 0) {
                    this.emi = Math.ceil(principal / months);
                    return;
                }

                const r = (rateAnnual / 100) / 12;
                const pvif = Math.pow(1 + r, months);
                const pmt = ((principal * r) * pvif) / (pvif - 1);

                this.emi = Math.ceil(pmt);
                console.log('Calculated emi: ', this.emi);
            }
// === Derived Getters ===

     get freshAmount() { 
          return (this.recommendedLoanAmount - this.btAmount).toFixed(2); 
      }
      
      get totalExposure() { 
          return (this.exposureObligationSum + this.sanctionedLoanAmount).toFixed(2); 
      }
      
      get grossLTVMarketValue() {
          if (this.marketValue > 0 && this.sanctionedLoanAmount) {
              return Number(((this.sanctionedLoanAmount / this.marketValue) * 100).toFixed(2)) + '%';
          }
          return '0%';
      }
      get grossLTVValuationValue() {
          if (this.acceptedMarketValue > 0 && this.sanctionedLoanAmount) {
              return Number(((this.sanctionedLoanAmount / this.acceptedMarketValue) * 100).toFixed(2)) + '%';
          }
          return '0%';
      }
      get netLTVMarketValue() {
          if (this.marketValue > 0 && this.sanctionedLoanAmount) {
              return Number(((this.sanctionedLoanAmount / this.marketValue) * 100).toFixed(2)) + '%';
          }
          return '0%';
      }
      get netLTVValuationValue() {
          if (this.acceptedMarketValue > 0 && this.sanctionedLoanAmount) {
              return Number(((this.sanctionedLoanAmount / this.acceptedMarketValue) * 100).toFixed(2)) + '%';
          }
          return '0%';
      }
      get aggregateLTV() {
          const totalLoan = this.exposureObligationSum + this.sanctionedLoanAmount;
          return this.acceptedMarketValue ? Number(((totalLoan / this.acceptedMarketValue) * 100).toFixed(2))+ '%' : '0%';
      }
      
      get totalLoanAmount() {
          return (this.exposureObligationSum + this.sanctionedLoanAmount).toFixed(2);
      }
      
      get iir() {
          let netIncome = this.totalAppraisedIncome - this.totalExpenses;
          let result = (this.emi / netIncome) * 100;
  
          console.log('Appraised income: ', this.totalAppraisedIncome);
          console.log('Total epxenses :', this.totalExpenses);
          console.log('Net income: ', netIncome);
  
          return (Number.isFinite(result) && !isNaN(result)) 
              ? Number(result.toFixed(2)) + '%' 
              : '0%';
      }
      
      get iar() {
          let netIncome = this.totalAppraisedIncome - this.totalExpenses;
          let result = (this.emi / netIncome) * 100;
  
          return (Number.isFinite(result) && !isNaN(result)) 
              ? Number(result.toFixed(2)) + '%' 
              : '0%';
      }
  
      get actualFOIR() {
          const income = (this.totalAppraisedIncome || 0);
          const expense = (this.totalExpenses || 0);
          const availableIncome = income - expense;
  
          const obligations = (this.obligationsEmiSum || 0);
          const currentEMI = (this.emi || 0);
  
          const foir = ((obligations + currentEMI) / availableIncome) * 100;
          
          return (Number.isFinite(foir) && !isNaN(foir)) 
              ? foir.toFixed(2) + '%' 
              : '0%';
      }
  
      get policyFOIRPercent() {
          return ((this.policyFOIR || 0) * 100).toFixed(2) + '%';
      }
  
      get grossMonthlySalary() {
          const income = Number(this.totalAppraisedIncome) || 0;
          const expense = Number(this.totalExpenses) || 0;
          
          const val = income - expense;
          return Number.isFinite(val) ? val.toFixed(2) : '0.00';
      }
  
      get initialServiceableEMI() {
          const grossSalary = parseFloat(this.grossMonthlySalary) || 0;
          const policy = (this.policyFOIR || 0);
          return (grossSalary * policy).toFixed(2);
      }
  
      get finalServiceableEMI() {
          const initialEMI = parseFloat(this.initialServiceableEMI) || 0;
          const obligations = (this.obligationsEmiSum || 0);
          return (initialEMI - obligations).toFixed(2);
      }
  
      get eligibleFundableValueIncome() {
          const serviceableEMI = (parseFloat(this.finalServiceableEMI) || 0);
          const rateOfInterest = (this.roi || 0);
          const tenureMonths = (this.tenure || 0);
  
          if (tenureMonths === 0) return 0; 
  
          const monthlyRate = (rateOfInterest / 100) / 12; 
          
          const value = monthlyRate > 0
              ? (serviceableEMI) * (1 - Math.pow(1 + monthlyRate, -tenureMonths)) / monthlyRate
              : (serviceableEMI) * tenureMonths;
              
          // CHANGE 2: Fix decimals
          return Number.isFinite(value) ? Number(value.toFixed(2)) : 0;
      }
  
      get eligibleFundableValueLTV() {
          const techValuation = parseFloat(this.technicalAcceptedValuation) || 0;
          const propCost = parseFloat(this.propertyCost) || 0;
          const ltvPolicy = parseFloat(this.policyLTV) || 0; 
  
          const minValue = Math.min(techValuation, propCost);
          const ltvValue = minValue * ltvPolicy;
  
          return ltvValue.toFixed(2);
      }
  
      get finalEligibleFundableValue() {
          const incomeBased = parseFloat(this.eligibleFundableValueIncome) || 0;
          const ltvBased = parseFloat(this.eligibleFundableValueLTV) || 0;
  
          const finalVal = Math.min(incomeBased, ltvBased);
          return Number.isFinite(finalVal) ? finalVal.toFixed(2) : '0.00';
      }
  
      get maxEligibleLoanAmount() {
          return this.finalEligibleFundableValue;
      }

    // === Handle Input Changes ===
    

    handleSave(event){
        if (this.isValidInputs()) {
            const fields = this.applicationObj;
            fields["Id"] = this.recordId;

            const recordInput = { fields };

            updateRecord(recordInput)
                .then(() => {
                    this.showToast("Success", "Details Updated Successfully.","success");
                    return refreshApex(this.contact);
                })
                .catch((error) => {
                    this.showToast("Error", error.body.message,"error");
                });
        } else {
            this.showToast("Error", "Check your input and try again.","error");
        }
    }

    isValidInputs(){
        return [...this.template.querySelectorAll("lightning-input")]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);
    }

    showToast(subject, msg, type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: subject,
                message: msg,
                variant: type
            }),
        );
    }
}