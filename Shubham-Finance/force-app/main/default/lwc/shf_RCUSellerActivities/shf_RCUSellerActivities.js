import { LightningElement, api, wire } from 'lwc';
import { getRecord, getObjectInfo, getPicklistValues } from 'lightning/uiRecordApi';

import VERIFICATION_OBJECT from '@salesforce/schema/Verification__c';
import CUSTOMER_TYPE from '@salesforce/schema/Verification__c.Customer_type_Seller__c';
import CONSTITUTION from '@salesforce/schema/Verification__c.Constitution__c';

const FIELDS = [
    CUSTOMER_TYPE,
    CONSTITUTION,
    'Verification__c.Total_Percentage__c',
    'Verification__c.Seller_Name__c',
    'Verification__c.Present_Registered_Number__c',
    'Verification__c.TCT_CCT_No__c',
    'Verification__c.Lot_No__c',
    'Verification__c.Percentage_Share__c',
    'Verification__c.DOB_Incorporation_Date__c',
    'Verification__c.Identification_Number__c',
    'Verification__c.Other_Remarks__c',
    'Verification__c.Account_Number__c',
    'Verification__c.Bank_Name__c',
    'Verification__c.IFSC__c',
    'Verification__c.Full_Address__c',
    'Verification__c.Pincode__c',
    'Verification__c.State__c',
    'Verification__c.City__c'
];

export default class Shf_RCUSellerActivities extends LightningElement {
    @api recordId;

    formData = {};

    customerTypeOptions = [];
    constitutionOptions = [];

    // -------- RECORD --------
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (data) {
            this.formData = {
                customerType: data.fields.Customer_type_Seller__c.value,
                constitution: data.fields.Constitution__c.value,
                totalPercentage: data.fields.Total_Percentage__c.value,
                sellerName: data.fields.Seller_Name__c.value,
                presentRegNo: data.fields.Present_Registered_Number__c.value,
                tctNo: data.fields.TCT_CCT_No__c.value,
                lotNo: data.fields.Lot_No__c.value,
                percentageShare: data.fields.Percentage_Share__c.value,
                dob: data.fields.DOB_Incorporation_Date__c.value,
                identificationNo: data.fields.Identification_Number__c.value,
                remarks: data.fields.Other_Remarks__c.value,
                accountNumber: data.fields.Account_Number__c.value,
                bankName: data.fields.Bank_Name__c.value,
                ifsc: data.fields.IFSC__c.value,
                fullAddress: data.fields.Full_Address__c.value,
                pinCode: data.fields.Pincode__c.value,
                state: data.fields.State__c.value,
                city: data.fields.City__c.value
            };
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getObjectInfo, { objectApiName: VERIFICATION_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: CUSTOMER_TYPE
    })
    wiredCustomerType({ data, error }) {
        if (data) {
            this.customerTypeOptions = data.values;
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: CONSTITUTION
    })
    wiredConstitution({ data, error }) {
        if (data) {
            this.constitutionOptions = data.values;
        } else if (error) {
            console.error(error);
        }
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        this.formData = { ...this.formData, [field]: event.target.value };
    }
}