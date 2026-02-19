/**
* @File Name          : SHF_DLAuthentication_Service.cls
* @Description        : Service class to verify Driving License details and create E-Verification records.
* @Author             : Riteek Tiwari
* 
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         25-07-2025        Riteek Tiwari    Initial Version
*/
public with sharing class SHF_DLAuthentication_Service {
    public SHF_HTTPCalloutService service;
    
    // Generate access token method
    public static String generateAccessToken() {
        try {
            SHF_DLAuthentication_Service accessTokenDLAuthentication = new SHF_DLAuthentication_Service();
            accessTokenDLAuthentication.service = new SHF_HTTPCalloutService('DL_Authentication_Access_Token');
            
            HttpResponse response;
            String responseBody;
            
            if (accessTokenDLAuthentication.service.getIsActive()) {
                response = accessTokenDLAuthentication.service.sendRequest();
            } else {
                response = new HttpResponse();
                response.setBody(accessTokenDLAuthentication.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            if (response != null && response.getStatusCode() == 200) {
                responseBody = response.getBody();
                System.debug('responseBody@: ' + responseBody);
                if (String.isNotBlank(responseBody)) {
                    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    if (resultMap.containsKey('id')) {
                        System.debug('Id@: ' + resultMap.get('id'));
                         return (String) resultMap.get('id'); 
                    }
                    if (resultMap.containsKey('userId')) {
                        System.debug('UserId@: ' + resultMap.get('userId'));
                       // return (String) resultMap.get('userId');
                    }
                }
            }
        } catch (Exception ex) {
            System.debug('Error in generateAccessToken: ' + ex.getMessage());
        }
        return null;
    }
    
    public static String validateDLDetails(Id applicantId) {
        Savepoint sp;
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('DL_Authentication_API');

        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{E_Verification__c.SObjectType});
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Loan_Applicant__c.SObjectType });
            String accessToken = generateAccessToken();
            if (String.isBlank(accessToken)) {
                Logger.error('Access token is empty. Cannot proceed with export.');
                message = MessageConfigMap.get('DLAuthantication_API_AcccessToken_Issue').Message__c;
                 return message;
            }
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ applicantId });
            
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + applicantId);    
                message = MessageConfigMap.get('DLAuthentication_Applicant_Not_Found').Message__c;
                 return message;
            }
            
            Loan_Applicant__c applicant = loanAppList[0];
            if(String.isBlank(applicant.Driving_License_Number__c)){
                Logger.error('Driving license number not found for applicant Id: ' + applicantId);    
                message = 'Driving license number is not found for applicant';
                 return message;
            }
            String dob = '';
            if (applicant.Date_of_Birth__c != null) {
                Date dobDate = applicant.Date_of_Birth__c;
                String day = dobDate.day() < 10 ? '0' + dobDate.day() : String.valueOf(dobDate.day());
                String month = dobDate.month() < 10 ? '0' + dobDate.month() : String.valueOf(dobDate.month());  
                dob = day + '/' + month + '/' + dobDate.year();
            }else{
                Logger.error('Date of Birth is not found for applicant Id: ' + applicantId);    
                message = 'Date of Birth is not found for applicant';
                 return message;
            }
            
            SHF_DLAuthentication_Service dlVerification = new SHF_DLAuthentication_Service();
            dlVerification.service = new SHF_HTTPCalloutService('DL_Authentication_API'); 
            
            String requestBody = dlVerification.service.getRequestBody();
            requestBody = requestBody.replace('<AccessToken>', accessToken);
            requestBody = requestBody.replace('<DrivingLicenceNumber>', String.isNotBlank(applicant.Driving_License_Number__c) ? applicant.Driving_License_Number__c : '');
            requestBody = requestBody.replace('<DOB>', String.isNotBlank(dob) ? dob : '');
            dlVerification.service.setRequestBody(requestBody);
            System.debug('Request Body: ' + dlVerification.service.getRequestBody());
            
            
            HttpResponse response;
            if (dlVerification.service.getIsActive()) {
                response = dlVerification.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(dlVerification.service.getmockRespnse());
            }

            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(applicantId,SHF_ConstantsUtil.DLAUTHENTICATION_RECORD_TYPE,SHF_ConstantsUtil.COMPLETEDSTATUS);
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> responseMap = (Map<String, Object>) rootMap.get('response');
                
                if (responseMap != null && responseMap.containsKey('result')) {
                    Map<String, Object> resultMap = (Map<String, Object>) responseMap.get('result');
                    
                    if (resultMap.containsKey('verified')) {
                        if(resultMap.get('verified') == 'true'){
                            eVerification.Status__c = 'Completed';
                        }
                        else if(resultMap.get('verified') == 'false'){
                            eVerification.Status__c = 'Failed';
                        }
                        // else{
                        //     eVerification.Status__c = String.valueOf(resultMap.get('verified'));
                        // }
                    }
                    if (resultMap.containsKey('message')) {
                        eVerification.Description__c = String.valueOf(resultMap.get('message'));
                    }
                }
                Logger.info('API Request - Body: ' + dlVerification.service.getRequestBody());
                message = MessageConfigMap.get('DLAuthantication_API_Success').Message__c;
                
            } else {
                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                eVerification.Description__c = 'Driving license Verification API call failed. Status: ' + response.getStatus() + ', Code: ' + response.getStatusCode();
                eVerification.Warning_Code__c = String.valueOf(response.getStatusCode());
                Logger.error('API Request - Body: ' + dlVerification.service.getRequestBody());  
                message = MessageConfigMap.get('DLAuthantication_API_Error').Message__c;
            }
            
            uow.registerNew(eVerification);
            uow.commitWork();
            
            applicant.DL_Verification__c = eVerification.Id;
            applicantUow.registerDirty(applicant);
            applicantUow.commitWork();
            
            Logger.info('API Response - Status Code: ' + response.getStatusCode());
            Logger.info('API Response - Status: ' + response.getStatus());
            Logger.info('API Response - Body: ' + response.getBody());
        } catch (Exception ex) {
            System.debug('Error in validateDlDetails: ' + ex.getMessage());
            Logger.error('Error in validateDlDetails: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }
        
        return message;
    }
}