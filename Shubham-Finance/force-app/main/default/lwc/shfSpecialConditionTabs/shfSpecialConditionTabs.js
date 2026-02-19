import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi'; 
import getDocumentByFileName from '@salesforce/apex/SHF_SpecialConditionTabController.getDocumentByFileName';
import RECORDTYPE_NAME from '@salesforce/schema/Application__c.RecordType.DeveloperName';
import DOCUMENT_OBJECT from '@salesforce/schema/Document__c';
import TYPE_OF_CONDITION_FIELD from '@salesforce/schema/Document__c.Type_Of_Condition__c';
import SANCTION_STATUS_FIELD from '@salesforce/schema/Document__c.Sanction_Condition_Status__c';
import QUERY_FIELD from '@salesforce/schema/Document__c.Query__c';
import ID_FIELD from '@salesforce/schema/Document__c.Id'; 
import createSpecialCondition from '@salesforce/apex/SHF_SpecialConditionTabController.createSpecialCondition';
import getSpecialConditions from '@salesforce/apex/SHF_SpecialConditionTabController.getSpecialConditions';
import updateSpecialCondition from '@salesforce/apex/SHF_SpecialConditionTabController.updateSpecialCondition';
import getConditionDescriptions from '@salesforce/apex/SHF_SpecialConditionTabController.getConditionDescriptions';
import getUserAccessInfo from '@salesforce/apex/SHF_SpecialConditionTabController.getUserAccessInfo';
import requestStatusChange from '@salesforce/apex/SHF_SpecialConditionTabController.requestStatusChange';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FILE_SANCTION_LETTER from '@salesforce/label/c.Sanction_Letter_File_Name';
import FILE_TENTATIVE_REPAYMENT from '@salesforce/label/c.Tentative_Repayment_File_Name';
import CONDITION_REVISED_SANCTION from '@salesforce/label/c.Special_Tab_Sanction_Sync';
import CONDITION_REPAYMENT from '@salesforce/label/c.Special_Tab_Tentative_Repayment_Sync';


import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import USER_Id from '@salesforce/user/Id';

export default class ShfSpecialConditionTabs extends NavigationMixin(LightningElement) {

    @api recordId;
    @api verificationId;
    @api hidePreDisbursmentTab = false;
    showModal = false;
    userId = USER_Id;
    
    @track typeOfConditionOptions = [];
    selectedTypeOfCondition;
    
    @track sanctionConditions = [];
    @track pddConditions = [];
    @track otcConditions = [];
    @track preDisbConditions = [];
    @track conditionsForChangeType = [];
    allConditionsForChangeType = [];
    
    conditionDescriptionOptions = [];
    isDescriptionLoading = false;

    selectedConditionDescription;
    comment;
    wiredResult;
    selectedRecordId;

    documentId;
    docName;
    docCategory;

    showUploadModal = false;
    isAddMode = false;
    isViewMode = false;
    isEditMode = false;

    isPreDisbursement = false;
    canChangeStatus = false;

    activeTab = 'preDisb'; 
    showChangeTypeModal = false;
    selectedRows = [];
    newConditionType;

    showChangeStatusModal = false;
    @track statusOptions = [];
    @track conditionsForChangeStatus = [];
    allConditionsForChangeStatus = [];
    newStatus = null;
    showQueryFlow = false;
    rowsToUpdateWithQuery = [];
    //SHF-1559 
    @track sendLinkToCustomerBtn  = 'Send link to Customer'
    @track showunUploadedDocumentModal = false;

