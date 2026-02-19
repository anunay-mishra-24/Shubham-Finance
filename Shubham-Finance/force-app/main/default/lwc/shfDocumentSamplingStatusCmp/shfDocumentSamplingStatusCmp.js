import { LightningElement, api, wire, track } from 'lwc';
// Import of Objects and Fields
import DOC_ACTIVITY_OBJECT from '@salesforce/schema/Document_Activity__c';
import RCU_VERIFICATION_STATUS from '@salesforce/schema/Document_Activity__c.RCU_Verification_Status__c';
import DECISION from '@salesforce/schema/Document_Activity__c.Decision__c';
import PICKUP_CRITERIA from '@salesforce/schema/Document_Activity__c.Pick_up_Criteria__c';
import REFERRED_BY from '@salesforce/schema/Document_Activity__c.Referred_By__c';
// Import of LDS methods
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Import of Apex methods
import getSampledDocumentRecord from '@salesforce/apex/SHF_DocumentSamplingStatusController.getSampledDocumentRecord';
import saveFCUDecision from '@salesforce/apex/SHF_DocumentSamplingStatusController.saveFCUDecision';
export default class ShfDocumentSamplingStatusCmp extends LightningElement {
    @api recordId;
    @api hideOtherCoumns = false;
    @track documents;
    @track statusRCUValues;
    @track decisionValues;
    @track pickUpCriteriaValues;
    @track referredByValues;
    @track noneItem = { label: 'none', value: 'none' };

    // FLAG VARIABLES
    @track showSpinner = false;

    // to get object info as defaul record type id will be used to fetch picklist values.
    @wire(getObjectInfo, { objectApiName: DOC_ACTIVITY_OBJECT })
    documentActivityObjectInfo;

    // to fetch picklist values for RCU Verification Status
    @wire(getPicklistValues, { recordTypeId: "$documentActivityObjectInfo.data.defaultRecordTypeId", fieldApiName: RCU_VERIFICATION_STATUS })
    verificationStatusPicklistInfo({ data, error }) {
        console.log('documentActivityObjectInfo V STATUS= ', data, this.documentActivityObjectInfo);
        if (data) {
            this.statusRCUValues = [];
            this.statusRCUValues.push(this.noneItem);
            this.statusRCUValues.push(...data.values);
        }
        else {
            console.log('PICKLIST DATA ERROR ', error);
        }
    }

    // to fetch picklist values for Decision
    @wire(getPicklistValues, { recordTypeId: "$documentActivityObjectInfo.data.defaultRecordTypeId", fieldApiName: DECISION })
    decisionPicklistInfo({ data, error }) {
        console.log('documentActivityObjectInfo DECISION= ', data, this.documentActivityObjectInfo);
        if (data) {
            this.decisionValues = [];
            this.decisionValues.push(this.noneItem);
            this.decisionValues.push(...data.values);
        }
        else {
            console.log('PICKLIST DATA ERROR ', error);
        }
    }

    // to fetch picklist values for Pickup Criteria
    @wire(getPicklistValues, { recordTypeId: "$documentActivityObjectInfo.data.defaultRecordTypeId", fieldApiName: PICKUP_CRITERIA })
    pickUpCriteriaPicklistInfo({ data, error }) {
        console.log('documentActivityObjectInfo PICKUP= ', data, this.documentActivityObjectInfo);
        if (data) {
            this.pickUpCriteriaValues = [];
            this.pickUpCriteriaValues.push(this.noneItem);
            this.pickUpCriteriaValues.push(...data.values);
        }
        else {
            console.log('PICKLIST DATA ERROR ', error);
        }
    }

    // to fetch picklist values for Reffered By field
    @wire(getPicklistValues, { recordTypeId: "$documentActivityObjectInfo.data.defaultRecordTypeId", fieldApiName: REFERRED_BY })
    referredByPicklistInfo({ data, error }) {
        if (data) {
            this.referredByValues = [];
            this.referredByValues.push(this.noneItem);
            this.referredByValues.push(...data.values);
        }
        else {
            console.log('PICKLIST DATA ERROR ', error);
        }
    }

    // connected callback method to setup component data.
    connectedCallback() {
        //this.recordId = 'a0CC100000w31DDMAY';
        this.handleGetRelatedDocuments();
    }

