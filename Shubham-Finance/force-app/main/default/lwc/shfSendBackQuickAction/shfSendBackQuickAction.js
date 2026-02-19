import { LightningElement, api, track } from 'lwc';
import getInitData from '@salesforce/apex/SHF_MovetoPreviousStages.getInitData';
import getReasonOptions from '@salesforce/apex/SHF_MovetoPreviousStages.getReasonOptions';
import sendBack from '@salesforce/apex/SHF_MovetoPreviousStages.sendBack';
import getUserOptions from '@salesforce/apex/SHF_MovetoPreviousStages.getUserOptions';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';
import LightningConfirm from 'lightning/confirm';

export default class ShfSendBackQuickAction extends LightningElement {
  _recordId;
  _isConnected = false;

  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(val) {
    this._recordId = val;
    if (this._isConnected && this._recordId) {
      this.loadInit();
    }
  }

  @track stageOptions = [];
  @track userOptions = [];
  @track reasonOptions = [];

  currentStage;
  currentRecordTypeDevName;

  selectedStage;
  selectedUserId;
  selectedReason;
  remarks = '';

  isLoading = true;
  isSaving = false;

  connectedCallback() {
    this._isConnected = true;
    if (this.recordId) {
      this.loadInit();
    } else {
      this.isLoading = false;
    }
  }

  get showSpinner() {
    return this.isLoading || this.isSaving;
  }

  get noStageOptions() {
    return !this.isLoading && (!this.stageOptions || this.stageOptions.length === 0);
  }

  get noReasonOptions() {
    return (
      !this.isLoading &&
      !!this.selectedStage &&
      (!this.reasonOptions || this.reasonOptions.length === 0)
    );
  }

  get disableReason() {
    return this.isLoading || !this.selectedStage || this.noReasonOptions;
  }

  get disableSave() {
    if (this.isLoading || this.isSaving || this.noStageOptions) return true;
    if (!this.selectedStage || !this.selectedUserId) return true;
    if (!this.remarks || !this.remarks.trim()) return true;

    // Reason is ALWAYS mandatory now
    if (!this.reasonOptions || this.reasonOptions.length === 0) return true;
    if (!this.selectedReason) return true;

    return false;
  }

  async loadInit() {
    this.isLoading = true;

    this.stageOptions = [];
    this.userOptions = [];
    this.reasonOptions = [];
    this.selectedStage = null;
    this.selectedUserId = null;
    this.selectedReason = null;
    this.remarks = '';

    try {
      const data = await getInitData({ applicationId: this.recordId });

      this.currentStage = data?.currentStage;
      this.currentRecordTypeDevName = data?.currentRecordTypeDevName;

      this.stageOptions = (data?.stageOptions || []).map((x) => ({
        label: x.label,
        value: x.value
      }));

      this.userOptions = (data?.userOptions || []).map((x) => ({
        label: x.label,
        value: x.value
      }));
    } catch (error) {
      this.showToast(
        'Error',
        error?.body?.message || error?.message || 'Failed to load data.',
        'error'
      );
      console.error('getInitData error', error);
    } finally {
      this.isLoading = false;
    }
  }

  async handleStageChange(event) {
    this.selectedStage = event.detail.value;

    // reset reason
    this.selectedReason = null;
    this.reasonOptions = [];
    this.selectedUserId = null;
    this.userOptions = [];

    if (!this.selectedStage) return;

    try {
      const [users, reasons] = await Promise.all([
      getUserOptions({
        applicationId: this.recordId,
        targetStage: this.selectedStage
      }),
      getReasonOptions({
        fromStage: this.currentStage,
        toStage: this.selectedStage
      })
    ]);

    this.userOptions = (users || []).map(x => ({ label: x.label, value: x.value }));
    this.reasonOptions = (reasons || []).map(x => ({ label: x.label, value: x.value }));
  } catch (e) {
    this.userOptions = [];
    this.reasonOptions = [];
    this.showToast('Error', e?.body?.message || e?.message || 'Failed to refresh users/reasons.', 'error');
    console.error('handleStageChange refresh error', e);
  }
  }

  handleUserChange(event) {
    this.selectedUserId = event.detail.value;
  }

  handleReasonChange(event) {
    this.selectedReason = event.detail.value;
  }

  handleRemarksChange(event) {
    this.remarks = event.detail.value;
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  async handleSave() {
    if (!this.selectedStage) return this.showToast('Error', 'Target Stage is mandatory.', 'error');
    if (!this.selectedUserId) return this.showToast('Error', 'User is mandatory.', 'error');
    if (!this.selectedReason) return this.showToast('Error', 'Send Back Reason is mandatory.', 'error');
    if (!this.remarks || !this.remarks.trim()) return this.showToast('Error', 'Remarks is mandatory.', 'error');

    const confirmed = await LightningConfirm.open({
      message:
        'On clicking the save button the Loan application owner and stage shall be changed. Are you sure?',
      label: 'Confirm',
      variant: 'headerless',
      okLabel: 'Submit',
      cancelLabel: 'Cancel'
    });

    if (!confirmed) return;

    this.isSaving = true;
    try {
      await sendBack({
        applicationId: this.recordId,
        targetStage: this.selectedStage,
        targetUserId: this.selectedUserId,
        sendBackReason: this.selectedReason,
        remarks: this.remarks
      });

      getRecordNotifyChange([{ recordId: this.recordId }]);
      this.dispatchEvent(new RefreshEvent());

      await this.loadInit();
      this.showToast('Success', 'Application sent back successfully.', 'success');
      this.dispatchEvent(new CloseActionScreenEvent());
    } catch (e) {
      this.showToast('Error', e?.body?.message || e?.message || 'Failed to send back.', 'error');
      console.error('sendBack error', e);
    } finally {
      this.isSaving = false;
    }
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}