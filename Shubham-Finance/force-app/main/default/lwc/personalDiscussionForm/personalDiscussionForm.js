import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import savePDRecord from '@salesforce/apex/SHF_PersonalDiscussionController.savePDRecord';
import getLoanApplicantsWithoutSalesPD from '@salesforce/apex/SHF_PersonalDiscussionController.getLoanApplicantsWithoutSalesPD';
import getPDRecordDetails from '@salesforce/apex/SHF_PersonalDiscussionController.getPDRecordDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PersonalDiscussionForm extends NavigationMixin(LightningElement) {
    @api recordId;

    @track pdRec = this.getEmptyPDRec();

    applicantDataMap = {};
    @track loanApplicantOptions = [];
    @track selectedEmploymentType = '';

    @track showSelfEmpSection = false;
    @track showSalSection = false;
    @track showQ2 = false;
    @track showQ3 = false;
    @track showQ4 = false;

    @track isLoading = false;
    @track isModalOpen = false;
    @track isViewDetailOpen = false;
    @track pdDetailRec;

    hasApplicants = false;

    yesNoOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    employmentOptions = [
        { label: 'Self-Employed', value: 'Self-Employed' },
        { label: 'Salaried', value: 'Salaried' }
    ];

    // ---------------- WIRE ----------------
    @wire(getLoanApplicantsWithoutSalesPD, { applicationId: '$recordId' })
    wiredLoanApplicants({ data, error }) {
        if (data) {
            this.hasApplicants = data.length > 0;
            this.loanApplicantOptions = [];
            this.applicantDataMap = {};

            data.forEach(app => {
                this.applicantDataMap[app.Id] = app.Employment_Type__c;
                this.loanApplicantOptions.push({
                    label: app.Account_Name__c,
                    value: app.Id
                });
            });
        } else if (error) {
            this.showToast('Error', 'Failed to load loan applicants.', 'error');
        }
    }

    // ---------------- MODAL ----------------
    openModal() {
        if (!this.hasApplicants) {
            this.showToast(
                'Error',
                'The Sales PD has been created for all the applicants.',
                'error'
            );
            return;
        }
        this.isModalOpen = true;
    }

    closeModal() {
        this.resetForm();
        this.isModalOpen = false;
    }

    // ---------------- VIEW DETAILS ----------------
    async handleViewDetail(event) {
        try {
            this.pdDetailRec = await getPDRecordDetails({ pdId: event.detail.recordId });
            this.isViewDetailOpen = true;
        } catch (e) {
            this.showToast('Error', 'Failed to load details.', 'error');
        }
    }

    closeViewDetail() {
        this.isViewDetailOpen = false;
        this.pdDetailRec = null;
    }

    // ---------------- CHANGE HANDLER ----------------
    handlePicklistChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.pdRec = { ...this.pdRec, [field]: value };

        // Loan Applicant selected
        if (field === 'Loan_Applicant__c') {
            this.selectedEmploymentType = this.applicantDataMap[value] || '';
            this.pdRec.Are_you_salaried_or_self_employed__c = this.selectedEmploymentType;

            this.showQ2 = true;
            this.showSelfEmpSection = this.selectedEmploymentType === 'Self-Employed';
            this.showSalSection = this.selectedEmploymentType === 'Salaried';
            this.showQ3 = false;
            this.showQ4 = false;

            this.clearDependentFields();
            return;
        }

        // Self-Employed flow
        if (this.showSelfEmpSection) {
            if (field === 'Is_the_GST_Report_available__c') {
                this.showQ3 = value === 'No';
                this.showQ4 = false;
            }
            if (field === 'Is_BankStatement_avail_for_BankSurrogate__c') {
                this.showQ4 = value === 'No';
            }
        }

        // Salaried flow
        if (this.showSalSection) {
            if (field === 'Is_the_last_2_month_salary_slip_availabl__c') {
                this.showQ3 = value === 'No';
                this.showQ4 = false;
            }
            if (field === 'Is_Form_16_available__c') {
                this.showQ4 = value === 'No';
            }
        }
    }

    // ---------------- SAVE ----------------
    async handleSave() {
        if (!this.isFormValid()) {
            this.showToast('Error', 'Please fill all mandatory questions.', 'error');
            return;
        }

        this.isLoading = true;
        try {
            this.pdRec.Application__c = this.recordId;
            await savePDRecord({ pdRec: this.pdRec });

            this.showToast('Success', 'Personal Discussion record saved successfully.', 'success');
            this.closeModal();
        } catch (e) {
            this.showToast('Error', e?.body?.message || 'Unexpected error', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ---------------- HELPERS ----------------
    isFormValid() {
        const p = this.pdRec;
        if (!p.Loan_Applicant__c || !p.Are_you_salaried_or_self_employed__c) return false;

        if (this.showSalSection) {
            if (!p.Is_the_last_2_month_salary_slip_availabl__c) return false;
            if (this.showQ3 && !p.Is_Form_16_available__c) return false;
            if (this.showQ4 && !p.Is_salary_credited_in_Bank_Account__c) return false;
        }

        if (this.showSelfEmpSection) {
            if (!p.Is_the_GST_Report_available__c) return false;
            if (this.showQ3 && !p.Is_BankStatement_avail_for_BankSurrogate__c) return false;
            if (this.showQ4 && !p.Can_Customer_Income_be_assessed__c) return false;
        }

        return true;
    }

    clearDependentFields() {
        Object.assign(this.pdRec, {
            Is_the_GST_Report_available__c: '',
            Is_BankStatement_avail_for_BankSurrogate__c: '',
            Can_Customer_Income_be_assessed__c: '',
            Is_Form_16_available__c: '',
            Is_the_last_2_month_salary_slip_availabl__c: '',
            Is_salary_credited_in_Bank_Account__c: ''
        });
    }

    resetForm() {
        this.pdRec = this.getEmptyPDRec();
        this.showSelfEmpSection = false;
        this.showSalSection = false;
        this.showQ2 = false;
        this.showQ3 = false;
        this.showQ4 = false;
    }

    getEmptyPDRec() {
        return {
            Are_you_salaried_or_self_employed__c: '',
            Is_BankStatement_avail_for_BankSurrogate__c: '',
            Can_Customer_Income_be_assessed__c: '',
            Is_Form_16_available__c: '',
            Is_the_last_2_month_salary_slip_availabl__c: '',
            Is_salary_credited_in_Bank_Account__c: '',
            Is_the_GST_Report_available__c: '',
            Loan_Applicant__c: '',
            Application__c: ''
        };
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}