/**
* @File Name          : SHF_AccountAggregator_Service.cls
* @Description        : Account Aggregator accesstoken and .
* @Author             : Vikas Soni
*
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         04-12-2025            Vikas Soni         Initial Version
*/
public with sharing class SHF_AccountAggregator_Service {
    SHF_HTTPCalloutService service;
    
    public static Map<String,String> generateAccessToken() {
        Map<String,String> retrunValues = new Map<String,String>();
        
        SHF_AccountAggregator_Service accountAggregatorAccessToken = new SHF_AccountAggregator_Service();
        accountAggregatorAccessToken.service = new SHF_HTTPCalloutService('Account_Aggregator_Access_Token');
        
        HttpResponse response;
        try {
            if (accountAggregatorAccessToken.service.getIsActive()) {
                response = accountAggregatorAccessToken.service.sendRequest();
            } else {
                response = new HttpResponse();
                response.setBody(accountAggregatorAccessToken.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            System.debug('Account Aggregator raw response: ' + response.getBody());
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                // List<Object> res = (List<Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('responseMap - '+responseMap);
                
                if (responseMap != null && responseMap.containsKey('token')) {
                    String tokenVal = (String) responseMap.get('token');
                    if (tokenVal != null) {
                        System.debug('Account Aggregator TOKEN Value: ' + tokenVal);
                        retrunValues.put('token',tokenVal);
                        // return tokenVal;
                    } else {
                        System.debug('Account Aggregator token key missing in response: ' + response.getBody());
                    }
                }
                if( responseMap != null && responseMap.containsKey('sessionId')){
                    String sessionId = (String) responseMap.get('sessionId');
                    if (sessionId != null) {
                        System.debug('Account Aggregator TOKEN Value: ' + sessionId);
                        retrunValues.put('sessionId',sessionId);
                        // return sessionId;
                    } else {
                        System.debug('Account Aggregator sessionId key missing in response: ' + response.getBody());
                    }
                }
            } else {
                System.debug('Account Aggregator Access response invalid. Status: ' + response.getStatusCode());
                // message = 'Account Aggregator response invalid';
            }
            Logger.info('Account aggregator Token successfully generated.');
            Logger.info('SHF_AccountAggregator_Service Request - Body: ' + accountAggregatorAccessToken.service.getRequestBody());
            Logger.info('SHF_AccountAggregator_Service Response - Status Code: ' + response.getStatusCode());
            Logger.info('SHF_AccountAggregator_Service Response - Status: ' + response.getStatus());
            Logger.info('SHF_AccountAggregator_Service Response - Body: ' + response.getBody());
        } catch (Exception e) {
            System.debug('Error in Account Aggregator Access generateAccessToken: ' + e.getMessage());
            Logger.error('Account Aggregator API Error: ' + e.getMessage());
            // message = 'Error in Account Aggregator Access generateAccessToken';
        } finally {
            Logger.saveLog();
        }
        return retrunValues;
    }
    
    @AuraEnabled
    public static String getInitiateAccountAggregator(String customerId){
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('Account_Aggregator');
        List<Message_Service__e> msgServicelist = new List<Message_Service__e>();
        Notification_Template__mdt notificationMTD = [SELECT Id, DeveloperName, SMS_Notification__c FROM Notification_Template__mdt
                                                      WHERE DeveloperName = :SHF_ConstantsUtil.ACCOUNT_AGGREGRATOR];
        system.debug('notificationMTD-->'+notificationMTD.SMS_Notification__c);
        Logger.info('notificationMTD: ' + notificationMTD);
        Savepoint sp;
        try {
            
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new Schema.SObjectType[] {E_Verification__c.SObjectType});
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork( new List<SObjectType> {Loan_Applicant__c.SObjectType});
            
            Map<String,String> accessTokenValues = generateAccessToken();
            if (accessTokenValues.isEmpty()) {
                Logger.error('Access token is empty.');
                message = MessageConfigMap.get('Account_Aggregator_Access_Token_Error').Message__c;
                return message;
            }
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ customerId });
            
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + customerId);
                message = MessageConfigMap.get('GST_Loan_Applicant_Error').Message__c;
                return message;
            }
            
            Loan_Applicant__c applicant = loanAppList[0];
            
            SHF_AccountAggregator_Service accountAggregator = new SHF_AccountAggregator_Service();
            accountAggregator.service = new SHF_HTTPCalloutService('Account_Aggregator_RedirectAA_Token');
            
            String requestBody = accountAggregator.service.getRequestBody();
            
            String clientTrnxId = String.valueOf(UUID.randomUUID()); 
            
            requestBody = requestBody.replace('<clienttrnxid>', clientTrnxId);                      
            requestBody = requestBody.replace('<mobilenumber>', applicant.Mobile_Number__c);
            requestBody = requestBody.replace('<sessionId>', accessTokenValues.get('sessionId'));
            requestBody = requestBody.replace('<panNumber>', String.isNotBlank(applicant.Pan_Number__c) ? applicant.Pan_Number__c : '');
            accountAggregator.service.setRequestBody(requestBody);
            
            accountAggregator.service.setHeaderParameter('Content-Type', 'application/json' );
            accountAggregator.service.setHeaderParameter('Authorization', 'Bearer '+ accessTokenValues.get('token'));
            HttpResponse response;
            
            if (accountAggregator.service.getIsActive()) {
                response = accountAggregator.service.sendRequest();
            } else {
                response = new HttpResponse();
                response.setBody(accountAggregator.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            E_Verification__c everficationObj = SHF_CommonUtil.createVerfication(applicant.Id, SHF_ConstantsUtil.CAMS_VERIFICATION_RECORD_TYPE, SHF_ConstantsUtil.INPROGRESS_STATUS);
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                // List<Object> res = (List<Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('responseMap - '+responseMap);
                
                if (responseMap != null && !responseMap.isEmpty()) {
                    
                    if (responseMap.containsKey('txnid')) {
                        everficationObj.Transaction_Id__c = (String) responseMap.get('txnid');
                    }
                    if (responseMap.containsKey('clienttxnid')) {
                        everficationObj.Client_Txn_Id__c = (String) responseMap.get('clienttxnid');
                    }
                    if (responseMap.containsKey('sessionId')) {
                        everficationObj.Session_Id__c = (String) responseMap.get('sessionId');
                    }
                    if (responseMap.containsKey('redirectionurl')) {
                        String redirectionurl = (String) responseMap.get('redirectionurl');
                        redirectionurl = redirectionurl.replaceAll('=+$', '');
                        everficationObj.Redirection_URL__c = (String) responseMap.get('redirectionurl');
                        logger.info('redircting URL - '+redirectionurl);
                        //Send SMS
                        msgServicelist.add(new Message_Service__e(
                            Receiver__c	= applicant.Mobile_Number__c,
                            Message_Template__c = SHF_CommonUtil.formatSMSTemplate(notificationMTD.SMS_Notification__c).replace('<redirectingURL>', redirectionurl)
                        ));
                        //
                    }
                    if (responseMap.containsKey('consentHandle')) {
                        everficationObj.Consent_Handle__c = (String) responseMap.get('consentHandle');
                    }
                    /*if (responseMap.containsKey('consentHandle')) {
                        String consentValue = (String) responseMap.get('consentHandle');
                        if (String.isNotBlank(consentValue)) {
                            List<String> values = consentValue.split(',');
                            everficationObj.Description__c = values.size() > 1 ? values[1] : values[0];
                        }
                    }*/
                    
                    if (responseMap.containsKey('consentHandle')) {
                        String consentValue = (String) responseMap.get('consentHandle');
                        if (String.isNotBlank(consentValue)) {
                            List<String> values = consentValue.replace(' ', '').split(',');
                            everficationObj.Consent_Handle_Periodic__c = values[values.size() - 1];
                        }
                    }                    
                }
                message = MessageConfigMap.get('Account_Aggregator_Success').Message__c;
            } else{
                message = MessageConfigMap.get('Account_Aggregator_Error_Catch').Message__c;
            }
            if (!msgServicelist.isEmpty()) {
                Logger.info('msgServicelist',msgServicelist);
                Database.SaveResult[] results = EventBus.publish(msgServicelist);
                message = 'Account_Aggregator_Success';
                Logger.info('results',results);
            }
            
            if (everficationObj != null) {
                uow.registerNew(everficationObj);                        
                uow.commitWork(); 
                applicant.Account_Aggregator_CAM__c = everficationObj.Id;                        
                applicantUow.registerDirty(loanAppList);
                applicantUow.commitWork(); 
                sp = database.setSavepoint();
                Logger.info('everficationObj record: ' + everficationObj);                
            }
            
            Logger.info('SHF_AccountAggregator_Service Request - Body: ' + accountAggregator.service.getRequestBody());
            Logger.info('SHF_AccountAggregator_Service Response - Status Code: ' + response.getStatusCode());
            Logger.info('SHF_AccountAggregator_Service Response - Status: ' + response.getStatus());
            Logger.info('SHF_AccountAggregator_Service Response - Body: ' + response.getBody());
            
        } catch (Exception e) {
            // Roll back if anything fails
            if (sp != null) {
                //   Database.rollback(sp);
            }
            Logger.error('error ' + e.getMessage()+e.getLineNumber());
            message = MessageConfigMap.get('Account_Aggregator_Error_Catch').Message__c;
        } finally {
            Logger.saveLog();
        }       
        return message;
    }
    
    @AuraEnabled
    public static String getManualFetchAccountDetails(String customerId) {
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap =
            SHF_CommonUtil.getMessageRecord('Account_Aggregator');
        Savepoint sp;
        
        try {
            fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType>{E_Verification__c.SObjectType});
            // Access Token
            Map<String, String> accessTokenValues = generateAccessToken();
            if (accessTokenValues.isEmpty()) {
                Logger.error('Access token is empty.');
                return messageConfigMap.get('Account_Aggregator_Access_Token_Error').Message__c;
            }
            // Fetch Applicant
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ customerId });
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for ID: ' + customerId);
                return 'Applicant not found';
            }
            Loan_Applicant__c applicant = loanAppList[0];
            
            if (applicant.Account_Aggregator_CAM__c == null) {
                Logger.error('Missing Account_Aggregator_CAM__c on applicant.');
                return 'Missing Account_Aggregator_CAM__c on applicant.';
            }
            
            E_Verification__c everficationObj = new E_Verification__c(Id = applicant.Account_Aggregator_CAM__c);
            
            SHF_AccountAggregator_Service accountAggregator = new SHF_AccountAggregator_Service();
            accountAggregator.service = new SHF_HTTPCalloutService('Account_Aggregator_Manual_Fetch');
            
            String requestBody = accountAggregator.service.getRequestBody();
            requestBody = requestBody.replace('<sessionId>', accessTokenValues.get('sessionId'));
            requestBody = requestBody.replace('<txnid>', '7ecf11d0-dede-400b-8822-52ef5a831d34');
            requestBody = requestBody.replace('<consentId>', 'f12980db-f877-4387-bcb1-d05f3b96537a');
            accountAggregator.service.setRequestBody(requestBody);
            
            accountAggregator.service.setHeaderParameter('Content-Type', 'application/json');
            accountAggregator.service.setHeaderParameter('Authorization','Bearer ' + accessTokenValues.get('token'));
            
            HttpResponse response;
            
            if (accountAggregator.service.getIsActive()) {
                response = accountAggregator.service.sendRequest();
            } else {
                response = new HttpResponse();
                response.setBody(accountAggregator.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            Logger.info('Manual Fetch Response Body Raw: ' + response.getBody());
            
            Map<String, Object> responseMap;
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                /* if (responseMap.containsKey('txnId')) {
                everficationObj.ManualFetch_TxnId__c = String.valueOf(responseMap.get('txnId'));
                }*/
                
                if (responseMap.containsKey('statusMessage')) {
                    everficationObj.Description__c = String.valueOf(responseMap.get('statusMessage'));
                }
                
                if (responseMap.containsKey('reference_id')) {
                    everficationObj.Reference_Id__c = String.valueOf(responseMap.get('reference_id'));
                }
                
                message = messageConfigMap.get('Account_Aggregator_Success').Message__c;
                
            } else {
                Logger.error('Manual Fetch Failed. StatusCode: ' +response.getStatusCode() + ' Body: ' + response.getBody());
                message = messageConfigMap.get('Account_Aggregator_Error_Catch').Message__c;
            }
            
            // Save E-Verification
            e_verificationUOW.registerDirty(everficationObj);
            e_verificationUOW.commitWork();
            
            Logger.info('Manual Fetch Request Body: ' + accountAggregator.service.getRequestBody());
            System.debug('Manual Fetch Request Body: ' + accountAggregator.service.getRequestBody());
            Logger.info('Manual Fetch Response Status Code: ' + response.getStatusCode());
            Logger.info('Manual Fetch Response Status: ' + response.getStatus());
            Logger.info('Manual Fetch Response Body: ' + response.getBody());
            System.debug('Manual Fetch Response Body: ' + response.getBody());
            
        } catch (Exception e) {
            if (sp != null) {
                // Database.rollback(sp);
            }
            Logger.error('Exception: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
            message = messageConfigMap.get('Account_Aggregator_Error_Catch').Message__c;
            
        } finally {
            Logger.saveLog();
        }
        
        return message;
    }
    
}