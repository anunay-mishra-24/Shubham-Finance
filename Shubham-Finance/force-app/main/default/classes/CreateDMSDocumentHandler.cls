/**
* @File Name          : CreateDMSDocumentHandler.cls
* @Description        : 
* @Author             : Akshi 
* @Test Class         : CreateDMSDocumentHandler_Test.cls
*==============================================================================
* Ver         Date         Author     Modification
*==============================================================================
* 1.0         03-06-2025   Akshi     Initial Version
*/
//Aadded by Ranjeet without sharing for Public Site Upload Documents
global without sharing class  CreateDMSDocumentHandler extends SHF_AbstractTriggerContext {
    
    global override void afterInsert(List<sObject> newList,List<sObject> oldList, Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        try {
            List<Create_DMS_Document__e> newEvents = (List<Create_DMS_Document__e>) newList;
            
            Map<String, Create_DMS_Document__e> docIdToEvent = new Map<String, Create_DMS_Document__e>();
            for (Create_DMS_Document__e evt : newEvents) {
                if (!String.isBlank(evt.Base__c)) {
                    docIdToEvent.put(evt.Base__c, evt);
                }
            }
            
            if (docIdToEvent.isEmpty()) {
                return;
            }
            
            List<ContentVersion> contentVersions = [SELECT ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId IN :docIdToEvent.keySet()];
            
            List<String> docCategories = new List<String>();
            List<String> base64Files   = new List<String>();
            List<Id> loanAppIds        = new List<Id>();
            List<Id> documentIds       = new List<Id>();
            
            for (ContentVersion cv : contentVersions) {
                try {
                    Create_DMS_Document__e evt = docIdToEvent.get(cv.ContentDocumentId);
                    if (evt == null) {
                        continue;
                    }
                    
                    String fileBase64 = EncodingUtil.base64Encode(cv.VersionData);
                    
                    docCategories.add(evt.Document_Category__c);
                    base64Files.add(fileBase64);
                    loanAppIds.add((Id) evt.Loan_Application_ID__c);
                    documentIds.add((Id) evt.Document_ID__c);
                } catch (Exception innerEx) {
                    System.debug('Error processing ContentVersion Id: ' + cv.Id + ' => ' + innerEx.getMessage());
                }
            }
            
            if (!docCategories.isEmpty()) {
                SHF_DMS_Service_Future.createDocsAsync(docCategories, base64Files, loanAppIds, documentIds );
            } else {
                System.debug('No documents to process. Skipping future call.');
            }
        } catch (Exception ex) {
            System.debug('Error in CreateDMSDocumentHandler.afterInsert: ' + ex.getMessage());
        }
    }
    @AuraEnabled
    public static void uploadAsAttachment(Id documentId, String base64Data, String fileName) {
        if (String.isBlank(documentId) || String.isBlank(base64Data) || String.isBlank(fileName)) {
            throw new AuraHandledException('Missing parameters');
        }

        Blob fileBody = EncodingUtil.base64Decode(base64Data);

        Attachment att = new Attachment();
        att.ParentId = documentId;        // 🔹 Link to Document__c
        att.Name = fileName;              // e.g. <Document Name>.jpg
        att.Body = fileBody;
        att.ContentType = 'image/jpeg';
        insert att;
    }

}