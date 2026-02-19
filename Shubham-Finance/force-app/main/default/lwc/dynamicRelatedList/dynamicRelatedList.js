import { LightningElement, api, track, wire } from 'lwc';
import returnRelatedRecords from '@salesforce/apex/DynamicRelatedListCtrl.returnRelatedRecords';
import deleteRecords from '@salesforce/apex/DynamicRelatedListCtrl.deleteRecord';
import getManagerOfManager from '@salesforce/apex/SHF_CommonUtil.getManagerOfManager';
import getUpperManagers from '@salesforce/apex/SHF_CommonUtil.getUpperManagers';
import getDeviationOwner from '@salesforce/apex/DynamicRelatedListCtrl.getDeviationOwner';
import softDeleteRecords from '@salesforce/apex/DynamicRelatedListCtrl.softDeleteRecords';
import initiateAPIVerification from '@salesforce/apex/SHF_HTTPCalloutService.initiateVerification';
import fetchVerificationId from '@salesforce/apex/SHF_CommonUtil.fetchVerificationId';
import getPDData from '@salesforce/apex/SHF_CreaditPDController.getPDData';
import getMessageConfigurations from '@salesforce/apex/SHF_CommonUtil.getMessageConfigurations';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord, updateRecord, getFieldValue, getRecord } from 'lightning/uiRecordApi';
import USER_ROLE_NAME from '@salesforce/schema/User.UserRole.Name';
import USER_PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import Id from '@salesforce/user/Id';
import CM_ID from "@salesforce/schema/Application__c.Credit_Manager__c";
import APPLICATIONID from "@salesforce/schema/Verification__c.Application__c";
import OWNER_ID from "@salesforce/schema/Verification__c.OwnerId";
import APPLICATION_OWNER_ID from "@salesforce/schema/Application__c.OwnerId";
import DEVIATION_ID from "@salesforce/schema/Deviation_and_Sanction_Condition__c.Id";
import DEVIATION_ISDELETED from "@salesforce/schema/Deviation_and_Sanction_Condition__c.Is_Delete__c";
import DEVIATION_DECISION_BY from "@salesforce/schema/Deviation_and_Sanction_Condition__c.Decision_By__c";
import { CurrentPageReference } from 'lightning/navigation';
import initiateMNRLVerification from '@salesforce/apex/SHF_Mobile_MNRL_Service.initiateMNRLVerification';
import callEmploymentVerificationAPI from '@salesforce/apex/SHF_Employment_Verification_API_Service.callEmploymentVerificationAPI';
import processEmploymentVerificationPDF from '@salesforce/apex/SHF_Employment_Verification_PDF_Service.processEmploymentVerificationPDF';
import updateApplicantUAN from '@salesforce/apex/SHF_Employment_Verification_API_Service.updateApplicantUAN';
import createDMSDoc from '@salesforce/apex/SHF_DMS_Service.createDoc';
import getSMSConsentDetails from '@salesforce/apex/SHF_SMSConsent_Service.getSMSConsentDetails';
import UpdateSMSConsentDetails from '@salesforce/apex/SHF_SMSConsent_Service.UpdateSMSConsentDetails';
import getPDFields from "@salesforce/apex/SHF_PersonalDiscussionController.getPDFields";
import IS_CURRENT_USER_FIELD from '@salesforce/schema/Application__c.Is_Current_User__c';
import callICICIInsuranceAPI from '@salesforce/apex/SHF_InsuranceAPIService.callICICIInsuranceAPI';
import getApplicantDetails from '@salesforce/apex/SHF_InsuranceAPIService.getApplicantDetails';
import callKotakInsuranceAPI from '@salesforce/apex/SHF_InsuranceAPIService.callKotakInsuranceAPI';
import USER_ID from '@salesforce/user/Id';
import INSTANT_LITIGATION_TIME from '@salesforce/label/c.Instant_Litigation_Wait_Time';

//import getApplicationDetails from '@salesforce/apex/SHF_InsuranceAPIService.getApplicationDetails';


