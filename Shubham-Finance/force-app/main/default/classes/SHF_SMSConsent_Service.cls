/**
* @File Name          : SHF_SMSConsent_Service.cls
* @Description        : Send otp by the sms and check the otp by the popup screen otp is correct or not.
* @Author             : Riteek Tiwari
* 
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         29-10-2025        Riteek Tiwari    Initial Version
*/
public with sharing class SHF_SMSConsent_Service {
    
    @AuraEnabled
    public static String initiateSMSConsentVerification(Id recordId, String otpValue) {
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('SMS_CONSENT_API');
        List<Message_Service__e> msgServicelist = new List<Message_Service__e>();
        
        // Get notification template metadata
       // Notification_Template__mdt notificationMTD = Notification_Template__mdt.getInstance(SHF_ConstantsUtil.MNRL_OTP_NOTIFICATION);
        
       Notification_Template__mdt notificationMTD = [SELECT Id, DeveloperName, SMS_Notification__c FROM Notification_Template__mdt
                                                      WHERE DeveloperName = :SHF_ConstantsUtil.MNRL_OTP_NOTIFICATION];
        system.debug('notificationMTD-->'+notificationMTD.SMS_Notification__c); 
        
        try {
            System.debug('Input recordId: ' + recordId);
            if (recordId == null) {
                return 'Record_Id_is_blank';
            }
            
            // Fetch Loan Applicant
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{recordId});
            if (loanAppList.isEmpty()) {
                return 'No_Loan_Applicant_Found';
            }
            
            Loan_Applicant__c loanApp = loanAppList[0];
            System.debug('Fetched Loan Applicant: ' + JSON.serialize(loanApp));
            
            // Validate mobile number
            if (String.isBlank(loanApp.Mobile_Number__c)) {
                System.debug('Mobile number not found.');
                message = MessageConfigMap.get('SMS_Consent_API_Mobile_Blank').Message__c;
                return message;
            }
            
            // Check if already completed
            if (loanApp.SMS_Consent__r != null && loanApp.SMS_Consent__r.Status__c == SHF_ConstantsUtil.COMPLETEDSTATUS) {
                System.debug('SMS Consent already completed.');
                return 'E_verification_already_completed';
            }
            
            // Initialize Unit of Work
            fflib_SObjectUnitOfWork eVerificationUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Loan_Applicant__c.SObjectType });
            
            // Create E-Verification record for SMS Consent
            E_Verification__c eVerificationSMS = SHF_CommonUtil.createVerfication(loanApp.Id,SHF_ConstantsUtil.SMSCONSENT_RECORD_TYPE,SHF_ConstantsUtil.INPROGRESS_STATUS);
            
            If(otpValue != Null && String.isNotBlank(otpValue)){
                eVerificationSMS.OTP_Sent_to_Customer__c = otpValue;
                eVerificationSMS.No_of_Attempt__c = 0;
            }
            
            eVerificationUow.registerNew(eVerificationSMS);
            eVerificationUow.commitWork();
            
            // Update lookup field on Loan Applicant
            loanApp.SMS_Consent__c = eVerificationSMS.Id;
            applicantUow.registerDirty(loanApp);
            applicantUow.commitWork();
            
            // send sms
            If(otpValue != Null && String.isNotBlank(otpValue)){
                logger.info('templateValue: 1');               
                
                 msgServicelist.add(new Message_Service__e(
                Receiver__c	= loanApp.Mobile_Number__c,
                Message_Template__c = SHF_CommonUtil.formatSMSTemplate(notificationMTD.SMS_Notification__c)
                 .replace('<OTP>', (otpValue != null ? otpValue : 'Customer'))
                 .replace('<Applicant>', (loanApp.First_Name__c != null ? loanApp.First_Name__c : 'Customer'))
                 .replace('<URL>', System.Label.Sms_Concent_URL)
                ));
            }
            
            if (!msgServicelist.isEmpty()) {
                Logger.info('msgServicelist',msgServicelist);
                Database.SaveResult[] results = EventBus.publish(msgServicelist);
                Logger.info('results',results);
            }
            
            logger.info('msgServicelist: ' + msgServicelist);
            System.debug('SMS Consent E-Verification created: ' + eVerificationSMS.Id);
            logger.info('SMS Consent E-Verification created: ' + eVerificationSMS.Id);
            logger.info('loanApp.SMS_Consent__c: ' + loanApp.SMS_Consent__c);
            //message = 'SMS_Consent_API_Success';
            message = MessageConfigMap.get('SMS_Consent_API_Success').Message__c;
        } catch (Exception ex) {
            message = 'SMS_Consent_API_Failed';
            System.debug('SMS Consent Exception: ' + ex.getMessage() + ' Line: ' + ex.getLineNumber());
            Logger.error('SMS Consent Exception: ' + ex.getMessage() + ' Line: ' + ex.getLineNumber());
        } finally {
            Logger.saveLog();
        }
        
        return message;
    }

    @AuraEnabled
    public static E_Verification__c getSMSConsentDetails(String recordId) {
        system.debug('getSMSConsentDetails call'+recordId);
        List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{recordId});
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
        
        if (loanAppList != Null && !loanAppList.isEmpty()) {
            System.debug('No Loan Applicant found for recordId: ' + recordId);
            Loan_Applicant__c loanApp = loanAppList[0];
           
        if (String.isNotBlank(loanApp.SMS_Consent__c)) {
            System.debug('SMS Consent record not found on Loan Applicant.');
            // return 'Mobile_Number_is_blank';
            String eVerificationId = loanApp.SMS_Consent__c;           
            System.debug('E-Verification Id: ' + eVerificationId);
            List<E_Verification__c> evList = new SHF_E_VerificationSelector().selectByIdsApplicantName(new Set<Id>{eVerificationId});
            E_Verification__c eVerification = evList[0];
            system.debug('eVerification ++ '+eVerification);
            return eVerification;
        }
        }        
        return null;
    }
    
     @AuraEnabled
    public static String UpdateSMSConsentDetails(String  eVerificationData){
        String Status = 'Failure';
        try{
            E_Verification__c eVerificationObj = (E_Verification__c) JSON.deserialize(eVerificationData, E_Verification__c.class);
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
            fflib_SObjectUnitOfWork Applicantuow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Loan_Applicant__c.SObjectType });
            uow.registerDirty(eVerificationObj);
            uow.commitWork();
            if (eVerificationObj.Loan_Applicant__c != null) {
            Loan_Applicant__c loanApp = new Loan_Applicant__c(
                Id = eVerificationObj.Loan_Applicant__c,
                Is_SMS_Consent_Given__c = true
            );
            Applicantuow.registerDirty(loanApp);
        }
            Applicantuow.commitWork();
            
            Status = 'Success';
        }catch(Exception ex){
            Status = 'Failure';
        }
        return Status;
    }
}