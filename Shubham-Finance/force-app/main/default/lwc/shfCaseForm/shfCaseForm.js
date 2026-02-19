import { LightningElement, api, track } from 'lwc';

export default class ShfCaseForm extends LightningElement {
    _selectedApplicationId;
    _selectedApplicationName;

    @track hasSelectedApplication = false;
    @track searchCriteriaAvailable = false;

    @api 
    get selectedApplicationId() {
        return this._selectedApplicationId;
    }
    set selectedApplicationId(value) {
        this._selectedApplicationId = value;
        this.hasSelectedApplication = !!value;
        this.searchCriteriaAvailable = this.hasSelectedApplication;
    }

    @api 
    get selectedApplicationName() {
        return this._selectedApplicationName;
    }
    set selectedApplicationName(value) {
        this._selectedApplicationName = value;
    }

    // Prepare default field values for the form
    get defaultFieldValues() {
        return {
            Search_Criteria_Available__c: this.hasSelectedApplication,
            Application__c: this.hasSelectedApplication ? this.selectedApplicationId : null
        };
    }

    handleSuccess(event) {
        const caseId = event.detail.id;
        this.dispatchEvent(new CustomEvent('casesuccess', { detail: caseId }));
    }
}