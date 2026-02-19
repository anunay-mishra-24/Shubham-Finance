/**
 * @File Name          : SHF_CKYC_Service.cls
 * @Description        : CKYC accesstoken and ckyc search customer , send otp and download details.
 * @Author             : Riteek Tiwari
 *
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0         11-07-2025            Riteek Tiwari         Initial Version
 */
public with sharing class SHF_CKYC_Service {
    SHF_HTTPCalloutService service;
    
    public static String generateAccessToken() {
        SHF_CKYC_Service ckycAccessToken = new SHF_CKYC_Service();
        ckycAccessToken.service = new SHF_HTTPCalloutService('CKYC_Access_Token');
        
        HttpResponse response;
        try {
            if (ckycAccessToken.service.getIsActive()) {
                response = ckycAccessToken.service.sendRequest();
            } else {
                response = new HttpResponse();
                response.setBody(ckycAccessToken.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            System.debug('CKYC raw response: ' + response.getBody());
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                List<Object> res = (List<Object>) JSON.deserializeUntyped(response.getBody());
                if (res != null && !res.isEmpty()) {
                    Map<String, Object> firstItem = (Map<String, Object>) res[0];
                    Object tokenVal = firstItem.get('TOKEN') != null ? firstItem.get('TOKEN') : firstItem.get('token');
                    if (tokenVal != null) {
                        System.debug('CKYC TOKEN Value: ' + tokenVal);
                        return String.valueOf(tokenVal);
                    } else {
                        System.debug('CKYC token key missing in response: ' + response.getBody());
                    }
                } else {
                    System.debug('CKYC response list is empty.');
                }
            } else {
                System.debug('CKYC response invalid. Status: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Error in CKYC generateAccessToken: ' + e.getMessage());
        }
        return null;
    }
    
    
    //CKYC Search API
    public static String cKYCSearchCustomer(Id customerId, String identityType, String identityNumber) {
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMapSuccess = SHF_CommonUtil.getMessageRecord('CKYC_Search_API');
        system.debug('inside ckyc search ');
        system.debug('inside ckyc search customerId '+customerId);
        system.debug('inside ckyc search identityType '+identityType);
        system.debug('inside ckyc search identityNumber'+identityNumber);
        Savepoint sp;
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Loan_Applicant__c.SObjectType});
            fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType>{E_Verification__c.SObjectType});
            Map<String, API_Fields_Mapping__mdt> fieldMap = SHF_CommonUtil.getAPIFieldsMappingsRecord('CKYC');
            
            String accessToken = generateAccessToken();
            if (String.isBlank(accessToken)) {
                Logger.error('Access token is empty.');
                message = 'Ckyc Access token error';
                return message;
            }
            
            Loan_Applicant__c applicant = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{customerId})[0];
            E_Verification__c everficationObj = SHF_CommonUtil.createVerfication(applicant.Id, SHF_ConstantsUtil.CKYC_RECORD_TYPE, SHF_ConstantsUtil.INPROGRESS_STATUS);
            
            SHF_CKYC_Service ckycService = new SHF_CKYC_Service();
            ckycService.service = new SHF_HTTPCalloutService('CKYC_Search_API');
            
            String idCode = '';
            String idValue = '';
            
            if (identityType == SHF_ConstantsUtil.PAN) {
                idCode = fieldMap.get('CKYC_PAN').Code__c;
                if (identityType == SHF_ConstantsUtil.PAN && String.isBlank(applicant.Pan_Number__c)){
                    message = messageConfigMapSuccess.get('CKYC_Pan_Not_Present').Message__c;
                    return message;
                }
                else{
                    idValue = applicant.Pan_Number__c;
                }
            } else if (identityType == SHF_ConstantsUtil.AADHAAR) {
                idCode = fieldMap.get('CKYC_Aadhaar').Code__c;
                // List<String> parts = String.isNotBlank(identityNumber) ? identityNumber.split(',') : new List<String>();
                if(String.isBlank(applicant.Aadhar_Number__c)){
                    return 'Aadhaar number is mandatrory field please update';
                }
                // String aadhaar = parts.size() > 0 ? parts[0].trim() : '';
                // String name = parts.size() > 1 ? parts[1].trim() : '';
                // String dob = parts.size() > 2 ? parts[2].trim() : '';
                // String gender = parts.size() > 3 ? parts[3].trim() : '';
                String aadhaar = String.isNotBlank(applicant.Aadhar_Number__c) ? applicant.Aadhar_Number__c.substring(applicant.Aadhar_Number__c.length() - 4) : '';
                String name = String.isNotBlank(applicant.Name) ? applicant.Name : '';
                Set<String> salutations = new Set<String>{'MR','MRS','MS','DR','SHRI','SMT','MISS'};
                List<String> parts = name.trim().split('\\s+');
                if (salutations.contains(parts[0].toUpperCase())) {
                    parts.remove(0);
                }
                
                name = String.join(parts, ' ');
                DateTime dt = DateTime.newInstance(applicant.Date_of_Birth__c.year(), applicant.Date_of_Birth__c.month(), applicant.Date_of_Birth__c.day());
                String formattedDob = dt.format('dd-MM-yyyy');
                
                String dob = String.isNotBlank(formattedDob) ? formattedDob : '';
                String gender = String.isNotBlank(applicant.Gender__c) ? applicant.Gender__c.equals('Male') ? 'M' : applicant.Gender__c.equals('Female')? 'F': '' : '';
                
                // if (dob.contains('-')) {
                    //     List<String> dateParts = dob.split('-');
                    //     if (dateParts.size() == 3) {
                        //         dob = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0];
                    //     }
                // }
                
                idValue = aadhaar + '|' + name + '|' + dob + '|' + gender;
            }
            
            String requestBody = ckycService.service.getRequestBody();
            requestBody = requestBody.replace('<IdCode>', String.isNotBlank(idCode) ? idCode : '');
            requestBody = requestBody.replace('<IdValue>', String.isNotBlank(idValue) ? idValue : '');
            requestBody = requestBody.replace('<AccessToken>', String.isNotBlank(accessToken) ? accessToken : '');
            ckycService.service.setRequestBody(requestBody);
            
            // Send request and get response via (API Or Mock)
            Map<String, Object> pidData = new Map<String, Object>();
            HttpResponse response;
            
            if (ckycService.service.getIsActive()) {
                response = ckycService.service.sendRequest();
            } else {
                response = new HttpResponse();
                response.setBody(ckycService.service.getmockRespnse());
                response.setStatusCode(200);
            }
            system.debug('response@ '+response);
            system.debug('response@ '+response.getBody());
            
            if (String.isNotBlank(response.getBody())) {
                Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (res != null && res.containsKey('PID_DATA')) {
                    pidData = (Map<String, Object>) res.get('PID_DATA');
                }
                else{
                    message = 'Ckyc response error';
                }
            }
            else{
                message = 'Ckyc getting null response ';
            }
            
            // Update applicant and verification from response
            if (!pidData.isEmpty()) {
                if (pidData.containsKey('CKYC_REFERENCE_ID')) {
                    String refId = String.valueOf(pidData.get('CKYC_REFERENCE_ID'));
                    everficationObj.CKYC_Reference_ID__c = refId;
                    applicant.CKYC_Reference_ID__c = refId;
                }
                if (pidData.containsKey('KYC_DATE')) {
                    everficationObj.CKYC_Date__c = String.valueOf(pidData.get('KYC_DATE'));
                }
                if (pidData.containsKey('UPDATED_DATE')) {
                    everficationObj.CKYC_Updated_Date__c = String.valueOf(pidData.get('UPDATED_DATE'));
                }
                // if (pidData.containsKey('NAME')) {
                    //     applicant.Name = String.valueOf(pidData.get('NAME'));
                // }
                if (pidData.containsKey('FATHERS_NAME')) {
                    applicant.Fathers_Name__c = String.valueOf(pidData.get('FATHERS_NAME'));
                }
                
                message = messageConfigMapSuccess.get('CKYC_Search_API_Success').Message__c;
            }
            
            // Commit verification and applicant updates
            e_verificationUOW.registerNew(everficationObj);
            e_verificationUOW.commitWork();
            
            applicant.Digilocker_Verification__c = everficationObj.Id;
            uow.registerDirty(applicant);
            
            // Log API response for debugging and auditing
            Logger.info('Request Body ' + ckycService.service.getRequestBody());
            logger.info('status code ' + response.getStatusCode());
            logger.info('status ' + response.getStatus());
            logger.info('Response Body ' + response.getBody());
            
            uow.commitWork();
            
        } catch (Exception e) {
            // Roll back if anything fails
            if (sp != null) {
                //   Database.rollback(sp);
            }
            Logger.error('error ' + e.getMessage() + e.getLineNumber());
            message = messageConfigMapSuccess.get('CKYC_API_Not_Working').Message__c;
        } finally {
            Logger.saveLog();
        }
        return message;
    }
    
    // CKYC Download API
    public static String cKYCCustomerDetails(Id customerId) {
        Map<String,Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('CKYC_Search_API');
        String message = '';
        Savepoint sp;
        try {
            //sp = Database.setSavepoint();
            fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
            String accessToken = generateAccessToken();
            if (String.isBlank(accessToken)) {
                Logger.error('Access token is empty. Cannot proceed.');
                return 'Access token is empty. Cannot proceed.';
            }
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
            Loan_Applicant__c applicant = loanAppList[0];
            
            if (applicant.Digilocker_Verification__c == null) {
                Logger.error('Missing Digilocker_Verification__c on applicant.');
                return 'Missing Digilocker_Verification__c on applicant.';
            }
            E_Verification__c everficationObj = new E_Verification__c(Id = applicant.Digilocker_Verification__c);
            
            SHF_CKYC_Service CKYC_Download_API = new SHF_CKYC_Service();
            CKYC_Download_API.service = new SHF_HTTPCalloutService('CKYC_Download_API');
            
            String requestBody = CKYC_Download_API.service.getRequestBody();
            requestBody = requestBody.replace('<CKYCRefNumber>', String.isNotBlank(applicant.CKYC_Reference_ID__c) ? String.valueOf(applicant.CKYC_Reference_ID__c) : '');
            requestBody = requestBody.replace('<MobileNumber>', String.isNotBlank(applicant.Mobile_Number__c) ? String.valueOf(applicant.Mobile_Number__c) : '');
            requestBody = requestBody.replace('<AccessToken>', String.isNotBlank(accessToken) ? accessToken : '');
            CKYC_Download_API.service.setRequestBody(requestBody);
            
            Map<String, Object> responseMap;
            HttpResponse response;
            
            if (!CKYC_Download_API.service.getIsActive()) {
                response = CKYC_Download_API.service.sendRequest();
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                }
            } else {
                response = new HttpResponse();
                response.setBody(CKYC_Download_API.service.getmockRespnse());
                response.setStatusCode(200);
                
                if (String.isNotBlank(response.getBody())) {
                    Map<String, Object> mockParsed = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    system.debug('mockParsed - '+mockParsed);
                    if (mockParsed != null && mockParsed.containsKey('CKYC_DOWNLOAD_RESPONSE')) {
                        responseMap = (Map<String, Object>) mockParsed.get('CKYC_DOWNLOAD_RESPONSE');
                    }
                }
            }
            system.debug('response@ '+response);
            system.debug('response Body@ '+response.getBody());
            system.debug('response responseMap@ '+responseMap);
            
            if (responseMap != null) {
                if (responseMap.containsKey('HEADER')) {
                    Map<String, Object> header = (Map<String, Object>) responseMap.get('HEADER');
                    system.debug('response header@ '+header);
                    if (header.containsKey('REQUEST_ID')) {
                        everficationObj.Request_ID__c = String.valueOf(header.get('REQUEST_ID'));
                    }
                }
                if (responseMap.containsKey('CKYC_INQ')) {
                    Map<String, Object> ckycInq = (Map<String, Object>) responseMap.get('CKYC_INQ');
                    system.debug('response ckycInq@ '+ckycInq);
                    if (ckycInq.containsKey('ERROR')) {
                        everficationObj.Error_Message__c = String.valueOf(ckycInq.get('ERROR'));
                        if(everficationObj.Error_Message__c.contains('failed')){
                            message = everficationObj.Error_Message__c;
                        }
                        else{
                            message = messageConfigMap.get('CKYC_Search_API_Success').Message__c;
                        }
                        
                    }
                }
            }
            
            logger.info('everficationObj @ ' + everficationObj);
            e_verificationUOW.registerDirty(everficationObj);
            e_verificationUOW.commitWork();
            
            Logger.info('Request Body ' + CKYC_Download_API.service.getRequestBody());
            logger.info('status code ' + response.getStatusCode());
            logger.info('status ' + response.getStatus());
            logger.info('Response Body ' + response.getBody());
            
        } catch (Exception e) {
            // Roll back if anything fails
            if (sp != null) {
                Database.rollback(sp);
            }
            Logger.error('CKYC OTP Exception: ' + e.getMessage());
            message = messageConfigMap.get('CKYC_API_Not_Working').Message__c;
        } finally {
            Logger.saveLog();
        }
        return message;
    }
    
    
    // CKYC Otp verification API
    public static String cKYCSendOTPtoCustomer(Id customerId, String otpVerification) {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Loan_Applicant__c.SObjectType,Address__c.SObjectType});
        fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
        system.debug('customerId '+customerId);
        try {
            String accessToken = generateAccessToken();
            if (String.isBlank(accessToken)) {
                Logger.error('Access token is empty.');
                return 'Access token is empty. Cannot proceed.';
            }
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
            if (loanAppList.isEmpty()) return 'Loan applicant not found.';
            system.debug('loanAppList '+loanAppList);
            Loan_Applicant__c applicant = loanAppList[0];
            
            SHF_CKYC_Service CKYC_OTPVerification_API = new SHF_CKYC_Service();
            CKYC_OTPVerification_API.service = new SHF_HTTPCalloutService('CKYC_OTP_Verification_API');
            
            String requestBody = CKYC_OTPVerification_API.service.getRequestBody();
            requestBody = requestBody.replace('<cKYCNumber>', String.isNotBlank(applicant.CKYC_Reference_ID__c) ? String.valueOf(applicant.CKYC_Reference_ID__c) : '');
            requestBody = requestBody.replace('<OTPNumber>', String.isNotBlank(otpVerification) ? otpVerification : '');
            requestBody = requestBody.replace('<RequestId>', String.isNotBlank(applicant.Digilocker_Verification__r.Request_Id__c) ? String.valueOf(applicant.Digilocker_Verification__r.Request_Id__c) : '');
            requestBody = requestBody.replace('<AccessToken>', String.isNotBlank(accessToken) ? accessToken : '');
            CKYC_OTPVerification_API.service.setRequestBody(requestBody);
            
            Map<String, Object> pidData = new Map<String, Object>();
            HttpResponse response;
            
            if (CKYC_OTPVerification_API.service.getIsActive()) {
                response = CKYC_OTPVerification_API.service.sendRequest();
            } else {
                response = new HttpResponse();
                response.setBody(CKYC_OTPVerification_API.service.getmockRespnse());
                response.setStatusCode(200);
            }
            system.debug('response@ '+response);
            system.debug('response@ '+response.getBody());
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (res != null && res.containsKey('PID_DATA')) {
                    pidData = (Map<String, Object>) res.get('PID_DATA');
                }
                else{
                    return 'CKYC API response is not valid';
                }
                
            }
            
            if (!pidData.isEmpty()) {
                Map<String, Object> personalDetails = (pidData.containsKey('PERSONAL_DETAILS'))
                    ? (Map<String, Object>) pidData.get('PERSONAL_DETAILS') : pidData;
                
                E_Verification__c everficationObj = new E_Verification__c(Id = applicant.Digilocker_Verification__c);
                Map<String, API_Fields_Mapping__mdt> fieldMap = SHF_CommonUtil.getAPIFieldsMappingsRecord('CKYC');
                
                // Applicant details
                if (personalDetails.containsKey('FNAME')) applicant.First_Name__c = String.valueOf(personalDetails.get('FNAME'));
                if (personalDetails.containsKey('MNAME')) applicant.Middle_Name__c = String.valueOf(personalDetails.get('MNAME'));
                if (personalDetails.containsKey('LNAME')) applicant.Last_Name__c = String.valueOf(personalDetails.get('LNAME'));
                if (personalDetails.containsKey('FULLNAME')) applicant.Name = String.valueOf(personalDetails.get('FULLNAME'));
                if (personalDetails.containsKey('FATHER_FULLNAME')) applicant.Fathers_Name__c = String.valueOf(personalDetails.get('FATHER_FULLNAME'));
                if (personalDetails.containsKey('PAN')) applicant.Pan_Number__c = String.valueOf(personalDetails.get('PAN'));
                if (personalDetails.containsKey('MOB_NUM')) applicant.Mobile_Number__c = String.valueOf(personalDetails.get('MOB_NUM'));
                if (personalDetails.containsKey('EMAIL')) applicant.Email__c = String.valueOf(personalDetails.get('EMAIL'));
                if (personalDetails.containsKey('KYC_DATE')) everficationObj.CKYC_Date__c = String.valueOf(personalDetails.get('KYC_DATE'));
                if (personalDetails.containsKey('GENDER')) {
                    String genderDetails = String.valueOf(personalDetails.get('GENDER'));
                    if (genderDetails == fieldMap.get('CKYC_Male').Code__c) {
                        applicant.Gender__c = SHF_ConstantsUtil.MALE;
                    } else if (genderDetails == fieldMap.get('CKYC_Female').Code__c) {
                        applicant.Gender__c = SHF_ConstantsUtil.FEMALE;
                    } else if (genderDetails == fieldMap.get('CKYC_Transgender').Code__c) {
                        applicant.Gender__c = SHF_ConstantsUtil.TRANSGENDER;
                    }
                }
                
                List<Address__c> currentAddressList = new SHF_AddressesSelector().selectCurrentAddressesByApplicantIds(new Set<Id>{customerId});
                Address__c currentAddress;
                
                if (!currentAddressList.isEmpty()) {
                    currentAddress = currentAddressList[0];
                } else {
                    currentAddress = SHF_CommonUtil.createAddress(applicant.Id, SHF_ConstantsUtil.ADDRESS_TYPE); // new
                }
                // Current Address Fields
                currentAddress.Address_Line_1__c = String.valueOf(personalDetails.get('CORRES_LINE1'));
                currentAddress.Address_Line_2__c = String.valueOf(personalDetails.get('CORRES_LINE2'));
                currentAddress.Address_Line_3__c = String.valueOf(personalDetails.get('CORRES_LINE3'));
                currentAddress.District__c       = String.valueOf(personalDetails.get('CORRES_DIST'));
                // currentAddress.State__c          = String.valueOf(personalDetails.get('CORRES_STATE'));
                //  currentAddress.Country__c        = String.valueOf(personalDetails.get('CORRES_COUNTRY'));
                // currentAddress.Pincode__c        = String.valueOf(personalDetails.get('CORRES_PIN'));
                currentAddress.Residence_STD_Code__c        = String.valueOf(personalDetails.get('RESI_STD_CODE'));
                currentAddress.Office_STD_Code__c        = String.valueOf(personalDetails.get('OFF_STD_CODE'));
                
                if (personalDetails.containsKey('CORRES_CITY')) {
                    String cityName = String.valueOf(personalDetails.get('CORRES_CITY'));
                    List<City_Master__c> cityList = new SHF_CitySelector().selectByName(cityName);
                    if (!cityList.isEmpty()) {
                        //   currentAddress.City__c = cityList[0].Id;
                    } else {
                        //    currentAddress.City__c = null;
                    }
                }
                
                // Register current address
                if (!currentAddressList.isEmpty()) {
                    uow.registerDirty(currentAddress);
                } else {
                    uow.registerNew(currentAddress);
                }
                
                // Permanent Address logic
                if (personalDetails.containsKey('PERM_CORRES_SAMEFLAG') &&
                String.valueOf(personalDetails.get('PERM_CORRES_SAMEFLAG')) == 'Y') {
                    
                    List<Address__c> permAddressList = new SHF_AddressesSelector().selectPermanentAddressesByApplicantIds(new Set<Id>{applicant.Id});
                    Address__c permAddress;
                    
                    if (!permAddressList.isEmpty()) {
                        permAddress = permAddressList[0];
                    } else {
                        permAddress = SHF_CommonUtil.createAddress(applicant.Id, SHF_ConstantsUtil.PERMANENT_ADDRESS);
                    }
                    
                    permAddress.Address_Line_1__c = String.valueOf(personalDetails.get('PERM_LINE1'));
                    permAddress.Address_Line_2__c = String.valueOf(personalDetails.get('PERM_LINE2'));
                    permAddress.Address_Line_3__c = String.valueOf(personalDetails.get('PERM_LINE3'));
                    permAddress.District__c       = String.valueOf(personalDetails.get('PERM_DIST'));
                    //  permAddress.State__c          = String.valueOf(personalDetails.get('PERM_STATE'));
                    //  permAddress.Country__c        = String.valueOf(personalDetails.get('PERM_COUNTRY'));
                    // permAddress.Pincode__c        = String.valueOf(personalDetails.get('PERM_PIN'));
                    permAddress.Residence_STD_Code__c  = String.valueOf(personalDetails.get('RESI_STD_CODE'));
                    permAddress.Office_STD_Code__c     = String.valueOf(personalDetails.get('OFF_STD_CODE'));
                    
                    if (personalDetails.containsKey('PERM_CITY')) {
                        String permCityName = String.valueOf(personalDetails.get('PERM_CITY'));
                        List<City_Master__c> permCityList = new SHF_CitySelector().selectByName(permCityName);
                        if (!permCityList.isEmpty()) {
                            //     permAddress.City__c = permCityList[0].Id;
                        } else {
                            //     permAddress.City__c = null;
                        }
                    }
                    
                    if (!permAddressList.isEmpty()) {
                        uow.registerDirty(permAddress);
                    } else {
                        uow.registerNew(permAddress);
                    }
                    
                    
                    // Identity info
                    if (pidData.containsKey('IDENTITY_DETAILS')) {
                        Map<String, Object> identityDetails = (Map<String, Object>) pidData.get('IDENTITY_DETAILS');
                        if (identityDetails.containsKey('IDENTITY')) {
                            Map<String, Object> identity = (Map<String, Object>) identityDetails.get('IDENTITY');
                            if (identity.containsKey('IDENT_NUM')) {
                                everficationObj.Masked_Identity_Number__c = String.valueOf(identity.get('IDENT_NUM'));
                            }
                        }
                    }
                    
                    e_verificationUOW.registerDirty(everficationObj);
                    e_verificationUOW.commitWork();
                    
                    uow.registerDirty(applicant);
                    uow.commitWork();
                    Logger.info('Request Body ' + CKYC_OTPVerification_API.service.getRequestBody());
                    Logger.info('status code ' + response.getStatusCode());
                    Logger.info('status ' + response.getStatus());
                    Logger.info('Body ' + response.getBody());
                }
            }
        } catch (Exception e) {
            Logger.error('CKYC Exception: ' + e.getMessage());
            return 'Getting erro in api, please try again later';
        } finally {
            Logger.saveLog();
        }
        return null;
    }
}