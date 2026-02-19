import { LightningElement, api } from 'lwc';
import x2jsLib from '@salesforce/resourceUrl/x2js';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';

import getProductMapping from '@salesforce/apex/SHF_CIBIL_CRIF_Bureau_Individual_API.getProductMapping';

import OBLIGATION_OBJECT from '@salesforce/schema/Obligation__c';
import APPLICATION_FIELD from '@salesforce/schema/Obligation__c.Application__c';
import LOAN_ID_FIELD from '@salesforce/schema/Obligation__c.Loan_Id__c';
import LOAN_STATUS_FIELD from '@salesforce/schema/Obligation__c.Loan_Status__c';
import EMI_FIELD from '@salesforce/schema/Obligation__c.EMI__c';
import OUTSTANDING_FIELD from '@salesforce/schema/Obligation__c.Outstanding_Amount__c';
import SANCTIONED_FIELD from '@salesforce/schema/Obligation__c.Sanctioned_Amount__c';
import TENOR_FIELD from '@salesforce/schema/Obligation__c.Tenor__c';
import SOURCE_FIELD from '@salesforce/schema/Obligation__c.Source__c';

export default class XmlToJson extends LightningElement {
    @api recordId;
    x2js;
    x2jsInitialized = false;
    productMap = {};

    connectedCallback() {
        Promise.all([
            loadScript(this, x2jsLib),
            getProductMapping().then(result => {
                this.productMap = result || {};
            })
        ])
        .then(() => {
            this.x2js = new window.X2JS();
            this.x2jsInitialized = true;
        })
        .catch(error => {
            this.showToast('Error', 'Initialization failed.', 'error');
            console.error('Initialization Error:', error);
        });
    }