    // method to handle form component changes
    handleFormValues(event) {
        console.log('handleFormValuesv= ', event.currentTarget.dataset.index, event.target.name, event.target.value);
        let index = event.currentTarget.dataset.index;
        let newList = JSON.parse(JSON.stringify(this.documents));
        if (event.target.name) {
            newList[index][event.target.name] = event.target.value;
        }

        if (event.target.name == 'Pick_up_Criteria__c' && event.target.value == 'Referred') {
            newList[index].disableOtherFields = false;
        } else if (event.target.name == 'Pick_up_Criteria__c' && event.target.value !== 'Referred') {
            newList[index].disableOtherFields = true;
            newList[index].Referred_By__c = '';
            newList[index].Comments__c = '';
        }
        this.documents = JSON.parse(JSON.stringify(newList));
        console.log('handleFormValuesv= ', JSON.parse(JSON.stringify(this.documents)));
    }

    handleViewDocument(event) {
        console.log('handleViewDocument= ', event.currentTarget.dataset.id);
        let docId = event.currentTarget.dataset.id;
        this.template.querySelector('c-shf-preview-document').preview(docId);
    }

    // method to handle save button click
    handleSave() {
        console.log('handleSave')
        let checkValidity = this.handleCheckValues();
        console.log('checkValidity  = ', checkValidity);
        if (!checkValidity) {
            this.showNotifications('error', 'Please complete all fields first', 'error');
            return;
        }
        this.handleSaveFCUDecisions();
    }

    // method to handle picklist values population
    populatePicklistValues() {
        let veriricationStatus = this.template.querySelectorAll('[name="RCU_Verification_Status__c"]');
        let decisionsValues = this.template.querySelectorAll('[name="Decision__c"]');
        let pickupCriteriaValues = this.template.querySelectorAll('[name="Pick_up_Criteria__c"]');
        let refferdByValues = this.template.querySelectorAll('[name="Referred_By__c"]');
        let index = 0;
        let docs = JSON.parse(JSON.stringify(this.documents))
        console.log('veriricationStatus = ', veriricationStatus);
        docs.forEach(element => {
            veriricationStatus[index].value = element.RCU_Verification_Status__c;
            decisionsValues[index].value = element.Decision__c;
            pickupCriteriaValues[index].value = element.Pick_up_Criteria__c;
            refferdByValues[index].value = element.Referred_By__c;
            if (element.Pick_up_Criteria__c == 'Referred') {
                element.disableOtherFields = false;
            } else {
                element.disableOtherFields = true;
            }
            index++;
        });
        this.documents = JSON.parse(JSON.stringify(docs));
    }

    // This Method Is Used To Show Toast Notification.
    showNotifications(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        }));
    }

    // method to check picklist values are filled or not
    handleCheckValues() {
        let allFieldsFilled = true;
        this.documents.forEach(element => {
            console.log('ELEMENT = ', JSON.parse(JSON.stringify(element)));
            if (!(element.Pick_up_Criteria__c && element.Decision__c)) {
                allFieldsFilled = false;
            }
            if (element.Pick_up_Criteria__c == 'Referred' && !(element.Referred_By__c && element.Comments__c)) {
                allFieldsFilled = false;
            }
        });
        return allFieldsFilled;
    }

    // method to fetch document data from apex call
    handleGetRelatedDocuments() {
        this.showSpinner = true;
        this.documents;
        getSampledDocumentRecord({ recordId: this.recordId }).then((result) => {
            console.log('getSampledDocumentRecord = ', result);
            this.showSpinner = false;
            if (result && result.length) {
                this.documents = JSON.parse(JSON.stringify(result));
                console.log('this.documents = ', this.documents);
                setTimeout(() => {
                    if (!this.hideOtherCoumns) {
                        this.populatePicklistValues();
                    }
                }, 1000);
            }
        }).catch((err) => {
            this.showSpinner = false;
            console.log('Error in getSampledDocumentRecord = ', err);
        });
    }

    // method to fetch save document decision data
    handleSaveFCUDecisions() {
        this.showSpinner = true;
        let tempArr = JSON.parse(JSON.stringify(this.documents));
        tempArr.forEach(element => {
            delete element.disableOtherFields;
        });
        saveFCUDecision({ records: JSON.stringify(tempArr) }).then((result) => {
            console.log('handleSaveFCUDecisions=', result);
            if (result == 'SUCCESS') {
                this.showNotifications('Success', 'FCU Decisions Saved Successfully', 'success');
                this.handleGetRelatedDocuments();
            } else {
                this.showNotifications('Error', 'Error in saving FCU Decisions, Please contact your System Administrator', 'error');
            }
            this.showSpinner = false;
        }).catch((err) => {
            this.showSpinner = false;
            console.log('Error in saveFCUDecision = ', err);
            this.showNotifications('Error', 'Error in saving FCU Decisions, Please contact your System Administrator', 'error');
        });
    }
}