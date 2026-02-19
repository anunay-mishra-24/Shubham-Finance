/**
* @File Name          : SHF_PassportVerification_Service.cls
* @Description        : Service class to verify passport details and create E-Verification records.
* @Author             : Riteek Tiwari
* 
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         24-07-2025        Riteek Tiwari    Initial Version
*/
public with sharing class SHF_PassportVerification_Service {
    public SHF_HTTPCalloutService service;
    
    public static String validatePassportDetails(Id applicantId) {
        //Savepoint sp;
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('Passport_Verification_API');
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{E_Verification__c.SObjectType});
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Loan_Applicant__c.SObjectType });
            
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ applicantId });
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + applicantId);
                return null;
            }
            
            Loan_Applicant__c applicant = loanAppList[0];
            String dob = '';
            if (applicant.Date_of_Birth__c != null) {
                Date dobDate = applicant.Date_of_Birth__c;
                String day = dobDate.day() < 10 ? '0' + dobDate.day() : String.valueOf(dobDate.day());
                String month = dobDate.month() < 10 ? '0' + dobDate.month() : String.valueOf(dobDate.month());
                String year = String.valueOf(dobDate.year());
                dob = day + '/' + month + '/' + year;
            }
            
            SHF_PassportVerification_Service passportVerification = new SHF_PassportVerification_Service();
            passportVerification.service = new SHF_HTTPCalloutService('Passport_Verification_API');
            
            String requestBody = passportVerification.service.getRequestBody();
            requestBody = requestBody.replace('<PassportFileNumber>', String.isNotBlank(applicant.Passport_File_Number__c) ? applicant.Passport_File_Number__c : '');
            requestBody = requestBody.replace('<DOB>', String.isNotBlank(dob) ? dob : '');
            requestBody = requestBody.replace('<Name>', String.isNotBlank(applicant.Name) ? applicant.Name : '');
            passportVerification.service.setRequestBody(requestBody);
            
            HttpResponse response;
            if (passportVerification.service.getIsActive()) {
                system.debug('body TEST ' + passportVerification.service);
                response = passportVerification.service.sendRequest();
                system.debug('body @@ ' + response.getBody());
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(passportVerification.service.getmockRespnse());
            }
            system.debug('API Request - Body: ' + passportVerification.service.getRequestBody());
            Logger.info('API Request - Body: ' + passportVerification.service.getRequestBody());
            Logger.info('API Response : ' + response.getBody());
            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(applicantId, SHF_ConstantsUtil.PASSPORT_VERIFICATION_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS);
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> responseMap = (Map<String, Object>) rootMap.get('response');
                
                if (responseMap != null && responseMap.containsKey('result')) {
                    Map<String, Object> resultMap = (Map<String, Object>) responseMap.get('result');
                    
                    if (resultMap.containsKey('verified')) {
                        eVerification.Status__c = String.valueOf(resultMap.get('verified'));
                    }
                    if (resultMap.containsKey('message')) {
                        eVerification.Description__c = String.valueOf(resultMap.get('message'));
                    }
                    message = MessageConfigMap.get('Passport_API_Success').Message__c;
                }
            } else {
                eVerification.Status__c =  SHF_ConstantsUtil.FAILED_STATUS;
                eVerification.Description__c = 'Passport Verification API call failed. Status: ' + response.getStatus() + ', Code: ' + response.getStatusCode();
                Map<String, Object> errorBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (errorBody.containsKey('error')) {
                    Map<String, Object> errorMap = (Map<String, Object>) errorBody.get('error');
                    if (errorMap.containsKey('message')) {
                        eVerification.Error_Message__c = String.valueOf(errorMap.get('message'));
                    }
                }
                message = MessageConfigMap.get('Passport_API_Error').Message__c;
            }
            
            uow.registerNew(eVerification);
            uow.commitWork();
            
            applicant.Passport_Verification__c = eVerification.Id;
            applicantUow.registerDirty(applicant);
            applicantUow.commitWork();
            
            Logger.info('API Request - Body: ' + passportVerification.service.getRequestBody());
            Logger.info('API Response - Status Code: ' + response.getStatusCode());
            Logger.info('API Response - Status: ' + response.getStatus());
            Logger.info('API Response - Body: ' + response.getBody());
            
        } catch (Exception ex) {
            // if (sp != null) Database.rollback(sp);
            Logger.error('Passport Verification Error: ' + ex.getMessage()+' Line '+ ex.getLineNumber());
        } finally {
            Logger.saveLog();
        }
        return message;
    }
}