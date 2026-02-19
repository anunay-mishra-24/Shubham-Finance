import { LightningElement, api, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import Owner_FIELD from '@salesforce/schema/Disbursement__c.OwnerId';
import ID_FIELD from '@salesforce/schema/Disbursement__c.Id';
import Status_FIELD from '@salesforce/schema/Disbursement__c.Status__c';
import loadScreen from '@salesforce/apex/SHF_DisbursementViewController.loadScreen';
import loadDisbursementRecord from '@salesforce/apex/SHF_DisbursementViewController.loadDisbursementRecord';
import getQueueByDeveloperName from '@salesforce/apex/SHF_DisbursementViewController.getQueueByDeveloperName';
import createNewTranche from '@salesforce/apex/SHF_DisbursementViewController.createNewTranche';
import updateTranches from '@salesforce/apex/SHF_DisbursementViewController.updateTranches';
import deleteTranche from '@salesforce/apex/SHF_DisbursementViewController.deleteTranche';
import saveApplication from '@salesforce/apex/SHF_DisbursementViewController.saveApplication';

export default class ShfDisbursementView extends NavigationMixin(LightningElement) {
    @api recordId;

    isLoading = false;
    isInitiateDisbursementDisabled = true;
    @track showConfirmModal = false;
    errorMessage = null;
    lanToBeLinkedSavedId = null;
    isDisbursementId;
    selectedDisStatus;
    viewData = {
        applicationId: null,
        branchName: null,
        applicantName: null,
        sanctionDate: null,

        maximumSanctionedAmount: null,
        sanctionedAmount: null,

        disbursedAmount: null,
        availableAmount: null,

        tenure: null,
        roi: null,
        applicationStatus: null,
        applicationStage: null,

        loanAccountNumber: null, // ✅ NEW
        loanCurtailment: false,
        lanToBeLinkedId: null,
        lanToBeLinkedName: null,
        lanToBeLinkedLocked: false
    };

    disbursalType = null;
    tranches = [];

    selectedTrancheId = null;
    selectedTrancheName = null;

    // ---------- Create modal ----------
    showCreateModal = false;
    newTrancheDate = null;
    newTrancheAmount = null;

    newPrincipalRecovery = false;
    newPrincipalRecoveryFrom = null;
    newPrincipalRecoveryOn = null;
    newDisbursementBankId = null;
    newStatus = null;

    // ---------- Edit modal ----------
    showEditModal = false;
    editTrancheId = null;
    editTrancheName = null;
    editDisbursalDate = null;
    editDisbursalAmount = null;
    editOldAmount = 0;

    editPrincipalRecovery = false;
    editPrincipalRecoveryFrom = null;
    editPrincipalRecoveryOn = null;
    editDisbursementBankId = null;
    editStatus = null;

    // ---------- Delete modal ----------
    showDeleteModal = false;
    deleteTrancheId = null;
    deleteTrancheName = null;
    queueId;
    queueName;

    @wire(getQueueByDeveloperName)
    wiredQueue({ data, error }) {
        if (data) {
            this.queueId = data.Id;
            this.queueName = data.Name;
        } else if (error) {
            console.error('Error fetching queue', error);
        }
    }
    stage = ['Cheque Printing','Disbursement Maker','Disbursement Checker'];
    // ✅ Record Picker filter/config for Bank_master__c
    bankFilter = {
        criteria: [
            { fieldPath: 'RecordType.Name', operator: 'eq', value: 'Dealing Disbursement Bank Master' }
        ]
    };

    bankDisplayInfo = {
        primaryField: 'Name',
        additionalFields: ['Name']
    };

    bankMatchingInfo = {
        primaryField: { fieldPath: 'Name', mode: 'contains' },
        additionalFields: [{ fieldPath: 'Name', mode: 'contains' }]
    };
    

   initColumns() {
    this.trancheColumns = [
        {
            label: 'Tranche ID',
            fieldName: 'trancheLinkBase',
            type: 'url',
            typeAttributes: { label: { fieldName: 'trancheId' }, target: '_blank' }
        },
        { label: 'Disbursal Date', fieldName: 'disbursalDate', type: 'date-local' },
        { label: 'Disbursal Amount', fieldName: 'disbursalAmount', type: 'currency' },
        { label: 'Adjustment Amount', fieldName: 'adjustmentAmount', type: 'currency' },
        { label: 'Actual Payment Amount', fieldName: 'actualPaymentAmount', type: 'currency' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: this.getRowActions.bind(this) // ✅ IMPORTANT
            }
        }
    ];
}

getRowActions(row, doneCallback) {
    const stageOk = this.isStageAllowed;
    const statusOk = (row?.status === 'Tranche Request Initiation');

    const disabled = !(stageOk && statusOk);

    doneCallback([
        { label: 'Edit', name: 'edit', disabled },
        { label: 'Delete', name: 'delete', disabled }
    ]);
}


    connectedCallback() {
         this.initColumns();
        this.load();
    }
    get isStageAllowed() {
    return this.stage.includes(this.viewData?.applicationStage);
    }

    get isFieldDisabled() {
        return this.isLoading || !this.isStageAllowed;
    }

    get isApplicationSave() {
        return this.isLoading || !this.isStageAllowed;
    }
    get isNewPrRequired() {
    return this.newPrincipalRecovery === true;
    }
    get isEditPrRequired() {
        return this.editPrincipalRecovery === true;
    }

    get lanMasterUrl() {
        return this.viewData.lanToBeLinkedId ? `/${this.viewData.lanToBeLinkedId}` : '#';
    }

    get isLanToBeLinkedDisabled() {
        return this.isLoading || this.viewData.lanToBeLinkedLocked === true;
    }

    get statusOptions() {
        return [
            { label: 'Tranche Request Initiation', value: 'Tranche Request Initiation' },
            { label: 'Tranche Approval', value: 'Tranche Approval' },
            { label: 'Tranche Disbursement', value: 'Tranche Disbursement' },
            { label: 'Disbursed', value: 'Disbursed' }
        ];
    }

    get disbursalTypeOptions() {
        const base = [
            { label: 'Single', value: 'Single' },
            { label: 'Multiple', value: 'Multiple' }
        ];
        if (this.disbursalType && !base.some(x => x.value === this.disbursalType)) {
            return [...base, { label: this.disbursalType, value: this.disbursalType }];
        }
        return base;
    }

    get singleTypeHint() {
        return this.disbursalType === 'Single' && (this.tranches?.length || 0) > 0;
    }

    get selectedRows() {
        return this.selectedTrancheId ? [this.selectedTrancheId] : [];
    }


   get isCreateTrancheDisabled() {
    const singleBlocked = this.disbursalType === 'Single' && (this.tranches?.length || 0) > 0;
    const available = Number(this.viewData.availableAmount || 0);
    const curtailBlocked = this.viewData.loanCurtailment === true || available === 0;
    return !this.isStageAllowed || singleBlocked || curtailBlocked;
}


    getTodayIsoLocal() {
        const d = new Date();
        const tz = d.getTimezoneOffset() * 60000;
        return new Date(d.getTime() - tz).toISOString().slice(0, 10);
    }
    handleUpdate() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.isDisbursementId;
        fields[Owner_FIELD.fieldApiName] = this.queueId;
        fields[Status_FIELD.fieldApiName] = 'Tranche Approval';
        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.toast('Success', 'Disbursement has been initiated successfully.', 'success');
                //this.navigateToRecord(this.isDisbursementId, 'Disbursement__c');
            })
            .catch(error => {
                this.toast('Error', error.body.message, 'error');
            });
    }
    handleConfirmYes() {
        //this.showConfirmModal = false;
        this.handleUpdate();
        this.showConfirmModal = false;
    }
    handleCancelConfirm() {
        this.showConfirmModal = false;
        //this.dispatchEvent(new CloseActionScreenEvent());
    }

    async load() {
        if (!this.recordId) return;

        this.isLoading = true;
        this.errorMessage = null;

        try {
            const res = await loadScreen({ applicationId: this.recordId });

            this.viewData = {
                applicationId: res?.application?.applicationId,
                branchName: res?.application?.branchName,
                applicantName: res?.application?.applicantName,
                sanctionDate: res?.application?.sanctionDate,
                applicationStage: res?.application?.applicationStage,
                maximumSanctionedAmount: res?.application?.maximumSanctionedAmount,
                sanctionedAmount: res?.application?.sanctionedAmount,

                disbursedAmount: res?.application?.disbursedAmount,
                availableAmount: res?.application?.availableAmount,

                tenure: res?.application?.tenure,
                roi: res?.application?.roi,
                applicationStatus: res?.application?.applicationStatus,

                loanAccountNumber: res?.application?.loanAccountNumber,
                loanCurtailment: res?.application?.loanCurtailment,
                lanToBeLinkedId: res?.application?.lanToBeLinkedId,
                lanToBeLinkedName: res?.application?.lanToBeLinkedName,
                lanToBeLinkedLocked: res?.application?.lanToBeLinkedLocked
            };

            this.disbursalType = res?.disbursalType;
            this.tranches = res?.tranches || [];
            console.log('viewData:', this.tranches);
            if (this.selectedTrancheId) {
                const sel = this.tranches.find(x => x.id === this.selectedTrancheId);
                if (sel) {
                    this.selectedTrancheName = sel.trancheId;
                } else {
                    this.selectedTrancheId = null;
                    this.selectedTrancheName = null;
                }
            }
        } catch (e) {
            const msg = this.normalizeError(e);
            this.errorMessage = msg;
            this.toast('Error', msg, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleLanToBeLinkedChange(event) {

        const recordId = event?.detail?.recordId || event?.detail?.value || null;


        const recordName = event?.detail?.recordName || this.viewData.lanToBeLinkedName;

        this.viewData = {
            ...this.viewData,
            lanToBeLinkedId: recordId,
            lanToBeLinkedName: recordName
        };
    }

    handleLoanCurtailmentChange(event) {
        const checked = event.target.checked;

        const disb = Number(this.viewData.disbursedAmount || 0);
        const maxAmt = Number(this.viewData.maximumSanctionedAmount || 0);

        const newSanction = checked ? disb : maxAmt;
        const newAvailable = Math.max(newSanction - disb, 0);

        this.viewData = {
            ...this.viewData,
            loanCurtailment: checked,
            sanctionedAmount: newSanction,
            availableAmount: newAvailable
        };
    }


    async handleSaveApplication() {
        this.isLoading = true;
        try {
            await saveApplication({
                applicationId: this.recordId,
                loanCurtailment: this.viewData.loanCurtailment,
                maximumSanctionedAmount: this.viewData.maximumSanctionedAmount,
                lanToBeLinkedId: this.viewData.lanToBeLinkedId
            });

            this.toast('Success', 'Application saved.', 'success');
            this.viewData = {
                ...this.viewData,
                lanToBeLinkedLocked: !!this.viewData.lanToBeLinkedId
            };
            await this.load();
        } catch (e) {
            this.toast('Error', this.normalizeError(e), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ---------- Row selection / actions ----------
    handleRowSelection(event) {
        this.isDisbursementId = event.detail.selectedRows[0].id;
        const rows = event.detail.selectedRows || [];
        const first = rows[0];
        this.selectedTrancheId = first ? first.id : null;
        this.selectedTrancheName = first ? first.trancheId : null;
        this.getSelectedDisbursement();
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        if (action?.name === 'edit') this.openEditModal(row);
        if (action?.name === 'delete') this.openDeleteModal(row);
    }
    getSelectedDisbursement() {
        loadDisbursementRecord({ disbursementId: this.isDisbursementId })
            .then(data => {
                console.log('record :', data);
                this.selectedDisStatus = data?.Status__c;
                if (this.selectedDisStatus === 'Tranche Request Initiation') {
                    this.isInitiateDisbursementDisabled = false;
                } else {
                    this.isInitiateDisbursementDisabled = true;
                }
            })
            .catch(error => {
                console.error('Error fetching record', error);
            });
    }

    // ---------- Create ----------
    handleCreateTranche() {
        this.newTrancheDate = this.getTodayIsoLocal();
        this.newTrancheAmount = null;

        this.newPrincipalRecovery = false;
        this.newPrincipalRecoveryFrom = null;
        this.newPrincipalRecoveryOn = null;
        this.newDisbursementBankId = null;
        this.newStatus = null;

        this.showCreateModal = true;
    }
    handleInitiateDisbursement() {
        console.log('handleInitiateDisbursement');
        this.showConfirmModal = true;
        //this.navigateToRecord(this.isDisbursementId, 'Disbursement__c');
    }
    navigateToRecord(recordId, objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName, // optional but recommended
                actionName: 'view' // view | edit
            }
        }).then(url => {
        window.open(url, '_blank');
    });
    }

    closeCreateModal() {
        this.showCreateModal = false;
    }

   handleNewTrancheChange(event) {
    const name = event.target.name;

    if (name === 'pr') {
        this.newPrincipalRecovery = event.target.checked;

        if (!this.newPrincipalRecovery) {
            this.newPrincipalRecoveryFrom = null;
            this.newPrincipalRecoveryOn = null;
        }
        return;
    }

    if (name === 'prFrom') this.newPrincipalRecoveryFrom = event.target.value;
    if (name === 'prOn') this.newPrincipalRecoveryOn = event.target.value;

    if (name === 'date') this.newTrancheDate = event.target.value;
    if (name === 'amount') this.newTrancheAmount = event.target.value;
    }


    handleNewDisbursementBankChange(event) {
        this.newDisbursementBankId = event.detail.recordId;
    }

    handleNewStatusChange(event) {
        this.newStatus = event.target.value;
    }

    async handleCreateSave() {
        const today = this.getTodayIsoLocal();
        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-record-picker'
        );
        
        let allValid = true;
        inputs.forEach(el => {
            if (!el.reportValidity()) allValid = false;
        });
        if (!allValid) return;

        if (this.newTrancheDate && this.newTrancheDate > today) {
            this.toast('Error', 'Disbursal Date cannot be a future date.', 'error');
            return;
        }

        if (this.newTrancheAmount === null || this.newTrancheAmount === '' || isNaN(this.newTrancheAmount)) {
            this.toast('Error', 'Disbursal Amount is required.', 'error');
            return;
        }

        const amt = Number(this.newTrancheAmount);
        if (amt <= 0) {
            this.toast('Error', 'Disbursal Amount must be greater than 0.', 'error');
            return;
        }

        const available = Number(this.viewData.availableAmount || 0);
        if (amt > available) {
            this.toast('Error', 'Disbursal Amount cannot be greater than Available Amount.', 'error');
            return;
        }

        // ✅ Mandatory
        if (!this.newDisbursementBankId) {
            this.toast('Error', 'Disbursement Bank is required.', 'error');
            return;
        }
       

        this.isLoading = true;
        try {
            await createNewTranche({
                applicationId: this.recordId,
                disbursalDate: this.newTrancheDate,
                disbursalAmount: amt,
                
                principalRecovery: this.newPrincipalRecovery,
                principalRecoveryFrom: this.newPrincipalRecoveryFrom,
                principalRecoveryOn: this.newPrincipalRecoveryOn,
                disbursementBankId: this.newDisbursementBankId,
                status: this.newStatus
            });

            this.toast('Success', 'New tranche created.', 'success');
            this.showCreateModal = false;
            await this.load();
        } catch (e) {
            this.toast('Error', this.normalizeError(e), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ---------- Edit ----------
    openEditModal(row) {
        this.editTrancheId = row.id;
        this.editTrancheName = row.trancheId;

        this.editDisbursalDate = row.disbursalDate;
        this.editDisbursalAmount = row.disbursalAmount;
        this.editOldAmount = Number(row.disbursalAmount || 0);

        this.editPrincipalRecovery = row.principalRecovery === true;
        this.editPrincipalRecoveryFrom = row.principalRecoveryFrom;
        this.editPrincipalRecoveryOn = row.principalRecoveryOn;
        this.editDisbursementBankId = row.disbursementBankId;
        this.editStatus = row.status;

        this.showEditModal = true;
    }

    closeEditModal() {
        this.showEditModal = false;

        this.editTrancheId = null;
        this.editTrancheName = null;
        this.editDisbursalDate = null;
        this.editDisbursalAmount = null;
        this.editOldAmount = 0;

        this.editPrincipalRecovery = false;
        this.editPrincipalRecoveryFrom = null;
        this.editPrincipalRecoveryOn = null;
        this.editDisbursementBankId = null;
        this.editStatus = null;
    }

    handleEditChange(event) {
    const name = event.target.name;

    if (name === 'editPr') {
        this.editPrincipalRecovery = event.target.checked;

        if (!this.editPrincipalRecovery) {
            this.editPrincipalRecoveryFrom = null;
            this.editPrincipalRecoveryOn = null;
        }
        return;
    }

    if (name === 'editPrFrom') this.editPrincipalRecoveryFrom = event.target.value;
    if (name === 'editPrOn') this.editPrincipalRecoveryOn = event.target.value;

    if (name === 'editDate') this.editDisbursalDate = event.target.value;
    if (name === 'editAmount'){
        this.editDisbursalAmount = event.target.value;
        this.editOldAmount = Number(event.target.value);
    } 
    }


    handleEditDisbursementBankChange(event) {
        this.editDisbursementBankId = event.detail.recordId;
    }

    handleEditStatusChange(event) {
        this.editStatus = event.target.value;
    }

    async handleEditSave() {
        const today = this.getTodayIsoLocal();
        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-record-picker'
        );
        let allValid = true;
        inputs.forEach(el => {
            if (!el.reportValidity()) allValid = false;
        });
        if (!allValid) return;

        if (this.editDisbursalDate && this.editDisbursalDate > today) {
            this.toast('Error', 'Disbursal Date cannot be a future date.', 'error');
            return;
        }

        if (this.editDisbursalAmount === null || this.editDisbursalAmount === '' || isNaN(this.editDisbursalAmount)) {
            this.toast('Error', 'Disbursal Amount is required.', 'error');
            return;
        }

        const newAmt = Number(this.editDisbursalAmount);
        if (newAmt <= 0) {
            this.toast('Error', 'Disbursal Amount must be greater than 0.', 'error');
            return;
        }

        const available = Number(this.viewData.availableAmount || 0);
        const maxAllowed = available + this.editOldAmount;
        if (newAmt > maxAllowed) {
            this.toast('Error', 'Disbursal Amount cannot be greater than Available Amount.', 'error');
            return;
        }

        // ✅ Mandatory
        if (!this.editDisbursementBankId) {
            this.toast('Error', 'Disbursement Bank is required.', 'error');
            return;
        }
        

        this.isLoading = true;
        try {
            await updateTranches({
                applicationId: this.recordId,
                updates: [
                    {
                        Id: this.editTrancheId,
                        Disbursal_Date__c: this.editDisbursalDate,
                        Disbursal_Amount__c: newAmt,
                        
                        PrincipalRecovery__c: this.editPrincipalRecovery,
                        PrincipalRecoveryFrom__c: this.editPrincipalRecoveryFrom,
                        PrincipalRecoveryOn__c: this.editPrincipalRecoveryOn,
                        Disbursement_Bank__c: this.editDisbursementBankId,
                        Status__c: this.editStatus
                    }
                ]
            });

            this.toast('Success', 'Tranche updated.', 'success');
            this.closeEditModal();
            await this.load();
        } catch (e) {
            this.toast('Error', this.normalizeError(e), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ---------- Delete ----------
    openDeleteModal(row) {
        this.deleteTrancheId = row.id;
        this.deleteTrancheName = row.trancheId;
        this.showDeleteModal = true;
    }

    closeDeleteModal() {
        this.showDeleteModal = false;
        this.deleteTrancheId = null;
        this.deleteTrancheName = null;
    }

    async handleDeleteConfirm() {
        if (!this.deleteTrancheId) return;

        this.isLoading = true;
        try {
            await deleteTranche({
                applicationId: this.recordId,
                trancheId: this.deleteTrancheId
            });

            if (this.selectedTrancheId === this.deleteTrancheId) {
                this.selectedTrancheId = null;
                this.selectedTrancheName = null;
            }

            this.toast('Success', 'Tranche deleted.', 'success');
            this.closeDeleteModal();
            await this.load();
        } catch (e) {
            this.toast('Error', this.normalizeError(e), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ---------- Utils ----------
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    normalizeError(e) {
        if (!e) return 'Unknown error';
        if (Array.isArray(e?.body)) return e.body.map(x => x.message).join(', ');
        return e?.body?.message || e?.message || 'Unknown error';
    }
}