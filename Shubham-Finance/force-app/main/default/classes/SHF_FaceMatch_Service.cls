/**
* @File Name          : SHF_FaceMatch_Service.cls
* @Description        : Service class to face image matching using a base64 encoded image API call and create E_Verification records based on the response.
* @Author             : Riteek Tiwari
* 
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         23-07-2025        Riteek Tiwari    Initial Version
*/

public with sharing class SHF_FaceMatch_Service {
    public SHF_HTTPCalloutService service;

   public static String validateFaceMatch(String firstBase64Image, String secondBase64Image, Id applicantId) {
     Savepoint sp;
   try {
    fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{E_Verification__c.SObjectType, Loan_Applicant__c.SObjectType});

        SHF_FaceMatch_Service faceMatchService = new SHF_FaceMatch_Service();
        faceMatchService.service = new SHF_HTTPCalloutService('Face_Match_API');

        String requestBody = faceMatchService.service.getRequestBody();
        requestBody = requestBody.replace('<FirstBase64Image>', String.isNotBlank(firstBase64Image) ? firstBase64Image : '');
        requestBody = requestBody.replace('<SecondBase64Image>', String.isNotBlank(secondBase64Image) ? secondBase64Image : '');
        faceMatchService.service.setRequestBody(requestBody);

        System.debug('Request Body: ' + requestBody);

        String responseBody = '';
        HttpResponse response;

        if (faceMatchService.service.getIsActive()) {
            response = faceMatchService.service.sendRequest();
             sp = Database.setSavepoint();
        } else {
            response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(faceMatchService.service.getmockRespnse());
        }

        responseBody = response.getBody();
        System.debug('Response Body: ' + responseBody);

        if (response.getStatusCode() == 200) {
            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
             if (applicantId != null) {
            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(applicantId,SHF_ConstantsUtil.CKYC_RECORD_TYPE,SHF_ConstantsUtil.COMPLETEDSTATUS);

            if (resultMap != null && resultMap.containsKey('result')) {
                Map<String, Object> resultData = (Map<String, Object>) resultMap.get('result');

                if (resultData.containsKey('verified')) {
                    eVerification.Status__c = String.valueOf(resultData.get('verified'));
                }

                if (resultData.containsKey('message')) {
                    eVerification.Description__c = String.valueOf(resultData.get('message'));
                }

                if (resultData.containsKey('matchPercentage')) {
                    eVerification.Match_Percentage__c = String.valueOf(resultData.get('matchPercentage'));
                }

                uow.registerNew(eVerification);
                uow.commitWork();
                Logger.info('API Request - Body: ' + faceMatchService.service.getRequestBody());
                Logger.info('status code ' + response.getStatusCode());
                Logger.info('status ' + response.getStatus());
                Logger.info('Body ' + response.getBody());
            }
        }
    }
    } catch (Exception ex) {
         if (sp != null) {
                Database.rollback(sp);
            }
        Logger.error('Exception: ' + ex.getMessage());   
     }finally {
            Logger.saveLog();
        }
    return null;
}
}