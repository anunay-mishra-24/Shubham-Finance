/**
* @File Name          : KYCVerify.cls
* @Description        : API to check Digilocker KYC for customer.
* @Author             : Riteek 
* @Test Class         : 
*==============================================================================
* Ver         Date         Author     Modification
*==============================================================================
* 1.0         26-06-2025   Riteek     Initial Version
*/
public with sharing class SHF_KYC_DigiLocker_Service {
    SHF_HTTPCalloutService service;
    // Call CKYC API to generate KYC URL and Transaction ID for the applicant
    
    public static String validateDigilockerKYC(Id customerId) {       
        String message = ''; // Return message from metadata
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('KYC_DigiLocker_API');        
        Savepoint sp;
        try {
            
            // Unit of Work
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Loan_Applicant__c.SObjectType});
            fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
            List<E_Verification__c> insertRecords = new List<E_Verification__c>(); 
            
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ');    
                message = MessageConfigMap.get('CKYC_Applicant_Not_Found').Message__c;
                return message;
            }

            Loan_Applicant__c applicant = loanAppList[0];
            if (applicant.Customer_Type__c.equals('Non-Individual')) {
                System.debug('Non_Individual_Customer_Type');
                message = MessageConfigMap.get('Non_Individual_Customer_Type').Message__c;
                return message;
            }
            if (String.isBlank(applicant.Mobile_Number__c)) {
                System.debug('Mobile number not found.');
                message = MessageConfigMap.get('CKYC_Mobile_Not_Found').Message__c;
                return message;
            }
            
            // Aadhaar verification limit validation
            if (applicant.Aadhaar_Verification_Count__c != null && applicant.Aadhaar_Verification_Count__c >= 3) {
                System.debug('Aadhaar verification limit reached.');
                message = MessageConfigMap.get('Aadhaar_OCR_Limit_Validation').Message__c;
                return message;
            }
            
            Integer randomNumber = Integer.valueOf((Math.random() * 100000000)); //randomNumber required for unique transaction id cration            
            SHF_KYC_DigiLocker_Service CKYC_API = new SHF_KYC_DigiLocker_Service();
            CKYC_API.service = new SHF_HTTPCalloutService('Digilocker_URL_API'); 
            
            String requestBody = CKYC_API.service.getRequestBody();
            requestBody = requestBody.replace('<firstName>', String.isNotBlank(applicant.First_Name__c) ? applicant.First_Name__c : '');
            requestBody = requestBody.replace('<lastName>', String.isNotBlank(applicant.Last_Name__c) ? applicant.Last_Name__c : '');
            requestBody = requestBody.replace('<uid>', (randomNumber != null) ? String.valueOf(randomNumber) : ''); 
            requestBody = requestBody.replace('<MobileNumber>', String.isNotBlank(applicant.Mobile_Number__c) ? applicant.Mobile_Number__c : '');
            requestBody = requestBody.replace('<Email>', String.isNotBlank(applicant.Email__c) ? applicant.Email__c : '');
            CKYC_API.service.setRequestBody(requestBody);
            
            HttpResponse response;
            if (CKYC_API.service.getIsActive()) {
                response = CKYC_API.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(CKYC_API.service.getmockRespnse());
            }
            
            E_Verification__c everficationObj = SHF_CommonUtil.createVerfication(loanAppList[0].Id,SHF_ConstantsUtil.AADHAR_VERIFICATION_RECORD_TYPE,SHF_ConstantsUtil.INPROGRESS_STATUS);
            if (response.getStatusCode() == 200) {
                Map<String, Object> mapResponseResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());                                 
                if (mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('model')) {
                    Map<String, Object> mapResponseBody = (Map<String, Object>) (mapResponseResult.get('model'));
                    
                    if (mapResponseBody != null && mapResponseBody.containsKey('url')) {
                        everficationObj.URL__c = String.valueOf(mapResponseBody.get('url'));
                    }
                    if (mapResponseBody != null && mapResponseBody.containsKey('transactionId')) {
                        everficationObj.Transaction_Id__c = String.valueOf(mapResponseBody.get('transactionId'));
                    }
                    if (mapResponseBody != null && mapResponseBody.containsKey('kycUrl')) {
                        everficationObj.KYC_URL__c = String.valueOf(mapResponseBody.get('kycUrl'));
                    }                    
                    message = messageConfigMap.get('KYC_DigiLocker_API_Success').Message__c;
                } else {
                    everficationObj.Failed_Reason__c = messageConfigMap.get('CKYC_Not_Found').Message__c;
                    everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    message = messageConfigMap.get('CKYC_Not_Found').Message__c;
                }
                everficationObj.Aadhar_Verification_Process__c = 'Digilocker';
                
            } else {
                everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                everficationObj.Aadhar_Verification_Process__c = 'Digilocker';
                everficationObj.Failed_Reason__c = messageConfigMap.get('CKYC_API_Issue').Message__c;
                message = messageConfigMap.get('KYC_DigiLocker_Error').Message__c;
            }
            
            insertRecords.add(everficationObj);
            
            if (!insertRecords.isEmpty()) {
                e_verificationUOW.registerNew(insertRecords[0]);                        
                e_verificationUOW.commitWork(); 
                
                loanAppList[0].Digilocker_Verification__c = insertRecords[0].Id;                        
                List<SObjectField> lstOfObj = new List<SObjectField>{
                    Loan_Applicant__c.Digilocker_Verification__c
                        };
                            uow.registerDirty(loanAppList, lstOfObj);
                uow.commitWork(); 
            }
            logger.info('Request Body '+  CKYC_API.service.getRequestBody());
            logger.info('status code '+response.getStatusCode());
            logger.info('status '+response.getStatus());
            logger.info('Response Body '+response.getBody());
            
        } catch (Exception ex) {
            // Roll back if anything fails
            if (sp != null) {
                Database.rollback(sp);
            }
            Logger.error('error ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }
        return message;
    }
    
    // Call CKYC API based on Transaction ID to fetch the details for the applicant
    public static String validateDigilockerKYCDetails(Id customerId) {
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('KYC_DigiLocker_API');
        String message = '';
        Savepoint sp;
        try {
            fflib_SObjectUnitOfWork uowLoanApp = new fflib_SObjectUnitOfWork(new List<SObjectType> {Loan_Applicant__c.SObjectType});
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType,Address__c.SObjectType});
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
            if (loanAppList[0].Customer_Type__c.equals('Non-Individual')) {
                System.debug('Non_Individual_Customer_Type');
                message = MessageConfigMap.get('Non_Individual_Customer_Type').Message__c;
                return message;
            }
            
            // Aadhaar verification limit validation
            if (loanAppList[0].Aadhaar_Verification_Count__c != null && loanAppList[0].Aadhaar_Verification_Count__c >= 3) {
                System.debug('Aadhaar verification limit reached.');
                message = MessageConfigMap.get('Aadhaar_OCR_Limit_Validation').Message__c;
                return message;
            }
            
            if(!loanAppList.isEmpty() && String.isNotBlank(loanAppList[0].Digilocker_Verification__c)){
                E_Verification__c everficationObj = new E_Verification__c();
                everficationObj.Id =  loanAppList[0].Digilocker_Verification__c; 
                
                SHF_KYC_DigiLocker_Service KYCDetailsCheck = new SHF_KYC_DigiLocker_Service();
                KYCDetailsCheck.service = new SHF_HTTPCalloutService('Digilocker_API_Details');
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('transactionId',String.isNotBlank(loanAppList[0].Digilocker_Verification__r.Transaction_Id__c) ? loanAppList[0].Digilocker_Verification__r.Transaction_Id__c : '');
                KYCDetailsCheck.service.setRequestBody(gen.getAsString());
                
                HttpResponse response;
                if (KYCDetailsCheck.service.getIsActive()) {
                    response = KYCDetailsCheck.service.sendRequest();
                    sp = Database.setSavepoint();
                } else {
                    response = new HttpResponse();
                    response.setStatusCode(200);
                    response.setBody(KYCDetailsCheck.service.getmockRespnse());
                }
                
                sp = Database.setSavepoint();
                Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                string responseMsg = '';
                
                if(response.getStatusCode() == 200){ 
                    if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('model')){
                        Map<String,Object> mapResponseBody = (Map<String,Object>) (mapResponseResult.get('model')); 
                         everficationObj.Status__c = 'Completed';
                        if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('maskedAdharNumber')){
                            everficationObj.Masked_Aadhar_No__c = (String) String.valueOf(mapResponseBody.get('maskedAdharNumber'));
                            loanAppList[0].Aadhar_Number__c = (String) String.valueOf(mapResponseBody.get('maskedAdharNumber'));
                        }
                        if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('name')){
                            everficationObj.Aadhaar_Full_Name__c = (String) String.valueOf(mapResponseBody.get('name'));
                        }
                        if (mapResponseBody.containsKey('name')) {
                            String fullName = String.valueOf(mapResponseBody.get('name'));
                            List<String> parts = fullName.trim().split('\\s+');
                            
                            if (parts.size() == 1) {
                                loanAppList[0].First_Name__c = parts[0];
                            } else if (parts.size() > 1) {
                                loanAppList[0].First_Name__c = parts[0];
                                loanAppList[0].Last_Name__c = parts[parts.size() - 1];
                            }
                        }
                        
                        loanAppList[0].Is_Aadhar_Fetched__c = true;
                        
                        if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('gender')){
                            everficationObj.Gender__c = (String) String.valueOf(mapResponseBody.get('gender'));
                        }             
                        if (mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('dob')) {
                            String dobStr = String.valueOf(mapResponseBody.get('dob'));
                            if (String.isNotBlank(dobStr)) {
                                List<String> parts = dobStr.split('-');
                                if (parts.size() == 3) {
                                    Integer day = Integer.valueOf(parts[0]);
                                    Integer month = Integer.valueOf(parts[1]);
                                    Integer year = Integer.valueOf(parts[2]);
                                    everficationObj.Date_of_Birth__c = Date.newInstance(year, month, day);
                                } else {
                                    System.debug('Unexpected date format: ' + dobStr);
                                }
                            }
                        }
                        if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('docLink')){
                           // everficationObj.Document_Link__c = (String) String.valueOf(mapResponseBody.get('docLink'));
                        }
                        if (mapResponseBody.containsKey('doclink')) {
                            everficationObj.Document_Link__c = String.valueOf(mapResponseBody.get('doclink'));
                        }                        
                        if (mapResponseBody.containsKey('address')) {
                            Map<String, Object> addressMap = (Map<String, Object>) mapResponseBody.get('address');
                            List<String> addressParts = new List<String>();
                            
                            List<String> keysInOrder = new List<String>{'house', 'street', 'landmark', 'loc', 'po', 'dist', 'subdist', 'vtc'};
                                for (String key : keysInOrder) {
                                    if (addressMap.containsKey(key)) {
                                        String value = String.valueOf(addressMap.get(key));
                                        if (String.isNotBlank(value)) addressParts.add(value.trim());
                                    }
                                }
                            
                            everficationObj.Address_Details__c = String.join(addressParts, ', ');
                            
                            if (addressMap.containsKey('pc')) {
                                everficationObj.Pincode__c = String.valueOf(addressMap.get('pc'));
                            }
                        }
                        
                        /* if (mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('pc')) {
                            String pincodeName = String.valueOf(mapResponseBody.get('pc'));
                            
                            if (!String.isBlank(pincodeName)) {
                            Id pincodeId = (new SHF_pincodeSelector()).selectPincodeIdByName(pincodeName);

                                if (pincodeId != null) {
                                    System.debug('Pincode found: ' + pincodeId);
                                } else {
                                    System.debug('No Pincode record found for pincode name: ' + pincodeName);
                                }
                            }
                        }*/
                    }
                    message = messageConfigMap.get('KYC_DigiLocker_API_Success').Message__c;
                    responseMsg = 'KYC_DigiLocker_API_Success';
                }else{
                    everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    everficationObj.Failed_Reason__c = MessageConfigMap.get('CKYC_API_Issue').Message__c;
                    if(mapResponseResult != null && mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('msg')){
                        everficationObj.Description__c = (String) String.valueOf(mapResponseResult.get('msg'));
                        responseMsg = 'CKYC_Not_Found';
                        message = messageConfigMap.get('CKYC_Not_Found').Message__c;
                    }                                                        
                } 
                logger.info('Request Body '+  KYCDetailsCheck.service.getRequestBody());
                logger.info('status code '+response.getStatusCode());
                logger.info('status '+response.getStatus());
                logger.info('Response Body '+response.getBody());
                uow.registerDirty(everficationObj);
                uow.commitWork(); 
                
                uowLoanApp.registerDirty(loanAppList);
                uowLoanApp.commitWork();
                return MessageConfigMap.get(responseMsg).Message__c; 
            }           
        } catch (Exception ex) {
            // Roll back if anything fails
            if (sp != null) {
                Database.rollback(sp);
            }
            Logger.error('error '+ex.getMessage());
            return MessageConfigMap.get('CKYC_Not_Found').Message__c;
        } finally {
            Logger.saveLog();
        }
        return message;
    }   
}