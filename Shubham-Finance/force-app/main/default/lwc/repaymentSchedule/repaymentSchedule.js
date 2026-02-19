import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
//import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import FIRST_INSTALLMENT_LABEL from '@salesforce/label/c.First_Installment_Date_Dynamic';
import getProductDetails from '@salesforce/apex/SHF_Application_RepaymentSchedule.getProductDetails';
import repaymentScheduleData from '@salesforce/apex/SHF_Application_RepaymentSchedule.repaymentScheduleData';
import RECORDTYPE_FIELD from '@salesforce/schema/Application__c.RecordType.Name';
import LOAN_AMOUNT_FIELD from '@salesforce/schema/Application__c.Sanction_Amount__c';
import ROI_FIELD from '@salesforce/schema/Application__c.Rate_of_Interest__c';
import RevisedRate_FIELD from '@salesforce/schema/Application__c.Revised_Rate__c';
import Tenor_In_Month from '@salesforce/schema/Application__c.Tenure__c';

export default class RepaymentSchedule extends LightningElement {

    @api recordId;
    @track showSpinner = false;
    @track firstInstallmentLabel;
    @track repaymentScheduleList = [];
    @track isRepaymentTableVisible = false;

    @track selectedProduct = {
        tenure: null,
        roi: null,
        loanAmount: null
    };

    @track selectionLabel = '';
    @track costLabel = '';

    // // Capture Record ID from URL if required
    // @wire(CurrentPageReference)
    // captureRecordId(currentPageReference) {
    //     if (currentPageReference?.state?.recordId) {
    //         this.recordId = currentPageReference.state.recordId;
    //     } else if (currentPageReference?.attributes?.recordId) {
    //         this.recordId = currentPageReference.attributes.recordId;
    //     }
    //     console.log('Current Record Id #####', this.recordId);
    // }

    // Fetch Application Record with Required Fields
    get isGenerateDisabled() {
        const { tenure, roi, loanAmount } = this.selectedProduct;
        return tenure === null || roi === null || loanAmount === null;
    }
    connectedCallback() {
        this.firstInstallmentLabel = FIRST_INSTALLMENT_LABEL;
        if (FIRST_INSTALLMENT_LABEL?.toLowerCase() === 'yes') {
            console.log('FIRST_INSTALLMENT_LABEL  #######', FIRST_INSTALLMENT_LABEL);
        } else {
            console.log('FIRST_INSTALLMENT_LABEL  #######', FIRST_INSTALLMENT_LABEL);
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [RECORDTYPE_FIELD, LOAN_AMOUNT_FIELD, ROI_FIELD, Tenor_In_Month,RevisedRate_FIELD]
    })
    fetchApplicationRecord({ error, data }) {
        if (error) {
            console.error('ERROR: Fetching Application Record ->', error);
        } else if (data) {
            const recordTypeName = data.fields.RecordType.value.fields.Name.value;
            console.log('Application Record Type #######', recordTypeName);
            console.log('Data  #######', data.fields.Tenure__c.value);


            this.selectionLabel = 'Loan Details';
            this.costLabel = 'Loan Amount';

            // Set fetched field values
            this.selectedProduct.loanAmount = data.fields.Sanction_Amount__c.value;
            this.selectedProduct.roi =
                data.fields.Revised_Rate__c?.value > 0
                    ? data.fields.Revised_Rate__c.value
                    : data.fields.Rate_of_Interest__c?.value;
            //this.selectedProduct.roi = data.fields.Revised_Rate__c.value;
            this.selectedProduct.tenure = data.fields.Tenure__c.value;

            this.validateInputs();
            console.log('Fetched Application Data ->', JSON.stringify(this.selectedProduct));

            // Fetch Tenure from Product Master
            //this.fetchProductTenure();

        }
    }

    validateInputs() {
        const { tenure, roi, loanAmount } = this.selectedProduct;

        if (!tenure || !roi || !loanAmount) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning',
                    message: 'Please complete the repayment data entry before generating the repayment schedule.',
                    variant: 'warning'
                })
            );
            this.handleCloseAction();
            return false;
            //this.dispatchEvent(new CloseActionScreenEvent());
        }
        return true;
    }

    // Fetch Tenure from Product Master
    fetchProductTenure() {
        getProductDetails({ loanApplicationId: this.recordId })
            .then(result => {
                if (result && result.length > 0) {
                    this.selectedProduct.tenure = result[0].Loan_Tenure_in_months__c; // Pick first product
                    console.log('Fetched Tenure from Product Master: ', this.selectedProduct.tenure);
                } else {
                    console.log('No Product Master Records Found for this Application.');
                }
            })
            .catch(error => {
                //Logger.error('error ' + e.getMessage());
                console.error('ERROR: Fetching Product Details ->', error);
                let err = '';
                if(error?.body?.message){
                    err = error.body.message;
                }else{
                    err = error;
                }
                this.showToast('Error', err, 'error');
            });
    }

    // Handle Input Changes for ROI, Tenure, Loan Amount
    handleInputChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;

        if (fieldName === 'ROI') {
            this.selectedProduct.roi = fieldValue;
        } else if (fieldName === 'LoanAmount') {
            this.selectedProduct.loanAmount = fieldValue;
        } else if (fieldName === 'Tenure') {
            this.selectedProduct.tenure = fieldValue;
        }

        console.log('Updated Selected Product ->', JSON.stringify(this.selectedProduct));
    }

    // Fetch Repayment Schedule
    handleGenerateSchedule() {
        this.showSpinner = true;
        

        repaymentScheduleData({
            tenure: this.selectedProduct.tenure,
            roi: this.selectedProduct.roi,
            appliedLoanAmount: this.selectedProduct.loanAmount,
            aplicationId:this.recordId
        })
            .then(result => {
                this.isRepaymentTableVisible = true;
                const rawList = JSON.parse(result);
                this.repaymentScheduleList = rawList.map(item => {
                    return {
                        ...item,
                        formattedEmiDate: this.formatDate(item.emiDate)
                    };
                });
                console.log('Repayment Schedule List ->', JSON.stringify(this.repaymentScheduleList));
                this.showSpinner = false;
            })
            .catch(error => {
                //Logger.error('error ' + e.getMessage());
                this.isRepaymentTableVisible = false;
                console.error('ERROR: Fetching Repayment Schedule ->', error);
                let err = '';
                if(error?.body?.message){
                    err = error.body.message;
                }else{
                    err = error;
                }
                this.handleCloseAction();
                this.showToast('Error', err, 'error');
                this.showSpinner = false;
            });
    }

    formatDate(dateValue) {
        if (!dateValue) return '';

        const dateObj = new Date(dateValue);

        const day = String(dateObj.getDate()).padStart(2, '0');
        const month = String(dateObj.getMonth() + 1).padStart(2, '0');
        const year = String(dateObj.getFullYear()).slice(-2);

        return `${day}-${month}-${year}`;
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

    // Close Quick Action
    handleCloseAction() {
        this.showSpinner = true;
        this.dispatchEvent(new CloseActionScreenEvent());
        this.showSpinner = false;
    }
}