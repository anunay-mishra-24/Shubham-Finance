import { LightningElement, api, track ,wire } from 'lwc';
import getVerificationRecords from '@salesforce/apex/ShfVerificationComponentCtrl.getVerificationRecords';
import saveVerificationRecord from '@salesforce/apex/ShfVerificationComponentCtrl.saveVerificationRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import VERIFICATION_OBJECT from '@salesforce/schema/Verification__c'; 

const COLUMNS = [
    {
        label: 'Name',
        fieldName: 'nameLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        }
    },
    {
        label: 'Activity Type',
        fieldName: 'RecordTypeName',
        type: 'text'
        
    },
    {
        label: 'Type',
        fieldName: 'Type__c',
        type: 'text'
        
    },
    {
        label: 'Status',
        fieldName: 'Status__c',
        type: 'text'
        
    },
    {
        label: 'Verifier Name',
        fieldName: 'VerifierNameLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Verifier_Name__c' },
            target: '_blank'
        }
    },
    {
        label: 'Date',
        fieldName: 'LastModifiedDate',
        type: 'date'
        
    },
    {
        label: 'Decision',
        fieldName: 'FCU_Manager_Decision__c',
        type: 'text'
        
    }
];
export default class ShfVerificationComponent extends LightningElement {
    @api recordId;
    @track verificationRecordList = [];
    @track verification = {'sobjectType': 'Verification__c'};
    @track recordTypeOptions = [];
    columns = COLUMNS;
    showSpinner = true;
    isShowModal = false;

    /*activityTypeOptions = [
        {label:'RCU', value:'RCU'},
        {label:'Technical Valuation', value:'Technical Valuation'}, 
        {label:'Legal Valuation', value:'FemLegal Valuationale'}
    ];*/

    typeOptions = [
        {label:'Seller', value:'Seller'},
        {label:'Borrower', value:'Borrower'}, 
        {label:'Document', value:'Document'}
    ];

    connectedCallback() {
        this.verification.Application__c = this.recordId;
        this.getVerificationRecords();
    }

    @wire(getObjectInfo, { objectApiName: VERIFICATION_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.recordTypeOptions = this.generateRecordTypeOptions(data.recordTypeInfos);
        } else if (error) {
            console.error('Error fetching object info', error);
        }
    }

    generateRecordTypeOptions(recordTypeInfos) {
        return Object.keys(recordTypeInfos)
        .filter(rtId => !recordTypeInfos[rtId].master) // exclude Master
        .map(rtId => {
            return {
                label: recordTypeInfos[rtId].name,
                value: recordTypeInfos[rtId].recordTypeId
            };
        });
        /*return Object.keys(recordTypeInfos).map(rtId => {
            return {
                label: recordTypeInfos[rtId].name,
                value: recordTypeInfos[rtId].recordTypeId
            };
        });*/
    }

    getVerificationRecords(){
        this.showSpinner = true;
        getVerificationRecords({recordId: this.recordId})
            .then(result => {
                console.log('RESSULT ', result);
                this.verificationRecordList = result.map(row => {
                    return {
                        ...row,
                        nameLink: '/' + row.Id,
                        Name :row.Name,
                        Verifier_Name__c: (row.Verifier_Name__c) ? row.Verifier_Name__r.Name : '',
                        VerifierNameLink:  (row.Verifier_Name__c) ? '/' + row.Verifier_Name__c : '',
                        RecordTypeName: (row.RecordType.Name) ? row.RecordType.Name : ''
                    };
                });
            })
            .catch(error => {
                //this.showErrorToast('Error obtaining access token', error.message);
                console.error(error);
                console.log('getVerificationRecords() ERROR ', JSON.stringify(error));
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleClick(event){
        if(event.target.label == 'New Activity'){
            this.verification.Application__c = this.recordId;
            this.isShowModal = true;
        }
        else if(event.target.name == 'Cancel'){
            this.clearModal();
            this.isShowModal = false;
        }
        else if(event.target.name == 'Save'){
            this.showSpinner = true;
            if(!this.validateData()){
                this.showSpinner = false;
                return false;
            }
            this.saveVerificationRecord();
        }
    }

    handleChange(event){
        this.verification[event.target.name] = event.target.value;
    }

    saveVerificationRecord(){
        console.log('TTT123');
        saveVerificationRecord({verificationRec: this.verification})
            .then(result => {
                console.log('RESULT ', result);
                this.showToast('Success', 'Verification record is created.', 'success');
                this.getVerificationRecords();
                this.clearModal();
                this.isShowModal = false;
            })
            .catch(error => {
                console.error('ERROR', JSON.stringify(error));
                let err = '';
                if(error?.body?.message){
                    err = error.body.message;
                }else{
                    err = error;
                }
                this.showToast('Error', err, 'error');
            })
            .finally(() => {
                this.showSpinner = false;
            });
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

    clearModal(){
        this.verification = {'sobjectType': 'Verification__c'};
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
}