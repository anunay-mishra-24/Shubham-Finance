/**
* @File Name          : SHF_AadhaarOCR_Service.cls
* @Description        : .
* @Author             : Vikas Soni
*
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         26-11-2025        Vikas Soni     Initial Version
1.1           27-12-2025      Riteek Tiwari    Updated Version
*/
public with sharing class SHF_AadhaarOCR_Service {
    SHF_HTTPCalloutService service;
    
    @AuraEnabled
    public static String initiateAadhaarOCR(Id customerId){
        Savepoint sp;
        String message = '';
        String fileContentLog = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('Aadhaar_OCR_API');
        
        try {
            system.debug('initiateAadhaarOCR');
            //Step 1: Get Aadhaar Document related to customerId
            List<Document__c> documents = [ SELECT Id, Name, Document_Checklist__r.Name
                                           FROM Document__c WHERE Loan_Applicant__c = :customerId
                                           AND Document_Checklist__r.Name = 'Aadhaar card' LIMIT 1 ];
            
            Document__c aadhaarDocument = (documents.size() > 0) ? documents[0] : null;
            if(aadhaarDocument == null){
                Logger.error('No Aadhaar Card document found for Customer: ' + customerId);
                return 'Aadhaar Document not found';
            }
            
            // Step 2: Fetch Notes & Attachments related to this document
            List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :aadhaarDocument.Id];
            List<ContentVersion> contentNoteList = new List<ContentVersion>();
            
            if(!docLinks.isEmpty()){
                Set<Id> contentDocIds = new Set<Id>();
                for(ContentDocumentLink l : docLinks){
                    contentDocIds.add(l.ContentDocumentId);
                }
                
                // Fetch Notes Content Versions
                contentNoteList = [ SELECT Id, Title, FileType, VersionData, TextPreview
                                   FROM ContentVersion WHERE ContentDocumentId IN :contentDocIds AND Title LIKE 'Aadhar_Card%' ];
            }
            Logger.info('Aadhaar Document Found → ' + aadhaarDocument.Id);
            Logger.info('Notes/ContentVersion Count: ' + contentNoteList.size());
            
             // Aadhaar verification limit validation
            if (contentNoteList == null || contentNoteList.isEmpty()) {
                System.debug('OCR ducument value is null.');
                message = MessageConfigMap.get('Aadhaar_OCR_Upload_Documant_Error').Message__c;
                return message;
            }
            
            if(!contentNoteList.isEmpty()){
                ContentVersion firstNote = contentNoteList[0];
                
                Logger.info('Title: ' + firstNote.Title);
                system.debug('Title: ' + firstNote.Title);
                
                if(firstNote.VersionData != null){
                    fileContentLog = firstNote.VersionData.toString();
                }
                system.debug('File Content: ' + fileContentLog);
                
                String fileFormat = '';
                if(fileContentLog.startsWith('data:')){
                    Integer startIdx = fileContentLog.indexOf('/') + 1;
                    Integer endIdx   = fileContentLog.indexOf(';');
                    if(startIdx > 0 && endIdx > startIdx){
                        fileFormat = fileContentLog.substring(startIdx, endIdx); 
                    }
                }                
                Logger.info('Aadhaar File Format Detected' + fileFormat);
                system.debug('Aadhaar File Format Detected' + fileFormat);
                                
            }
            
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Loan_Applicant__c.SObjectType});
            fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType>{E_Verification__c.SObjectType});
            
            Loan_Applicant__c applicant = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{customerId})[0];
            if (applicant == Null) {
                Logger.error('Loan Applicant not found for Id: ' + customerId);
                return null;
            }
            
             // Aadhaar verification limit validation
            if (applicant.Aadhaar_Verification_Count__c != null && applicant.Aadhaar_Verification_Count__c < 3) {
                System.debug('Digilocker Verification First Validation.');
                message = MessageConfigMap.get('Digilocker_Verification_First_Validation').Message__c;
                return message;
            }
            
            SHF_AadhaarOCR_Service aadhaarService = new SHF_AadhaarOCR_Service();
            aadhaarService.service = new SHF_HTTPCalloutService('Aadhaar_OCR_API');
            
            String requestBody = aadhaarService.service.getRequestBody();
            
            requestBody = requestBody.replace('<base64>', String.isNotBlank(fileContentLog) ? String.valueOf(fileContentLog) : '');
           // requestBody = requestBody.replace('<imageFormate>', String.isNotBlank(imageFormate) ? String.valueOf(imageFormate) : '');
            aadhaarService.service.setRequestBody(requestBody);
            
            HttpResponse response;
            if (aadhaarService.service.getIsActive()) {
                response = aadhaarService.service.sendRequest();
                sp = database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(aadhaarService.service.getmockRespnse());
            }
            
            E_Verification__c everficationObj = SHF_CommonUtil.createVerfication(applicant.Id, SHF_ConstantsUtil.AADHAR_VERIFICATION_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS);
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                
                Map<String, Object> mapResponseResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());  
                if(mapResponseResult != null && mapResponseResult.containsKey('name')){
                    everficationObj.Aadhaar_Full_Name__c = String.valueOf(mapResponseResult.get('name'));
                }
                // if(mapResponseResult != null && mapResponseResult.containsKey('dob')){
                //     everficationObj.Date_of_Birth__c = String.valueOf(mapResponseResult.get('dob'));
                // }
                if(mapResponseResult != null && mapResponseResult.containsKey('address')){
                    everficationObj.Address_Details__c = String.valueOf(mapResponseResult.get('address'));
                }
                if(mapResponseResult != null && mapResponseResult.containsKey('pincode')){
                    everficationObj.Pincode__c = String.valueOf(mapResponseResult.get('pincode'));
                }
                
                if(mapResponseResult != null && mapResponseResult.containsKey('name')){
                    String fullName = String.valueOf(mapResponseResult.get('name')).trim();
                    everficationObj.Aadhaar_Full_Name__c = fullName;
                    
                    List<String> nameParts = fullName.split(' ');
                    applicant.First_Name__c = nameParts.size() > 0 ? nameParts[0] : null;
                    applicant.Last_Name__c  = nameParts.size() > 1 ? nameParts[nameParts.size()-1] : null;
                }
                
                if(mapResponseResult != null && mapResponseResult.containsKey('gender')){
                    everficationObj.Gender__c = String.valueOf(mapResponseResult.get('gender'));
                }
                everficationObj.Aadhar_Verification_Process__c = 'Aadhar OCR';
                applicant.Is_Aadhar_Fetched__c = true;
                //
                message = MessageConfigMap.get('Aadhaar_OCR_API_Success').Message__c;
            }
            else{
                everficationObj.Status__c =  SHF_ConstantsUtil.FAILED_STATUS;
                everficationObj.Aadhar_Verification_Process__c = 'Aadhar OCR';
                everficationObj.Failed_Reason__c = messageConfigMap.get('Aadhaar_OCR_API_Error').Message__c;
                message = MessageConfigMap.get('Aadhaar_OCR_API_Error').Message__c;
            }
            if (everficationObj != null) {
                e_verificationUOW.registerNew(everficationObj);                        
                e_verificationUOW.commitWork(); 
                applicant.Digilocker_Verification__c = everficationObj.Id;                        
                uow.registerDirty(applicant);
                uow.commitWork(); 
                sp = database.setSavepoint();
                Logger.info('everficationObj record: ' + everficationObj);
                String reqBodyLog = aadhaarService.service.getRequestBody();
                if (reqBodyLog != null && reqBodyLog.length() > 5000) {
                    reqBodyLog = reqBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Request Body: ' + reqBodyLog);
                system.debug('Request Body: ' + reqBodyLog);
                Logger.info('Status Code: ' + response.getStatusCode());
                Logger.info('Status: ' + response.getStatus());
                Logger.info('Body: ' + response.getBody());
                system.debug('Body: ' + response.getBody());
                
            }
            
        } catch (Exception ex) {
            if (sp != null) Database.rollback(sp);
            Logger.error('Aadhaar OCR Error: ' + ex.getMessage());
        }
        finally{
            Logger.saveLog();
        }
        return message;
    }
}