    columns = [
        { label: 'Name', fieldName: 'recordLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
        { label: 'Type', fieldName: 'Type_Of_Condition__c', type: 'text' },
        { label: 'Condition Description', fieldName: 'Condition_Description__c', type: 'text' },
        { label: 'Comment', fieldName: 'Comment__c', type: 'text' },
        { label: 'Status', fieldName: 'Sanction_Condition_Status__c', type: 'text' },
        { label: 'Upload Status', fieldName: 'Status__c', type: 'text' },
        {
            type: 'action', typeAttributes: { rowActions: [{ label: 'View Condition', name: 'viewCondition' }, { label: 'Edit', name: 'edit' }, { label: 'Upload', name: 'upload', iconName: 'action:upload' }, { label: 'View', name: 'View', iconName: 'utility:preview' }] }
        }
    ];

    handleTabActive(event) {
        this.activeTab = event.target.value;
    }

    handleRowAction(event) {
        this.isViewMode = false;
        this.isEditMode = false;
        this.isAddMode = false;
        this.showModal = false;
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        //SHF-1559 
        if (actionName === 'upload') {
            this.documentId = row.Id;
            this.docName = row.File_Name__c;
            this.docCategory = row.Document_Category__c;
            this.showUploadModal = true;
            return;
        }

        if (actionName === 'View') {
            let fileNameToFetch = null;

    if (row.Condition_Description__c === CONDITION_REVISED_SANCTION) {
        fileNameToFetch = FILE_SANCTION_LETTER;

    } else if (row.Condition_Description__c === CONDITION_REPAYMENT) {
        fileNameToFetch = FILE_TENTATIVE_REPAYMENT;
    }

    if (fileNameToFetch) {
        getDocumentByFileName({
            applicationId: this.recordId,
            fileName: fileNameToFetch
        })
            .then(doc => {
                if (doc) {
                    this.template
                        .querySelector('c-shf-preview-document')
                        .preview(doc.Id);
                } else {
                    this.showToast(
                        'Info',
                        `${fileNameToFetch} document not found.`,
                        'info'
                    );
                }
            })
            .catch(error => this.handleError(error));
    } else {
            this.documentId = row.Id;
            this.template.querySelector('c-shf-preview-document').preview(this.documentId);
             return;
    }
        }

        this.selectedRecordId = row.Id;
        this.selectedTypeOfCondition = row.Type_Of_Condition__c;
        this.comment = row.Comment__c;
        
        if (actionName === 'viewCondition') {
            this.isViewMode = true;
            this.isEditMode = false;
            this.isAddMode = false;

            this.loadDescriptions(this.selectedTypeOfCondition).then(() => {
                this.selectedConditionDescription = row.Condition_Description__c;
                this.showModal = true;
            });
        }

        if (actionName === 'edit') {
            if (this.userId != row.CreatedById) {
                this.showToast('Error','You can not edit this condition as you have not created this.','error');
                return;
            }
            this.isViewMode = false;
            this.isEditMode = true;
            this.isAddMode = false;

            this.loadDescriptions(this.selectedTypeOfCondition).then(() => {
                this.selectedConditionDescription = row.Condition_Description__c;
                this.showModal = true;
            });
        }
    }

    @wire(getObjectInfo, { objectApiName: DOCUMENT_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: TYPE_OF_CONDITION_FIELD
    })
    wiredPicklist({ data }) {
        if (data) {
            let tempArr = [];
            data.values.forEach(currentItem => {
                tempArr.push(currentItem);
            });
            this.typeOfConditionOptions = JSON.parse(JSON.stringify(tempArr));
        }
    }

    @wire(getUserAccessInfo, { applicationId: '$recordId' })
    wiredUserAccess({ data, error }) {
        if (data) {
            this.canChangeStatus = data.canChangeStatus;
            console.log('--- User Access Info ---');
            console.log('Can Change Status:', this.canChangeStatus);
        } else if (error) {
            console.error('Error getting user access info', error);
            this.canChangeStatus = false;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: SANCTION_STATUS_FIELD
    })
    wiredStatusPicklist({ data, error }) {
        if (data) {
            // By default, we hide 'Completed' and 'Pending'.
            // To hide 'PDD' and 'OTC', we add them to the list of hidden statuses.
            // To make them visible again, just remove them from the HIDDEN_STATUSES array.
            const HIDDEN_STATUSES = ['Completed', 'Pending', 'PDD', 'OTC'];
            this.statusOptions = data.values.filter(item => !HIDDEN_STATUSES.includes(item.value));
        } else if (error) {
            console.error('Error loading status picklist values', error);
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [RECORDTYPE_NAME]
    })
    wiredApplication({ data, error }) {
        if (data) {
            console.log('--- Debugging Application Data ---');
            console.log('Raw data:', JSON.stringify(data, null, 2));

            const rtDeveloperName = getFieldValue(data, RECORDTYPE_NAME);
            console.log('RecordType DeveloperName from getFieldValue:', rtDeveloperName);
            
            if (rtDeveloperName === 'Pre_Disbursement') {
                this.isPreDisbursement = true;
            } else {
                this.isPreDisbursement = false;
            }
            console.log('Record Type Match? (isPreDisbursement):', this.isPreDisbursement);
            console.log('--- End Debugging ---');

        } else if (error) {
            console.error('Error loading application', error);
        }
    }

    @wire(getSpecialConditions, { applicationId: '$recordId' })
    wiredConditions(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.sanctionConditions = [];
            this.pddConditions = [];
            this.otcConditions = [];
            this.preDisbConditions = [];

            const filteredData = data.filter(rec => rec.Sanction_Condition_Status__c !== 'Approval Pending');

            filteredData.forEach(rec => {

                const row = { ...rec, recordLink: '/' + rec.Id };
                switch (rec.Type_Of_Condition__c) {
                    case 'Sanction Condition': this.sanctionConditions.push(row); break;
                    case 'PDD': this.pddConditions.push(row); break;
                    case 'OTC': this.otcConditions.push(row); break;
                    case 'Pre-Disbursement Document': this.preDisbConditions.push(row); break;
                }
            });


        } else if (error) {
            console.error(error);
        }
    }

