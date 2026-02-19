/**
* @File Name          : SHF_Mobile_MNRL_Service.cls
* @Description        : API to check Mobile Details for customer.
* @Author             : Riteek 
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         23-06-2025               Riteek                 Initial Version
*/
public with sharing class SHF_Mobile_MNRL_Service {
    public SHF_HTTPCalloutService service;
    
    @AuraEnabled
    public static String initiateMNRLVerification(Id recordId , string actionName) {
        String message = ''; 
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('Mobile_MNRL_API'); 
        
        try {        
            System.debug('Input recordId: ' + recordId);
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{recordId}); 
            System.debug('Fetched Loan Applicant List Size: ' + loanAppList.size());
            
            if (loanAppList.isEmpty()) {
                System.debug('No Loan Applicant found for Id: ' + recordId);
                return message;
            }
            
            Loan_Applicant__c loanApp = loanAppList[0];
            System.debug('Loan Applicant Details: ' + JSON.serialize(loanApp));
            
            // Check if verification is already completed
            if ((loanApp.Mobile_Verification__r != null && loanApp.Mobile_Verification__r.Status__c == SHF_ConstantsUtil.COMPLETEDSTATUS &&
                 loanApp.Alternate_Mobile_Verification__r != null && loanApp.Alternate_Mobile_Verification__r.Status__c == SHF_ConstantsUtil.COMPLETEDSTATUS)) {
                     
                     System.debug('Mobile Verification is already completed. Skipping new verification.');
                     return 'E_verification_already_completed';
                 }
            
            fflib_SObjectUnitOfWork eVerificationUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
            fflib_SObjectUnitOfWork eVerificationUowAlt = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Loan_Applicant__c.SObjectType });            
            List<E_Verification__c> eVerificationList = new List<E_Verification__c>();
            List<E_Verification__c> eVerificationListAlt = new List<E_Verification__c>();
            
            // Create verification record for Primary number
            if(actionName == SHF_ConstantsUtil.INITIATEPRIMARYVERIFICATION){
                if (loanApp.Mobile_Number__c != null){
                    if((loanApp.Mobile_Verification__r == null || loanApp.Mobile_Verification__r.Status__c != SHF_ConstantsUtil.COMPLETEDSTATUS) && actionName == SHF_ConstantsUtil.INITIATEPRIMARYVERIFICATION){
                        E_Verification__c eVerificationMobile = SHF_CommonUtil.createVerfication(loanApp.Id, SHF_ConstantsUtil.MOBILE_VERIFICATION_RECORD_TYPE, '');
                        eVerificationList.add(eVerificationMobile);
                        eVerificationUow.registerNew(eVerificationMobile); 
                    }else{                   
                        return 'E_verification_already_completed';
                    }                
                }else{
                    return 'Mobile_Number_is_blank';
                }
            }
            
            // Create verification record for Alternate number
            else if (loanApp.Alternate_Mobile_Number__c != null){
                if((loanApp.Alternate_Mobile_Verification__r == null || loanApp.Alternate_Mobile_Verification__r.Status__c != SHF_ConstantsUtil.COMPLETEDSTATUS) && actionName == SHF_ConstantsUtil.INITIATEALTERNATEVERIFICATION){
                    E_Verification__c eVerificationAlt = SHF_CommonUtil.createVerfication(loanApp.Id, SHF_ConstantsUtil.MOBILE_VERIFICATION_RECORD_TYPE, '');
                    eVerificationListAlt.add(eVerificationAlt);
                    eVerificationUowAlt.registerNew(eVerificationAlt); 
                }else{                   
                    return 'E_verification_already_completed';
                }                
            }else{
                return 'Mobile_Number_is_blank';
            }
            
            LOS_Callout_Event__e losCalloutAlternateMobile = new LOS_Callout_Event__e();
            LOS_Callout_Event__e losCalloutMobile = new LOS_Callout_Event__e();
            if(!eVerificationListAlt.isEmpty()){
                eVerificationUowAlt.commitWork();
                loanApp.Alternate_Mobile_Verification__c = eVerificationListAlt[0].Id;               
                losCalloutAlternateMobile.RecordId__c = eVerificationListAlt[0].Id;
                losCalloutAlternateMobile.Event_Type__c = SHF_ConstantsUtil.MOBILEVERIFICATION;
                losCalloutAlternateMobile.Additional_Attributes__c = loanApp.Alternate_Mobile_Number__c != null ? loanApp.Alternate_Mobile_Number__c :'';
                System.debug('Published single losCalloutAlternateMobile: ' + JSON.serialize(losCalloutAlternateMobile));
            }
            if (!eVerificationList.isEmpty()) {
                eVerificationUow.commitWork();
                loanApp.Mobile_Verification__c = eVerificationList[0].Id;               
                losCalloutMobile.RecordId__c = eVerificationList[0].Id;
                losCalloutMobile.Event_Type__c = SHF_ConstantsUtil.MOBILEVERIFICATION;
                losCalloutMobile.Additional_Attributes__c = loanApp.Mobile_Number__c != null ? loanApp.Mobile_Number__c :'';
                System.debug('Published single losCalloutMobile: ' + JSON.serialize(losCalloutMobile));
            } else {
                System.debug('No new E_Verification records created. Skipping commit and event publish.');
            }
            Logger.info('action Name: ' + actionName);
            applicantUow.registerDirty(loanApp);
            applicantUow.commitWork();
            EventBus.publish(losCalloutAlternateMobile);
            EventBus.publish(losCalloutMobile);            
            message = 'Mobile_MNRL_API_Success';
        } catch (Exception ex) {
            message = 'Mobile_Verification_Failed';
            System.debug('Mobile Verification Exception: ' + ex.getMessage() + ' Line: ' + ex.getLineNumber());
            Logger.error('Mobile Verification Exception: ' + ex.getMessage() + ' Line: ' + ex.getLineNumber());
        } finally {
            Logger.saveLog();
        }
        return message;
    }    
    
    public static E_Verification__c processMobileVerification(String mobile, Id eVerificationId) {
        Savepoint sp;
        String message = ''; 
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('Mobile_MNRL_API'); 
        E_Verification__c verificationToReturn;
        System.debug('Number of eVerification records: ' + eVerificationId);
        logger.info('Number of eVerification records: ' + eVerificationId);
        
        try {
            
            if (String.isBlank(mobile)) {
                // return messageConfigMap.get('Mobile_Not_Found').Message__c;
            }
            logger.info('mobile : ' + mobile);
            SHF_Mobile_MNRL_Service mobileService = new SHF_Mobile_MNRL_Service();
            mobileService.service = new SHF_HTTPCalloutService('Mobile_MNRL');
            mobileService.service.setURLParameter('', mobile);
            
            HttpResponse response;
            if (mobileService.service.getIsActive()) {
                response = mobileService.service.sendRequest();
                // sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(mobileService.service.getmockRespnse());
            }
            System.debug('response.getBody(): ' + response.getBody());
            Logger.info('API Response - Body: ' + response.getBody());
            List<E_Verification__c> evList = new E_VerificationSelector().selectByIdsApplicantName(new Set<Id>{eVerificationId});
            system.debug('evList @ '+evList);
            E_Verification__c eVerification; 
            if (!evList.isEmpty()) {
                eVerification = evList[0];
                fflib_SObjectUnitOfWork eVerificationUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    Map<String, Object> mapResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if (mapResponseBody != null && !mapResponseBody.isEmpty()) {
                        if (mapResponseBody.containsKey('msg')) {
                            eVerification.Description__c = String.valueOf(mapResponseBody.get('msg'));
                            Logger.info('String.valueOf(mapResponseBody.get : ' + String.valueOf(mapResponseBody.get('msg')));
                        }
                        if (mapResponseBody.containsKey('isFound')) {
                            String isFoundStr = String.valueOf(mapResponseBody.get('isFound'));
                            eVerification.Mobile_IsFound__c = String.isNotBlank(isFoundStr) && isFoundStr.toLowerCase() == 'true';
                            Logger.info('String.isNotBlank(isFoundStr) : ' + String.isNotBlank(isFoundStr));
                            if(mapResponseBody.get('isFound') == true){
                                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                                message = eVerification.Description__c ;
                            }
                            else {
                                eVerification.Status__c = SHF_ConstantsUtil.COMPLETEDSTATUS;
                                // message = eVerification.Description__c ;
                            }
                        }
                    } else {
                        eVerification.Failed_Reason__c = messageConfigMap.get('Mobile_API_Issue').Message__c;
                        eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    }
                    message = messageConfigMap.get('Mobile_MNRL_API_Success').Message__c;
                } else {
                    eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    eVerification.Failed_Reason__c = messageConfigMap.get('Mobile_API_Issue').Message__c;
                    message = messageConfigMap.get('Mobile_Not_Found').Message__c;
                }
                verificationToReturn = eVerification;
                //  eVerificationUow.registerDirty(eVerification);
                //  eVerificationUow.commitWork();
            }            
            Logger.info('Updated eVerification record: ' + eVerification);
            Logger.info('API Response - Status Code: ' + response.getStatusCode());
            Logger.info('API Response - Status: ' + response.getStatus());
            Logger.info('API Response - Body: ' + response.getBody());
            
        } catch (Exception ex) {
            if (sp != null) Database.rollback(sp);
            Logger.error('Mobile Verification Error: ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
        } finally {
            Logger.saveLog();
        }
        return verificationToReturn;
    }
}