const rowAction = [];
export default class DynamicRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api applicantId;
    @api objectApiName;
    @api metadataName;
    @api userQuery;
    @api title;
    @api queryParameters;
    @track showScreenFlow = false;
    @track showScreenFlowCKYCAadhaar = false;
    @track showScreenFlowElectricity = false;
    @track showScreenFlowSMSConsent = false;
    @track showScreenFlowCkycOTP = false;
    @track showScreenFlowUdyam = false;
    @api callingApi;
    @track actionCallName;
    @track relatedRecords;
    @track flowInputVeriables;
    @track modelTitle;
    @track showSpinner;
    @track rowAction = rowAction;
    dataRecordId;
    actionName;
    finalOutputString;
    consumerId;
    serviceProvider;
    serviceProviderName;
    mobileNumber;
    userRoleName;
    currentUserId;
    udyamRegNo;
    @track cm;
    @track ownerId;
    userProfileName;
    @track inputs = {};
    @track selectedRows;
    @track inputVariables = [];
    submitDecision = false;
    isApproved = false;
    isMitigants = false;
    @track showValidationModal = false;
    @track missingFields = [];
    messagesMap = {};
    msgResult;
    @track showCibilAadhaarModal = false;
    @track aadhaarNumber = '';
    @track isShowAddress = false;
    @track showCreditPDView = false; // Gaurav Kumar 05-Dec-2025
    @track selectedPersonalDiscussionId; // Gaurav Kumar 05-Dec-2025
    @track isDisabled = false; // Gaurav Kumar 05-Dec-2025
    addressId;
    pincodeId;
    isEditAdd = false;
    @track isEditAddressFromDRL = false;
    otpNumberValue;
    otpNumber;
    ckycOTP;
    @track selectedRecordId;
    @track showPersonalDiscussionView = false;
    @track selectedRecordId;
    @track isConfirmModalOpen;
    selectedData;
    @track showPDViewModal = false;
    @track pd;
    @track isEditMode = false;
    @track showInsuranceModal = false;
    @track isCurrentUser = false;
    @track isMitigantAdded = false;
    @track deviationIdList = [];

    @track isICICI = false;
    @track isKotak = false;
    @track pdRec;
    //UAN 
    @track showUanModal = false;
    @track uanNumber;
    originalUanNumber;
    @track isVerificatioOwner = false;
    // get isVerificatioOwner() {
    //     return this.isVerificatioOwner;
    // }

    // set isVerificatioOwner(value) {
    //     this.isVerificatioOwner = value;
    // }
    connectedCallback() {
        this.getRelatedRecords();
        console.log('recordId', this.recordId);
        this.loadMessageConfigurations(); //fetch all the message config metadata records
    }

    @wire(getRecord, { recordId: '$recordId', fields: [APPLICATIONID, OWNER_ID] })
    wiredRecord({ data, error }) {
        if (data) {
            // let userId = USER_ID;
            this.curObjectApiName = data.apiName;
            const ownerId = getFieldValue(data, OWNER_ID);
            const appId = getFieldValue(data, APPLICATIONID);
            
            console.log('Object Name: ', ownerId);
            this.isVerificatioOwner = (USER_ID == ownerId ? true : false);
            console.log('this.isVerificatioOwner - ',this.isVerificatioOwner);
            console.log('Object Name: ', this.curObjectApiName);
            if ((this.curObjectApiName == 'Verification__c')) {
                this.recordId = appId;
                console.log('finally record Id ', this.recordId);

            }
        } else if (error) {
            console.error(error);
        }
    }

    @wire(CurrentPageReference)
    getLAFId(currentPageReference) {
        if (currentPageReference.state.recordId) {
            this.recordId = currentPageReference.state.recordId;
            this.parentRecordId = currentPageReference.state.recordId;
        } else if (currentPageReference.attributes.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
            this.parentRecordId = currentPageReference.state.recordId;
        }
        console.log('recordId-> ', this.recordId);
    }

    @wire(getRecord, { recordId: '$recordId', fields: [IS_CURRENT_USER_FIELD] })
    wiredApplication({ data, error }) {
        if (data) {
            this.isCurrentUser = data.fields.Is_Current_User__c.value;
            console.log('Is Current User:', this.isCurrentUser);
            console.log('App owner', data.fields);
        } else if (error) {
            console.error('Error fetching Is_Current_User__c:', error);
        }
    }

    @wire(getRecord, { recordId: Id, fields: [USER_ROLE_NAME, USER_PROFILE_NAME] })
    userDetails({ error, data }) {
        console.log('inside wire>> ');
        if (error) {
            this.error = error;
            console.log('inside error>> ', error);

        } else if (data) {
            console.log('inside data>> ', data);
            this.currentUserId = data.id;
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
                if (data.fields.UserRole.value != null) {
                    this.userRoleName = data.fields.UserRole.value.fields.Name.value;
                }
            }
            console.log('this.userRoleName ', this.userRoleName);
            console.log('this.currentUserId ', this.currentUserId);
        }
    }
    @wire(getRecord, { recordId: "$recordId", fields: [CM_ID, APPLICATION_OWNER_ID] })
    applicationDetails({ error, data }) {
        if (error) {
            this.error = error;
            console.log('inside error cm>> ', error);
        } else if (data) {
            console.log(' this.ownerId> ', data);
            this.cm = data.fields.Credit_Manager__c.value;
            this.ownerId = data.fields.OwnerId.value;
            console.log(' this.ownerId> ', this.ownerId);
        }

    }
    // Load message configurations from Apex 
    async loadMessageConfigurations() {
        try {
            const data = await getMessageConfigurations();
            this.messagesMap = data;
            // console.error('Edata>> ', data);
        } catch (error) {
            console.error('Error loading messages:', error.body.message);
        }
    }

    @api getRelatedRecords() {
        this.relatedRecords = undefined;

        returnRelatedRecords({ applicationId: this.recordId, metadataName: this.metadataName, query: this.userQuery /*'Lead__c IN : IDS_SET'*/, queryParameters: this.queryParameters })
            .then((result) => {
                this.showSpinner = false;
                this.relatedRecords = JSON.parse(JSON.stringify(result));
                console.log('Results++11 ', this.relatedRecords.headerActions);
                console.log('Results++22 ', JSON.stringify(this.relatedRecords.headerActions));
                console.log('Results++ ', JSON.stringify(this.relatedRecords));
                this.objectAPIName = result.objectAPIName;
                this.modelTitle = result.label;
            }).catch((err) => {
                this.showSpinner = false;
                console.log('Error in returnRelatedRecords = ', err);
            });
    }
    // add to DynamicRelatedList class
    openPerfiosModal(recordId) {
        // find the child component instance
        const child = this.template.querySelector('c-initiate-perfios');
        if (child && typeof child.openModalFromParent === 'function') {
            child.openModalFromParent(recordId);
        } else {
            console.warn('InitiatePerfios child component not found');
        }
    }


    async handleTableSelection(evt) {
        var data = evt.detail;
        this.selectedData = evt.detail;
        console.log('data-> ', JSON.stringify(data));
        this.dataRecordId = data.recordData.Id;
        this.selectedRecordId = data.recordData.id;
        this.actionCallName = data.ActionName;
        
        
        console.log('this.dataRecordId >> ', this.dataRecordId);
        console.log('this.metadataName >> ', this.metadataName);
        console.log('ActionName >> ', data.ActionName);
        // console.log('recordData >> ', data.recordData);
        // console.log('recordData 3>> ', data.recordData["Litigation_Instant_Verification__r.Status__c"]);
        console.log('this.callingApi >> ', this.callingApi);
        if (data.ActionName === 'Initiate Perfios' || (data.ActionName || '').toLowerCase().includes('perfios')) {
            this.openPerfiosModal(data.recordData.Id);
            return;
        }
        console.log('isCurrentUser 0 - ', this.isCurrentUser, this.recordId);
        console.log('isCurrentUser 0 - ', this.recordId.startsWith('a03'));
        console.log('isCurrentUser 23- ', (!(this.isVerificatioOwner || this.isCurrentUser) && data.ActionName != 'View Detail' && data.ActionName != 'Edit' && data.ActionName != 'View Details'));
        if (!(this.isVerificatioOwner || this.isCurrentUser) && data.ActionName != 'View Detail' && data.ActionName != 'Edit' && data.ActionName != 'View Details') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Access Denied',
                    message: 'You do not have access to perform this action.',
                    variant: 'error'
                })
            );
            return;
        }

        if (data.ActionName === 'Initiate Perfios' || data.ActionName === 'InitiatePerfios') {
            // pass the clicked record id to child and open modal
            this.openPerfiosModal(data.recordData.Id);
            return; // stop further processing for this action
        }
        //  Added by Harshita for PD Edit/View logic


        if (data.recordData.Id != undefined && this.callingApi != undefined) {

            console.log('data.recordData.Id >> ', data.recordData.Id);
            console.log('this.callingApi >> ', this.callingApi);
            console.log('ActionName >> ', data.ActionName);
            console.log('this.metadataName >> ', this.metadataName);
            console.log('PanDetails @ ' + data.recordData.Pan_Number__c);

            this.actionName = data.ActionName;
            this.inputs.customerId = data.recordData.Id;
            this.inputs.apiName = this.callingApi;
            this.inputs.actionName = data.ActionName;
            this.inputs.panNo = data.recordData.Pan_Number__c;

            // added by vikas on 28 nov. for aadhar ocr
            /*if (this.callingApi == 'Digilocker Verification API' && data.ActionName == 'Aadhar OCR') {
                let value = await this.template.querySelector('c-shf-aadhaar-o-c-r-upload').handleCallApi();

            }*/

            // if (this.callingApi == 'CKYC Verification API' && data.ActionName == 'Initiate Verification via Aadhaar') {
            //     this.showScreenFlowCKYCAadhaar = true;
            //     this.flowInputVeriables = [
            //         { name: 'recordDataId', type: 'String', value: data.recordData.Id }
            //     ];
            // }
            if (this.callingApi == 'Electricity Verification API' && data.ActionName == 'Initiate Verification') {
                this.showScreenFlowElectricity = true;
                this.flowInputVeriables = [
                    { name: 'recordDataId', type: 'String', value: data.recordData.Id }
                ];
            }
            else if (this.callingApi == 'UDYAM API' && data.ActionName == 'Initiate Udyam Registration') {
                this.showScreenFlowUdyam = true;
                this.flowInputVeriables = [
                    { name: 'recordDataId', type: 'String', value: data.recordData.Id }
                ];
            }
            else if (this.callingApi == 'SMS Consent' && data.ActionName == 'Verify OTP') {
                console.log('data.ActionName >>>> : ', data.ActionName);
                this.showScreenFlowSMSConsent = true;
            }
            // else if (this.callingApi == 'INSURANCE API' && data.ActionName == 'Initiate Verification') {
            //     console.log('Calling Insurance API with inputs:', JSON.stringify(this.inputs));
            //     this.showSpinner = true;
            //     initiateAPIVerification({ inputString: JSON.stringify(this.inputs) })
            //         .then(result => {
            //             console.log('Insurance API result: ', result);
            //             if (result.includes('missingFields')) {
            //                 this.showInsuranceModal = true;
            //                 let resObj = JSON.parse(result);
            //                 this.missingFields = resObj.missingFields;
            //                 this.showValidationModal = true;
            //             } else if (result.includes('Success')) {

            //                 this.showToastMsg('Success', 'API was successfully triggered and the details are saved on the record', 'success');
            //             }
            //         })
            //         .catch(err => {
            //             console.error('Error calling Insurance API', err);
            //             this.showToastMsg('Error', 'There was a glitch in the action, kindly re-initiate', 'error');
            //         })
            //         .finally(() => {
            //             this.showSpinner = false;
            //         });
            // }
            else if (this.callingApi == 'INSURANCE API' && data.ActionName == 'Initiate Verification') {
                this.showSpinner = true;

                initiateAPIVerification({ inputString: JSON.stringify(this.inputs) })
                    .then(result => {
                        const resObj = JSON.parse(result);

                        // ---------------- ERROR CASE ----------------
                        if (resObj.status === 'error') {
                            this.missingFields = resObj.missingFields;
                            this.showValidationModal = true;
                        }

                        // ---------------- ICICI CASE ----------------
                        else if (resObj.status === 'hold') {

                            this.isICICI = true;
                            this.isKotak = false;

                            getApplicantDetails({ applicantId: resObj.applicantId })
                                .then(app => {
                                    if (app) {
                                        this.selectedApplicantId = resObj.applicantId;
                                        this.selectedApplicantData = {
                                            tenure: app.Application__r?.Tenure__c,
                                            sanctionAmount: app.Application__r?.Sanction_Amount__c,
                                            product: app.Application__r?.Loan_Product__c,
                                            name: app.Name,
                                            gender: app.Gender__c,
                                            dob: app.Date_of_Birth__c,
                                            age: app.Applicant_Age__c
                                        };
                                        this.showInsuranceModal = true;
                                    } else {
                                        this.showToastMsg('Error', 'Applicant details not found', 'error');
                                    }
                                })
                                .catch(error => {
                                    console.error('Error fetching applicant:', error);
                                    this.showToastMsg('Error', 'Failed to fetch applicant details', 'error');
                                })
                                .finally(() => {
                                    this.showSpinner = false;
                                });
                        }

                        // ---------------- KOTAK CASE ----------------
                        else if (resObj.status === 'kotakInputRequired') {

                            this.isICICI = false;
                            this.isKotak = true;

                            getApplicantDetails({ applicantId: resObj.applicantId })
                                .then(app => {
                                    if (app) {
                                        this.selectedApplicantId = resObj.applicantId;
                                        this.selectedApplicantData = {
                                            tenure: app.Application__r?.Tenure__c,
                                            sanctionAmount: app.Application__r?.Sanction_Amount__c,
                                            product: app.Application__r?.Loan_Product__c,
                                            name: app.Name,
                                            gender: app.Gender__c,
                                            dob: app.Date_of_Birth__c,
                                            age: app.Applicant_Age__c
                                        };
                                        this.showInsuranceModal = true;
                                    } else {
                                        this.showToastMsg('Error', 'Applicant details not found', 'error');
                                    }
                                })
                                .catch(error => {
                                    console.error('Error fetching applicant:', error);
                                    this.showToastMsg('Error', 'Failed to fetch applicant details', 'error');
                                })
                                .finally(() => {
                                    this.showSpinner = false;
                                });

                            /*
                            getApplicationDetails({ applicationId: this.recordId })
                                .then(app => {
                                    if (app) {
                                        this.selectedApplicantId = resObj.applicantId;
                                        this.selectedApplicationData = {
                                            tenure: app.Tenure__c,
                                            sanctionAmount: app.Sanction_Amount__c
                                        };
                                        this.showInsuranceModal = true;
                                    }
                                })
                                .catch(error => {
                                    this.showToastMsg('Error', 'Failed to fetch applicant details', 'error');
                                })
                                .finally(() => { this.showSpinner = false });
                            */
                        }

                        // ---------------- SUCCESS CASE ----------------
                        else if (resObj.status === 'success') {
                            this.showToastMsg('Success', 'API was successfully triggered and the details are saved on the record', 'success');
                        }
                    })
                    .catch(err => {
                        console.error(err);
                        this.showToastMsg('Error', 'API call failed', 'error');
                    })
                    .finally(() => {
                        this.showSpinner = false;
                        this.getRelatedRecords(); // Refresh list
                    });
            }
            else if (this.callingApi === 'Advance Litigation' && data.ActionName === 'Initiate Verification'){
                this.showSpinner = true;
                 initiateAPIVerification({ inputString: JSON.stringify(this.inputs) })
                    .then( async result => {
                        if (result == 'Success') {
                            this.showToastMsg('Success', 'The Advance Litigation has been triggered successfully', 'Success');
                        }
                        else if( result == 'Already in progress'){
                            this.showToastMsg('Warning', 'Already in progress may be take upto 2 days ', 'Warning');
                        }
                        else if( result == 'Already completed'){
                            this.showToastMsg('Success', 'The response from Advance Litigation has been received', 'Success');
                        }
                        else if(result == ''){
                            this.showToastMsg('Error', 'Currently facing issues try again later', 'Error');

                        }
                        else{
                            this.showToastMsg('Error', result, 'Error');
                        }
                        this.showSpinner = false;      

                        this.getRelatedRecords(); // refresh list
                    }).catch(err => {
                        console.error('Error calling Advance Litigation API:', err);
                        this.showToastMsg('Error', 'There was a glitch, kindly retry', 'error');
                        this.getRelatedRecords();
                    }).finally(() => {
                        this.showSpinner = false;
                        this.getRelatedRecords(); // refresh list
                    });
            }
            else if (this.callingApi === 'Instant Litigation' && data.ActionName === 'Initiate Verification') {
                this.showSpinner = true;
                this.litigationStatus = data.recordData["Litigation_Instant_Verification__r.Status__c"];
                console.log('litigationStatus -- ',this.litigationStatus);
                if(this.litigationStatus == 'Completed'){
                    this.showToastMsg('Success', 'The response from Instant Litigation has been received', 'Success');
                    this.showSpinner = false;
                }
                else{
                await initiateAPIVerification({ inputString: JSON.stringify(this.inputs) })
                    .then( async result => {
                        if (result == 'Success') {
                            this.showToastMsg('Success', 'The Instant Litigation has been triggered successfully', 'Success');
                            let time = INSTANT_LITIGATION_TIME * 1000;
                            console.log('timee - ', time);
                            await this.sleep(time);
                            // setTimeout(() => {
                            this.showSpinner = true;
                            this.callingApi = 'Instant Litigation Result';
                            this.inputs.apiName = this.callingApi;
                            await initiateAPIVerification({ inputString: JSON.stringify(this.inputs) })
                                .then(result => {
                                    if (result == 'Success Report') {

                                        this.showToastMsg('Success', 'The response from Instant Litigation has been received', 'Success');
                                        // this.showToastMsg('Success', 'The response from Instant Litigation has been received', 'Success');
                                    }

                                    this.getRelatedRecords(); // refresh list
                                }).catch(err => {
                                    console.error('Error calling Instant Litigation API:', err);
                                    this.showToastMsg('Error', 'There was a glitch, kindly retry', 'error');
                                    // this.getRelatedRecords();
                                }).finally(() => {
                                    this.showSpinner = false;
                                });
                            // }, time);
                        }

                        // this.getRelatedRecords(); // refresh list
                    }).catch(err => {
                        console.error('Error calling Instant Litigation API:', err);
                        this.showToastMsg('Error', 'There was a glitch, kindly retry', 'error');
                        // this.getRelatedRecords();
                    }).finally(() => {
                        this.showSpinner = false;
                    });
                }
            }
            else if (this.callingApi === 'DISCOVER API' && data.ActionName === 'Initiate Verification') {
                this.showSpinner = true;
                this.discoverStatus = data.recordData["Discover_Verification__r.Status__c"];
                console.log('discoverStatus -- ', this.discoverStatus);
                if (this.discoverStatus == 'Completed') {
                    this.showToastMsg('Success', 'The response from Discover API has been already received', 'Success');
                    this.showSpinner = false;
                    return;
                }
                this.showToastMsg('Success', 'The Discover API has been triggered successfully', 'Success');
                initiateAPIVerification({ inputString: JSON.stringify(this.inputs) })
                    .then(result => {
                        if (result == 'Success') {
                            this.showToastMsg('Success', 'The response from Discover API has been received', 'Success');
                        } else {
                            this.showToastMsg('Error', 'There was a glitch, kindly retry', 'error');
                        }

                        this.getRelatedRecords(); // refresh list
                    }).catch(err => {
                        console.error('Error calling Discover API:', err);
                        this.showToastMsg('Error', 'There was a glitch, kindly retry', 'error');
                        this.getRelatedRecords();
                    }).finally(() => {
                        this.showSpinner = false;
                    });
            }
            else if (this.callingApi == 'CIBIL CRIF Bureau Individual API' && data.ActionName == 'Initiate Verification') {
                this.dataRecordId = data.recordData.Id;
                this.actionName = data.ActionName;
                this.submitAadhaar(); // Commnet by Vikas Soni for bureau aadhaar shwoing issue
                // this.showCibilAadhaarModal = true;
            }
            //Added by Dimple for Hunter API
            else if (this.callingApi === 'Hunter API' && data.ActionName === 'Initiate Hunter Verification') {
                this.showSpinner = true;
                initiateAPIVerification({ inputString: JSON.stringify(this.inputs) })
                    .then(result => {
                        let resObj;
                        try {
                            resObj = JSON.parse(result);
                        } catch (e) {
                            console.error('Error parsing Apex result:', e);
                            console.log(e);
                            this.showToastMsg('Error', 'Invalid response from server', 'error');
                            return;
                        }
                        if (resObj.status === 'error' && resObj.missingFields?.length > 0) {
                            // Missing fields → show modal
                            console.log('Missing fields found:', resObj.missingFields);
                            this.missingFields = resObj.missingFields;
                            this.showValidationModal = true;
                        } else {
                            console.log('API successfully triggered');
                            this.showToastMsg('Success', 'Hunter API was successfully triggered', 'success');
                        }
                        this.getRelatedRecords(); // refresh list
                    }).catch(err => {
                        console.error('Error calling Hunter API:', err);
                        this.showToastMsg('Error', 'There was a glitch, kindly retry', 'error');
                        this.getRelatedRecords();
                    }).finally(() => {
                        this.showSpinner = false;
                    });
            }


            else if (this.callingApi === 'EMPLOYMENT API' && data.ActionName === 'Initiate Verification') {
                this.dataRecordId = data.recordData.Id;
                this.actionName = data.ActionName;

                if (data.recordData.Id) {
                    this.uanNumber = data.recordData.UAN_Number__c; // existing UAN
                    this.originalUanNumber = data.recordData.UAN_Number__c; // existing UAN;
                    this.showUanModal = true;
                }
            }

            else {
                if (this.callingApi === 'Mobile MNRL API' && (data.ActionName === 'Initiate Primary Verification' || data.ActionName === 'Initiate Alternate Verification')) {
                    console.log('Calling initiateMNRLVerification for record: ', data.recordData.Id);
                    if (data.recordData.Id != '' || data.recordData.Id != undefined) {
                        this.showSpinner = true;
                        initiateMNRLVerification({ recordId: data.recordData.Id, actionName: data.ActionName })
                            .then(result => {
                                console.log('Platform Event Published Successfully', result);
                                console.log(' this.getMessageByKey(result).message : ', this.getMessageByKey(result).message);
                                this.showToastMsg(this.getMessageByKey(result).type, this.getMessageByKey(result).message, this.getMessageByKey(result).type);
                            })
                            .catch(error => {
                                console.error('Error publishing MNRL event', error);
                                this.showToastMsg('Error', 'result', 'error');
                            })
                            .finally(() => {
                                this.showSpinner = false;
                                // window.setTimeout(() => {
                                //     window.location.reload();
                                // }, 1000);
                                this.getRelatedRecords(); // Refresh list after update
                            });

                    }
                }
                /*    else if (this.callingApi == 'SMS Consent' && data.ActionName == 'Initiate Verification') {
            console.log('data.ActionName >>>> : ', data.ActionName);
            this.showSpinner = true;
        
            // Step 1: Generate 4-digit OTP
            const otp = Math.floor(1000 + Math.random() * 9000);
            console.log('Generated OTP:', otp);
        
            // Step 2: Call Apex method with recordId and OTP
            initiateSMSConsentVerification({ recordId: data.recordData.Id , otpValue: otp})
                .then(result => {
                    this.showSpinner = false;
                    console.log('Apex result:', result);
                    // You can show toast or open Enter OTP screen here
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.error('Error in SMS Consent initiation:', error);
                });
        } */

                else if (this.callingApi == 'SMS Consent' && data.ActionName == 'Initiate Verification') {
                    console.log('data.ActionName >>>> : ', data.ActionName);
                    // Step 1: Generate 4-digit OTP
                    const otp = Math.floor(1000 + Math.random() * 9000);
                    console.log('Generated OTP:', otp);
                    this.inputs.otpValue = otp;
                    this.otpNumberValue = otp;
                    console.log('this inputs otpValue', this.inputs.otpValue);
                    this.showSpinner = true;
                    this.initiateAPIVerification(this.inputs);
                }
                else if (this.callingApi == 'CKYC Verification API' && data.ActionName == 'Verify OTP') {
                    this.showScreenFlowCkycOTP = true;
                }
                else if (this.callingApi != '' && this.callingApi != undefined && this.metadataName != '' && this.metadataName != undefined && this.callingApi != 'SMS Consent' && data.ActionName != 'View Detail') {
                    this.showSpinner = true;
                    this.initiateAPIVerification(this.inputs);
                }
            }
        }

        if (data.ActionName == 'View Detail') {

            console.log('DEBUG: Inside View Detail action');

            console.log('DEBUG: Params going to Apex - customerId:', data?.recordData?.Id,
                ', apiName:', this?.callingApi);

            fetchVerificationId({
                customerId: data.recordData.Id,
                apiName: this.callingApi
            })
                .then((result) => {

                    console.log('DEBUG: Apex returned result:', result);
                    this.showSpinner = false;

                    if (result) {
                        console.log('DEBUG: Navigating to record with Id:', result);
                        this.navigateToRecordPage(result, 'E_Verification__c');
                    } else {
                        console.log('DEBUG: No verification record found');
                        this.showToastMsg(
                            'Warning',
                            'Kindly initiate the ' + this.callingApi + ' verification for the applicant to proceed further!',
                            'Warning'
                        );
                    }
                })
                .catch((err) => {
                    this.showSpinner = false;

                    console.log('DEBUG: Apex Error:', JSON.stringify(err));
                    console.log('DEBUG: Full Error Object:', err);

                    this.showToastMsg(
                        'Application Error',
                        'Kindly contact your admin!',
                        'Warning'
                    );
                });
        }

        //hard delete of record--added by mansur on 10-09-2025
        if (this.selectedRecordId != undefined && data.ActionName == 'Delete') {

        }


        //added by mansur on  13-10-2025
        if (data.ActionName == 'Edit') {
            console.log('metadata name> ', this.metadataName);
            console.log('data.recordData.Pincode__c> ', data.recordData.Pincode__c);
            console.log('data.recordData.Ide> ', data.recordData.Id);
            console.log('parent > ', this.recordId);


            if ((this.metadataName == 'Address' || this.metadataName == 'Address_Individual') && data.recordData.Id != undefined) {
                console.log('called add child comp ');
                this.addressId = data.recordData.Id;
                this.pincodeId = data.recordData.Pincode__c;
                this.isEditAdd = true;
                this.isShowAddress = true;
                this.isEditAddressFromDRL = true;
            }
        }

        // === Added by Harshita for Personal Discussion Edit/View ===
        /*
        if (this.metadataName === 'Personal_Discussion' && data.ActionName === 'Edit') {
            console.log('Navigating to Edit page for Personal Discussion:', data.recordData.Id);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: data.recordData.Id,
                    objectApiName: 'Personal_Discussion__c',
                    actionName: 'edit'
                }
            });
        }
        
        if (this.metadataName === 'Personal_Discussion' && data.ActionName === 'View Detail') {
            const recordUrl = `/lightning/r/Personal_Discussion__c/${data.recordData.Id}/view?print=1&nooverride=1&readOnly=1`;
            console.log('Navigating to clean read-only view:', recordUrl);
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url: recordUrl }
            });
        }*/

        // --- Replace the existing Personal_Discussion View/Edit handling block with this ---
        if (this.metadataName === 'Personal_Discussion' && (data.ActionName === 'View Details' || data.ActionName === 'Edit')) {
            const recordId = data.recordData.Id;
            console.log('Opening PD modal:', recordId);
            this.selectedRecordId = recordId;
            this.isEditMode = (data.ActionName === 'Edit');
            this.showSpinner = true;

            getPDFields({ recordId })
                .then(result => {
                    console.log('Raw PD Fields:', JSON.stringify(result));

                    // Helper function to deeply filter empty values
                    const deepFilter = (obj) => {
                        const out = {};
                        Object.keys(obj || {}).forEach(key => {
                            const val = obj[key];

                            // Always keep all fields in edit mode
                            if (this.isEditMode) {
                                out[key] = val;
                                return;
                            }

                            // Skip null/undefined/empty-string
                            if (val === null || val === undefined || val === '') return;

                            // If nested object, recurse
                            if (typeof val === 'object' && !Array.isArray(val)) {
                                const sub = deepFilter(val);
                                if (Object.keys(sub).length > 0) out[key] = sub;
                                return;
                            }

                            out[key] = val;
                        });
                        return out;
                    };

                    this.pd = deepFilter(result);
                    this.showPersonalDiscussionView = true;
                    this.showSpinner = false;
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.error('Error loading PD fields:', error);
                    this.showToastMsg('Error', 'Unable to load Personal Discussion fields', 'error');
                });

            return;
        }
        if (this.metadataName === 'Credit_PD' && (data.ActionName === 'View Details' || data.ActionName === 'Edit')) {
            const recordId = data.recordData.Id;
            console.log('Opening PD modal:', recordId);
            this.selectedPersonalDiscussionId = recordId;
            if (data.ActionName === 'Edit') {
                this.showCreditPDView = true;
                this.isDisabled = false;
                console.log('this.isDisabled:', this.isDisabled);
            } else if (data.ActionName === 'View Details') {
                console.log('View Details:');
                this.showCreditPDView = true;
                this.isDisabled = true;
            }
            return;
        }

    }

    // --- Handlers for edit inputs, save and modal title ---

    handleSuccess(event) {
        const savedId = event.detail.id;
        this.closeModal();
        this.dispatchEvent(new CustomEvent('saved', { detail: { id: savedId } }));
    }
    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // Update pd when an input changes (works for checkbox, number, text, textarea)
    handlePDFieldChange(event) {
        const field = event.target.dataset.field;
        if (!field) return;

        const newValue = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

        // Special handling for relationship-like pseudo fields
        if (field === 'Application__rName') {
            this.pd = {
                ...this.pd,
                Application__r: { ...(this.pd.Application__r || {}), Name: newValue }
            };
        } else {
            this.pd = { ...this.pd, [field]: newValue };
        }
    }


    handleSavePD() {
        if (!this.selectedRecordId) {
            this.showToastMsg('Error', 'No record selected to save', 'error');
            return;
        }

        console.log('this.selectedRecordId >>>>>', this.selectedRecordId);

        // Only fields that are allowed to be updated
        const allowedFields = [
            'Name',
            'Credit_PD_Mode__c',
            'Remarks__c',
            'Are_you_salaried_or_self_employed__c',
            'Is_the_GST_Report_available__c',
            'Is_BankStatement_avail_for_BankSurrogate__c',
            'Can_Customer_Income_be_assessed__c',
            'Is_the_last_2_month_salary_slip_availabl__c',
            'Is_Form_16_available__c',
            'Is_salary_credited_in_Bank_Account__c'
        ];

        // Build valid updateRecord fields object
        const fields = { Id: this.selectedRecordId };
        allowedFields.forEach(f => {
            if (this.pd[f] !== undefined) {
                fields[f] = this.pd[f];
            }
        });

        console.log('Fields after filtering>>>>', fields);

        const recordInput = { fields };
        console.log('recordInput >>>>', recordInput);

        this.showSpinner = true;

        updateRecord(recordInput)
            .then(() => {
                this.showToastMsg('Success', 'Record updated successfully', 'success');
                return getPDFields({ recordId: this.selectedRecordId });
            })
            .then(updated => {

                // Clean null/blank values
                const deepFilter = (obj) => {
                    const out = {};
                    Object.keys(obj || {}).forEach(key => {
                        const val = obj[key];
                        if (val === null || val === undefined || val === '') return;
                        if (typeof val === 'object' && !Array.isArray(val)) {
                            const sub = deepFilter(val);
                            if (Object.keys(sub).length > 0) out[key] = sub;
                            return;
                        }
                        out[key] = val;
                    });
                    return out;
                };

                this.pd = deepFilter(updated);
                this.isEditMode = false;
                this.showSpinner = false;

                this.getRelatedRecords(); // Refresh list after update
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error saving PD:', error);
                this.showToastMsg('Error', error?.body?.message || 'Failed to save record', 'error');
            });
    }


    handleCreditPDSuccess() {
        console.log("Record updated successfully!");
        this.showToastMsg('Success', 'Record Saved Successfully.', 'success');
        this.closeModal();
        window.location.reload();
    }
    handleSubmit(event) {
        console.log("handleCreditPDSuccess Submit!");
        this.showCreditPDView = false;
        event.preventDefault();
        // Optionally manipulate fields before submit:
        // event.preventDefault();
        // const fields = event.detail.fields;
        // fields.SomeField__c = 'value';
    }


    handleError(event) {
        console.error("Error updating:", event.detail);
    }
    // Close modal and reset edit state
    closeModal() {

        this.showPersonalDiscussionView = false;
        this.showCreditPDView = false;
        this.showUanModal = false;
        console.log('showCreditPDView :', this.showCreditPDView);
        this.isEditMode = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Computed helper for header text (LWC template expressions must be simple props)
    get modalTitle() {
        return this.isEditMode ? 'Edit' : 'View Details';
    }


    //added by mansur on 06-11-2025
    handleConfirm() {
        this.isConfirmModalOpen = false;
        softDeleteRecords({ deviationIdList: this.deviationIdList, curruntUserId: this.currentUserId })
            .then(result => {
                if (result.startsWith('success')) {
                    this.showToastMsg('Success', 'Record Deleted Successfully', 'Success');
                    window.setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                } else if (result.startsWith('error')) {
                    this.showToastMsg('Error', 'Error in Record Deletion ', 'error');
                }

            })
            .catch(e => {
                console.log('Exception is >>>>', e.message);
            })

    }

    closeConfirmModal() {
        this.isConfirmModalOpen = false;
    }

    // closeModal() {
    //     this.showPersonalDiscussionView = false;
    // }


    // Show Aadhaar modal
    handleCibilVerification() {
        this.aadhaarNumber = '';
        console.log('Opening Aadhaar modal...');
        this.showCibilAadhaarModal = true;
    }

    // Handle Aadhaar input
    handleAadhaarChange(event) {
        this.aadhaarNumber = event.target.value;
        console.log('Aadhaar input changed: ', this.aadhaarNumber);
    }

    // Submit Aadhaar & check missing fields via Apex
    submitAadhaar() {
        console.log('Submitting Aadhaar: ', this.aadhaarNumber);
        this.showCibilAadhaarModal = false;
        this.showSpinner = true;

        const inputs = {
            customerId: this.dataRecordId,
            apiName: 'CIBIL CRIF Bureau Individual API',
            actionName: 'Initiate Verification',
            finalOutputAadhaarString: this.aadhaarNumber || ''
        };

        console.log('Inputs going to Apex: ', JSON.stringify(inputs));

        initiateAPIVerification({ inputString: JSON.stringify(inputs) })
            .then(result => {
                this.showSpinner = false;
                console.log('Apex response: ', result);

                let resObj;
                try {
                    resObj = JSON.parse(result);
                } catch (e) {
                    console.error('Error parsing Apex result: ', e);
                    this.showToastMsg('Error', 'Invalid response from server', 'error');
                    return;
                }

                if (resObj.status === 'error' && resObj.missingFields?.length > 0) {
                    // Missing fields found → show modal
                    console.log('Missing fields found: ', resObj.missingFields);
                    this.missingFields = resObj.missingFields;
                    this.showValidationModal = true;
                } else {
                    console.log('API successfully triggered with Aadhaar: ', this.aadhaarNumber);
                    this.showToastMsg('Success', 'API was successfully triggered', 'success');
                }
                this.getRelatedRecords(); // Refresh list after update
            })
            .catch(err => {
                this.showSpinner = false;
                console.error('Error calling CIBIL API', err);
                this.showToastMsg('Error', 'There was a glitch, kindly retry', 'error');
                this.getRelatedRecords(); // Refresh list after update
            });

    }

    // Close missing fields modal
    closeValidationModal() {
        console.log('Closing validation modal...');
        this.showValidationModal = false;
        this.missingFields = [];
        this.aadhaarNumber = '';
        this.showCibilAadhaarModal = false;
    }

    //UAN Change
    handleUanChange(event) {
        this.uanNumber = event.target.value;
    }

    handleUanConfirm() {
        // Validate format
        if (!/^[0-9]{12}$/.test(this.uanNumber)) {
            this.showToastMsg('Error', 'UAN must be exactly 12 digits', 'error');
            return;
        }

        this.showUanModal = false;

        // UAN NOT changed then directly call API
        if (this.uanNumber === this.originalUanNumber) {
            return this.startEmploymentVerification();
        }

        // UAN changed save first, then call API
        updateApplicantUAN({
            applicantId: this.dataRecordId,
            uanNumber: this.uanNumber
        })
            .then(() => {
                return this.startEmploymentVerification();
            })
            .catch(error => {
                this.showToastMsg(
                    'Error',
                    error.body?.message || error.message,
                    'error'
                );
            });
    }

    startEmploymentVerification() {
        this.showSpinner = true;

        return callEmploymentVerificationAPI({
            loanApplicantId: this.dataRecordId
        })
            .then(result => {
                if (result.isSuccess) {
                    this.showToastMsg('Success', result.message, 'success');

                    if (result.pdfLink) {
                        return processEmploymentVerificationPDF({
                            applicantId: this.dataRecordId,
                            pdfLink: result.pdfLink
                        });
                    }
                    return null;
                } else {
                    throw new Error(result.message || 'Employment verification failed');
                }
            })
            .then(pdfResult => {
                if (!pdfResult) return null;

                return createDMSDoc({
                    docCategory: pdfResult.documentCategory,
                    base64Doc: pdfResult.base64Pdf,
                    loanApplicationId: pdfResult.applicationId,
                    docId: pdfResult.documentId
                });
            })
            .then(() => {
                this.showToastMsg('Success', 'DMS Upload Completed', 'success');
                this.getRelatedRecords();
            })
            .catch(error => {
                this.showToastMsg('Error', error.message, 'error');
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    // added by mansur on 0909-2025----- to approve the deviation records
    handleRowSelection(event) {

        this.selectedRows = null;
        console.log('here ', JSON.stringify(event.detail));
        this.selectedRows = event.detail;
        this.isApproved = false;
        this.isMitigants = false;
        const amlError = this.getMessageByKey('Mobile_API_Issue');
        console.log(amlError.message); // Error message content
        console.log(amlError.type);

    }

    handleheaderAction(event) {
        let selectedIds = [];
        console.log('header action > ', event.target.name);
        if (event.target.name == 'Submit_Decision') { // submit decision functionality
            this.isMitigantAdded = false;
            if (this.selectedRows == undefined || this.selectedRows.length == undefined || this.selectedRows.length == 0) {
                console.log('this.selectedRows3 ', this.selectedRows);
                this.showToastMsg(this.getMessageByKey('Select_at_least_one_record').type, this.getMessageByKey('Select_at_least_one_record').message, this.getMessageByKey('Select_at_least_one_record').type);

            }
            else {
                if (this.selectedRows.length > 0) {
                    this.selectedRows.forEach(currentItem => {
                        if (currentItem.Decision__c == 'Approved' || currentItem.Decision__c == 'Rejected') {
                            this.isApproved = true;
                        }
                        const mitigantName = currentItem["Mitigants__r.Mitigant_Name__c"];
                        if (!mitigantName || mitigantName.trim() === "") {
                            this.isMitigants = true;
                        }
                        console.log(' currentItem>>>   ', JSON.stringify(currentItem));
                        //level-1
                        if (this.userRoleName == 'Credit Head' || this.userProfileName == 'System Administrator') {
                            if (currentItem.Approving_Authority__c.includes(this.userProfileName) || currentItem.Approving_Authority__c.includes(this.userRoleName) || currentItem.Approving_Authority__c.includes('Branch Credit Manager') || currentItem.Approving_Authority__c.includes('Area Credit Manager') || currentItem.Approving_Authority__c.includes('State Head') || currentItem.Approving_Authority__c.includes('Regional Manager') || currentItem.Approving_Authority__c.includes('Zonal Manager') || currentItem.Approving_Authority__c.includes('Credit Manager/Officer')) {
                                console.log('currentItem1-> ', currentItem.Approving_Authority__c);
                                selectedIds.push(currentItem.id);
                            }
                        }

                        //level-2
                        else if (this.userRoleName == 'Zonal Manager') {
                            if (currentItem.Approving_Authority__c.includes(this.userRoleName) || currentItem.Approving_Authority__c.includes('Area Credit Manager') || currentItem.Approving_Authority__c.includes('State Head') || currentItem.Approving_Authority__c.includes('Regional Manager') || currentItem.Approving_Authority__c.includes('Branch Credit Manager') || currentItem.Approving_Authority__c.includes('Credit Manager/Officer')) {
                                console.log('currentItem1-> ', currentItem.Approving_Authority__c);
                                selectedIds.push(currentItem.id);
                            }
                        }

                        //level-2
                        else if (this.userRoleName == 'Regional Manager') {
                            if (currentItem.Approving_Authority__c.includes(this.userRoleName) || currentItem.Approving_Authority__c.includes('State Head') || currentItem.Approving_Authority__c.includes('Area Credit Manager') || currentItem.Approving_Authority__c.includes('Branch Credit Manager') || currentItem.Approving_Authority__c.includes('Credit Manager/Officer')) {
                                console.log('currentItem1-> ', currentItem.Approving_Authority__c);
                                selectedIds.push(currentItem.id);
                            }
                        }

                        //level-3
                        else if (this.userRoleName == 'State Head') {
                            if (currentItem.Approving_Authority__c.includes(this.userRoleName) || currentItem.Approving_Authority__c.includes('Area Credit Manager') || currentItem.Approving_Authority__c.includes('Branch Credit Manager') || currentItem.Approving_Authority__c.includes('Credit Manager/Officer')) {
                                console.log('currentItem1-> ', currentItem.Approving_Authority__c);
                                selectedIds.push(currentItem.id);
                            }
                        }

                        //level-4
                        else if (this.userRoleName == 'Area Credit Manager') {
                            if (currentItem.Approving_Authority__c.includes(this.userRoleName) || currentItem.Approving_Authority__c.includes('Branch Credit Manager') || currentItem.Approving_Authority__c.includes('Credit Manager/Officer')) {
                                console.log('currentItem1-> ', currentItem.Approving_Authority__c);
                                selectedIds.push(currentItem.id);
                            }
                        }

                        //level-5
                        else if (this.userRoleName == 'Branch Credit Manager') {
                            if (currentItem.Approving_Authority__c.includes(this.userRoleName) || currentItem.Approving_Authority__c.includes('Credit Manager/Officer')) {
                                console.log('currentItem1-> ', currentItem.Approving_Authority__c);
                                selectedIds.push(currentItem.id);
                            }
                        }

                        //level-6
                        if (this.userRoleName == 'Credit Manager/Officer') {
                            if (currentItem.Approving_Authority__c.includes(this.userRoleName)) {
                                selectedIds.push(currentItem.id);
                            }
                        }
                    });
                    console.log('isApproved-> ', this.isApproved);
                }
                if (selectedIds.length > 0 && selectedIds.length == this.selectedRows.length) {
                    //validation when already approved deviation is selected
                    if (this.isApproved) {
                        this.showToastMsg(this.getMessageByKey('Selected_deviation_already_approved').type, this.getMessageByKey('Selected_deviation_already_approved').message, this.getMessageByKey('Selected_deviation_already_approved').type);
                    } else if (this.userProfileName == 'Credit') {
                        //fetch managers of credit heirarchy and apply validaiton
                        if (!this.isMitigants) {
                            getManagerOfManager({ userId: this.ownerId })
                                .then(result => {
                                    console.log('result cm ', result);
                                    if (result) {
                                        if (result.includes(this.currentUserId) && selectedIds && this.ownerId == this.currentUserId) {
                                            this.inputVariables = [];
                                            this.inputVariables = [
                                                {
                                                    name: 'deviationConIds',
                                                    type: 'String',
                                                    value: selectedIds
                                                },
                                                {
                                                    name: 'addMitigants',
                                                    type: 'Boolean',
                                                    value: false
                                                },
                                                {
                                                    name: 'recordId',
                                                    type: 'String',
                                                    value: this.recordId
                                                }
                                            ];
                                            this.showSpinner = false;
                                            this.submitDecision = true;
                                        } else {
                                            this.showToastMsg(this.getMessageByKey('Not_authorise_to_submit_decision').type, this.getMessageByKey('Not_authorise_to_submit_decision').message, this.getMessageByKey('Not_authorise_to_submit_decision').type);
                                        }
                                    }

                                })
                                .catch(e => {
                                    console.log('Exception is >>>>', e.message);
                                });
                        } else {
                            this.showToastMsg(this.getMessageByKey('Add_Mitigants_Before_Approval').type, this.getMessageByKey('Add_Mitigants_Before_Approval').message, this.getMessageByKey('Add_Mitigants_Before_Approval').type);
                        }
                    } else {
                        this.showToastMsg(this.getMessageByKey('Credit_user_not_available').type, this.getMessageByKey('Credit_user_not_available').message, this.getMessageByKey('Credit_user_not_available').type);
                    }
                } else {
                    this.showSpinner = false;
                    this.showToastMsg(this.getMessageByKey('Warning_for_owned_deviation_approval').type, this.getMessageByKey('Warning_for_owned_deviation_approval').message, this.getMessageByKey('Warning_for_owned_deviation_approval').type);
                }
            }
        }
        //Add mitigants functionality ...added by mansur on 14-11-2025
        if (event.target.name == 'Add_Mitigant') {
            this.isMitigantAdded = true;
            console.log(' this.isApprove>> in  miti ', this.isApproved);
            let selectedIds = [];
            if (this.selectedRows == undefined || this.selectedRows.length == undefined || this.selectedRows.length == 0) {
                this.showToastMsg(this.getMessageByKey('Select_at_least_one_record').type, this.getMessageByKey('Select_at_least_one_record').message, this.getMessageByKey('Select_at_least_one_record').type);
            }

            else if (this.userProfileName == 'Credit') {
                if (this.selectedRows.length > 0) {
                    this.selectedRows.forEach(currentItem => {
                        console.log('currentItem.Approving_Authority__c  ', currentItem.Approving_Authority__c);
                        console.log('currentItem.Decision__c  ', currentItem.Decision__c);
                        if (currentItem.Decision__c == 'Approved' || currentItem.Decision__c == 'Rejected') {
                            this.isApproved = true;
                        } else {
                            console.log(' currentItem.id>>>   ', currentItem.id);
                            selectedIds.push(currentItem.id);
                            console.log(' this.selectedIds>>iiiii  ', selectedIds);
                            console.log(' currentItem.id>>>   ', JSON.stringify(currentItem.id));
                        }
                    })
                }

                if (!this.isApproved) {
                    //fetch managers of credit heirarchy and apply validaiton
                    console.log('dddddd ', selectedIds);
                    getManagerOfManager({ userId: this.ownerId })
                        .then(result => {
                            console.log('result cm ', result);
                            if (result) {
                                if (result.includes(this.currentUserId) && this.ownerId == this.currentUserId) {
                                    this.inputVariables = [];
                                    this.inputVariables = [
                                        {
                                            name: 'deviationConIds',
                                            type: 'String',
                                            value: selectedIds
                                        },
                                        {
                                            name: 'addMitigants',
                                            type: 'Boolean',
                                            value: true
                                        },
                                        {
                                            name: 'recordId',
                                            type: 'String',
                                            value: this.recordId
                                        }
                                    ];
                                    this.showSpinner = false;
                                    //open modal to select the mitigants
                                    this.submitDecision = true;
                                } else {
                                    this.showToastMsg(this.getMessageByKey('You_are_not_application_owner').type, this.getMessageByKey('You_are_not_application_owner').message, this.getMessageByKey('You_are_not_application_owner').type);
                                }
                            }
                        })
                        .catch(e => {
                            console.log('Exception is >>>>', e.message);
                        });
                } else {
                    this.showToastMsg(this.getMessageByKey('Selected_deviation_already_approved').type, this.getMessageByKey('Selected_deviation_already_approved').message, this.getMessageByKey('Selected_deviation_already_approved').type);
                }
            } else {
                this.showToastMsg(this.getMessageByKey('Credit_user_not_available').type, this.getMessageByKey('Credit_user_not_available').message, this.getMessageByKey('Credit_user_not_available').type);
            }
        }
        // console.log('delete1 ', this.selectedRecordId + ' action ' + data.ActionName + ' metadata ' + this.metadataName);
        if (event.target.name == 'Delete_Deviation') {
            console.log('rrrr');
            let isDelete = true;
            let isAuthorizeToDelete = true;

            if (this.selectedRows == undefined || this.selectedRows.length == undefined || this.selectedRows.length == 0) {
                this.showToastMsg(this.getMessageByKey('Select_at_least_one_record').type, this.getMessageByKey('Select_at_least_one_record').message, this.getMessageByKey('Select_at_least_one_record').type);
            } else if (this.selectedRows.length > 0) {
                this.deviationIdList = [];
                this.selectedRows.forEach(currentItem => {
                    this.deviationIdList.push(currentItem.id);
                    if (currentItem["Deviations__r.Source__c"] != 'Manual') {
                        isDelete = false;
                    } else if (currentItem.Decision__c != 'Pending') {
                        isDelete = false;
                    }
                })
                if (this.deviationIdList != null) {
                    let deviationNamesStr = '';
                    getDeviationOwner({ deviationIdList: this.deviationIdList, curruntUserId: this.currentUserId })
                        .then(result => {
                            deviationNamesStr = result.unauthorizedDeviationNames.join(', ');
                            console.log('result> ', result);
                            console.log('result545> ', deviationNamesStr);
                            if (!result.isAuthorizeToDelete) {
                                console.log('result>11 ', result);
                                isAuthorizeToDelete = false;
                            }
                        })
                        .catch(e => {
                            console.log('Exception is >>>>', e.message);
                        }).finally(() => {
                            if (isAuthorizeToDelete == false) {
                                console.log('result.unauthor ', deviationNamesStr);
                                // this.showToastMsg('Error', 'You can not delete Auto or Approved Deviations.55', 'error');
                                this.showToastMsg(this.getMessageByKey('Can_t_delete_deviation').type, this.getMessageByKey('Can_t_delete_deviation').message + ': ' + deviationNamesStr, this.getMessageByKey('Can_t_delete_deviation').type);
                                // this.showToastMsg(this.getMessageByKey('Can_t_delete_deviation').type, this.getMessageByKey('Can_t_delete_deviation').message +': '+ result.unauthorizedDeviationNames.join(', '), this.getMessageByKey('Can_t_delete_deviation').type);
                            }
                            else if (isDelete == false) {
                                this.showToastMsg(this.getMessageByKey('Manual_deviaiton_deletion').type, this.getMessageByKey('Manual_deviaiton_deletion').message, this.getMessageByKey('Manual_deviaiton_deletion').type);
                                //this.showToastMsg('Error', 'You can not delete Auto or Approved Deviations.', 'error');
                            }
                            else {
                                this.isConfirmModalOpen = true;
                            }
                        });
                }
                console.log('isAuthorizeToDelete33 > ', isAuthorizeToDelete);

            }
        }
    }

    handleSubmitDecision() {
        this.submitDecision = false;
    }

    handleFlowExecution(event) {
        this.showSpinner = true;
        if (event.detail.status === 'FINISHED') {
            console.log('this.callingApi >> ', this.callingApi);
            if (this.callingApi == 'CKYC Verification API') {
                this.showScreenFlowCKYCAadhaar = false;
                const outputVariables = event.detail.outputVariables;
                for (let i = 0; i < outputVariables.length; i++) {
                    const outputVar = outputVariables[i];
                    if (outputVar.name == "finalOutputString") {
                        this.finalOutputString = outputVar.value;
                        this.inputs.finalOutputAadhaarString = outputVar.value;
                    }
                }
                this.initiateAPIVerification(this.inputs);
            }
            else if (this.callingApi == 'Electricity Verification API') {
                this.showScreenFlowElectricity = false;
                const outputVariables = event.detail.outputVariables;
                for (let i = 0; i < outputVariables.length; i++) {
                    const outputVar = outputVariables[i];
                    if (outputVar.name == "consumerId") {
                        this.inputs.consumerId = outputVar.value;
                        console.log('this.inputs.mobileNumber : ', this.inputs.consumerId);
                    }
                    else if (outputVar.name == "serviceProvider") {
                        this.inputs.serviceProvider = outputVar.value;
                    }
                    else if (outputVar.name == "mobileNumber") {
                        this.inputs.mobileNumber = outputVar.value;
                        console.log('this.mobileNumber : ', this.mobileNumber);
                        console.log('this.inputs.mobileNumber : ', this.inputs.mobileNumber);
                    }
                    else if (outputVar.name == "serviceProviderName") {
                        this.inputs.serviceProviderName = outputVar.value;
                    }
                }
                this.initiateAPIVerification(this.inputs);
            }
            //Added by Dimple Kapri for Udyam Registration API
            else if (this.callingApi == 'UDYAM API') {
                this.showScreenFlowUdyam = false;
                const outputVariables = event.detail.outputVariables;
                for (let i = 0; i < outputVariables.length; i++) {
                    const outputVar = outputVariables[i];
                    if (outputVar.name == "udyamRegNo") {
                        this.inputs.udyamRegNo = outputVar.value;
                        console.log('this.inputs.udyamRegNo : ', this.inputs.udyamRegNo);
                    }
                }
                this.initiateAPIVerification(this.inputs);
            }
            else if (this.callingApi == 'Login Fee API') {
                console.log('Login Fee API ***', JSON.stringify(this.inputs));
                if (outputVar.name == "applicationId") {
                    this.inputs.consumerId = this.recordId;
                    console.log('this.inputs.applicationId : ', this.inputs.applicationId);
                }
                this.initiateAPIVerification(this.inputs);
                this.showScreenFlow = false;
            }
            else if (this.callingApi == 'deviation') {
                this.submitDecision = false;
                if (this.isMitigantAdded) {
                    this.showToastMsg(this.getMessageByKey('Mitigants_added_successfully').type, this.getMessageByKey('Mitigants_added_successfully').message, this.getMessageByKey('Mitigants_added_successfully').type);
                } else {
                    this.showToastMsg(this.getMessageByKey('Deviation_decision_updated_successfully').type, this.getMessageByKey('Deviation_decision_updated_successfully').message, this.getMessageByKey('Deviation_decision_updated_successfully').type);
                }
                window.setTimeout(() => {
                    window.location.reload();
                }, 2000);
            }
            else if (this.callingApi == 'SMS Consent') {
                this.showScreenFlowSMSConsent = false;
            }
        }
        else if (event.detail.status === 'ERROR') {
            this.showToastMsg('Error', 'Flow encountered an error', 'error');
            this.showSpinner = false;
        }
        this.showSpinner = false;
    }

    handlePerfiosSave(event) {
        const payload = event.detail; //  files, password, fromDate, toDate, recordId // initiate perfios
        console.log('Perfios payload received:', payload);

        this.getRelatedRecords();
    }
    handleCloseCKYCAadhaar(event) {
        this.showScreenFlowCKYCAadhaar = false;
        this.showSpinner = false;
    }
    handleCloseElectricity(event) {
        this.showScreenFlowElectricity = false;
        this.showSpinner = false;
    }
    handleCloseUdyam(event) {
        this.showScreenFlowUdyam = false;
        this.showSpinner = false;
    }
    navigateToRecordPage(recordId, objectApiName) {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'view'
            }
        });
    }

    handleClose(event) {
        this.showDocumentModal = false;
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    closePreviewModal(event) {
        this.showPreviewModal = event.detail;
    }

    async initiateAPIVerification(inputs) {
        try {

            const data = await initiateAPIVerification({ inputString: JSON.stringify(this.inputs) });
            this.showSpinner = false;
            this.relatedRecords = [];
            if (data.includes('Success')) {
                if (this.actionName === "Aadhar OCR" && this.callingApi === "Digilocker Verification API") {
                    this.showToastMsg('Success', 'Aadhaar OCR API Triggered Successfully', 'Success');
                } else {
                    this.showToastMsg('Success', this.callingApi + ' Triggered Successfully', 'Success');
                }
                // this.relatedRecords = [];
                this.getRelatedRecords(); // Refresh list after update
            } else {
                this.showToastMsg('Error', data, 'error');
                this.getRelatedRecords(); // Refresh list after update
            }
        } catch (error) {
            console.error('Error loading messages:', error.body.message);
            this.showSpinner = false;
            this.showToastMsg('Error', this.callingApi + 'API Verification Failed', 'error');
            console.log('Error in API Verification @@ ', JSON.stringify(err));
            this.getRelatedRecords(); // Refresh list after update
        }
        this.showSpinner = false;
    }

    /*    initiateAPIVerification(inputs) {
        console.log('inputs ***', JSON.stringify(this.inputs));
        initiateAPIVerification({ inputString: JSON.stringify(this.inputs) })
            .then((result) => {
    
                console.log('RESULTTTTTT  ', result);
                console.log('this.callingApi  ', this.callingApi);
                console.log('this.recordId  ', this.recordId);
                this.showSpinner = true;
                if (result.includes('Success')) {
                    this.showToastMsg('Success', this.callingApi + ' Triggered Successfully', 'Success');
                } else {
                    this.showToastMsg('Error', result, 'error');
                }
                setTimeout(() => {
                    this.showSpinner = false;
                }, 1500);
    
    
            }).catch((err) => {
                this.showSpinner = false;
                this.showToastMsg('Error', this.callingApi + 'API Verification Failed', 'error');
                console.log('Error in API Verification @@ ', JSON.stringify(err));
            });
    }*/

    showToastMsg(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: "pester"
            })
        )
    }

    //use this method to delete record
    deleteRecords(recordIdToDelete) {
        deleteRecord(recordIdToDelete)
            .then(() => {
                this.showToastMsg('Success', 'Record deleted Successfully', 'Success');
            })
            .catch((error) => {
                console.log(error);
            });
    }

    // Generic method to get message by DeveloperName
    getMessageByKey(developerName) {
        console.log('messagesMap >  ', this.messagesMap)
        if (!this.messagesMap || Object.keys(this.messagesMap).length === 0) {
            this.showToastMsg('Error', 'Message configurations not loaded yet. Please try again.', 'error');
            return null;
        }
        const messageConfig = this.messagesMap[developerName];
        if (!messageConfig) {
            this.showToastMsg('Error', `Message with DeveloperName '${developerName}' not found.`, 'error');
            return null;
        }
        return {
            message: messageConfig.Message__c,
            type: messageConfig.Message_Type__c
        };
    }
    //added by mansur on 13-10-2025
    handleAddressClose(event) {
        console.log('in dynamicList Handle Close', event.detail);
        this.isShowAddress = event.detail;
        // this.getRelatedRecords();
        //  this.selectedRows = undefined;
    }

    handleOTPChange(event) {
        const inputCmp = event.target;
        this.otpNumber = inputCmp.value.replace(/\D/g, '').slice(0, 4);
        inputCmp.setCustomValidity(this.otpNumber.length === 4 ? '' : 'Only 4-digit numbers are allowed in OTP');
        inputCmp.reportValidity();
        console.log('Entered OTP: ', this.otpNumber);
    }

    handleCKYCOTPChange(event) {
        const inputCmp = event.target;
        this.ckycOTP = inputCmp.value.replace(/\D/g, '').slice(0, 6);
        inputCmp.setCustomValidity(this.ckycOTP.length === 6 ? '' : 'Only 6-digit numbers are allowed in OTP');
        inputCmp.reportValidity();
        console.log('Entered OTP: ', this.ckycOTP);
    }

    async submitOtp(event) {
        this.showSpinner = true;
        try {
            const data = await this.getOtpFromEVerification();
            if (!data) {
                this.showToastMsg('Error', 'Please Initiate Verification first', 'error');
                this.showSpinner = false;
                this.showScreenFlowSMSConsent = false;
                return;
            }

            if (data.No_of_Attempt__c >= 3) {
                this.showToastMsg('Error', 'Maximum attempts are exhausted. Kindly re-initiate', 'error');
                this.showSpinner = false;
                this.showScreenFlowSMSConsent = false;
                return;
            }

            if (data.OTP_Sent_to_Customer__c === this.otpNumber) {
                data.No_of_Attempt__c += 1;
                data.Status__c = 'Completed';
                data.Loan_Applicant__r.Is_SMS_Consent_Given__c = true;
                this.showScreenFlowSMSConsent = false;
                await UpdateSMSConsentDetails({ eVerificationData: JSON.stringify(data) });
                this.showToastMsg('Success', 'Verification is completed', 'success');
                this.getRelatedRecords(); // Refresh list after update
                // setTimeout(() => window.location.reload(), 1000);
                return;
            }
            data.No_of_Attempt__c += 1;
            if (data.No_of_Attempt__c < 3) {
                data.Status__c = 'In Progress';
                this.showToastMsg('Error', 'You entered the wrong OTP', 'error');
            }
            else if (data.No_of_Attempt__c === 3) {
                data.Status__c = 'Failed';
                this.showToastMsg('Error', 'You entered the wrong OTP', 'error');
                this.getRelatedRecords(); // Refresh list after update
                // setTimeout(() => window.location.reload(), 1000);
            }
            await UpdateSMSConsentDetails({ eVerificationData: JSON.stringify(data) });
        } catch (error) {
            console.error('Error in submitOtp:', error);
            this.showToastMsg('Error', 'Something went wrong. Please try again later.', 'error');
        } finally {
            this.showSpinner = false;
            this.otpNumber = '';
            const inputField = this.template.querySelector('lightning-input');
            if (inputField) inputField.value = '';
        }
    }

    async submitCkycOtp(event) {
        this.showSpinner = true;
        if (this.ckycOTP == '') {
            this.showToastMsg('Error', 'Please enter OTP', 'error');
            this.showSpinner = false;
            return;
        }
        else {
            this.inputs.otpValue = this.ckycOTP;
            this.inputs.customerId = this.dataRecordId;
            this.inputs.apiName = this.callingApi;
            this.inputs.actionName = this.actionCallName;
            console.log('this inputs otpValue', this.inputs.otpValue);
            console.log('this inputs apiName', this.inputs.apiName);
            console.log('this inputs actionName', this.inputs.actionName);
            console.log('this inputs customerId', this.inputs.customerId);
            this.showSpinner = true;
            await this.initiateAPIVerification(this.inputs);
            this.handleCloseSMSConsent();
        }
    }

    handleCloseSMSConsent(event) {
        this.showScreenFlowSMSConsent = false;
        this.otpNumber = '';
        const inputField = this.template.querySelector('lightning-input');
        if (inputField) {
            inputField.value = '';
        }
    }

    handleCloseCkycOtp(event) {
        this.showScreenFlowCkycOTP = false;
        this.ckycOTP = '';
        const inputField = this.template.querySelector('lightning-input');
        if (inputField) {
            inputField.value = '';
        }
    }

    async getOtpFromEVerification() {
        try {
            const data = await getSMSConsentDetails({ recordId: this.dataRecordId });
            console.log('Service Response:', data);
            return data ? data : null;
        } catch (error) {
            console.error('Error calling getSMSConsentDetails:', error);
            return null;
        }
    }

    handleICICISave(event) {
        const { eVerificationId, applicantId, insuranceData, isIcici, isKotak } = event.detail;
        this.showSpinner = true;
        // ICICI case
        if (isIcici) {
            callICICIInsuranceAPI({
                eVerificationId: eVerificationId,
                applicantId: applicantId,
                insuranceJson: JSON.stringify(insuranceData)
            })
                .then(result => {
                    console.log('ICICI raw result:', result);

                    // Parse JSON string
                    const resObj = JSON.parse(result);

                    console.log('Parsed ICICI response:', resObj);

                    //  BUSINESS ERROR FROM ICICI
                    if (resObj.response && resObj.response.startsWith('ERROR|')) {
                        const iciciMessage = resObj.response.replace('ERROR|', '');

                        this.showToastMsg(
                            'Insurance Validation Error',
                            iciciMessage,
                            'error'
                        );

                        this.showInsuranceModal = false;
                        return;
                    }

                    // SUCCESS
                    this.showToastMsg(
                        'Success',
                        'API was successfully triggered and the details are saved on the record',
                        'success'
                    );

                    this.showInsuranceModal = false;
                })
                .catch(error => {
                    console.error(error);

                    this.showToastMsg(
                        'Error',
                        'There was a glitch in the action, kindly re-initiate',
                        'error'
                    );

                    this.showInsuranceModal = false;
                })
                .finally(() => this.showSpinner = false);

            return;
        }

        // KOTAK case
        if (isKotak) {
            callKotakInsuranceAPI({
                eVerificationId: eVerificationId,
                applicantId: applicantId,
                insuranceJson: JSON.stringify(insuranceData)
            })
                .then(result => {
                    if (result && result.startsWith('ERROR::')) {
                        const message = result.replace('ERROR::', '');
                        this.showToast('Insurance Validation Error', message, 'error');
                        return;
                    }
                    this.showToast(
                        'Success',
                        'API was successfully triggered and the details are saved on the record',
                        'success'
                    );
                    /*const resObj = JSON.parse(result);
                    if (resObj.status === 'success') {
                        this.showToastMsg('Success', 'Kotak API triggered successfully', 'success');
                        this.showInsuranceModal = false;
                    } else {
                        this.showToastMsg('Error', resObj.message || 'Kotak API error', 'error');
                    }*/
                })
                .catch(error => {
                    console.error(error);
                    this.showToastMsg('Error', 'There was a glitch in the action, kindly re-initiate', 'error');
                })
                .finally(() => this.showSpinner = false);
        }
    }

    handleModalClose(event) {
        console.log('Modal closed:', event.detail);
        this.showInsuranceModal = false;
    }
}