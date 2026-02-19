import { LightningElement, wire ,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import executeBRE from '@salesforce/apex/SHF_BusinessRuleEngine.executeBRE';

export default class Shf_ExecuteBRE extends LightningElement {
 @api recordId;
    isLoading = false;

    @wire(CurrentPageReference)
    getAddressId(currentPageReference) {
        if (currentPageReference?.state?.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference?.attributes?.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }

        console.log('recordId -> ', this.recordId);
        this.handleExecute();
    }

    handleExecute() {
        this.isLoading = true;

        executeBRE({ applicationId: this.recordId })
            .then(result => {
                console.log('BRE Result:', result);

                if(result === 'Success') {
                    this.showToast('Success', 'The BRE has been executed successfully and the deviations as per latest inputs are available.', 'success');
                    setTimeout(() => {
                window.location.reload();
            }, 600);
                } else {
                    this.showToast('Warning', 'BRE returned: ' + result, 'warning');
                }
            })
            .catch(error => {
                console.error('BRE Error:', JSON.stringify(error));
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
                 this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title, message, variant
            })
        );
    }
}