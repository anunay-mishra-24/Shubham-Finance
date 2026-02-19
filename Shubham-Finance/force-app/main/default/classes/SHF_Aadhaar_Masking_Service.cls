/**
* @File Name          : SHF_Aadhaar_Masking_Service.cls
* @Description        : API to masked the aadhaar details to the customer.
* @Author             : Riteek Tiwari
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       17-07-2025      Riteek Tiwari     Initial Version
1.1         20-12-2025      Riteek Tiwari     Updated Version
*/
//Added by Ranjeet without sharing for Public Site Upload Documents
public without sharing class SHF_Aadhaar_Masking_Service {
    public SHF_HTTPCalloutService service;
    
    @AuraEnabled
    public static String aadhaarMasking(String docDetails, string imageFormate, string documentId) {
        Savepoint sp;
        String maskedImage;        
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Document__c.SObjectType});
            Logger.info('imageFormate : ' + imageFormate);
            Logger.info('documentId : ' + documentId);
            SHF_Aadhaar_Masking_Service aadhaarMaskingService = new SHF_Aadhaar_Masking_Service();
            aadhaarMaskingService.service = new SHF_HTTPCalloutService('Aadhaar_Masking_API');
            
            String requestBody = aadhaarMaskingService.service.getRequestBody();
            requestBody = requestBody.replace('<imageFormate>', String.isNotBlank(imageFormate) ? String.valueOf(imageFormate) : '');
            requestBody = requestBody.replace('<docDetails>', String.isNotBlank(docDetails) ? String.valueOf(docDetails) : '');
            aadhaarMaskingService.service.setRequestBody(requestBody);
            
            HttpResponse response;
            if (aadhaarMaskingService.service.getIsActive()) {
                response = aadhaarMaskingService.service.sendRequest();
            } else {
                response = new HttpResponse();
                response.setBody(aadhaarMaskingService.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            String responseBody = response.getBody();
            
            if (response.getStatusCode() == 200 && String.isNotBlank(responseBody)) {
                Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                if (res.containsKey('result')) {
                    Map<String, Object> resultMap = (Map<String, Object>) res.get('result');
                    
                    if (resultMap.containsKey('isMasked')) {
                        Logger.info('Is Masked: ' + String.valueOf(resultMap.get('isMasked')));
                    }
                    
                    if (resultMap.containsKey('maskedImages')) {
                        List<Object> maskedImages = (List<Object>) resultMap.get('maskedImages');
                        if (!maskedImages.isEmpty()) {
                            maskedImage = String.valueOf(maskedImages[0]);
                            system.debug('Masked Image: ' + maskedImage);
                        }
                    }
                }
            }
            
            // =====================================================
           /* if (String.isNotBlank(documentId) && String.isNotBlank(maskedImage)) {
                Blob txtBlob = Blob.valueOf(maskedImage);
                
                ContentVersion cv = new ContentVersion();
                cv.Title = 'Aadhar_Card_' + imageFormate + '.txt';
                cv.PathOnClient = 'Aadhar_Card_' + imageFormate + '.txt';
                cv.VersionData = txtBlob;
                cv.FirstPublishLocationId = documentId;                
                insert cv;
                Logger.info('Masked Aadhaar Base64 attached successfully to Document Id: ' + documentId);
            }*/
            
            String reqBodyLog = aadhaarMaskingService.service.getRequestBody();
            if (reqBodyLog != null && reqBodyLog.length() > 5000) {
                reqBodyLog = reqBodyLog.substring(0, 5000) + '... [TRUNCATED]';
            }
            Logger.info('Request Body: ' + reqBodyLog);
            
            Logger.info('Response Status Code: ' + response.getStatusCode());
            Logger.info('Response Status: ' + response.getStatus());
            system.debug('Response Status: ' + response.getStatus());
            
            String respBodyLog = response.getBody();
            if (respBodyLog != null && respBodyLog.length() > 5000) {
                respBodyLog = respBodyLog.substring(0, 5000) + '... [TRUNCATED]';
            }
            Logger.info('Response Body: ' + respBodyLog);
            system.debug('Response Body: ' + respBodyLog);
        } catch (Exception e) {
            if (sp != null) {
                Database.rollback(sp);
            }
            System.debug('Error in aadhaarMasking: ' + e.getMessage());
            Logger.error('Error: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
        return maskedImage;
    }
    
    //METHOD for Saves Masked Aadhaar File (called after DMS upload in JS)
    @AuraEnabled
    public static void saveMaskedAadhaarToDMS(String maskedImage, String imageFormate, String documentId) {
        try {
            
            if(String.isBlank(maskedImage) || String.isBlank(documentId)) {
                Logger.info('Missing documentId for saving file: ' + documentId);
                String maskedLog = maskedImage;
                if (maskedLog != null && maskedLog.length() > 5000) {
                    maskedLog = maskedLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Missing maskedImage for saving file: ' + maskedLog);
            }
            
            ContentVersion cv = new ContentVersion(
                Title = 'Aadhar_Card_' + Datetime.now().getTime(),
                PathOnClient = 'Aadhar_Card_' + imageFormate,
                VersionData = Blob.valueOf(maskedImage),
                FirstPublishLocationId = documentId
            );
            insert cv;
            
            Logger.info('Masked Aadhaar file saved successfully DocumentId: ' + documentId);
            
        } catch (Exception e) {
            Logger.error('Error in saveMaskedAadhaarToDMS: ' + e.getMessage());
        } finally {
            Logger.saveLog(); 
        }
    }
    
    //* Deletes all attached files for a single Document Id
    @AuraEnabled
    public static void deleteExistingFiles(String documentId) {
        try {
            if(String.isBlank(documentId)) {
                Logger.info('deleteExistingFiles skipped documentId is blank');
                return;
            }
            Logger.info('Checking attached files for DocumentId ' + documentId);
            
            List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId 
                                                  FROM ContentDocumentLink WHERE LinkedEntityId = :documentId];
            
            if(docLinks.isEmpty()) {
                Logger.info('No files found for deletion on DocumentId → ' + documentId);
                return;
            }
            
            Set<Id> contentDocIds = new Set<Id>();
            for(ContentDocumentLink link : docLinks){
                contentDocIds.add(link.ContentDocumentId);
            }
            
            List<ContentDocument> docsToDelete = [ SELECT Id FROM ContentDocument WHERE Id IN :contentDocIds ];
            
            if(!docsToDelete.isEmpty()) {
                delete docsToDelete;
                Logger.info('Deleted ' + docsToDelete.size() + ' file(s) for DocumentId → ' + documentId);
            } else {
                Logger.info('No ContentDocument records found to delete');
            }
        } catch(Exception e) {
            Logger.error('Error while deleting files: ' + e.getMessage());
        } finally {
            Logger.saveLog(); 
        }
    }  
    
}