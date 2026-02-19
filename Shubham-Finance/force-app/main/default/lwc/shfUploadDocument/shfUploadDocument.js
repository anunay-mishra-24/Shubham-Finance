import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createDocumentRecord from '@salesforce/apex/SHF_DisplayDocumentsController.createDocumentRecord';
import getToken from '@salesforce/apex/SHF_DMS_Service.generateAccessToken';
import logDMSCall from '@salesforce/apex/SHF_DMSLogger.logDMSCall';
import getApplicantInfo from '@salesforce/apex/SHF_DMS_Service.getApplicantInfo';
import updateDocumentWithDmsResponse from '@salesforce/apex/SHF_DMS_Service.updateDocumentWithDmsResponse';
import uploadAsAttachment from '@salesforce/apex/CreateDMSDocumentHandler.uploadAsAttachment';
import aadhaarMasking from '@salesforce/apex/SHF_Aadhaar_Masking_Service.aadhaarMasking';
import saveMaskedAadhaarToDMS from '@salesforce/apex/SHF_Aadhaar_Masking_Service.saveMaskedAadhaarToDMS';
import deleteExistingFiles from '@salesforce/apex/SHF_Aadhaar_Masking_Service.deleteExistingFiles';


function serializeFormData(fd) {
    const obj = {};
    for (let [key, value] of fd.entries()) {
        if (key === 'document' && typeof value === 'string') {
            obj[key] = value.substring(0, 100) + '... [truncated]';
        } else if (key === 'token' && typeof value === 'string') {
            obj[key] = value.substring(0, 10) + '... [truncated]';
        } else {
            obj[key] = value;
        }
    }
    console.log('obj : ',obj);
    return obj;
}

export default class ShfUploadDocument extends LightningElement {
    @api applicationId;
    @api docId;
    @api docCategory;
    @api docName;
    @api linkedDocumentFor;// Gaurav Kumar 11-Dec-2025
    @api context = 'flow';
    @api parentObjectName;
    @api parentRecordId;
    @api applicantId;
    @api caseId;
    @api caseName;
    @api caseStatus;
    @api branchCode;
    @api uploadFromPublicSite = false; //Added by Ranjeet for checking documents upload from public site.

    @track fileSelected = false;
    @track fileName = '';
    @track base64File = '';
    @track showSpinner = false;
    @track uploadDisabled = false;
    @track inlineError = '';
    @track fileSize = 0;


    isError = false;

    get isFlow() {
        return this.context === 'flow';
    }

    get acceptedFormats() {
        // Aadhaar card → only image formats
    if (this.docName === 'Aadhaar card') {
        return ['.jpg', '.jpeg', '.png'];
    }
    // All other documents → allow all formats
        return ['.jpg','.jpeg','.png','.csv','.doc','.docx','.pdf','.xls','.xlsx','.txt'];
    }

    get inputClass() {
        return this.isError ? 'slds-has-error' : '';
    }

    @api
    get flowContext() {
        if (this.isFlow && this.fileSelected) {
            this.handleUpload();
        }
        return 'done';
    }
    set flowContext(value) {}

    @api uploadFromParent(data) {
    this.isParentTriggered = true; 
    this.base64File = data.base64File;
    this.fileName = data.fileName;
    this.docId = data.docId;
    this.docCategory = data.docCategory;
    this.docName = data.docName;
    this.parentObjectName = data.parentObjectName;
    this.parentRecordId = data.parentRecordId;
    this.applicantId = data.applicantId;
    console.log('===== Upload From Parent Triggered =====');
    console.log('Base64 File (first 100 chars): ', this.base64File ? this.base64File.substring(0,100) + '...' : 'NO FILE');
    console.log('data: ', data);
    console.log('File Name: ', this.fileName);
    console.log('Document Id: ', this.docId);
    console.log('Document Category: ', this.docCategory);
    console.log('Document Name: ', this.docName);
    console.log('Parent Object: ', this.parentObjectName);
    console.log('Parent Record Id: ', this.parentRecordId);
    console.log('Applicant Id: ', this.applicantId);
    console.log('Applicant Id 22>>: ', this.applicantId);



    this.fileSelected = true;
        console.log('Data Set in Uploader — Starting Upload...');


    this.handleUpload();
}

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        this.fileSize = file.size;
         const fileExtension = file.name.split('.').pop().toLowerCase();

        let allowedExtensions;
        let maxFileSize;

