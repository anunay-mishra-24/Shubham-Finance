import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ShfNegotiationDetail extends LightningElement {
    isLoading = false;

    // After submit -> disable Save/Reset/Submit
    hasSubmitted = false;
    showSubmitSuccessMessage = false;

    // Save gating: Submit enabled only after successful Save
    hasSavedSuccessfully = false;
    hasUnsavedChanges = false;

    // Modal controls
    showReasonModal = false;
    showSubmitConfirmModal = false;

    // Editable values (these will map to "Negotiation*" fields later)
    editableValues = {
        sanctionLoanAmount: '',
        tenure: '',
        roi: '',
        processingFee: '',
        processingFeePercent: '',
        insuranceApplicant1: { insuredAmount: '', insurancePremium: '', insuranceTenure: '' },
        insuranceApplicant2: { insuredAmount: '', insurancePremium: '', insuranceTenure: '' }
    };

    // Requested values (read-only bottom section) - "Negotiation*" values
    requestedValues = {
        sanctionLoanAmount: '',
        tenure: '',
        roi: '',
        processingFee: '',
        processingFeePercent: '',
        insuranceApplicant1: { insuredAmount: '', insurancePremium: '', insuranceTenure: '' },
        insuranceApplicant2: { insuredAmount: '', insurancePremium: '', insuranceTenure: '' }
    };

    // Reasons for modified fields
    changeReasons = {
        sanctionLoanAmount: '',
        tenure: '',
        roi: '',
        processingFee: '',
        processingFeePercent: '',
        applicant1_insuredAmount: '',
        applicant1_insurancePremium: '',
        applicant1_insuranceTenure: '',
        applicant2_insuredAmount: '',
        applicant2_insurancePremium: '',
        applicant2_insuranceTenure: ''
    };

    // --- UI State getters ---
    get isSaveDisabled() {
        return this.isLoading || this.hasSubmitted || !this.hasUnsavedChanges;
    }
    get isResetDisabled() {
        return this.isLoading || this.hasSubmitted;
    }
    get isSubmitDisabled() {
        return this.isLoading || this.hasSubmitted || !this.hasSavedSuccessfully || this.hasUnsavedChanges;
    }

    // --- Reason modal "only modified fields" booleans (Top) ---
    get showReasonSanctionLoanAmount() { return this.isFieldModified('sanctionLoanAmount'); }
    get showReasonTenure() { return this.isFieldModified('tenure'); }
    get showReasonRoi() { return this.isFieldModified('roi'); }
    get showReasonProcessingFee() { return this.isFieldModified('processingFee'); }
    get showReasonProcessingFeePercent() { return this.isFieldModified('processingFeePercent'); }

    // --- Reason modal booleans (Insurance Applicant 1) ---
    get showReasonApplicant1InsuredAmount() { return this.isInsuranceFieldModified('insuranceApplicant1', 'insuredAmount'); }
    get showReasonApplicant1InsurancePremium() { return this.isInsuranceFieldModified('insuranceApplicant1', 'insurancePremium'); }
    get showReasonApplicant1InsuranceTenure() { return this.isInsuranceFieldModified('insuranceApplicant1', 'insuranceTenure'); }

    // --- Reason modal booleans (Insurance Applicant 2) ---
    get showReasonApplicant2InsuredAmount() { return this.isInsuranceFieldModified('insuranceApplicant2', 'insuredAmount'); }
    get showReasonApplicant2InsurancePremium() { return this.isInsuranceFieldModified('insuranceApplicant2', 'insurancePremium'); }
    get showReasonApplicant2InsuranceTenure() { return this.isInsuranceFieldModified('insuranceApplicant2', 'insuranceTenure'); }

    // ---------------- Handlers ----------------
    connectedCallback() {
    // initial baseline = requestedValues (read-only) same as editable
    this.requestedValues = this.deepClone(this.editableValues);
    this.hasUnsavedChanges = false;
    this.hasSavedSuccessfully = false;
}
    handleTopFieldChange(event) {
        const fieldKey = event.target.dataset.field;
        const newValue = event.detail.value;

        this.editableValues = { ...this.editableValues, [fieldKey]: newValue };

        this.applyInlineValidations();
        this.hasUnsavedChanges = true;
        this.hasSavedSuccessfully = false;
    }

    handleInsuranceFieldChange(event) {
        const rowKey = event.target.dataset.row; 
        const columnKey = event.target.dataset.col; // insuredAmount / insurancePremium / insuranceTenure
        const newValue = event.detail.value;

        const updatedRow = { ...this.editableValues[rowKey], [columnKey]: newValue };
        this.editableValues = { ...this.editableValues, [rowKey]: updatedRow };

        this.applyInlineValidations();
        this.hasUnsavedChanges = true;
        this.hasSavedSuccessfully = false;
    }

    handleSaveClick() {
        if (this.hasSubmitted) return;

        // Inline validations first
        const valid = this.applyInlineValidations();
        if (!valid) {
            this.toast('Validation Error', 'Please correct the highlighted errors.', 'error');
            return;
        }

        // Must have at least one modified field
        if (!this.hasAnyModifiedField()) {
            this.toast('No Changes', 'No changes detected. Nothing to save.', 'info');
            return;
        }

        // Open reason modal only for modified fields
        this.showReasonModal = true;
    }

    handleResetClick() {
        if (this.hasSubmitted) return;

        // Reset editable to last requested (saved) values
        this.editableValues = this.deepClone(this.requestedValues);

        // Clear validity messages on inputs
        this.clearInlineValidity();

        // Reset flags (after reset, there are no unsaved changes)
        this.hasUnsavedChanges = false;

        // Submit should remain enabled only if last action was a successful save
        // (we keep hasSavedSuccessfully as-is)
    }

    handleSubmitClick() {
        if (this.hasSubmitted) return;

        if (!this.hasSavedSuccessfully || this.hasUnsavedChanges) {
            this.toast('Error', 'Please save your changes before submitting for approval.', 'error');
            return;
        }

        this.showSubmitConfirmModal = true;
    }

    closeSubmitConfirmModal() {
        this.showSubmitConfirmModal = false;
    }

    confirmSubmit() {
        // For now UI only (Apex/flow mapping later)
        this.showSubmitConfirmModal = false;

        this.hasSubmitted = true;
        this.showSubmitSuccessMessage = true;

        // Disable all actions
        this.hasUnsavedChanges = false;
        this.hasSavedSuccessfully = false;

        this.toast('Success', 'Submitted for approval successfully.', 'success');
    }

    // -------- Reason Modal handlers --------
    closeReasonModal() {
        this.showReasonModal = false;
    }

    handleReasonTextChange(event) {
        const reasonKey = event.target.dataset.reason;
        const reasonValue = event.detail.value;
        this.changeReasons = { ...this.changeReasons, [reasonKey]: reasonValue };
    }

    proceedSaveWithReasons() {
        // Validate all visible reason textareas are filled
        const allReasonInputs = this.template.querySelectorAll('lightning-textarea');
        let allReasonsValid = true;

        allReasonInputs.forEach((t) => {
            // Only validate those currently rendered (visible ones exist in DOM)
            if (!t.checkValidity()) {
                t.reportValidity();
                allReasonsValid = false;
            }
        });

        if (!allReasonsValid) {
            this.toast('Validation Error', 'Please provide reasons for all modified fields.', 'error');
            return;
        }

        // Save requestedValues (this will map to "Negotiation*" fields later)
        this.requestedValues = this.deepClone(this.editableValues);

        // Mark state
        this.showReasonModal = false;
        this.hasUnsavedChanges = false;
        this.hasSavedSuccessfully = true;

        this.toast('Success', 'Saved successfully.', 'success');

        // NOTE: Later we will call Apex to save:
        // - Negotiation* fields
        // - per-field reason fields
    }

    // ---------------- Validation helpers ----------------
    applyInlineValidations() {
        let allValid = true;

        // Validate all lightning-inputs in the form
        const inputs = this.template.querySelectorAll('lightning-input');
        inputs.forEach((input) => {
            const value = input.value;

            // Required check
            if (input.required && (value === null || value === undefined || value === '')) {
                input.setCustomValidity('This field is required.');
                input.reportValidity();
                allValid = false;
                return;
            }

            // Number > 0 check (no 0 / negative)
            const num = Number(value);
            if (!Number.isNaN(num)) {
                if (num <= 0) {
                    input.setCustomValidity('Value must be greater than 0.');
                    input.reportValidity();
                    allValid = false;
                    return;
                }
            }

            // Percent fields <= 100
            const fieldKey = input.dataset.field;
            if (fieldKey === 'roi' || fieldKey === 'processingFeePercent') {
                if (!Number.isNaN(num) && num > 100) {
                    input.setCustomValidity('Value must be less than or equal to 100.');
                    input.reportValidity();
                    allValid = false;
                    return;
                }
            }

            input.setCustomValidity('');
            input.reportValidity();
        });

        return allValid;
    }

    clearInlineValidity() {
        const inputs = this.template.querySelectorAll('lightning-input');
        inputs.forEach((input) => {
            input.setCustomValidity('');
            input.reportValidity();
        });
    }

    // ---------------- Modified field detection ----------------
    hasAnyModifiedField() {
        // Top fields
        if (this.isFieldModified('sanctionLoanAmount')) return true;
        if (this.isFieldModified('tenure')) return true;
        if (this.isFieldModified('roi')) return true;
        if (this.isFieldModified('processingFee')) return true;
        if (this.isFieldModified('processingFeePercent')) return true;

        // Insurance fields
        if (this.isInsuranceFieldModified('insuranceApplicant1', 'insuredAmount')) return true;
        if (this.isInsuranceFieldModified('insuranceApplicant1', 'insurancePremium')) return true;
        if (this.isInsuranceFieldModified('insuranceApplicant1', 'insuranceTenure')) return true;

        if (this.isInsuranceFieldModified('insuranceApplicant2', 'insuredAmount')) return true;
        if (this.isInsuranceFieldModified('insuranceApplicant2', 'insurancePremium')) return true;
        if (this.isInsuranceFieldModified('insuranceApplicant2', 'insuranceTenure')) return true;

        return false;
    }

    isFieldModified(fieldKey) {
        return this.normalize(this.editableValues[fieldKey]) !== this.normalize(this.requestedValues[fieldKey]);
    }

    isInsuranceFieldModified(rowKey, columnKey) {
        return this.normalize(this.editableValues[rowKey][columnKey]) !== this.normalize(this.requestedValues[rowKey][columnKey]);
    }

    normalize(value) {
        if (value === null || value === undefined) return '';
        return String(value).trim();
    }

    deepClone(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}