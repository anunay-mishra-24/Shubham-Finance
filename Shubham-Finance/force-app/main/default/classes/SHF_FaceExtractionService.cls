/**
* @File Name          : SHF_Aaadhaar_Face_Extraction_Service.cls
* @Description        : API to get the document details and change it to base64 customer.
* @Author             : Riteek Tiwari
* @Test Class         : 
*==============================================================================
* Ver           Date          Author        Modification
*==============================================================================
* 1.0         21-07-2025   Riteek Tiwari    Initial Version
*/
public with sharing class SHF_FaceExtractionService {    
    public SHF_HTTPCalloutService service;
    @AuraEnabled
    public static String aadhaarFaceExtaintion(String docDetails, String type, Id applicantId) {
        Savepoint sp;
        String message = '';
        try {
            logger.info('type: ' + type);
            
            if (String.isBlank(type)) {
                logger.error('Error: Type cannot be blank. Please specify PAN or AADHAAR');
                return 'Error: Type cannot be blank. Please specify PAN or AADHAAR.';
            }
            
            if (applicantId == null) {
                logger.error('Error: Applicant Id cannot be null.');
                return 'Error: Applicant Id cannot be null.';
            }
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ applicantId });
            if (loanAppList == null || loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + applicantId);
                return 'Error: Loan Applicant not found.';
            }
            Loan_Applicant__c loanApp = loanAppList[0];
            
            fflib_SObjectUnitOfWork eVerificationUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType }); 
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Loan_Applicant__c.SObjectType });
            
            SHF_FaceExtractionService faceExtractionService = new SHF_FaceExtractionService();
            faceExtractionService.service = new SHF_HTTPCalloutService('PAN_Aadhaar_Face_Extraction_API');
            
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('url', String.isNotBlank(docDetails) ? docDetails : '');
            gen.writeEndObject();
            
            faceExtractionService.service.setRequestBody(gen.getAsString());
            System.debug('Request Body: ' + gen.getAsString());
            
            HttpResponse response;
            if (faceExtractionService.service.getIsActive()) {
                response = faceExtractionService.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setBody(faceExtractionService.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            if (response == null) {
                Logger.error('Null HTTP response received.');
                return 'Error: No response received from API.';
            }
            
            String responseBody = response.getBody();
            System.debug('Response Body: ' + responseBody);
            
            // Create Verification Record
            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(loanApp.Id, SHF_ConstantsUtil.FACEEXTRACTION_RECORD_TYPE, '');  
            
            if (response.getStatusCode() == 200 && String.isNotBlank(responseBody)) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                if (responseMap != null && responseMap.containsKey('faceUrl')) {
                    String faceResponse = String.valueOf(responseMap.get('faceUrl'));
                    logger.info('Face Response: ' + faceResponse); 
                    
                    if (String.isNotBlank(faceResponse)) {
                        if (type == SHF_ConstantsUtil.PAN) {
                            eVerification.PAN_Face_Extraction_Details__c = faceResponse;
                        } else if (type == SHF_ConstantsUtil.AADHAAR) {
                            eVerification.Aadhaar_Face_Extraction_Details__c = faceResponse;
                        }
                        eVerification.Status__c = SHF_ConstantsUtil.COMPLETEDSTATUS;
                    } else {
                        eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                        eVerification.Description__c = 'Face URL is blank in API response.';
                        message = 'Error: Blank faceUrl received from API.';
                    }
                } else {
                    eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    eVerification.Description__c = 'faceUrl key not found in API response.';
                    message = 'Error: faceUrl not found in response.';
                }
                
                if (String.isBlank(message)) {
                    message = 'Face extraction completed successfully.';
                }
                
            } else {
                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                eVerification.Description__c = 'FaceExtraction API call failed. Status: ' + response.getStatus() + ', Code: ' + response.getStatusCode();
                message = 'Error: Invalid response from face extraction API.';
            }
            eVerificationUow.registerNew(eVerification);
            eVerificationUow.commitWork();
            
            if (type == SHF_ConstantsUtil.PAN) {
                loanApp.PAN_Face_Extraction_Verification__c = eVerification.Id;
            }
            if (type == SHF_ConstantsUtil.AADHAAR) {
                loanApp.Aadhaar_Face_Extraction_Verification__c = eVerification.Id;
            }
            
            applicantUow.registerDirty(loanApp);
            applicantUow.commitWork();
            
            logger.info('Request Body ' + faceExtractionService.service.getRequestBody());
            logger.info('Responsebody: ' + response.getBody());
            logger.info('Status code: ' + response.getStatusCode());
            logger.info('Status get Status: ' + response.getStatus());            
        } catch (Exception ex) {
            if (sp != null) {
                Database.rollback(sp);
            }
            System.debug('Error: ' + ex.getMessage());
            Logger.error('Error in Face Extraction: ' + ex.getMessage());
            message = 'Exception: ' + ex.getMessage();
        } finally {
            Logger.saveLog();
        }
        return message;
    }
}