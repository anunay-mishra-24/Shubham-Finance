import { LightningElement, track,api,wire } from 'lwc';
import getLoanApplicants from '@salesforce/apex/SHF_PersonalDiscussionController.getLoanApplicants';
export default class Shf_NegotiationScreen extends LightningElement {
    @api applicationId;
    @track loanAplicantData;
    @track pdRec = {
        Sanction_Amount__c: '',
        RecordTypeId: '',
        Tenure__c: '',
        Rate_of_Interest__c: '',
        LTV__c: '',
        Industry__c: '',
        Remarks__c: '',
        processingFee: '',
        Total_Expences__c: 0,
        processingFeeINR: ''
    };
    rules = {
        PD_Visit_Remarks_Recommendation_Note__c: { min: 250, max: 10000 },
        Sanction_Amount__c: { type: 'number', minValue: 1 },
        Rate_of_Interest__c: { type: 'number', minValue: 1 },
        Tenure__c: { type: 'number', minValue: 1 },
        LTV__c: { type: 'number', minValue: 1 }
    };

    @wire(getLoanApplicants, { applicationId: '$recordId' })
    wiredLoanApplicants({ data, error }) {
        if (data) {
            console.log('loanApplicantMap', data);
            let updatedData = JSON.parse(JSON.stringify(data));

            updatedData.forEach(res => {
                res.recordLink = '/' + res.Id; // URL
                // res.Name stays as Name
            });

            this.loanAplicantData = updatedData;
            // this.loanApplicantOptions = data.map(app => {
            //     return {
            //         label: app.Name,
            //         value: app.Id
            //     };
            // });
            //console.log('loanApplicantMap', this.loanApplicantMap);
        } else if (error) {
            console.error('Error fetching loan applicants:', error);
        }
    }
    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        console.log('field  => ', field);
        console.log('value  => ', value);
        this.pdRec = { ...this.pdRec, [field]: value };

        event.target.setCustomValidity('');
        if (this.rules[field]) {
            const rule = this.rules[field];

            if (!rule.type || rule.type === 'text') {
                const len = value ? value.length : 0;

                if (len < rule.min) {
                    event.target.setCustomValidity(
                        `Minimum ${rule.min} characters required. Current: ${len}`
                    );
                } else if (len > rule.max) {
                    event.target.setCustomValidity(
                        `Maximum ${rule.max} characters allowed. Current: ${len}`
                    );
                }
            }

            if (rule.type === 'number') {
                const num = Number(value);

                if (isNaN(num) || num <= 0) {
                    event.target.setCustomValidity(
                        'Only positive numbers greater than 0 are allowed.'
                    );
                }
            }
        }

        event.target.reportValidity();
    }
}