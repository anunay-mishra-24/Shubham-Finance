import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
// import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export default class GenericNewRecordNavigator extends NavigationMixin(LightningElement) {
    // @api objectApiName; 

    // hasNavigated = false;
    // @api recordTypeId;
    hasRedirected = false;
    connectedCallback() {
        console.log('OUTPUT 21 : ');
        // sessionStorage.setItem('EmploymentRedirected', 'false');
        if (sessionStorage.getItem('EmploymentRedirected') === 'true') {
            return; // stop repeating
        }

        // Mark as navigated
            this.createRecordWithType();
        sessionStorage.setItem('EmploymentRedirected', 'true');
    }
    
    createRecordWithType() {
        console.log('Inside createrecord : ');
        const defaultValues =  {
            Type_of_Employment__c: 'Individual'
        };

        let url = this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Employment__c",
                actionName: "new"
            },
            state: {
                defaultFieldValues: defaultValues
                // recordTypeId: this.recordTypeId
            }
        });
        console.log('Generated URL:', url);
        window.location.href = '/apex/EmploymentNewOverride?url=' + encodeURIComponent(url);
    }


    // @api createRecordUrl() {
    //     const defaultValues =  encodeDefaultFieldValues({
    //         Type_of_Employment__c: 'Individual'
    //     });

    //     // Generate the Lightning "New" URL
    //     console.log('OUTPUT : ');
    //     const url = this[NavigationMixin.Navigate]({
    //         type: 'standard__objectPage',
    //         attributes: {
    //             objectApiName: 'Employment__c',
    //             actionName: 'new'
    //         },
    //         state: {
    //             defaultFieldValues: defaultValues
    //         }
    //     });

    //     console.log('Generated URL:', url);

    //     // Redirect to the VF page with the generated URL
    //    // window.location.href = '/apex/EmploymentNewOverride?url=' + encodeURIComponent(url);
    // }
}