    handleAddNew() {
        this.isAddMode = true;
        this.isViewMode = false;
        this.isEditMode = false;
        this.showModal = true;
    }

    handleClose() {
        this.showModal = false;
        this.resetForm();
    }

    resetForm() {
        this.selectedTypeOfCondition = null;
        this.selectedConditionDescription = null;
        this.comment = null;
    }

    handleTypeOfConditionChange(event) {
        this.selectedTypeOfCondition = event.detail.value;
        this.selectedConditionDescription = null;
        this.loadDescriptions(this.selectedTypeOfCondition);
    }

    loadDescriptions(typeVal) {
        this.conditionDescriptionOptions = [];
        this.isDescriptionLoading = true;
        return getConditionDescriptions({ typeOfCondition: typeVal })
            .then(result => {
                this.conditionDescriptionOptions = result.map(item => ({ label: item, value: item }));
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', 'Unable to load condition descriptions', 'error');
            })
            .finally(() => { this.isDescriptionLoading = false; });
    }

    handleDescriptionChange(event) { this.selectedConditionDescription = event.detail.value; }
    handleCommentChange(event) { this.comment = event.detail.value; }

    handleChangeStatusClick() {
        const allConditions = [
            ...this.sanctionConditions,
            ...this.pddConditions,
            ...this.otcConditions,
            ...this.preDisbConditions
        ];

        const eligibleConditions = allConditions.filter(row => row.Status__c !== 'Uploaded');

        if (eligibleConditions.length === 0) {
            this.showToast('Info', 'No conditions with status "Not Uploaded" are available to change status.', 'info');
            return;
        }

        this.conditionsForChangeStatus = eligibleConditions;
        this.allConditionsForChangeStatus = [...eligibleConditions];
        this.newStatus = null; // Reset status
        this.showChangeStatusModal = true;
    }

    get showChangeStatusButton() {
        return this.isPreDisbursement;
    }

    closeChangeStatusModal() {
        this.showChangeStatusModal = false;
        this.conditionsForChangeStatus = [];
        this.allConditionsForChangeStatus = [];
        this.newStatus = null;
        this.showQueryFlow = false;
        this.rowsToUpdateWithQuery = [];
    }

    handleNewStatusChange(event) {
        this.newStatus = event.detail.value;
        if (this.newStatus) {
            this.conditionsForChangeStatus = this.allConditionsForChangeStatus.filter(
                row => row.Sanction_Condition_Status__c !== this.newStatus
            );
        } else {
            this.conditionsForChangeStatus = [...this.allConditionsForChangeStatus];
        }
    }

    get showStatusSaveButton() {
        return ['Waived Off', 'Deferred', 'OTC', 'PDD'].includes(this.newStatus);
        // return ['Waived Off', 'Deferred', 'OTC', 'PDD'].includes(this.newStatus);
    }

    get showStatusNextButton() {
        return this.newStatus === 'Raise Query';
    }

