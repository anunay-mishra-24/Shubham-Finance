import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getPrimaryApplicant from '@salesforce/apex/SHF_HDFC_PaymentLink_Service.getPrimaryApplicant';
import createPaymentLink from '@salesforce/apex/SHF_HDFC_PaymentLink_Service.createPaymentLink';
import qrcode from './qrcode.js';
import MOBILE_QR_URL from '@salesforce/label/c.Mobile_QR_URL';
export default class shfFeeCollection extends LightningElement {

    @api recordId;
    @api loanApplicantId;
    @api feeObj;

    @track selectedChannel = ' ';
    @track showQrScanner = false;
    @track scanResult;
    @track isLoading = false;
    @track showSampleQr = false;
    @track qrcodeInitialized = false;
    @track qrLibLoaded = false;

    applicantId;

    // Replace with your uploaded static resource name for sample QR
    //sampleQrUrl = '/resource/sample_qr_image';
    sampleQrUrl = '/resource/sample_qr_image';
    qrURl = 'upi://pay?ver=01&mode=03&tr=68272241&tn=Dynamic&payment&pa=shubhamhousing@hdfcbank&mc=6012&am=50.00&cu=INR&qrMedium=06';

    channelOptions = [
        { label: 'QR Code', value: 'QR' },
        { label: 'SMS', value: 'SMS' }
    ];

    get QR_URL() {
        const url = MOBILE_QR_URL
            .replace('{RECORD_OrderId}', '123232-order-one2')
            .replace('{RECORD_Amount}', this.feeObj.amount);
        console.log('url = ', url);
        return url;
        // this.openCustomUrl(url);
    }

    async connectedCallback() {
        try {

            this.applicantId = await getPrimaryApplicant({
                applicationId: this.recordId,
                loanApplicantId: this.loanApplicantId ? this.loanApplicantId : null
            });

            if (!this.applicantId) {
                this.showToast("Error", "Applicant not found", "error");
            }

        } catch (error) {
            console.error("Error fetching applicant:", error);
            this.showToast("Error", "Unable to load Applicant details", "error");
        }
    }

    handleChannelChange(event) {
        this.selectedChannel = event.detail.value;

        if (this.selectedChannel === 'QR') {
            this.showQrScanner = true;
            this.showSampleQr = true; // Show sample QR
            this.scanResult = null;
            setTimeout(() => {
                const qrCodeGenerated = new qrcode(0, 'H');
                qrCodeGenerated.addData(this.qrURl);
                qrCodeGenerated.make();
                let element = this.template.querySelector(".qrcode");
                if (element) {
                    element.innerHTML = qrCodeGenerated.createSvgTag({});
                } else {
                    console.error("QR Code container not found!");
                }
            }, 1000);
        } else {
            this.showQrScanner = false;
            this.showSampleQr = false;
            this.scanResult = null;
        }
    }

    async handleSubmit() {
        if (!this.applicantId) {
            this.showToast("Error", "Primary Applicant not found", "error");
            return;
        }

        this.isLoading = true;

        try {
            const result = await createPaymentLink({
                loanApplicantId: this.applicantId,
                qrData: this.selectedChannel
            });

            this.showToast("Success", result, "success");

        } catch (error) {
            this.showToast("Error", "Payment initiation failed. Please retry or contact support.", "error");
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}