    handleClick() {
        if (!this.x2jsInitialized) {
            this.showToast('Error', 'XML parser not loaded yet.', 'error');
            return;
        }

        const dummyResponse = `{
            "STATUS": "COMPLETED",
            "ACKNOWLEDGEMENT-ID": 10323168,
            "HEADER": {
                "CUST-ID": "111111",
                "APPLICATION-ID": "189040217268",
                "RESPONSE-TYPE": "RESPONSE"
            },
            "FINISHED": [
                {
                    "TRACKING-ID": 8858667,
                    "BUREAU-STRING": "<INDV-REPORT-FILE><INDV-REPORTS><INDV-REPORT><LOAN-DETAILS><ACCT-NUMBER>1234567890</ACCT-NUMBER><ACCT-TYPE>39</ACCT-TYPE><ACCOUNT-STATUS>Active</ACCOUNT-STATUS><ORIGINAL-TERM>240</ORIGINAL-TERM><INSTALLMENT-AMT>20000</INSTALLMENT-AMT><DISBURSED-AMT>1000000</DISBURSED-AMT><CURRENT-BAL>900000</CURRENT-BAL></LOAN-DETAILS></INDV-REPORT></INDV-REPORTS></INDV-REPORT-FILE>",
                    "STATUS": "SUCCESS",
                    "PRODUCT": "INDV",
                    "BUREAU": "HIGHMARK"
                },
                {
                    "TRACKING-ID": 8858668,
                    "BUREAU-STRING": "{ \\"controlData\\": {\\"success\\": true}, \\"consumerCreditData\\": [{ \\"accounts\\": [  { \\"index\\": \\"T001\\", \\"memberShortName\\": \\"NOT DISCLOSED\\", \\"accountNumber\\": \\"XXXX4321\\", \\"accountType\\": \\"05\\", \\"ownershipIndicator\\": 1, \\"dateOpened\\": \\"31122018\\", \\"lastPaymentDate\\": \\"04032019\\", \\"dateClosed\\": \\"01011900\\", \\"dateReported\\": \\"31032019\\", \\"highCreditAmount\\": 34000, \\"currentBalance\\": 33372, \\"amountOverdue\\": 0, \\"paymentHistory\\": \\"000XXX000000\\", \\"paymentStartDate\\": \\"01032019\\", \\"paymentEndDate\\": \\"01122022\\", \\"suitFiled\\": \\"00\\", \\"creditFacilityStatus\\": \\"00\\", \\"collateralValue\\": \\"000123456\\", \\"collateralType\\": \\"01\\", \\"creditLimit\\": \\"000023434\\", \\"cashLimit\\": \\"000000200\\", \\"interestRate\\": 24.13, \\"paymentTenure\\": 48, \\"emiAmount\\": 1392, \\"woAmountTotal\\": 2343, \\"woAmountPrincipal\\": 78787, \\"settlementAmount\\": 67676, \\"paymentFrequency\\": \\"03\\", \\"actualPaymentAmount\\": 1392, \\"errorDate\\": \\"12122022\\", \\"errorCode\\": \\"009\\", \\"cibilRemarksDate\\": \\"12122022\\", \\"cibilRemarksCode\\": \\"TL1008\\", \\"errorRemardsDate\\": \\"12122022\\", \\"errorRemarksCode1\\": \\"000001\\" },{ \\"index\\": \\"T001\\", \\"memberShortName\\": \\"NOT DISCLOSED\\", \\"accountNumber\\": \\"XXXX4321\\", \\"accountType\\": \\"61\\", \\"ownershipIndicator\\": 1, \\"dateOpened\\": \\"31122018\\", \\"lastPaymentDate\\": \\"04032019\\", \\"dateClosed\\": \\"01011900\\", \\"dateReported\\": \\"31032019\\", \\"highCreditAmount\\": 34000, \\"currentBalance\\": 33372, \\"amountOverdue\\": 0, \\"paymentHistory\\": \\"000XXX000000\\", \\"paymentStartDate\\": \\"01032019\\", \\"paymentEndDate\\": \\"01122022\\", \\"suitFiled\\": \\"00\\", \\"creditFacilityStatus\\": \\"00\\", \\"collateralValue\\": \\"000123456\\", \\"collateralType\\": \\"01\\", \\"creditLimit\\": \\"000023434\\", \\"cashLimit\\": \\"000000200\\", \\"interestRate\\": 24.13, \\"paymentTenure\\": 48, \\"emiAmount\\": 1392, \\"woAmountTotal\\": 2343, \\"woAmountPrincipal\\": 78787, \\"settlementAmount\\": 67676, \\"paymentFrequency\\": \\"03\\", \\"actualPaymentAmount\\": 1392, \\"errorDate\\": \\"12122022\\", \\"errorCode\\": \\"009\\", \\"cibilRemarksDate\\": \\"12122022\\", \\"cibilRemarksCode\\": \\"TL1008\\", \\"errorRemardsDate\\": \\"12122022\\", \\"errorRemarksCode1\\": \\"000001\\"} ] }] }",
                    "STATUS": "SUCCESS",
                    "PRODUCT": "CIRCV",
                    "BUREAU": "CIBIL"
                }
            ]
        }`;

        const parsedResponse = JSON.parse(dummyResponse);
        const promises = [];

        if (parsedResponse?.FINISHED?.length) {
            const highmarkRecords = [];
            const cibilRecords = [];

            for (const item of parsedResponse.FINISHED) {
                // HIGHMARK
                if (item.BUREAU === 'HIGHMARK' && item['BUREAU-STRING']) {
                    const xml = item['BUREAU-STRING'];
                    const highmarkJson = this.x2js.xml2js(xml);
                    const loan = highmarkJson?.['INDV-REPORT-FILE']?.['INDV-REPORTS']?.['INDV-REPORT']?.['LOAN-DETAILS'];
                    if (!loan) continue;

                    const product = this.productMap?.[loan['ACCT-TYPE']];
                    console.log('product',+this.product);
                    const fields = {
                        [APPLICATION_FIELD.fieldApiName]: this.recordId,
                        [LOAN_ID_FIELD.fieldApiName]: loan['ACCT-NUMBER'],
                        [LOAN_STATUS_FIELD.fieldApiName]: loan['ACCOUNT-STATUS'],
                        [EMI_FIELD.fieldApiName]: Number(loan['INSTALLMENT-AMT'] || 0),
                        [OUTSTANDING_FIELD.fieldApiName]: Number(loan['CURRENT-BAL'] || 0),
                        [SANCTIONED_FIELD.fieldApiName]: Number(loan['DISBURSED-AMT'] || 0),
                        [TENOR_FIELD.fieldApiName]: String(loan['ORIGINAL-TERM'] || ''),
                        [SOURCE_FIELD.fieldApiName]: 'CRIF'
                    };
                    if (product) fields['Product__c'] = product;
                    highmarkRecords.push(fields);

                }

                // CIBIL
                if (item.BUREAU === 'CIBIL' && item['BUREAU-STRING']) {
                    let cibilJson;
                    try {
                        cibilJson = JSON.parse(item['BUREAU-STRING']);
                    } catch (e) {
                        console.error('Invalid JSON for CIBIL:', e);
                        continue;
                    }

                    const accounts = cibilJson?.consumerCreditData?.[0]?.accounts || [];
                    const uniqueKeys = new Set();

                    for (const acc of accounts) {
                        const key = `${acc.accountType}_${acc.highCreditAmount}_${acc.dateOpened}`;
                        if (!uniqueKeys.has(key)) {
                            uniqueKeys.add(key);

                            const product = this.productMap?.[acc.accountType];
                            console.log('product',+this.product);
                            const fields = {
                                [APPLICATION_FIELD.fieldApiName]: this.recordId,
                                [LOAN_ID_FIELD.fieldApiName]: acc.accountNumber,
                                [LOAN_STATUS_FIELD.fieldApiName]: acc.suitFiled,
                                [EMI_FIELD.fieldApiName]: Number(acc.emiAmount || 0),
                                [OUTSTANDING_FIELD.fieldApiName]: Number(acc.currentBalance || 0),
                                [SANCTIONED_FIELD.fieldApiName]: Number(acc.highCreditAmount || 0),
                                [TENOR_FIELD.fieldApiName]: String(acc.paymentTenure || ''),
                                [SOURCE_FIELD.fieldApiName]: 'CIBIL'
                            };
                            if (product) fields['Product__c'] = product;

                            cibilRecords.push(fields);
                        }
                    }
                }
            }

            // Now bulk insert all collected records
            const allObligationRecords = [...highmarkRecords, ...cibilRecords];

            const createPromises = allObligationRecords.map((fields, index) => {
            return createRecord({ apiName: OBLIGATION_OBJECT.objectApiName, fields });
            });

        }

        Promise.all(promises)
            .then(() => {
                this.showToast('Success', 'Obligations created for HIGHMARK and CIBIL.', 'success');
            })
            .catch(error => {
                console.error('Create record error:', error);
                this.showToast('Error', 'Failed to create obligations.', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    @api
    runFromExternalButton() {
        this.handleClick();
    }
}