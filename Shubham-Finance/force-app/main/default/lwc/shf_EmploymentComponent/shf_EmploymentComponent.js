import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getEmploymentRecordTypes from '@salesforce/apex/shf_EmploymentRecordTypeController.getEmploymentRecordTypes';
import { getRecord } from 'lightning/uiRecordApi';
import RECORD_TYPE_FIELD from '@salesforce/schema/Loan_Applicant__c.RecordType_Name__c';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export default class Shf_EmploymentComponent extends NavigationMixin(LightningElement) {
    @api recordId; // Applicant record

    employmentRTs = {};
    applicantRecordType;

    @wire(getRecord, { recordId: '$recordId', fields: [RECORD_TYPE_FIELD] })
    applicantData({ data }) {
        if (data) {
            this.applicantRecordType = data.fields.RecordType_Name__c.value;
            console.log('applicantRecordType : ',this.applicantRecordType);
            //this.navigateBasedOnRT();
        }
    }

    @wire(getEmploymentRecordTypes)
    wiredRT({ data }) {
        if (data) {
            this.employmentRTs = data;
            console.log('employmentRTs : ',this.employmentRTs);
        }
    }

    navigateBasedOnRT() {
        if (!this.applicantRecordType || Object.keys(this.employmentRTs).length === 0) return;

        let targetRT;

        if (this.applicantRecordType === 'Individual') {
            targetRT = this.employmentRTs['Individual'];
        } else if (this.applicantRecordType === 'Non-Individual') {
            targetRT = this.employmentRTs['Non-Individual'];
        }

        if (!targetRT) {
            console.error('ERROR: No matching RT found for: ', this.applicantRecordType);
            return;
        }

        // ⭐ Tag Loan_Applicant__c field with recordId
        const defaultValues = encodeDefaultFieldValues({
            Loan_Applicant__c: this.recordId
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Employment__c',
                actionName: 'new'
            },
            state: {
                recordTypeId: targetRT,
                defaultFieldValues: defaultValues
            }
        });
    }


    createNewEmployment(){
        this.navigateBasedOnRT();
    }
}