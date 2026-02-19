import { LightningElement, api, wire, track } from 'lwc';
import LightningToast from 'lightning/toast';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
// import USER_ID from '@salesforce/user/Id'; //Added by Ranjeet
import { getRecord } from 'lightning/uiRecordApi';  //Added by Ranjeet
const Application_Fields = ['Application__c.Application_Stage__c'];  //Added by Ranjeet
import getApplicants from '@salesforce/apex/SHF_DisplayDocumentsController.getLoanApplicantRecords';

export default class shfDisplayDocuments extends LightningElement {
    @api recordId;
    @track loanApplicantList = [];
    @track wiredApplicantResult;
    @track isRecordFound = true;
    @track buttonLabel = 'New';
    @track sendLinkToCustomerBtn  = 'Send link to Customer' //   <!-- Added By Ranjeet Pandit on 05/01/2026 -->
    // @track showSendLinkButton = false; // Added By Ranjeet Pandit
    @track showunUploadedDocumentModal = false;
    @track showDocumentModal = false;
    @track newButtonDisable = false;
    hideNew = false;

    @wire(getApplicants, { applicationId: '$recordId' })
    wiredApplicants({ error, data }) {
        if (data) {
            console.log('OUTPUT: loan applicant data:', data);
            if (data.isSuccess) {
                const tempList = JSON.parse(data.responseBody);
                const formattedList = tempList.map(applicant => {
                    let displayName = applicant.Name;

                    return {
                        ...applicant,
                        displayName
                    };
                    
                });

                // Add "Application" as the first tab
                this.loanApplicantList = [{ Name: 'Application', Id: '', displayName: 'Application Documents' }, ...formattedList];

                console.log('Final Applicant List with displayName:', this.loanApplicantList);
            } else {
                this.isRecordFound = false;
                console.log('No record found. Data:', data);
            }
        } else if (error) {
            console.error('Error fetching applicants:', error);
        }
    }
    

    //Added by Ranjeet Pandit 
    @wire(getRecord, { recordId: '$recordId' ,fields: Application_Fields})   
    wiredApplication({ error, data }) {
        if (data) {
            const stage = data.fields.Application_Stage__c.value;
            console.log('Application Stage==>',stage);
            // this.showSendLinkButton = stage === 'QDE'
        }
        if(error) {
            console.error('Error fetching application record', error);
        }
    }
   /* get disableSendLinkButton() {
     return !this.showSendLinkButton;
    }*/
    sendLinkToCustomerBtnClick(){
      this.showunUploadedDocumentModal = true;
      console.log('Button click Send Link to customer');
        // LightningToast.show({
        //     label: 'Success!',
        //     message: 'Send link to Customer successfully ',
        //     variant: 'success'
        // }, this);
    }

    handleClick(event) {
        // Filter only actual applicants (non-empty Id)
        const actualApplicants = this.loanApplicantList.filter(app => app.Id);
        this.childApplicantList = actualApplicants; // store separately for child
        this.showDocumentModal = true;
    }

    handleClose(event) {
        this.showDocumentModal = false;
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleUnuploadedClose(event){
        this.showunUploadedDocumentModal = false;
    }
}