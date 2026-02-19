import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getPdfFilesAsBase64 from '@salesforce/apex/SHF_MergeReportController.getPdfFilesAsBase64';
import saveMergedPdf from '@salesforce/apex/SHF_MergeReportController.saveMergedPdf';
import getPrimaryApplicant from '@salesforce/apex/SHF_MergeReportController.getPrimaryApplicant';
import pdfLib from '@salesforce/resourceUrl/PdfLib';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Shf_MergeReport extends LightningElement {
    recordId;
    isLibLoaded = false;
    mergedPdfUrl;
    pdfLibInstance;
    applicationId;
    mergedPdfBytes;

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef) {
            this.recordId = pageRef.state.recordId;
        }
    }

    renderedCallback() {
        if (this.isLibLoaded) {
            return;
        }
        loadScript(this, pdfLib + '/pdf-lib.min.js')
            .then(() => {
                if (window['pdfLib'] || window['PDFLib']) {
                    this.isLibLoaded = true;
                    this.pdfLibInstance = window['pdfLib'] || window['PDFLib'];
                    this.fetchAndMerge();
                } else {
                    console.error('PDF-LIB not loaded correctly.');
                }
            })
            .catch(error => {
                console.error('Error loading PDF-LIB:', error);
            });
    }

    fetchAndMerge() {
        if (this.recordId) {
            getPdfFilesAsBase64({ verificationId: this.recordId })
                .then(data => {
                    if (data === 'There are some child activities pending for closure') {
                        this.showToast('Error', data, 'error');
                        this.handleCancel();
                    } else if (data === 'No Verification Activity Found') {
                        this.showToast('Error', data, 'error');
                        this.handleCancel();
                    } else if (data && data.length > 0) {
                        console.log('Merging PDFs...');
                        const pdfFiles = JSON.parse(data);
                        this.mergePDFs(pdfFiles);
                    } else {
                        this.showToast('Error', 'No PDF files found to merge.', 'error');
                        this.handleCancel();
                    }
                })
                .catch(error => {
                    console.error('Error fetching PDFs:', error);
                    this.showToast('Error', error.body?.message || 'Unknown error occurred', 'error');
                    this.handleCancel();
                });
        }
    }

    async mergePDFs(pdfFiles) {
        if (!this.pdfLibInstance) return;

        try {
            const { PDFDocument } = this.pdfLibInstance;
            const mergedPdf = await PDFDocument.create();

            for (let pdfFile of pdfFiles) {
                const pdfBytes = Uint8Array.from(atob(pdfFile.Base64Data), c => c.charCodeAt(0));
                const pdfDoc = await PDFDocument.load(pdfBytes);
                const copiedPages = await mergedPdf.copyPages(pdfDoc, pdfDoc.getPageIndices());
                copiedPages.forEach(page => mergedPdf.addPage(page));
            }

            this.mergedPdfBytes = await mergedPdf.save();

            this.mergedPdfUrl = URL.createObjectURL(
                new Blob([this.mergedPdfBytes], { type: 'application/pdf' })
            );
        } catch (error) {
            console.error('Error during merging:', error);
            this.showToast('Error', 'Failed to merge PDFs', 'error');
            this.handleCancel();
        }
    }

    async handleSave() {
        const response = await saveMergedPdf({ verificationId: this.recordId });
        console.log('Response from saveMergedPdf:', response);
        const { document, verification } = response;
        console.log('Document and Verification from Apex:', document, verification);
        this.applicationId = document.Application__c;
        const applicantId = await getPrimaryApplicant({ applicationId: document.Application__c });
        const base64Data = this.arrayBufferToBase64(this.mergedPdfBytes);
        const uploader = this.template.querySelector('c-shf-upload-document');
        let doc = {
            base64File: base64Data,
            fileName: document.File_Name__c + ' - ' + verification.Name,
            docId: document.Id,
            docCategory: document.File_Name__c,
            docName: document.File_Name__c,
            parentObjectName: 'Application__c',
            parentRecordId: document.Application__c,
            applicantId: applicantId || null
        };
        uploader.uploadFromParent(doc);

        this.showToast('Processing', `${document.File_Name__c} uploading to DMS...`, 'success');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    arrayBufferToBase64(buffer) {
        let binary = '';
        const bytes = new Uint8Array(buffer);
        const len = bytes.byteLength;
        for (let i = 0; i < len; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return window.btoa(binary);
    }

    handleCancel() {
        if (this.isPhone) {
            this.dispatchEvent(new CustomEvent('close'));
        } else {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    handleDmsResponse(event) {
        const resp = event.detail;
        console.log('DMS Response:', resp);
        this.dispatchEvent(
            new ShowToastEvent({
                title: resp.status == 'SUCCESS' ? 'Success' : 'Error',
                message: resp.message,
                variant: resp.variant || (resp.status == 'SUCCESS' ? 'success' : 'error'),
            })
        );
        this.handleCancel();
    }
}