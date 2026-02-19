import { LightningElement, api, track } from 'lwc';
import getLoanApplicants from '@salesforce/apex/SHF_FinancialCalculatorController.getLoanApplicants';
import getSavedIncomeProgram from '@salesforce/apex/SHF_FinancialCalculatorController.getSavedIncomeProgram';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ShfFinancialCalculator extends LightningElement {
    @api recordId;

    @track existingLoanApplicant = [];
    @track applicantIncomeType;
    @track selectedBorrowerId = '';
    @track selectedIncomeProgram = '';
    @track IncomeProgramValues = [];
    @track showIncomeType = true;

    @track spinnerActive = false;
    @track showCustomerData = true;
    @track isBorrowerSubmitted = false;

    get isIncomeProgramDisabled() {
        return !this.selectedBorrowerId;
    }

    connectedCallback() {
        console.log('FinancialCalculator connected', this.recordId);
        this.fetchLoanApplicants();
    }

    fetchLoanApplicants() {
        this.spinnerActive = true;
        getLoanApplicants({ applicationId: this.recordId })
            .then(result => {
                this.existingLoanApplicant = result.map(r => ({
                    label: r.name,
                    value: r.id,
                    customerProfile: r.customerProfile 
                }));
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.spinnerActive = false;
            });
    }

    handleChange(event) {
        this.selectedBorrowerId = event.detail.value;
        this.selectedIncomeProgram = ''; // Reset selection

        const selected = this.existingLoanApplicant.find(
            x => x.value === this.selectedBorrowerId
        );

        if (selected) {
            this.applicantIncomeType = selected.customerProfile;
            
            // 1. Set the allowed options based on profile
            this.setIncomePrograms(this.applicantIncomeType);
            
            // 2. Then try to auto-populate
            this.autoPopulateCalculator(this.selectedBorrowerId);
        } else {
            this.applicantIncomeType = '';
            this.IncomeProgramValues = [];
        }
    }

    setIncomePrograms(profile) {
        let options = [];

        if (profile === 'Formal Salaried' || 
            profile === 'Informal Salaried- Cash' || 
            profile === 'Informal Salaried- Bank Credit') {
            
            options = [
                { label: 'Common Income Program', value: 'Final_Eligibility_Calculator' }
            ];

        } else if (profile === 'Self Employed- Informal') {
            
            options = [
                { label: 'Self Employed - Assessed Income', value: 'Self_Employed_Assessed' }
            ];

        } else if (profile === 'Self Employed- GST/ITR') {
            
            options = [
                { label: 'GST Program', value: 'GST_Program' },
                { label: 'ITR', value: 'ITR' }
            ];

        } else if (profile === 'Self Employed- Banking Surrogate') {
            
            options = [
                { label: 'ABB Surrogate Program', value: 'ABB_Surrogate' }
            ];

        } else {
            options = [];
        }

        this.IncomeProgramValues = options;
    }

    autoPopulateCalculator(loanAppId) {
        this.spinnerActive = true;
        getSavedIncomeProgram({ loanApplicantId: loanAppId })
            .then(savedProgram => {
                if (savedProgram) {
                    console.log('Found saved program:', savedProgram);
                    let programToSet = '';

                    // Normalize saved value to LWC value
                    if (['Self_Employed_Retail', 'Self_Employed_Contract', 'Self_Employed_Manual', 'Self_Employed_Service'].includes(savedProgram)) {
                        programToSet = 'Self_Employed_Assessed';
                    } else if (savedProgram === 'GST Program' || savedProgram === 'GST_Program') {
                        programToSet = 'GST_Program';
                    } else if (savedProgram === 'ITR') {
                        programToSet = 'ITR';
                    } else if (savedProgram === 'ABB Surrogate' || savedProgram === 'ABB_Surrogate') {
                        programToSet = 'ABB_Surrogate';
                    } else if (savedProgram === 'Common Income Program' || savedProgram === 'Final_Eligibility_Calculator') {
                        programToSet = 'Final_Eligibility_Calculator';
                    } else {
                        programToSet = savedProgram;
                    }

                    const isValidOption = this.IncomeProgramValues.some(opt => opt.value === programToSet);
                    if (isValidOption) {
                        this.selectedIncomeProgram = programToSet;
                    } else {
                        console.warn('Saved program is not valid for this customer profile:', programToSet);
                        this.selectedIncomeProgram = '';
                    }
                }
            })
            .catch(error => {
                console.error(error);
            })
            .finally(() => {
                this.spinnerActive = false;
            });
    }

    handleIncomeProgramChange(event) {
        this.selectedIncomeProgram = event.detail.value;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    handleClick(event) {
        let clickedButton = event.target.label;

        if (clickedButton === 'Submit') {
            if (!this.selectedBorrowerId || !this.selectedIncomeProgram) {
                this.showToast('Error', 'All fields are mandatory', 'error');
                return;
            }

            this.spinnerActive = true;

            try {
                this.dispatchEvent(
                    new CustomEvent('borrowersubmit', {
                        detail: {
                            borrowerId: this.selectedBorrowerId,
                            incomeProgram: this.selectedIncomeProgram
                        }
                    })
                );
                this.isBorrowerSubmitted = true;

            } catch (error) {
                console.error('Error dispatching event:', error);
                this.showToast('Error', 'Something went wrong while submitting', 'error');
            } finally {
                this.spinnerActive = false;
            }
            return;
        }

        if (clickedButton === 'Clear') {
            this.selectedBorrowerId = '';
            this.applicantIncomeType = '';
            this.selectedIncomeProgram = '';
            this.IncomeProgramValues = []; 
            this.isBorrowerSubmitted = false;
            this.dispatchEvent(new CustomEvent('borrowerclear'));
            this.showToast('Info', 'Fields cleared', 'info');
        }
    }
}