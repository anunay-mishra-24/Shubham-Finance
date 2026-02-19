/**
 * @File Name          : SHF_Udyam_Registrartion_Service.cls
 * @Description        : Service class to get Udyam registration date and create E-Verification records.
 * @Author             : Kunal Soni
 * 
 * ==============================================================================
 * Ver         Date              Author           Modification
 * ==============================================================================
 * 1.0         06-08-2025        Kunal Soni        Initial Version
 * 1.1         17-12-2025        Dimple Kapri      Modified Version
 */
public class SHF_Udyam_Registrartion_Service {

    public SHF_HTTPCalloutService service;

    public static String initiateUdyamRegistration(String customerId, String udyamRegNo) {
        Savepoint sp;
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('UDYAM_API');

        try{
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Loan_Applicant__c.SObjectType });
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ customerId });

            System.debug('customer Id'+ customerId);
            System.debug('udyamRegNo'+ udyamRegNo);
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + customerId);
                return null;
            }

            Loan_Applicant__c applicant = loanAppList[0];
            System.debug('Applicant' +applicant);
     
            SHF_Udyam_Registrartion_Service udyamRegService = new SHF_Udyam_Registrartion_Service();
            udyamRegService.service = new SHF_HTTPCalloutService('Udyam_Registration');
            udyamRegService.service.setRequestTimeout(30000);
            String requestBody = udyamRegService.service.getRequestBody();
            requestBody = requestBody.replace('<udyamNumber>',  String.isNotBlank(udyamRegNo) ? udyamRegNo : '' );
                 
            udyamRegService.service.setRequestBody(requestBody);
            System.debug('Request Body: ##' + udyamRegService.service.getRequestBody());
           
            HttpResponse response;
            if (udyamRegService.service.getIsActive()) {
                response = udyamRegService.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(udyamRegService.service.getmockRespnse());
           }         

            String responseBody = response.getBody();
            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(customerId, SHF_ConstantsUtil.UDYAM_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS);
            
            if (response.getStatusCode() == 200 && String.isNotBlank(responseBody)) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

                if (responseMap.containsKey('result') && responseMap.get('result') != null) {
                    Map<String, Object> resultMap = (Map<String, Object>) responseMap.get('result');

                      if (resultMap != null && !resultMap.isEmpty()) {
                        if (resultMap.containsKey('udyamRegistrationNo')) eVerification.Udyam_Registration_Number__c = String.valueOf(resultMap.get('udyamRegistrationNo'));
                        if (resultMap.containsKey('dateOfRegistration')) eVerification.Date_of_Registration__c = String.valueOf(resultMap.get('dateOfRegistration'));
                        
                        if (resultMap.containsKey('profile') && resultMap.get('profile') != null) {
                        Map<String, Object> profileMap =(Map<String, Object>) resultMap.get('profile');

                        if (profileMap.containsKey('name')) eVerification.Profile_Name__c = String.valueOf(profileMap.get('name'));
                        if (profileMap.containsKey('majorActivity')) eVerification.Major_Activity__c = String.valueOf(profileMap.get('majorActivity'));
                        if (profileMap.containsKey('organizationType')) eVerification.Organization_Type__c = String.valueOf(profileMap.get('organizationType'));
                        if (profileMap.containsKey('ownerName')) eVerification.Profile_Owner_Name__c = String.valueOf(profileMap.get('ownerName'));
                        if (profileMap.containsKey('dateOfIncorporation')) eVerification.Date_Of_Incorporation__c = String.valueOf(profileMap.get('dateOfIncorporation'));
                        if (profileMap.containsKey('dateOfCommencement')) eVerification.Date_Of_Commencement__c = String.valueOf(profileMap.get('dateOfCommencement'));
                        }
                        message = MessageConfigMap.get('Udyam_Registration_Success').Message__c;
                        System.debug('message'+ message);
                }
                else {
                        eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                        Logger.error('Missing or null "result" node in response'+ udyamRegService.service.getRequestBody());
                        message = MessageConfigMap.get('Udyam_API_Error').Message__c;
                }
              }
            }  else {
                        Logger.error('API FAILED due to Non-status-200 error ');
                        message = 'API Failed';
                 }
            
                uow.registerNew(eVerification);
                uow.commitWork();
                loanAppList[0].Udyam_Verification__c=eVerification.Id;
                applicantUow.registerDirty(loanAppList);
                applicantUow.commitWork();
                Logger.info('Request Body: ' + udyamRegService.service.getRequestBody());
                System.debug('Request Body2: ' + udyamRegService.service.getRequestBody());
                Logger.info('Status Code: ' + response.getStatusCode());
                Logger.info('Status: ' + response.getStatus());
                Logger.info('Body: ' + response.getBody());
               
         }
         catch (Exception e) {
           if (sp != null) Database.rollback(sp);
           Logger.error('Error in Udyam Registration Service: ' + e.getMessage());
           System.debug('Error in Udyam Registration Service: ' + e.getMessage());
         } finally {
            Logger.saveLog();
        }
        return message;
    }
}