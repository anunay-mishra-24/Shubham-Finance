/**
* @File Name          : SHF_VoterIdVerification_Service.cls
* @Description        : Service class to verify Voter ID details and create E-Verification record.
* @Author             : Riteek Tiwari
* 
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         30-07-2025        Riteek Tiwari    Initial Version
*/
public with sharing class SHF_VoterIdVerification_Service {
    public SHF_HTTPCalloutService service;
    
    public static String voterIdVerification(String customerId) {
        Savepoint sp;
        String message = ''; 
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('VOTERID_API');
        
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Loan_Applicant__c.SObjectType });
            
            String accessToken = SHF_DLAuthentication_Service.generateAccessToken();
            if (String.isBlank(accessToken)) {
                Logger.error('Access token generation failed.');
                return MessageConfigMap.get('VoterId_API_AccessToken_Error').Message__c;
            }
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ customerId });
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + customerId);
                return 'Loan applicant not found.';
            }
            Loan_Applicant__c applicant = loanAppList[0];
            
            if(String.isBlank(applicant.Voter_Id_Number__c)){
                Logger.error('Voter Id not found for Id: ' + customerId);
                return 'Voter Id not found.';
            }
            if(String.isBlank(applicant.name)){
                Logger.error('Name not found for Id: ' + customerId);
                return 'Name not found on applicant.';
            }
            String addressState = '';
            List<Address__c> currentAddresses = new SHF_AddressesSelector().selectAddressByApplicantIds(new Set<Id>{ applicant.Id });
            System.debug('### Retrieved Address Records: ' + currentAddresses);
            
            if (!currentAddresses.isEmpty()) {
                Address__c currentAddress = currentAddresses[0];
                System.debug('### Current Address Id: ' + currentAddress.Id);
                
                // Debug the State field
                if (String.isNotBlank(currentAddress.State__c)) {
                    addressState = currentAddress.State__c;
                    System.debug('### Address State: ' + addressState);
                } else {
                    System.debug('### Address State is blank or null');
                     Logger.info('### Address State is blank or null');
                     return 'State is not present on applicant, please update the address state';
                }
            } else {
                System.debug('### No address records found for applicant Id: ' + applicant.Id);
                 Logger.info('### No address records found for applicant Id: ' + applicant.Id);
                 return 'State is not present on applicant, please update the address state';
            }
            
            SHF_VoterIdVerification_Service voterService = new SHF_VoterIdVerification_Service();
            voterService.service = new SHF_HTTPCalloutService('Voter_Id_Verification_API');
            
            String requestBody = voterService.service.getRequestBody();
            requestBody = requestBody
                .replace('<VoterIdNumber>', String.isNotBlank(applicant.Voter_Id_Number__c) ? applicant.Voter_Id_Number__c : '')
                .replace('<AccessToken>', accessToken)
                .replace('<LoanApplicantName>', String.isNotBlank(applicant.Name) ? applicant.Name : '')
                .replace('<State>', String.isNotBlank(addressState) ? addressState : '');
            
            voterService.service.setRequestBody(requestBody);
            System.debug('Request Body: ' + voterService.service.getRequestBody());
            
            HttpResponse response;
            if (voterService.service.getIsActive()) {
                response = voterService.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(voterService.service.getmockRespnse());
            }
            
            System.debug('Response Body: ' + response.getBody());
            String responseBody = response.getBody();
            
            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(customerId, SHF_ConstantsUtil.VOTERID_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS);
            eVerification.Verification__c = SHF_ConstantsUtil.COMPLETEDSTATUS;
            if (response.getStatusCode() == 200 && String.isNotBlank(responseBody)) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                Map<String, Object> resultMap = (Map<String, Object>) responseMap.get('response');
                
                if (resultMap != null && resultMap.get('result') != null) {
                    Logger.info('getresult: ' + resultMap.get('result'));
                    Map<String, Object> result = (Map<String, Object>) resultMap.get('result');     
                    // String verificationValue ;
                    // if(result.get('verification') != null && result.get('verification') == 'true'){
                    //     verificationValue = 'Completed';
                    // }
                    // else if(result.get('verification') != null && result.get('verification') == 'false'){
                    //     verificationValue = 'Failed';
                    // }
                    eVerification.Verification__c = SHF_ConstantsUtil.COMPLETEDSTATUS;
                    // eVerification.Verification__c = result.get('verification') != null ?  verificationValue : null;                   
                    eVerification.Description__c = result.get('message') != null ? String.valueOf(result.get('message')) : null;                   
                    message = MessageConfigMap.get('VoterId_API_Success').Message__c;
                } else {
                    eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    eVerification.Verification__c = SHF_ConstantsUtil.FAILED_STATUS;
                    message = MessageConfigMap.get('VoterId_API_Error').Message__c;
                }
            } else {
                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                eVerification.Verification__c = SHF_ConstantsUtil.FAILED_STATUS;
                message = MessageConfigMap.get('VoterId_API_Error').Message__c;
            }
            
            
            uow.registerNew(eVerification);
            uow.commitWork();
            
            applicant.VoterId_Verification__c = eVerification.Id;
            applicantUow.registerDirty(applicant);
            applicantUow.commitWork();
            
            Logger.info('Request Body: ' + voterService.service.getRequestBody());
            Logger.info('Status Code: ' + response.getStatusCode());
            Logger.info('Status: ' + response.getStatus());
            Logger.info('Response Body: ' + response.getBody());
        } catch (Exception e) {
            if (sp != null) Database.rollback(sp);
            Logger.error('Error in Voter ID Verification Service: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
        return message;
    }
}