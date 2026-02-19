import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDocuments from '@salesforce/apex/SHF_conditionTableController.getDocuments';
import updateDocumentStatus from '@salesforce/apex/SHF_conditionTableController.updateDocumentStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import { getRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';


const COLUMNS = [
    {
        label: 'Name',
        fieldName: 'recordLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        }
    },
    { label: 'Type Of Condition', fieldName: 'Type_Of_Condition__c' },
    { label: 'Type', fieldName: 'Type__c' },
    { label: 'Condition Description', fieldName: 'Condition_Description__c' },
    { label: 'Comment', fieldName: 'Comment__c' },
    { label: 'Status', fieldName: 'Sanction_Condition_Status__c' }
];

const FIELDS = [
    'Activity_History__c.Application__c',
    'Activity_History__c.RecordType.Name',
    'Activity_History__c.OwnerId'
];


export default class Sfh_TableOfCondition extends NavigationMixin(LightningElement) {

    columns = COLUMNS;
    documentData = [];
    selectedRows = [];
    selectedRowIds = [];

    recordId;
    applicationId;
    recordTypeIdName;
    buttonLable;
    isButtonActive = true;
    isOwner = false;


    // ---------------- GET RECORD ID ----------------
    @wire(CurrentPageReference)
    getActHistoryId(currentPageReference) {
        if (currentPageReference?.state?.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference?.attributes?.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }
    }

    // ---------------- GET APPLICATION ----------------
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.applicationId = data.fields.Application__c.value;
            this.recordTypeIdName = data.fields.RecordType.displayValue;

            const ownerId = data.fields.OwnerId.value;

            // Check if logged-in user is owner
            this.isOwner = (ownerId === USER_ID);

            this.loadDocuments();
        } else if (error) {
            console.error('Record error:', error);
        }
    }


    // ---------------- LOAD DOCUMENTS ----------------
    loadDocuments() {
        getDocuments({ applicationId: this.applicationId, activityHistoryId: this.recordId })
            .then(result => {
                this.documentData = (result || []).map(row => ({
                    ...row,
                    recordLink: `/lightning/r/Document__c/${row.Id}/view`
                }));
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', 'Failed to load documents', 'error');
            });
    }

    // ---------------- ROW SELECTION ----------------
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
        this.selectedRowIds = this.selectedRows.map(row => row.Id);
        console.log('Selected Ids:', this.selectedRowIds);
    }

    // ---------------- BUTTON CLICK ----------------
    async handleClick(event) {
        this.buttonLable = event.target.label;

        if (!this.selectedRows || this.selectedRows.length === 0) {
            this.showToast('Error', 'Select at least one record', 'error');
            return;
        }

        // reset flag
        this.isButtonActive = true;

        // validate status
        this.selectedRows.forEach(item => {
            if (item.Sanction_Condition_Status__c !== 'Approval Pending') {
                this.isButtonActive = false;
            }
        });

        if (!this.isButtonActive) {
            this.showToast('Error', 'Please uncheck conditions where decision already provided.', 'error');
            return;
        }

        const result = await LightningConfirm.open({
            message: `Are you sure you want to ${this.buttonLable} the selected record(s)?`,
            variant: 'header',
            label: 'Confirmation'
        });

        if (result) {
            this.updateStatus();
        }
    }

    // ---------------- UPDATE STATUS ----------------
    updateStatus() {

        if (!this.selectedRowIds || this.selectedRowIds.length === 0) {
            this.showToast('Error', 'Select at least one record', 'error');
            return;
        }

        updateDocumentStatus({
            recordIds: this.selectedRowIds,
            decision: this.buttonLable
        })
            .then(result => {
                if (result) {
                    this.showToast('Success', `Records ${this.buttonLable} successfully`, 'success');
                    setTimeout(() => {
                        window.location.reload();
                    }, 300);
                }
            })
            .catch(error => {
                console.error('Update error:', error);
                this.showToast('Error', 'Failed to update records', 'error');
            });
    }

    // ---------------- TOAST ----------------
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}