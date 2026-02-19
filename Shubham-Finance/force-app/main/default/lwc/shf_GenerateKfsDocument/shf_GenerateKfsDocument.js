import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

// Apex Methods
import getVFPageName from '@salesforce/apex/SHF_GenerateKFSDocumentController.getVFPageName';
import getPrimaryApplicantLanguage from '@salesforce/apex/SHF_GenerateKFSDocumentController.getPrimaryApplicantLanguage';
import createKfsDocumentRecord from '@salesforce/apex/SHF_GenerateKFSDocumentController.createKfsDocumentRecord';


const FIELDS = [
    'Application__c.E_Sign_Executed__c', 'Application__c.E_Sign_Success__c'
];


export default class Shf_GenerateKfsDocument extends LightningElement {

    @api recordId;

    @track kfsVFUrl;
    @track isLoading = true;

    isInitialized = false;

    eSignExecuted;
    eSignSuccess;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredApplication({ data, error }) {
        if (data) {
            const { E_Sign_Executed__c, E_Sign_Success__c } = data.fields;
            this.eSignExecuted = E_Sign_Executed__c.value;
            this.eSignSuccess = E_Sign_Success__c.value;
            if (!this.eSignExecuted) {
                this.showToast('Error', 'E-Sign must be initiated before creating a manual signed document or progressing to the next stage', 'error');
                this.isLoading = false;
                this.dispatchEvent(new CloseActionScreenEvent());
            }

        } else if (error) {
            console.error('wiredApplication : error --> ' + JSON.stringify(error));
        }
    }

    // Quick Action RecordId Fix
    @wire(CurrentPageReference)
    async getStateParameters(currentPageReference) {

        if (this.isInitialized) return;

        if (currentPageReference) {

            this.recordId =
                currentPageReference.state?.recordId ||
                currentPageReference.state?.c__recordId;

            console.log('RecordId => ', this.recordId);

            if (this.recordId) {
                if (!this.eSignExecuted) {
                    this.showToast('Error', 'E-Sign must be initiated before creating a manual signed document or progressing to the next stage', 'error');
                    this.isLoading = false;
                    this.dispatchEvent(new CloseActionScreenEvent());
                } else {
                    this.isInitialized = true;
                    await this.loadKfsPreview();
                }
            }
        }
    }

    // Main Logic
    async loadKfsPreview() {

        try {

            // Step 1: Get Primary Applicant Language
            const language = await getPrimaryApplicantLanguage({
                applicationId: this.recordId
            });

            console.log('Language => ', language);

            // Step 2: Get VF Page Name
            const vfPage = await getVFPageName({
                applicationId: this.recordId,
                language: language
            });

            console.log('VF Page => ', vfPage);

            // Step 3: Load VF Preview URL
            this.kfsVFUrl = `/apex/${vfPage}?id=${this.recordId}`;

            // Step 4: Auto Create Document Record
            await createKfsDocumentRecord({
                applicationId: this.recordId
            });

            this.showToast(
                'Success',
                'KFS Document Generated Successfully',
                'success'
            );

        } catch (e) {

            console.error('ERROR => ', JSON.stringify(e));

            this.showToast(
                'Error',
                e?.body?.message || 'Unable to load KFS preview',
                'error'
            );
        }

        this.isLoading = false;
    }

    // Toast Utility
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}