        // Aadhaar Card Specific Validation
        if (this.docName === 'Aadhaar card') {
            allowedExtensions = ['jpg', 'jpeg', 'png'];
            maxFileSize = 3 * 1024 * 1024; // 3 MB
        } 
        // Other Documents
        else {
            allowedExtensions = [
                'jpg', 'jpeg', 'png', 'csv', 'doc', 'docx',
                'pdf', 'xls', 'xlsx'
            ];
            maxFileSize = 25 * 1024 * 1024; // 25 MB
        }
        //  Validate extension
        if (!allowedExtensions.includes(fileExtension)) {
            this.showNotification(
                'Error',
                `Invalid file format. Allowed formats are: ${allowedExtensions.join(', ')}`,
                'error'
            );
            this.isError = true;
            this.fileSelected = false;
            this.fileName = '';
            return;
        }

        //  Validate size
        if (file.size > maxFileSize) {
            this.showNotification(
                'Error',
                'File size exceeds the 25 MB limit. Please upload a smaller file.',
                'error'
            );
            this.isError = true;
            this.fileSelected = false;
            this.fileName = '';
            return;
        }

        //  If valid → proceed
        this.fileName = file.name;
        this.isError = false;
         // DEBUG FILE DETAILS
    console.log('Selected File Name real name:',  this.fileName);
        const reader = new FileReader();
        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            this.base64File = base64;
            this.fileSelected = true;
        };
        reader.readAsDataURL(file);
    }

    // async uploadToCRM() {
    //     console.log('>>>Inside CRM Called');
    //     let formData;
    //     try {
    //         const [token] = await Promise.all([
    //             getToken()
    //         ]);

    //         //const wrapper = await getApplicantInfo({ applicationId: this.applicationId, applicantId: this.applicantId });
    //         const dataJson = {
    //             DOC_STAGE: this.caseStatus,
    //             DOC_CUST_NAME: this.caseName,
    //             DOC_CUST_ID: this.caseId,
    //             DOC_COPY: 'Original'
    //         };

    //         /*const productMap = new Map([
    //             ["Loan Against Property", "LoanAgainstProperty"],            
    //             ["Plot Plus Self Construction", "Plot Plus Constructi"],
    //             ["Home Loan Project", "Home Loan-Project"],
    //             ["LAP Project Finance", "LAP-Project Finance"],
    //         ]);*/
    //         //let product = (productMap.has(info.productCode)) ? productMap.get(info.productCode) : info.productCode;

    //         formData = new FormData();
    //         formData.append('docCategory', this.docCategory || 'Other');
    //         formData.append('token', token);
    //         formData.append('data', JSON.stringify(dataJson));
    //         //formData.append('path', `${info.branchCode}/${info.productCode}`);
    //         formData.append('path', `${this.branchCode}/Ready Property`);
    //         formData.append('subPath', '2024/SEP');
    //         formData.append('clientId', 'SHUBHAM/OP');
    //         formData.append('file', this.caseId);
    //         formData.append('document', this.base64File);

    //         const serialized = serializeFormData(formData);
    //         console.log('Request payload (safe):', serialized);

    //         // Initial log
    //         await logDMSCall({
    //             requestBody: JSON.stringify(serialized),
    //             responseBody: null,
    //             statusCode: null,
    //             isError: false
    //         });
    //         console.log(' Uploading to DMS...');
    //         const response = await fetch('http://13.127.33.202:8080/Deep/deep-rest/ddfs/service/add', {
    //             method: 'POST',
    //             body: formData
    //         });

    //         const status = response.status;
    //         const success = response.ok;

    //         let responseText = '';
    //         try {
    //             responseText = await response.text();
    //         } catch (e) {
    //             responseText = '[no response body]';
    //         }

    //         // Log response
    //         console.log(' Response Status:', status);
    //         console.log(' Response Body:', responseText);
    //         await logDMSCall({
    //             requestBody: JSON.stringify(serialized),
    //             responseBody: responseText.substring(0, 2000),
    //             statusCode: status,
    //             isError: !success
    //         });

    //         if (!success) {
    //             throw new Error(`Upload failed with status ${status}`);
    //         }

    //         const parsed = JSON.parse(responseText);
    //         console.log('Parsed Response ===>', parsed);
    //          if (!parsed || !parsed.documentId || !parsed.version) {
    //             console.error('Invalid DMS response:', parsed);

    //             await logDMSCall({
    //                 requestBody: JSON.stringify(serialized),
    //                 responseBody: JSON.stringify(parsed).substring(0, 2000),
    //                 statusCode: status,
    //                 isError: true
    //             });
    //             this.sendDmsResult('Error', 'DMS upload failed: Invalid response from server.', 'error');
    //             this.showNotification('Error', 'DMS upload failed: Invalid response from server.', 'error');
    //             this.showSpinner = false;
    //             return;
    //         }
    //         await this.createChildDocumentRecord(parsed);
    //         if (!this.isParentTriggered) {
    //         this.showNotification('Success', 'Document uploaded successfully.', 'success');
    //         }
    //         this.dispatchEvent(new CustomEvent('closemodal'));
    //         setTimeout(() => {
    //             window.location.href = `/lightning/r/Application__c/${this.applicationId}/view`;
    //         }, 200);
    //         this.sendDmsResult('SUCCESS', 'Loan Application Form generated successfully.');


    //     } catch (error) {
    //         console.error('Upload failed:', error);

    //         const serialized = formData ? serializeFormData(formData) : { error: 'FormData not built' };
    //         await logDMSCall({
    //             requestBody: JSON.stringify(serialized),
    //             responseBody: error.message,
    //             statusCode: 0,
    //             isError: true
    //         });

    //         this.showNotification('Error', error.message || 'Upload failed.', 'error');
    //         this.sendDmsResult('ERROR', error.message || 'Upload failed');

    //     } finally {
    //         this.showSpinner = false;
    //     }
    // }
    
    handleUpload() {
        if (!this.base64File) {
            this.isError = true;
            this.showNotification('Error', 'Please select a document before uploading', 'Error'); // added by kunal for check if we click upload button without file upload. 
            return;
        }

        this.showSpinner = true;
        console.log('Applicant Id 21: ', this.applicantId);
        if (!this.docId) {
            console.log('doc create : ');
            createDocumentRecord({
               // applicationId: this.caseId,
                applicationId: this.applicationId,
                applicantId: this.applicantId || null,
                //documentFor: 'Case',
                documentFor: this.linkedDocumentFor || 'Case', // Gaurav Kumar 11-Dec-2025
                category: this.docCategory || 'Others',
                type: 'Other',
                docName: this.fileName,
                parentRecordId: this.parentRecordId || null,
                parentObjectName: this.parentObjectName || null
            })
            .then(result => {
                if (result.isSuccess) {
                    this.docId = result.recordId;
                    this.uploadToDMS();
                //    console.log('>>>Upload to CRM Called');
                //    this.uploadToCRM();
                //    console.log('>>>After CRM Called');
                } else {
                    console.log('>>>Else Case');
                    this.showNotification('Error', result.responseBody, 'error');
                    this.showSpinner = false;
                }
            })
            .catch(error => {
                this.showNotification('Error', error.body?.message || 'Error creating document.', 'error');
                this.showSpinner = false;
            });
        }
        else if (this.docId && (this.docName === 'Applicant Photo' || this.docName === 'Applicant Signature' || this.docName === 'RM Selfie')) {
            console.log('Special document upload started');

            this.inlineError = '';

            // ---------------------------
            // Only JPG Allowed
            // ---------------------------
            console.log('Validating file type...');
            if (
                !this.fileName.toLowerCase().endsWith('.jpg') &&
                !this.fileName.toLowerCase().endsWith('.jpeg')
            ) {
                this.showSpinner = false;
                this.inlineError = 'Only JPG files are allowed.';
                console.log('Invalid file type');
                return;
            }

            // ---------------------------
            // Max Size = 3 MB
            // ---------------------------
            console.log('Validating file size...');
            if (this.fileSize > 3 * 1024 * 1024) {
                this.showSpinner = false;
                this.inlineError = 'File size cannot exceed 3 MB.';
                console.log('File too large');
                return;
            }

            // ---------------------------
            // Attachment Name
            // ---------------------------
            let finalName = this.docName + '.jpg';
            console.log('Final attachment name:', finalName);

            // ---------------------------
            // Apex Call
            // ---------------------------
            console.log('Calling uploadAsAttachment Apex...');
            console.log('upload this.docId==>'+this.docId);
            console.log('upload base64==>'+this.base64File);
            uploadAsAttachment({
                documentId: this.docId,
                base64Data: this.base64File,
                fileName: finalName
            })
                .then(() => {
                    console.log('Upload success');
                    this.showNotification('Success', 'Uploaded successfully', 'success');
                    this.showSpinner = false;
                    //Added by Ranjeet for stop relaoding site when documents upload from public site.
                    if(!this.uploadFromPublicSite){
                      setTimeout(() => {
                        console.log('Reloading page...');
                        window.location.reload();
                      }, 2000);
                    }
                    else if(this.uploadFromPublicSite){
                        this.dispatchEvent(new CustomEvent('closemodal'));
                    }
                })
                .catch(error => {
                    console.log('Upload error:', error);
                    this.showNotification('Error', 'Upload failed', 'error');
                    this.showSpinner = false;
                });

        }

        else {
            console.log('Applicant Id 2222: ', this.applicantId);
            this.uploadToDMS();
            //this.uploadToCRM;
        }
    }

    async uploadToDMS() {
         console.log('Applicant Id 22: ', this.applicantId);
        let formData;
        try {
            console.log("applicationId 11 ---> "+ this.applicationId +'  applicantId --->'+ this.applicantId ? this.applicantId : null);
            const [token, info] = await Promise.all([
                getToken(),
                getApplicantInfo({ applicationId: this.applicationId, applicantId: this.applicantId ? this.applicantId : null })
            ]);
            console.log("applicationId 22 ---> "+ this.applicationId +'  applicantId --->'+ this.applicantId);

            console.log('this.base64File before >>>--> ', this.base64File);
            
            let maskedBase64 = null;
            if (this.docName === 'Aadhaar card') {

                console.log('Aadhaar Card Starting process...');
                console.log('Selected File Name real name : ', this.fileName);
                console.log('Document Id : ', this.docId);

                const imageFormate = this.fileName ? this.fileName.split('.').pop().toLowerCase() : '';
                try{
                    console.log('Deleting old Aadhaar files...');
                    await deleteExistingFiles({ documentId: this.docId });
                    console.log('Old Aadhaar files deleted successfully');
                }catch(error){
                    console.error('Error deleting files → ', error);
                }
                maskedBase64 = await aadhaarMasking({ docDetails: this.base64File, imageFormate: imageFormate, documentId: this.docId });
                if (!maskedBase64) {
                    throw new Error('Aadhaar masking failed');
                }
               let cleanedBase64 = maskedBase64;
                if (cleanedBase64.includes('base64,')) {
                    cleanedBase64 = cleanedBase64.split('base64,')[1];
                }

                this.base64File = cleanedBase64;
                console.log('this.base64File (masked) => ', maskedBase64.substring(0, 100) + '...');
            }
            // =========================================


            //const wrapper = await getApplicantInfo({ applicationId: this.applicationId, applicantId: this.applicantId });
            const dataJson = {
                DOC_STAGE: info.applicationStage,
                DOC_CUST_NAME: info.applicantName,
                DOC_CUST_ID: info.applicantId,
                DOC_COPY: info.docCopy
            };
            console.log('dataJson : ',dataJson);
            console.log('dataJson : ',JSON.stringify(dataJson));
            
            const productMap = new Map([
                ["Loan Against Property", "LoanAgainstProperty"],
                ["Plot Plus Self Construction", "Plot Plus Constructi"],
                ["Home Loan Project", "Home Loan-Project"],
                ["LAP Project Finance", "LAP-Project Finance"],
            ]);
            let product = (productMap.has(info.productCode)) ? productMap.get(info.productCode) : info.productCode;

            formData = new FormData();
            formData.append('docCategory', this.docName || 'Other');
            formData.append('token', token);
            formData.append('data', JSON.stringify(dataJson));
            console.log('OUTPUT dataJson : ', JSON.stringify(dataJson));
            console.log('OUTPUT dataJson@@ : ', formData.data);
            //formData.append('path', `${info.branchCode}/${info.productCode}`);
            formData.append('path', `${info.branchCode}/${product}`);
            // formData.append('subPath', '2024/SEP');
            // formData.append('clientId', 'SHUBHAM/OP');
            formData.append('subPath', info.subPath);
            formData.append('clientId', info.clientId);
            formData.append('file', info.appName);
            formData.append('document', this.base64File);

            const serialized = serializeFormData(formData);
            console.log('Request payload (safe):', serialized);
            console.log('api method', info.apiMethod);
            console.log('api endpoint:', info.endPoint);

            // Initial log
            await logDMSCall({
                requestBody: JSON.stringify(serialized),
                responseBody: null,
                statusCode: null,
                isError: false
            });
            console.log(' Uploading to DMS...');
             console.log(' info.endPoint...',info.endPoint);
            console.log(' info.apiMethod...',info.apiMethod);
            console.log(' formData...',formData);
            const response = await fetch(info.endPoint, {
                method: info.apiMethod,
                body: formData
            });
            console.log(' 22 Uploading to DMS...');
            const status = response.status;
            const success = response.ok;

            let responseText = '';
            try {
                responseText = await response.text();
            } catch (e) {
                responseText = '[no response body]';
            }

            // Log response
            console.log(' Response Status:', status);
            console.log(' Response Body:', responseText);
            await logDMSCall({
                requestBody: JSON.stringify(serialized),
                responseBody: responseText.substring(0, 2000),
                statusCode: status,
                isError: !success
        });

            const errorMsg = info?.message;
            if (errorMsg !== 'SUCCESS') {
                this.showNotification( 'Error', errorMsg || 'Validation failed.', 'error');
                return;
            }

        console.log('this.base64File After >>>--> ', this.base64File);

        if (!success) {
            throw new Error(`Upload failed with status ${status}`);
            }

            const parsed = JSON.parse(responseText);
            console.log('Parsed Response ===>', parsed);
             if ( !parsed || parsed.status !== 'SUCCESS' || !parsed.documentId || parsed.version === undefined || parsed.version === null) {
                console.error('Invalid DMS response:', parsed);

                await logDMSCall({
                    requestBody: JSON.stringify(serialized),
                    responseBody: JSON.stringify(parsed).substring(0, 2000),
                    statusCode: status,
                    isError: true
                });

                this.sendDmsResult('Error', 'DMS upload failed: Invalid response from server.', 'error');
                this.showNotification('Error', 'DMS upload failed: Invalid response from server.', 'error');
                this.showSpinner = false;
                return;
            }

        // Create the document record in JS  
         if (this.docName === 'Aadhaar card') {
            console.log('Saving masked Aadhaar as ContentVersion in Salesforce...');
            const imageFormate = this.fileName ? this.fileName.split('.').pop().toLowerCase() : '';
            await saveMaskedAadhaarToDMS({
                maskedImage: maskedBase64,
                imageFormate: imageFormate,
                documentId: this.docId
            });

            console.log('ContentVersion Created for Masked Aadhaar');
        }
        // -----------------------------------------------------------------------

            await this.createChildDocumentRecord(parsed);
            if (!this.isParentTriggered) {
            this.showNotification('Success', 'Document uploaded successfully.', 'success');
            }
            this.dispatchEvent(new CustomEvent('closemodal'));
            /*setTimeout(() => {
    window.location.href = `/lightning/r/Application__c/${this.applicationId}/view`;
}, 200);*/
            if (this.fileName && this.fileName.toUpperCase().includes('RCU')) {

                this.sendDmsResult('SUCCESS', 'RCU Report generated successfully.');

            }else if (this.fileName && this.fileName.toUpperCase().includes('CAM')){

                this.sendDmsResult('SUCCESS', 'CAM Report generated successfully.');

            }else if (this.fileName && this.fileName.toUpperCase().includes('SANCTION')){

                this.sendDmsResult('SUCCESS', 'Sanction Letter generated successfully.');

            }else if (this.fileName && this.fileName.toUpperCase().includes('TENTATIVE')){

                this.sendDmsResult('SUCCESS', 'Tentative Repayment Schedule generated successfully.');

            }
            else{

                this.sendDmsResult('SUCCESS', 'Loan Application Form generated successfully.');
            }     

        } catch (error) {
            console.error('Upload failed:', error);

            const serialized = formData ? serializeFormData(formData) : { error: 'FormData not built' };
            await logDMSCall({
                requestBody: JSON.stringify(serialized),
                responseBody: error.message,
                statusCode: 0,
                isError: true
            });

            this.showNotification('Error', error.message || 'Upload failed.', 'error');
            this.sendDmsResult('ERROR', error.message || 'Upload failed');

        } finally {
            this.showSpinner = false;
        }
    }

    

    async createChildDocumentRecord(dmsResponse) {
         console.log('ENTERED createChildDocumentRecord');
    console.log('docId received:', this.docId);
    console.log('dmsResponse received:', dmsResponse);

        if (!this.docId || !dmsResponse) {
        console.log('docId or dmsResponse missing. Exiting method');
        return;
    }

        try {
             console.log('Calling Apex updateDocumentWithDmsResponse...');
            await updateDocumentWithDmsResponse({
                docId: this.docId,
               versionId: dmsResponse.version,
               dmsDocId: dmsResponse.documentId

            });
            this.dispatchEvent(new CustomEvent('uploadcompleted', { detail: { docId: this.docId } }));
        } catch (error) {
            console.error('Failed to create child document:', error);
            this.showNotification('Warning', 'DMS Response Inavlid', 'warning');
        }
    }

    showNotification(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleCancel() {
        if (!this.isFlow) {
            this.dispatchEvent(new CustomEvent('closemodal'));
        }
    }
sendDmsResult(status, message, variant = 'success') {
    this.dispatchEvent(new CustomEvent('dmsresponse', {
        detail: { status, message, variant },
        bubbles: true,
        composed: true
    }));
}
}