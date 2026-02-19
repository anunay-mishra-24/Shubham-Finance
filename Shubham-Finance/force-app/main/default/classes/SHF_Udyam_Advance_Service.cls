/**
 * @File Name          : SHF_Udyam_Advance_Service.cls
 * @Description        : Service class to get Udyam Incorporation and Commencement date and create E-Verification records.
 * @Author             : Kunal Soni
 * 
 * ==============================================================================
 * Ver         Date              Author           Modification
 * ==============================================================================
 * 1.0         06-08-2025        Kunal Soni        Initial Version
 * 1.0         20-12-2025        Dimple Kapri      Modified Version
 */
public class SHF_Udyam_Advance_Service {
    
    public SHF_HTTPCalloutService service;

    public static String fetchUdyamAdvDetails(String customerId, String udyamRegNo) {
        Savepoint sp;
        String message = ''; // To return API error/success/validation message
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('UDYAM_API');

        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Loan_Applicant__c.SObjectType });
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ customerId });

            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + customerId);
                return null;
            }
             
              Loan_Applicant__c applicant = loanAppList[0];
              if (applicant.Udyam_Verification__r.Is_Udyam_Registration_Verified__c == true) {
              
                SHF_Udyam_Advance_Service udyamAdvService = new SHF_Udyam_Advance_Service();
                udyamAdvService.service = new SHF_HTTPCalloutService('Udyam_Advance');
                udyamAdvService.service.setRequestTimeout(30000);  
                String requestBody = udyamAdvService.service.getRequestBody();
                requestBody =  requestBody.replace('<udyamNumber>',  String.isNotBlank(udyamRegNo) ? udyamRegNo : '' );
             
                udyamAdvService.service.setRequestBody(requestBody);
                
                System.debug('Request Body: ##' + udyamAdvService.service.getRequestBody());
            
                HttpResponse response;

                if (udyamAdvService.service.getIsActive()) {
                    response = udyamAdvService.service.sendRequest();
                    sp = Database.setSavepoint();
                } else {
                    response = new HttpResponse();
                    response.setStatusCode(200);
                    response.setBody(udyamAdvService.service.getmockRespnse());
                }

                  E_Verification__c eVerification;

                  if (applicant.Udyam_Verification__c != null) {
                   // Fetch existing E-Verification
                  List<E_Verification__c> existingList = new SHF_E_VerificationSelector() 
                    .selectByrecordId(new Set<Id>{ applicant.Udyam_Verification__c });

                  if (!existingList.isEmpty()) {
                   eVerification = existingList[0];
                  }
                 }
   
                // Parse response
                // Fetch Udyam registration date
                //List<String> udyamRegisDate = SHF_Udyam_Registrartion_Service.initiateUdyamRegistration(applicantId);

               /** if (!udyamRegisDate.isEmpty()) {
                SHF_Udyam_Registrartion_Service udyamRegis = new SHF_Udyam_Registrartion_Service();
                udyamRegis.service = new SHF_HTTPCalloutService('Udyam_Advance');
                udyamRegis.service.setRequestBody(
                    udyamRegis.service.getRequestBody().replace('<udyamNumber>', loanAppList[0].Udyam_Registration_Number__c)
                );*/

                    /*if (rootMap.containsKey('result')) {
                        List<Object> resultList = (List<Object>) rootMap.get('result');

                        for (Object resultObj : resultList) {
                            Map<String, Object> resultMap = (Map<String, Object>) resultObj;

                            if (resultMap.containsKey('dateOfCommencement')) {
                                eVerification.Date_of_Commencement__c = String.valueOf(resultMap.get('dateOfRegistration'));
                            } else {
                                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                                message = messageConfigMap.get('Udyam_API_Error').Message__c;
                                Logger.error('Missing dateOfCommencement. Request Body: ' + udyamRegis.service.getRequestBody());
                            }

                            if (resultMap.containsKey('dateOfIncorporation')) {
                                eVerification.Date_of_Incorporation__c = String.valueOf(resultMap.get('dateOfRegistration'));
     
                            } else {
                                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                                message = messageConfigMap.get('Udyam_API_Error').Message__c;
                                Logger.error('Missing dateOfIncorporation. Request Body: ' + udyamRegis.service.getRequestBody());
                            }
                        }*/
                        String responseBody = response.getBody();

                        if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                        Object resultObj = responseMap.get('result');

                        Map<String, Object> resultMap;

                        if (resultObj instanceof Map<String, Object>) {
                            resultMap = (Map<String, Object>) resultObj;

                        } else if (resultObj instanceof List<Object>) {
                          List<Object> resultList = (List<Object>) resultObj;
                          if (!resultList.isEmpty() && resultList[0] instanceof Map<String, Object>) {
                          resultMap = (Map<String, Object>) resultList[0];
                          }
                         }

                        if (resultMap != null) {
                            if (resultMap.containsKey('dateOfCommencement')) {
                                eVerification.Date_of_Commencement__c = String.valueOf(resultMap.get('dateOfCommencement'));
                            }
                            if (resultMap.containsKey('dateOfIncorporation')) {
                                eVerification.Date_of_Incorporation__c = String.valueOf(resultMap.get('dateOfIncorporation'));
     
                            }
                            if (resultMap.containsKey('dateOfRegistration')) {
                                eVerification.Date_of_Registration__c = String.valueOf(resultMap.get('dateOfRegistration'));
     
                            }

                        // -------- Address --------
                       if (resultMap.containsKey('address') && resultMap.get('address') instanceof Map<String, Object>) {
                       Map<String, Object> addressMap = (Map<String, Object>) resultMap.get('address');

                       if (addressMap.containsKey('block')) eVerification.Address_Block__c = String.valueOf(addressMap.get('block'));
                       if (addressMap.containsKey('building')) eVerification.Building__c = String.valueOf(addressMap.get('building'));
                       if (addressMap.containsKey('city')) eVerification.City__c = String.valueOf(addressMap.get('city'));
                       if (addressMap.containsKey('district')) eVerification.District__c = String.valueOf(addressMap.get('district'));
                       if (addressMap.containsKey('flat')) eVerification.Flat__c = String.valueOf(addressMap.get('flat'));
                       if (addressMap.containsKey('email')) eVerification.Email__c = String.valueOf(addressMap.get('email'));
                       if (addressMap.containsKey('emailDomain')) eVerification.Email_Domain__c = String.valueOf(addressMap.get('emailDomain'));
                       if (addressMap.containsKey('contact')) eVerification.Contact__c = String.valueOf(addressMap.get('contact'));
                       if (addressMap.containsKey('pincode')) eVerification.Pincode__c = String.valueOf(addressMap.get('pincode'));
                       if (addressMap.containsKey('road')) eVerification.Road__c = String.valueOf(addressMap.get('road'));
                       if (addressMap.containsKey('state')) eVerification.State__c = String.valueOf(addressMap.get('state'));
                       if (addressMap.containsKey('village')) eVerification.Village__c = String.valueOf(addressMap.get('village'));
                       if (addressMap.containsKey('maskedContact')) eVerification.Masked_Contact__c = String.valueOf(addressMap.get('maskedContact'));
                      }

                       if (resultMap.containsKey('enterpriseTypeDetails') && resultMap.get('enterpriseTypeDetails') instanceof List<Object>) {

                       List<Object> enterpriseList = (List<Object>) resultMap.get('enterpriseTypeDetails');

                       if (!enterpriseList.isEmpty() && enterpriseList[0] instanceof Map<String, Object>) {

                       Map<String, Object> enterpriseMap = (Map<String, Object>) enterpriseList[0];

                       if (enterpriseMap.containsKey('type')) eVerification.Enterprise_Type__c = String.valueOf(enterpriseMap.get('type'));
                       if (enterpriseMap.containsKey('classificationDate')) eVerification.Classification_Date__c = String.valueOf(enterpriseMap.get('classificationDate'));
                       if (enterpriseMap.containsKey('dataYear')) eVerification.Data_Year__c = String.valueOf(enterpriseMap.get('dataYear'));
                       if (enterpriseMap.containsKey('classificationYear')) eVerification.Classification_Year__c = String.valueOf(enterpriseMap.get('classificationYear'));
                      }
                    }
                       message = messageConfigMap.get('Udyam_Advance_Success').Message__c;
                 }

               } else {
                     eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                     Logger.error('API FAILED due to Non-status-200 error ');
                     message = 'API Failed';
                 }
                // Commit records
                    if (eVerification != null ) {
                    uow.registerDirty(eVerification);
                    uow.commitWork();

                    loanAppList[0].Udyam_Verification__c = eVerification.Id;
                    applicantUow.registerDirty(loanAppList);
                    applicantUow.commitWork();

                   Logger.info('Request Body: ' + udyamAdvService.service.getRequestBody());
                   System.debug('Request Body2: ' + udyamAdvService.service.getRequestBody());
                   Logger.info('Status Code: ' + response.getStatusCode());
                   Logger.info('Status: ' + response.getStatus());
                   Logger.info('Body: ' + response.getBody());    
                }
            }
            else{
              Logger.error('Udyam registration is not invoked');
              message = messageConfigMap.get('Udyam_Avance_Error').Message__c;
             }            
        }  catch (Exception ex) {
            if (sp != null) Database.rollback(sp);
            Logger.error('Udyam Verification Error: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }

        return message;
    }
}