    handleStatusSave() {
        const datatable = this.template.querySelector('[data-id="changeStatusTable"]');
        const selectedRows = datatable.getSelectedRows();

        if (!selectedRows || selectedRows.length === 0) {
            this.showToast('Error', 'Please select at least one condition.', 'error');
            return;
        }

        if (this.newStatus === 'Waived Off' || this.newStatus === 'Deferred') {
            const selectedIds = selectedRows.map(row => row.Id);
            requestStatusChange({ conditionIds: selectedIds, requestedStatus: this.newStatus })
                .then(() => {
                    this.showToast('Success', 'Approval request has been initiated for the change of status.', 'success');
                    this.closeChangeStatusModal();
                    return refreshApex(this.wiredResult);
                })
                .catch(error => {
                    this.handleError(error);
                });
        } else {
            const inputs = selectedRows.map(row => {
                const fields = {};
                fields[ID_FIELD.fieldApiName] = row.Id;
                fields[SANCTION_STATUS_FIELD.fieldApiName] = this.newStatus;
                return { fields };
            });

            const promises = inputs.map(recordInput => updateRecord(recordInput));

            Promise.all(promises)
                .then(() => {
                    this.showToast('Success', 'The status for selected conditions has been changed successfully.', 'success');
                    this.closeChangeStatusModal();
                    return refreshApex(this.wiredResult);
                })
                .catch(error => {
                    this.handleError(error);
                });
        }
    }

    handleStatusNext() {
        const datatable = this.template.querySelector('[data-id="changeStatusTable"]');
        const selectedRows = datatable.getSelectedRows();

        if (!selectedRows || selectedRows.length === 0) {
            this.showToast('Error', 'Please select at least one condition.', 'error');
            return;
        }
        
        this.rowsToUpdateWithQuery = selectedRows;
        this.showQueryFlow = true;
    }

    get flowInputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    handleFlowStatusChange(event) {
        console.log('--- Flow Status Change Event ---');
        console.log('Flow Status:', event.detail.status);
        console.log('Flow Detail:', JSON.stringify(event.detail, null, 2));

        if (event.detail.status === 'FINISHED') {
            console.log('Flow finished. Processing outputs...');
            const outputVariables = event.detail.outputVariables;
            
            if (!outputVariables) {
                console.error('Flow finished but no output variables were found.');
                this.handleError({ body: { message: 'Flow finished without returning any output.' } });
                this.closeChangeStatusModal();
                return;
            }

            const queryRecordVar = outputVariables.find(v => v.name === 'QueryRecord');
            const newQueryId = queryRecordVar && queryRecordVar.value ? queryRecordVar.value.Id : null;
            console.log('Extracted Query ID:', newQueryId);

            if (!newQueryId) {
                this.handleError({ body: { message: 'Flow finished without returning a Query Record ID.' } });
                this.closeChangeStatusModal();
                return;
            }
            
            console.log('---rowsToUpdateWithQuery---',this.rowsToUpdateWithQuery);
            console.log('Rows to update:', JSON.stringify(this.rowsToUpdateWithQuery, null, 2));

            const inputs = this.rowsToUpdateWithQuery.map(row => {
                const fields = {};
                fields[ID_FIELD.fieldApiName] = row.Id;
                fields[SANCTION_STATUS_FIELD.fieldApiName] = 'Raise Query';
                fields[QUERY_FIELD.fieldApiName] = newQueryId;
                return { fields };
            });

            console.log('Preparing to update records with this data:', JSON.stringify(inputs, null, 2));

            const promises = inputs.map(recordInput => updateRecord(recordInput));

            Promise.all(promises)
                .then(() => {
                    console.log('Successfully updated all records.');
                    this.showToast('Success', 'The status for selected conditions has been changed successfully.', 'success');
                    this.closeChangeStatusModal();
                    return refreshApex(this.wiredResult);
                })
                .catch(error => {
                    console.error('--- ERROR during record update after flow ---');
                    console.error(JSON.stringify(error, null, 2));
                    this.handleError(error);
                });
        }
    }

    get isConditionDescriptionDisabled() {
        return this.isViewMode || !this.selectedTypeOfCondition;
    }
    
    get closeLabel() {
        return (this.isAddMode || this.isEditMode) ? 'Cancel' : 'Close';
    }

