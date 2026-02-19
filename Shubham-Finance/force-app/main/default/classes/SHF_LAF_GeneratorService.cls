/**
 * @File Name : SHF_LAF_GeneratorService.cls
 * @Description : Validate fields & generate LAF PDF on demand
 **/
public without sharing class SHF_LAF_GeneratorService {
    
    @AuraEnabled
    public static Map<String,Object> validateOnly(Id applicationId) {
        return validateAndGenerate(applicationId, false);
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getPrimaryApplicant(Id applicationId) {
        Loan_Applicant__c primaryApplicant = [
            SELECT Id 
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            AND Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        System.debug('### Primary Applicant Found = ' + primaryApplicant);
        return primaryApplicant != null ? primaryApplicant.Id : null;
    }
    
    
    @AuraEnabled
    public static Map<String,Object> generatePDF(Id applicationId) {
        return validateAndGenerate(applicationId, true);
    }
    
    private static Map<String,Object> validateAndGenerate(Id applicationId, Boolean generate) {
        
        Map<String,Object> result = new Map<String,Object>();
        
        try {
            List<String> missing = new List<String>();
            
            Application__c app = [
                SELECT Id, Name, Application_Stage__c
                FROM Application__c 
                WHERE Id = :applicationId
            ];
            
            // Fetch the RM Selfie document 
            List<Document__c> selfieDocs = [
                SELECT Id 
                FROM Document__c 
                WHERE Application__c = :applicationId 
                AND File_Name__c = 'RM Selfie' 
                AND Document_Category__c = 'Loan Specific Documents'
                LIMIT 1
            ];
            
            if(selfieDocs.isEmpty()) {
                missing.add('Please upload RM Selfie first before generating LAF.');
            } else {
                Document__c selfieDoc = selfieDocs[0];
                
                // Check if any attachment exists for this document
                List<Attachment> attList = [
                    SELECT Id, Name 
                    FROM Attachment 
                    WHERE ParentId = :selfieDoc.Id 
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
                
                if(attList.isEmpty()) {
                    missing.add('Please upload RM Selfie first before generating LAF.');
                }
            }
            
            
            if(String.isBlank(app.Name)) missing.add('Application Name');
            
            List<Loan_Applicant__c> applicants = [
                SELECT Id,Name, First_Name__c, Last_Name__c, Aadhar_Number__c,Mobile_Number__c, PAN_Number__c,Entity_Name__c,RecordType.DeveloperName
                FROM Loan_Applicant__c
                WHERE Application__c = :applicationId AND IsDeleted__c = False
            ];
            
            if(applicants.isEmpty()) {
                missing.add('At least one Loan Applicant');
            } else {
                for(Loan_Applicant__c la : applicants) {
                    List<String> applicantMissing = new List<String>();
                    
                    if (la.RecordType != null && la.RecordType.DeveloperName == 'Individual') {
                        if (String.isBlank(la.First_Name__c))    applicantMissing.add('First Name');
                        if (String.isBlank(la.Last_Name__c))     applicantMissing.add('Last Name');
                        //if (String.isBlank(la.Aadhar_Number__c)) applicantMissing.add('Aadhar Number');
                        if (String.isBlank(la.PAN_Number__c))    applicantMissing.add('PAN Number');
                        if (String.isBlank(la.Mobile_Number__c)) applicantMissing.add('Primary Mobile Number');
                    }
                    else if (la.RecordType != null && la.RecordType.DeveloperName == 'Non_Individual') {
                        if (String.isBlank(la.Entity_Name__c))   applicantMissing.add('Entity Name');
                        if (String.isBlank(la.PAN_Number__c))    applicantMissing.add('PAN Number');
                        if (String.isBlank(la.Mobile_Number__c)) applicantMissing.add('Primary Mobile Number');
                    }
                    
                    if(!applicantMissing.isEmpty()) {
                        String applicantName = !String.isBlank(la.Name)? la.Name: (la.First_Name__c + ' ' + la.Last_Name__c).trim();
                        String formattedMissing = '"' + String.join(applicantMissing, '", "') + '"';
                        
                        missing.add(
                            'Please fill the mandatory information, ' + formattedMissing + ' for ' + applicantName + '.'
                            );
                    }
                }
                if(!applicants.isEmpty()){
                    Set<Id> applicantIds = new Set<Id>();
                    for(Loan_Applicant__c la : applicants) applicantIds.add(la.Id);
                    
                    // Fetch required KYC documents
                    List<Document__c> allDocs = [
                    SELECT Id, Loan_Applicant__c, File_Name__c
                    FROM Document__c
                    WHERE Loan_Applicant__c IN :applicantIds
                      AND Document_Category__c = 'KYC Documents'
                      AND File_Name__c IN ('Applicant Photo', 'Applicant Signature')
                ];
                    
                    Map<Id, Set<String>> applicantToDocNames = new Map<Id, Set<String>>();
                    Map<Id, Id> docToApplicant = new Map<Id, Id>();
                    for(Document__c doc : allDocs){
                        docToApplicant.put(doc.Id, doc.Loan_Applicant__c);
                        if(!applicantToDocNames.containsKey(doc.Loan_Applicant__c)) applicantToDocNames.put(doc.Loan_Applicant__c, new Set<String>());
                        applicantToDocNames.get(doc.Loan_Applicant__c).add(doc.File_Name__c);
                    }
                    
                    // Fetch attachments in bulk
                    Map<Id, Boolean> docWithAttachment = new Map<Id, Boolean>();
                    if(!docToApplicant.isEmpty()){
                        List<Attachment> attachments = [SELECT Id, ParentId FROM Attachment WHERE ParentId IN :docToApplicant.keySet()];
                        for(Attachment att : attachments) docWithAttachment.put(att.ParentId, true);
                    }
                    
                    // Identify missing docs per applicant
                    Set<String> requiredDocs = new Set<String>{'Applicant Photo','Applicant Signature'};
                    for(Loan_Applicant__c la : applicants){
                        Set<String> missingDocs = new Set<String>();
                        Set<String> uploadedDocs = applicantToDocNames.containsKey(la.Id) ? applicantToDocNames.get(la.Id) : new Set<String>();
                        missingDocs.addAll(requiredDocs);
                        missingDocs.removeAll(uploadedDocs);
                        
                        // Check uploaded docs without attachment
                        if(applicantToDocNames.containsKey(la.Id)){
                            for(Document__c doc : allDocs){
                                if(doc.Loan_Applicant__c == la.Id && !docWithAttachment.containsKey(doc.Id)){
                                    missingDocs.add(doc.File_Name__c);
                                }
                            }
                        }
                        
                        if(!missingDocs.isEmpty()){
                            String applicantName = !String.isBlank(la.Name) ? la.Name : (la.First_Name__c + ' ' + la.Last_Name__c).trim();
                            missing.add('Please upload ' + applicantName + ' - ' + String.join(new List<String>(missingDocs), ', ') + ' first before generating LAF.');
                        }
                    }
                }
            }
            
            if(!missing.isEmpty()){
                result.put('status','error');
                result.put('missing',missing);
                return result;
            }
            
            // if(!generate) {
                //     result.put('status','success');
                //     result.put('message','Validation passed');
                //     return result;
            // } // Commneted by vikas for an requirenment 1200 laf ticket
            
            PageReference pr = Page.SHF_LAF_Form;
            pr.getParameters().put('id', applicationId);
            Blob pdfBlob = pr.getContentAsPDF();
            
            List<Document__c> docs = [
                SELECT Id, File_Name__c , Name,Document_Category__c
                FROM Document__c 
                WHERE Application__c = :applicationId
                AND Document_Category__c = 'Loan Specific Documents'
                AND Mandatory_Document__c = TRUE
                //   AND Name LIKE '%Loan Application Form%'
                AND File_Name__c LIKE '%Loan Application Form%'
                LIMIT 1
            ];
            
            System.debug('### Existing Docs Found = ' + docs.size());
            
            String base64Pdf = EncodingUtil.base64Encode(pdfBlob);
            Document__c doc;
            
            if(!docs.isEmpty()) {
                doc = docs[0];
            } else {
                System.debug('### CREATING NEW DOCUMENT RECORD...');
                doc = new Document__c();
                doc.File_Name__c = 'Loan Application Form';
                //doc.Name = 'Loan Application Form';
                doc.Stage__c = 'QDE';
                doc.Mandatory_Document__c = TRUE;
                doc.Document_Category__c = 'Loan Specific Documents';
                doc.Application__c = applicationId;
                doc.Status__c = 'Uploaded';
                doc.Document_Received_Date__c = Date.today();
                doc.Document_Source__c = 'API';
                System.debug('>>> Before Insert Source = ' + doc.Document_Source__c);
                insert doc;
                System.debug('>>> After Insert Source = ' + doc.Document_Source__c);
            }
            
            result.put('status','success');
            result.put('message','Loan Application Form generated successfully');
            result.put('docId', doc.Id);
            result.put('fileName', doc.File_Name__c);
            result.put('fileBase64', base64Pdf);
            system.debug('doc Id  = '+doc.Id);
            List<ContentDocumentLink> contentDocLink = [SELECT Id, ContentDocumentId,LinkedEntityId
                                                        FROM ContentDocumentLink 
                                                        WHERE LinkedEntityId = :doc.Id LIMIT 1];
            String contendocId ;

            if(contentDocLink != null && !contentDocLink.isEmpty()) {
                contendocId = contentDocLink.get(0).ContentDocumentId;
            }
            else{
                contendocId = null;
            }
            UploadResponse response = uploadAndSendToDMS(doc.File_Name__c, base64Pdf,doc.Id,contendocId);
            
            
            if(!response.success) {
                result.put('status','error');
                result.put('message','Loan Application Form generation failed, unable to create content version');
            }
            else if (response.success){
                doc.Public_View_Url__c = response.publicUrl;
                result.put('publicUrl',response.publicUrl);
                Update doc;
                result.put('status','success');
                result.put('message','Loan Application Form generated successfully');
                result.put('docId', doc.Id);
            }
            return result;
            
        } catch(Exception e) {
            System.debug('LAF ERROR => ' + e.getMessage()+e.getLineNumber());
            result.put('status','error');
            result.put('message', e.getMessage());
            return result;
        }
    }
    
    @AuraEnabled
    public static UploadResponse uploadAndSendToDMS(String fileName,String base64Data,Id documentId,Id existingContentDocumentId) {
        UploadResponse response = new UploadResponse();
        try {
            Blob fileBlob = EncodingUtil.base64Decode(base64Data);
            
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName + '.pdf';
            cv.PathOnClient =  fileName +'.pdf';
            cv.VersionData = fileBlob;
            cv.IsMajorVersion = true;
            
            // Maintain versioning
            if (existingContentDocumentId != null) {
                cv.ContentDocumentId = existingContentDocumentId;
            }
            
            insert cv;
            
            // Fetch ContentDocumentId
            cv = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
            ];
            
            // Link to record (first time only)
            if (existingContentDocumentId == null) {
                ContentDocumentLink cdl = new ContentDocumentLink(
                    ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = documentId,
                ShareType = 'V',
                Visibility = 'AllUsers'
                    );
                insert cdl;
            }
            
            // for public url
            ContentDistribution dist = new ContentDistribution();
            dist.Name = 'Public File Link';
            dist.ContentVersionId = cv.Id;
            dist.PreferencesAllowViewInBrowser = true;
            dist.PreferencesLinkLatestVersion = true;
            dist.PreferencesAllowOriginalDownload = true;
            dist.PreferencesNotifyOnVisit = false;
            
            insert dist;
            dist = [SELECT DistributionPublicUrl
                        FROM ContentDistribution
                        WHERE Id = :dist.Id];
            
            
            response.publicUrl = dist.DistributionPublicUrl;
            response.success = true;
            response.contentDocumentId = cv.ContentDocumentId;
            // response.message = 'File uploaded and sent to DMS successfully';
            response.message = 'File uploaded successfully';
            
        } catch (Exception e) {
            response.success = false;
            response.message = 'File upload failed: ' + e.getMessage();
        }
        
        return response;
    }
    
    public class UploadResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String publicUrl;
        
    }
    
    
    @AuraEnabled
    public static void markLAFGenerated(Id applicationId){
        System.debug('markLAFGenerated START');
        Application__c app = new Application__c(
            Id = applicationId,
        Is_LAF_Generated__c = TRUE
            );
        update app;
        System.debug('Application updated successfully. Is_LAF_Generated__c set to TRUE');
    }
    
    @AuraEnabled
    public static void sendOtpSms(String mobile, String otp) {
        
        Map<String, String> templateData =
            SHF_CommonUtil.getNotificationTemplate('LAF_Consent_For_RM');
        
        if (templateData == null) {
            throw new AuraHandledException('Notification template not found');
        }
        
        String smsTemplate = templateData.get('SMS_Notification');
        
        // Replace variable placeholder
        String finalMessage = smsTemplate.replace('{#var#}', otp);
        
        // Publish Platform Event
        Message_Service__e evt = new Message_Service__e();
        evt.Receiver__c = mobile;
        evt.Message_Template__c = finalMessage;
        
        EventBus.publish(evt);
    }
    
    
    
}