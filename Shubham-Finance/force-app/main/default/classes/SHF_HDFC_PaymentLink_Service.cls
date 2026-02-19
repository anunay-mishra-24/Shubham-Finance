public with sharing class SHF_HDFC_PaymentLink_Service {
    
    public SHF_HTTPCalloutService service;
    
    @AuraEnabled
    public static String createPaymentLink(Id loanApplicantId, String qrData, String feeId) {
        String message = ' ';
        Savepoint sp;
        
        try {
            // Fetch message config
            Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('HDFC_PaymentGateway_Link_API');
            if (messageConfigMap == null) messageConfigMap = new Map<String, Messages_Config__mdt>();
            List<Message_Service__e> msgServicelist = new List<Message_Service__e>();
            Notification_Template__mdt notificationMTD = [SELECT Id, DeveloperName, SMS_Notification__c FROM Notification_Template__mdt
                                                          WHERE DeveloperName = :SHF_ConstantsUtil.ACCOUNT_AGGREGRATOR];
            system.debug('notificationMTD-->'+notificationMTD.SMS_Notification__c);
            Logger.info('notificationMTD: ' + notificationMTD);
            
            // UOW for E_Verification
            fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
            
            // Get Applicant
            List<Loan_Applicant__c> applicantList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ loanApplicantId });
            if (applicantList.isEmpty()) {
                Logger.error('Loan Applicant not found');
                // return messageConfigMap.containsKey('Applicant_Not_Found') ? messageConfigMap.get('Applicant_Not_Found').Message__c : 'Applicant not found';
            }
            
            Loan_Applicant__c applicant = applicantList[0];
            if (String.isBlank(applicant.Mobile_Number__c) || String.isBlank(applicant.Email__c)) {
                Logger.error('Loan Applicant email not found');
                // return messageConfigMap.containsKey('Mobile_Email_Not_Found') ? messageConfigMap.get('Mobile_Email_Not_Found').Message__c : 'Mobile/Email not found';
            }
            
            // Initialize HDFC Service
            SHF_HDFC_PaymentLink_Service hdfcPaymentGatewayService = new SHF_HDFC_PaymentLink_Service();
            hdfcPaymentGatewayService.service = new SHF_HTTPCalloutService('HDFC_PaymentGateway_Link_API');
            if (hdfcPaymentGatewayService.service == null) {
                Logger.error('HDFC Payment Gateway Service not configured');
                return 'HDFC Payment Gateway Service not configured';
            }
            
            List<Fees__c> feeRecord = [SELECT Id, Amount__c, Fee_Type__c,Status__c FROM Fees__c WHERE Id =:feeId];
            if(feeRecord == null || feeRecord.isEmpty()){
                return null;
            }
            String requestBody = hdfcPaymentGatewayService.service.getRequestBody();
            if (requestBody == null) requestBody = '';
            String uniqueValue = Math.round(Math.random() * 100) + String.valueOf(System.now().year()).substring(2)+''+System.now().Month()+''+System.now().day()+''+System.now().hour()+''+System.now().Minute()+''+System.now().Second();
            // Replace placeholders safely
            requestBody = requestBody.replace('<orderId>', uniqueValue);
            requestBody = requestBody.replace('<amount>', feeRecord.get(0).Amount__c+'');
            requestBody = requestBody.replace('<customerId>', 'BFL20240512');
            requestBody = requestBody.replace('<email>', applicant.Email__c);
            requestBody = requestBody.replace('<primaryMobileNumber>',('+91' + applicant.Mobile_Number__c));
            requestBody = requestBody.replace('<firstName>', applicant.First_Name__c != null ? applicant.First_Name__c : '');
            requestBody = requestBody.replace('<lastName>', applicant.Last_Name__c != null ? applicant.Last_Name__c : '');
            
            hdfcPaymentGatewayService.service.setRequestBody(requestBody);
            
            // Callout
            HttpResponse response;
            if (hdfcPaymentGatewayService.service.getIsActive()) {
                response = hdfcPaymentGatewayService.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(hdfcPaymentGatewayService.service.getmockRespnse());
            }
            
            // Create Verification Object safely
            E_Verification__c everficationObj = SHF_CommonUtil.createVerfication(
                applicant != null ? applicant.Id : null,
                SHF_ConstantsUtil.PAYMENT_GATEWAY_VERIFICATION_RECORD_TYPE,
                SHF_ConstantsUtil.INPROGRESS_STATUS
            );
            
            // Parse response safely
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                feeRecord.get(0).Order_id__c = uniqueValue;
                update feeRecord;
                Map<String, Object> mapResponseResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (mapResponseResult != null && mapResponseResult.keySet().size() > 0) {
                    
                    /* status Relatedfields */                    
                    if (mapResponseResult.containsKey('status')) {
                        system.debug(mapResponseResult.get('status'));
                        everficationObj.URL__c = String.valueOf(mapResponseResult.get('status'));
                    }
                    
                    if (mapResponseResult.containsKey('id')) {
                        system.debug(mapResponseResult.get('id'));
                    }
                    
                    if (mapResponseResult.containsKey('order_id')) {
                        system.debug(mapResponseResult.get('order_id'));
                    }
                    
                    /* Payment Links */                   
                    if (mapResponseResult.containsKey('payment_links')) {
                        
                        Map<String, Object> paymentLinksMap = (Map<String, Object>) mapResponseResult.get('payment_links');
                        
                        if (paymentLinksMap != null && paymentLinksMap.containsKey('web')) {
                            system.debug(paymentLinksMap.get('web'));
                            String web = (String) paymentLinksMap.get('web');
                            //Send SMS
                            if(qrData == 'SMS'){
                                msgServicelist.add(new Message_Service__e(
                                    Receiver__c	= applicant.Mobile_Number__c,
                                    Message_Template__c = SHF_CommonUtil.formatSMSTemplate(notificationMTD.SMS_Notification__c).replace('<redirectingURL>', web)
                                ));
                            }
                            //
                        }
                        
                        if (paymentLinksMap != null && paymentLinksMap.containsKey('expiry')) {
                            system.debug(paymentLinksMap.get('expiry'));
                        }
                    }
                    
                    /*SDK Details */                    
                    if (mapResponseResult.containsKey('sdk_payload')) {
                        
                        Map<String, Object> sdkPayloadMap =(Map<String, Object>) mapResponseResult.get('sdk_payload');
                        if (sdkPayloadMap.containsKey('requestId')) {
                            system.debug(sdkPayloadMap.get('requestId'));
                        }
                        
                        if (sdkPayloadMap != null && sdkPayloadMap.containsKey('payload')) {
                            
                            Map<String, Object> payloadMap = (Map<String, Object>) sdkPayloadMap.get('payload');
                            if (payloadMap.containsKey('firstName')) {
                                system.debug(payloadMap.get('firstName'));
                                everficationObj.PAN_Full_Name__c = String.valueOf(payloadMap.get('firstName'));
                            }
                            
                            if (payloadMap.containsKey('clientAuthToken')) {
                                system.debug(payloadMap.get('clientAuthToken'));
                            }
                            
                            if (payloadMap.containsKey('customerId')) {
                                system.debug(payloadMap.get('customerId'));
                                everficationObj.Consumer_Number__c = String.valueOf(payloadMap.get('customerId'));
                            }
                            
                            if (payloadMap.containsKey('amount')) {
                                system.debug(payloadMap.get('amount'));
                            }
                            if (payloadMap.containsKey('mandate.maxAmount')) {
                                system.debug(payloadMap.get('mandate.maxAmount'));
                                everficationObj.Amount_Payable__c = String.valueOf(payloadMap.get('mandate.maxAmount'));
                            }
                        }
                    }
                    
                    /*Payment Gateway Values */                  
                    if (mapResponseResult.containsKey('payment_gateway_response')) {
                        
                        Map<String, Object> gatewayRespMap = (Map<String, Object>) mapResponseResult.get('payment_gateway_response');
                        
                        if (gatewayRespMap != null && gatewayRespMap.containsKey('txn_id')) {
                            system.debug(gatewayRespMap.get('txn_id'));
                        }
                        
                        if (gatewayRespMap != null && gatewayRespMap.containsKey('rrn')) {
                            system.debug(gatewayRespMap.get('rrn'));
                        }
                        
                        if (gatewayRespMap != null && gatewayRespMap.containsKey('resp_message')) {
                            system.debug(gatewayRespMap.get('resp_message'));
                        }
                        
                        if (gatewayRespMap != null && gatewayRespMap.containsKey('resp_code')) {
                            system.debug(gatewayRespMap.get('resp_code'));
                        }
                    }
                    
                    message = messageConfigMap.get('HDFC_PaymentGateway_Success').Message__c;
                    
                } else {
                    message = messageConfigMap.get('HDFC_PaymentGateway_Error').Message__c;
                }
                
            } else {
                message = messageConfigMap.containsKey('HDFC_PaymentGateway_Error') ?
                    messageConfigMap.get('HDFC_PaymentGateway_Error').Message__c :
                'Payment link creation failed';
            }
            
            // Commit verification safely
            if (everficationObj != null) {
                e_verificationUOW.registerNew(everficationObj);
                e_verificationUOW.commitWork();
            }
            
            if (!msgServicelist.isEmpty()) {
                Logger.info('msgServicelist',msgServicelist);
                Database.SaveResult[] results = EventBus.publish(msgServicelist);
                //message = 'HDFC Payment Gateway Success';
                Logger.info('results',results);
            }
            
            Logger.info('Request Body :: ' + requestBody);
            Logger.info('QR Data Sent :: ' + qrData);
            Logger.info('Response Body :: ' + (response != null ? response.getBody() : 'null'));
            Logger.info('Status Code :: ' + (response != null ? String.valueOf(response.getStatusCode()) : 'null'));
            
        } catch (Exception ex) {
            if (sp != null) Database.rollback(sp);
            Logger.error('HDFC Payment Link Error :: ' + ex.getMessage());
            // Return actual error message to LWC for debug
            return 'ERROR: ' + ex.getMessage();
        } finally {
            Logger.saveLog();
        }
        
        return message;
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getPrimaryApplicant(Id applicationId, Id loanApplicantId) {
        
        // Validation
        if (applicationId == null) {
            return null;
        }
        
        if (loanApplicantId != null) {
            List<Loan_Applicant__c> applicantList = [ SELECT Id FROM Loan_Applicant__c WHERE Id = :loanApplicantId LIMIT 1 ];
            return applicantList.isEmpty() ? null : applicantList[0].Id;
        }
        
        List<Loan_Applicant__c> primaryApplicantList = [ SELECT Id FROM Loan_Applicant__c WHERE Application__c = :applicationId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1 ];
        return primaryApplicantList.isEmpty() ? null : primaryApplicantList[0].Id;
    }
    
}