    handleSave() {
        if (!this.validateForm()) return;
        
        let activityId = this.verificationId ? this.verificationId : null;
        createSpecialCondition({
            applicationId: this.recordId,
            typeOfCondition: this.selectedTypeOfCondition,
            conditionDescription: this.selectedConditionDescription,
            comment: this.comment,
            verificationId: activityId
        })
        .then(() => {
            this.showToast('Success', 'Condition added successfully', 'success');
            this.showModal = false;
            this.resetForm();
            refreshApex(this.wiredResult);
        })
        .catch(error => this.handleError(error));
    }

    handleUpdate() {
        if (!this.validateForm()) return;

        updateSpecialCondition({
            recordId: this.selectedRecordId,
            typeOfCondition: this.selectedTypeOfCondition,
            conditionDescription: this.selectedConditionDescription,
            comment: this.comment
        })
        .then(() => {
            this.showToast('Success', 'Condition updated successfully', 'success');
            this.showModal = false;
            refreshApex(this.wiredResult);
        })
        .catch(error => this.handleError(error));
    }

    validateForm() {
        if (!this.selectedTypeOfCondition || !this.selectedConditionDescription) {
            this.showToast('Error', 'Please fill all mandatory fields', 'error');
            return false;
        }
        return true;
    }

    handleChangeType() {
        const allConditions = [
            ...this.sanctionConditions,
            ...this.pddConditions,
            ...this.otcConditions,
            ...this.preDisbConditions
        ];

        const eligibleConditions = allConditions.filter(row => row.Status__c !== 'Uploaded');

        if (eligibleConditions.length === 0) {
            this.showToast('Info', 'No conditions are available to change type.', 'info');
            return;
        }

        this.conditionsForChangeType = eligibleConditions;
        this.allConditionsForChangeType = [...eligibleConditions];
        this.newConditionType = null;
        this.selectedRows = [];
        this.showChangeTypeModal = true;
    }


    //SHF-1559
    sendLinkToCustomerBtnClick(){
      this.showChangeTypeModal = false;
      this.showunUploadedDocumentModal = true;
      console.log('Button click Send Link to customer');
    }

    handleUnuploadedClose(event){
        this.showunUploadedDocumentModal = false;
    }

    handleNewTypeChange(event) {
        this.newConditionType = event.detail.value;
        if (this.newConditionType) {
            this.conditionsForChangeType = this.allConditionsForChangeType.filter(
                row => row.Type_Of_Condition__c !== this.newConditionType
            );
        } else {
            this.conditionsForChangeType = [...this.allConditionsForChangeType];
        }
    }

    closeChangeTypeModal() {
        this.showChangeTypeModal = false;
        this.selectedRows = [];
        this.newConditionType = null;
        this.conditionsForChangeType = [];
        this.allConditionsForChangeType = [];
    }

    handleSaveConditionType() {
        if (!this.newConditionType) {
            this.showToast('Error', 'Please select a Condition Type.', 'error');
            return;
        }

        const modalDatatable = this.template.querySelector('[data-id="changeTypeTable"]');
        if (!modalDatatable) {
            this.showToast('Error', 'Datatable not found.', 'error');
            return;
        }
        
        const selectedRows = modalDatatable.getSelectedRows();

        if (!selectedRows || selectedRows.length === 0) {
            this.showToast('Error', 'Please select at least one condition from the list.', 'error');
            return;
        }

        const inputs = selectedRows.map(row => {
            const fields = {};
            fields[ID_FIELD.fieldApiName] = row.Id;
            fields[TYPE_OF_CONDITION_FIELD.fieldApiName] = this.newConditionType;
            return { fields };
        });

        const promises = inputs.map(recordInput => updateRecord(recordInput));

        Promise.all(promises)
            .then(() => {
                this.showToast('Success', 'The condition type for selected conditions has been changed successfully.', 'success');
                this.closeChangeTypeModal();
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.handleError(error);
            });
    }


    handleUploadCompleted(event) {
        const { docId } = event.detail;
        const fields = {};
        fields[ID_FIELD.fieldApiName] = docId;
        fields[SANCTION_STATUS_FIELD.fieldApiName] = 'Completed';

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Status updated to Completed', 'success');
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.handleError(error);
            });
    }

    handleUploadClose() {
        this.showUploadModal = false;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleError(error) {
        this.showToast('Error', error?.body?.message || 'Something went wrong', 'error');
    }

}