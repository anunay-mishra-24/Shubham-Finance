public with sharing class SHF_RcuReportGeneratorService {
    
    @AuraEnabled
    public static Map<String, Object> generateRCUReport(Id applicationId, Id verificationActivityId, String vfPageName) {
        
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            
            Application__c app = [
                SELECT Id, Name, Application_Stage__c
                FROM Application__c 
                WHERE Id = :applicationId
            ];
            
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Dummy PDF Content');
            } else {
                PageReference pr = new PageReference('/apex/' + vfPageName);
                pr.getParameters().put('id', verificationActivityId);
                pdfBlob = pr.getContentAsPDF();
            }
            
            List<Document__c> docs = [
                SELECT Id, File_Name__c , Name
                FROM Document__c
                WHERE Application__c = :applicationId
                AND Document_Category__c = 'Loan Specific Documents'
                AND Mandatory_Document__c = TRUE
                AND File_Name__c LIKE '%RCU Seller Verification%'
                LIMIT 1
            ];
            
            String base64Pdf = EncodingUtil.base64Encode(pdfBlob);
            Document__c doc;
            
            if(!docs.isEmpty()){
                doc = docs[0];
            }else{
                doc = new Document__c();
                doc.File_Name__c = 'RCU Seller Verification - '+ applicationId;
                doc.Stage__c = 'QDE';
                doc.Mandatory_Document__c = TRUE;
                doc.Document_Category__c = 'Loan Specific Documents';
                doc.Application__c = applicationId;
                doc.Verification_Activity__c = verificationActivityId;
                doc.Status__c = 'Uploaded';
                doc.Document_Received_Date__c = Date.today();
                doc.Document_Source__c = 'API';
                
                insert doc;
            }
            
            result.put('status','success');
            result.put('message','RCU Report generated successfully');
            result.put('docId', doc.Id);
            result.put('fileName', doc.File_Name__c);
            result.put('fileBase64', base64Pdf);
            
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
            UploadResponse response = uploadAndSendToDMS(doc.File_Name__c, base64Pdf, doc.Id, contendocId);
            
            if(!response.success) {
                result.put('status','error');
                result.put('message','RCU Report generation failed, unable to create content version');
            }
            else if (response.success){
                doc.Public_View_Url__c = response.publicUrl;
                Update doc;
                result.put('status','success');
                result.put('message','RCU Report generated successfully');
                result.put('docId', doc.Id);
            }
            return result;
            
        } catch (Exception e) {
            System.debug('RCU ERROR => ' + e.getMessage()+e.getLineNumber());
            result.put('status','error');
            result.put('message', e.getMessage());
            return result;
        }
    }
    
    @AuraEnabled
    public static UploadResponse uploadAndSendToDMS(String fileName, String base64Data, Id documentId, Id existingContentDocumentId) {
        UploadResponse response = new UploadResponse();
        try {
            Blob fileBlob = EncodingUtil.base64Decode(base64Data);
            
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = '/' + fileName;
            cv.VersionData = fileBlob;
            
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
            
            insert dist;
            dist = [SELECT DistributionPublicUrl
                    FROM ContentDistribution
                    WHERE Id = :dist.Id];
            
            
            response.publicUrl = dist.DistributionPublicUrl;
            response.success = true;
            response.contentDocumentId = cv.ContentDocumentId;
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
    
    @AuraEnabled(cacheable=true)
    public static Id getPrimaryApplicant(Id applicationId) {
        System.debug('applicationId-- ' +applicationId);
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
}