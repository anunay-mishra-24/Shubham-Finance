import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import createOrRetryEnach from '@salesforce/apex/SHF_Enach_Controller.createOrRetryEnach';
import getEnachRecords from '@salesforce/apex/SHF_Enach_Controller.getEnachRecords';
import sendEnachLinkToCustomer from '@salesforce/apex/SHF_Enach_Controller.sendEnachLinkToCustomer';


export default class ShfEnachTable extends NavigationMixin(LightningElement) {

    @api recordId;
    records;
    error;
    wiredResult;
    isSendDisabled = false;


    columns = [
        {
            label: 'E-Nach Name',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_self'
            }
        },
        {
            label: 'E-Nach Accepted',
            fieldName: 'Status__c'
        }
    ];

    @wire(getEnachRecords, { applicationId: '$recordId' })
    wiredEnach(result) {
        this.wiredResult = result;

        if (result.data) {
            this.records = result.data.map(row => ({
                ...row,
                recordUrl: '/' + row.Id
            }));
         if (data.length > 0 && data[0].Enach_Process_Count__c >= 3) {
            this.isSendDisabled = true;
           } 
           else {
            this.isSendDisabled = false;
          }

        this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.records = undefined;
        }
    }

    createEnachRecordandSendLink() {
        createOrRetryEnach({ applicationId: this.recordId })
           .then(() => {
            return sendEnachLinkToCustomer({
                applicationId: this.recordId
            });
            })
            .then(() => {
                this.showToast(
                    'Success',
                    'E-Nach process triggered successfully',
                    'success'
                );
                // AUTO REFRESH TABLE
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.showToast(
                    'E-Nach Blocked',
                    error?.body?.message || 'Unable to trigger E-Nach',
                    'error'
                );
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}