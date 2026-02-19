import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class GenericEmploymentLauncher extends NavigationMixin(LightningElement) {
    @api parentId;       // Loan_Applicant__c Id from Flow
    @api applicantType;  // "Individual" / "Non_Individual"

    connectedCallback() {
        
        let defaultValues = `Loan_Applicant__c=${this.parentId}`;


        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Employment__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues
            }
        });
    }
}