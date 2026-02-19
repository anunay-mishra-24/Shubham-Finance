import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import validateOnly from '@salesforce/apex/SHF_LAF_GeneratorService.validateOnly';
import generatePdf from '@salesforce/apex/SHF_LAF_GeneratorService.generatePDF';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import markLAFGenerated from '@salesforce/apex/SHF_LAF_GeneratorService.markLAFGenerated';
import getPrimaryApplicant from '@salesforce/apex/SHF_LAF_GeneratorService.getPrimaryApplicant';
import sendOtpSms from '@salesforce/apex/SHF_LAF_GeneratorService.sendOtpSms';
import FORM_FACTOR from '@salesforce/client/formFactor';


// To fetch current logged-in user mobile
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';



export default class Shf_LafGenerateAction extends NavigationMixin(LightningElement) {
    @api recordId;
    //= 'a03C100000Kb822IAB';
    missingFields = [];
    showMissingScreen = false;
    showPdfScreen = false;
    pdfUrl;
    @track isUploading = false;
    showOtpScreen = false;
    generatedOtp;
    userOtp = '';
    otpError = '';
    mobileNumber;
    documentId;
    publicUrl;
    sentotpLabel = 'Send OTP'

    @track isDesktop = FORM_FACTOR === 'Large';


    // @wire(CurrentPageReference)
    // getStateParameters(currentPageReference) {
    //     if (currentPageReference && !this.recordId) {
    //         this.recordId = currentPageReference.state?.recordId 
    //                      || currentPageReference.state?.c__recordId;
    //         console.log('Record Id from URL ==> ', this.recordId);
    //     }
    // }

    @wire(getRecord, { recordId: USER_ID, fields: ['User.Phone'] })
    wiredUser({ error, data }) {
        if (data) {
            this.mobileNumber = data.fields.Phone.value;
            console.log('User Mobile:', this.mobileNumber);
        }
    }

    connectedCallback() {
        console.log('Record Id in connectedCallback ===> ', this.recordId);

        if (!this.recordId) {
            setTimeout(() => this.init(), 200);
        } else {
            this.init();
        }
    }


    generateAndSendOtp() {
        this.generatedOtp = Math.floor(1000 + Math.random() * 9000).toString();
        console.log('Generated OTP:', this.generatedOtp);

        sendOtpSms({
            mobile: this.mobileNumber,
            otp: this.generatedOtp
        })
            .then(() => {
                console.log('OTP Sent Successfully');
            })
            .catch((err) => {
                console.error('OTP Send Error', err);
            });
    }


    handleOtpChange(event) {
        this.userOtp = event.target.value;
    }

    handlePreview() {
        window.open(this.publicUrl,'_blank');
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__namedPage',
        //     attributes: {
        //         pageName: 'filePreview'
        //     },
        //     state: {
        //         selectedRecordId: '069C10000062XajIAE'
        //     }
        // });
    }

    verifyOtp() {
        if (this.userOtp === this.generatedOtp) {
            this.otpError = '';

            // hide OTP
            this.showOtpScreen = false;

            // SHOW PDF SCREEN DIRECTLY
            this.pdfUrl = `/apex/SHF_LAF_Form?id=${this.recordId}`;
            // this.showPdfScreen = true;
            this.handleSend();
        } else {
            this.otpError = 'Invalid OTP. Please try again.';
        }
    }

    resendOtp() {
        this.userOtp = '';
        this.otpError = '';
        if(this.sentotpLabel == 'Send OTP'){
            this.sentotpLabel = 'Resend OTP';
        }
        if (this.mobileNumber == null || this.mobileNumber == '') {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please enter mobile number',
                variant: 'error'
            }));
        }
        else { this.generateAndSendOtp(); }
    }

    init() {
        validateOnly({ applicationId: this.recordId })
            .then(res => {
                if (res.status === 'error') {
                    this.missingFields = res.missing;
                    this.showMissingScreen = true;
                    this.showOtpScreen = false;
                    this.showPdfScreen = false;
                } else {
                    // this.pdfUrl = `/apex/SHF_LAF_Form?id=${this.recordId}`;
                    // this.showPdfScreen = true;
                    this.showMissingScreen = false;
                    this.showOtpScreen = true;
                    this.showPdfScreen = false;
                    this.documentId = res.docId;
                    this.publicUrl = res.publicUrl;

                    // generate & send OTP only now
                    // this.generateAndSendOtp();
                }
            })
            .catch(err => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: err.body?.message,
                    variant: 'error'
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    async handleSend() {
        this.isUploading = true;

        try {
            const res = await generatePdf({ applicationId: this.recordId });
            console.log('PDF Generate Response =>', res);
            this.documentId = this.recordId.docId;
            console.log('documentId Id --- ', this.documentId);

            const applicantId = await getPrimaryApplicant({ applicationId: this.recordId });
            console.log('Primary Applicant Id =>', applicantId);

            const uploader = this.template.querySelector('c-shf-upload-document');
            uploader.uploadFromParent({
                base64File: res.fileBase64,
                fileName: res.fileName,
                docId: res.docId,
                docCategory: 'Loan Specific Documents',
                docName:   res.fileName,// res.fileName,
                parentObjectName: 'Application__c',
                parentRecordId: this.recordId,
                applicantId: applicantId || null
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Processing',
                    message: 'Uploading to DMS...',
                    variant: 'success'
                })
            );

        } catch (err) {
            console.error('Error:', err);
            this.isUploading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: err.body?.message || err.message,
                    variant: 'error'
                })
            );
        }
    }

    get isPhone() {
        return FORM_FACTOR === 'Small';
    }

    handleClose() {
        if (this.isPhone) {
            this.dispatchEvent(new CustomEvent('close'));
        } else {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    async handleDmsResponse(event) {
        const resp = event.detail;
        console.log('DMS Response:', resp);
        this.isUploading = false;

        this.dispatchEvent(
            new ShowToastEvent({
                title: resp.status === 'SUCCESS' ? 'Success' : 'Error',
                message: resp.message || 'Loan Application Form generated successfully.',
                variant: resp.variant || (resp.status === 'SUCCESS' ? 'success' : 'error'),
            })
        );


        if (resp.status === 'SUCCESS') {
            try {
                await markLAFGenerated({ applicationId: this.recordId });
                this.dispatchEvent(new CloseActionScreenEvent());
            } catch (err) {
                console.error('Flag update failed:', err.body?.message);
            }
            finally {
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        } else {
            console.error('DMS upload failed:', resp.message || 'Unknown error');
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

}