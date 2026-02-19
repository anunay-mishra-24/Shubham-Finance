/**
* @File Name          : SHF_DisplayDocumentsController.cls
* @Description        : This class is used to Display Documents for Document Checklist
* @Author             : Akshi Sharma
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         07-07-2025              Akshi Sharma
*/
//Added by Ranjeet without sharing for Public Site Upload Documents
public without sharing class SHF_DisplayDocumentsController {
    
    /**
* @description getLoanApplicantRecords
* @param applicationId
* @return response
*/ 
    
    @AuraEnabled(Cacheable=true)
    public static ResponseWrapper getLoanApplicantRecords(String applicationId){
        ResponseWrapper response = new ResponseWrapper();
        try{
            List<Loan_Applicant__c> loanApplicantList = [SELECT Id, Name, Applicant_Type__c, Account_Name__c, Application__r.Application_Stage__c,
                                                         Application__c, Entity_Name__c, Customer_Type__c
                                                         FROM Loan_Applicant__c 
                                                         WHERE Application__c = :applicationId AND IsDeleted__c = FALSE
                                                         ORDER BY Applicant_Type__c];
            if(loanApplicantList != null && !loanApplicantList.isEmpty()){
                response.loanApplicationStage = loanApplicantList[0].Application__r.Application_Stage__c;
                
                Map<String, String> loanApplicantIdAndRelationMap = new Map<String, String>();
                for(Loan_Applicant__c record : loanApplicantList){
                    String name = '';
                    String key = record.Account_Name__c + '-' + record.Application__c;
                    if(loanApplicantIdAndRelationMap.containsKey(key)){
                        name = loanApplicantIdAndRelationMap.get(key);
                        name += ', ' + record.Applicant_Type__c;
                        loanApplicantIdAndRelationMap.put(key, name);
                    } else {
                        name = record.Account_Name__c + '(' + record.Applicant_Type__c;
                        loanApplicantIdAndRelationMap.put(key, name);
                    }
                }
                
                // Generate JSON safely
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartArray();
                for(Loan_Applicant__c record : loanApplicantList){
                    String key = record.Account_Name__c + '-' + record.Application__c;
                    String baseName;
                    
                    // If Non-Individual, use Entity_Name, otherwise use Account_Name
                    if(record.Customer_Type__c == 'Non-Individual' && record.Entity_Name__c != null) {
                        baseName = record.Entity_Name__c;
                    } else {
                        baseName = record.Account_Name__c;
                    }
                    // Append Applicant Type
                    String name = baseName + '(' + record.Applicant_Type__c + ')';
                    
                    //String name = loanApplicantIdAndRelationMap.containsKey(key) ? loanApplicantIdAndRelationMap.get(key) : record.Name;
                    
                    gen.writeStartObject();
                    gen.writeStringField('Id', record.Id);
                    gen.writeStringField('Name', name);
                    gen.writeStringField('Customer_Type__c', record.Customer_Type__c != null ? record.Customer_Type__c : '');
                    gen.writeStringField('Entity_Name__c', record.Entity_Name__c != null ? record.Entity_Name__c : '');
                    gen.writeEndObject();
                    
                    // Clear the map value so repeated keys are skipped in concatenation, but JSON still writes every record
                    loanApplicantIdAndRelationMap.put(key, '');
                }
                gen.writeEndArray();
                
                response.responseBody = gen.getAsString();
                response.isSuccess = true;
            } else {
                response.isSuccess = false;
                response.responseBody = 'Loan Applicants records do not exist';
            }
        } catch(Exception ex) {
            response.isSuccess = false;
            response.responseBody = ex.getMessage();
            return response;
        }
        
        System.debug('ResponseWrapper-> ' + response);
        return response;
    }
    
    // Added by Karan Keswani on 16th of December
    @AuraEnabled
    public static ResponseWrapper uploadDocument(String documentSubType , String fileName, String base64, String recordId, String contentVersionId) {
        ResponseWrapper response = new ResponseWrapper();
        System.debug('UPLOAD CLASSSSS');
        System.debug('documentSubType  '+documentSubType);
        System.debug('base64base64base64base64  '+base64);
        try{
            Id profileId=userinfo.getProfileId();
            List<Valuation__c> RCUActivityLst = new List<Valuation__c>();
            String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
            List<Document__c> documentList = [SELECT Id,Document_Sub_Type__c,Document_Type__c, Status__c,Loan_Applicant__c,Application__c FROM Document__c WHERE Id =: recordId];
            System.debug('<><  '+documentList +'<><> '+ recordId);
            if(documentList[0]?.Loan_Applicant__c != null && documentList[0]?.Application__c != null && documentList[0]?.Document_Type__c == 'Photo'){
                RCUActivityLst = [select id,name,Loan_Applicant__c,Application__c,RecordType_Name__c,Applicant_URL__c from Valuation__c WHERE Application__c =:documentList[0].Application__c AND Loan_Applicant__c =:documentList[0].Loan_Applicant__c AND RecordType_Name__c='RCU'/*:UB_ConstantsUtil.RCU_VALUATION_RECORD_TYPE*/ ORDER BY CreatedDate Desc];
            }
            
            System.debug('RCUActivityLst===>'+RCUActivityLst);
            System.debug('documentList   '+documentList);
            System.debug('base64      '+documentList);
            if(documentList != null && documentList.size() > 0 && contentVersionId != null ){
                Document__c documentChild = new Document__c();
                documentChild.Parent_Document__c = documentList[0].Id;
                documentChild.File_Name__c = fileName;
                Datetime now = Datetime.now();
                Integer offset = UserInfo.getTimezone().getOffset(now);
                Datetime local = now.addSeconds(offset/1000);
                system.debug('local-> ' + local);
                documentChild.Uploaded_Date_Formated__c = local;
                INSERT documentChild;
                System.debug('documentChild   '+documentChild);
                
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
                
                
                List<Document__c> documentInsertedList = [SELECT Id FROM Document__c WHERE Id =: documentChild.Id];
                
                //ContentVersion cv = new ContentVersion();
                //cv.Title = fileName;
                //cv.PathOnClient = fileName;
                //cv.VersionData =  Blob.valueOf( base64);
                //if(profileName == UB_ConstantsUtil.PORTAL_PROFILE_NAME) {
                // cv.NetworkId =  [SELECT NetworkId, MemberId FROM NetworkMember WHERE MemberId = :UserInfo.getUserId()].NetworkId;
                // }
                //cv.VersionData = EncodingUtil.base64Decode(base64);
                //cv.IsMajorVersion = true;
                // Insert cv;
                
                
                
                //Create ContentDocumentLink 
                ContentDocumentLink cdl = New ContentDocumentLink();
                cdl.LinkedEntityId = documentInsertedList[0].Id;
                cdl.ContentDocumentId = conDocId;
                cdl.shareType = 'I';
                Insert cdl;
                
                ContentDistribution newDist = new ContentDistribution();
                newDist.ContentVersionId = contentVersionId;
                newDist.Name = fileName;
                newDist.PreferencesNotifyOnVisit = false;
                newDist.PreferencesAllowViewInBrowser = true;
                newDist.PreferencesAllowOriginalDownload=true;
                insert newDist;
                
                List<ContentDistribution> distribution = [Select Id, ContentDownloadUrl, 
                                                          DistributionPublicUrl, PdfDownloadUrl FROM
                                                          ContentDistribution where id =: newDist.Id];
                if(distribution != null && distribution.size() > 0){
                    if(distribution[0].DistributionPublicUrl != null && String.isNotBlank(distribution[0].DistributionPublicUrl) && distribution[0].ContentDownloadUrl != null && String.isNotBlank(distribution[0].ContentDownloadUrl)){
                        if(documentInsertedList != null && documentInsertedList.size() > 0){
                            documentInsertedList[0].Document_URL__c = distribution[0].ContentDownloadUrl;
                            documentInsertedList[0].Document_Preview_Url__c = distribution[0].DistributionPublicUrl;
                            documentInsertedList[0].Status__c = 'Uploaded';
                            UPDATE documentInsertedList;
                        }
                    }
                }
                
                //documentInsertedList[0].Document_URL__c = distribution[0].ContentDownloadUrl;
                //documentInsertedList[0].Document_Preview_Url__c = distribution[0].DistributionPublicUrl;
                documentList[0].Status__c = 'Uploaded';
                documentList[0].Document_Sub_Type__c = String.isNotBlank(documentSubType) ? documentSubType : '';
                UPDATE documentList;
                
                if(RCUActivityLst.size()>0 && documentList[0]?.Document_Type__c != null && documentList[0]?.Document_Type__c == 'Photo'){
                    RCUActivityLst[0].Applicant_URL__c = distribution[0].DistributionPublicUrl;
                    update RCUActivityLst;
                }
                response.isSuccess = true;
            }
        }
        catch(Exception error){
            system.debug('error' + error.getLineNumber());
            system.debug('error' + error.getMessage());
            response.isSuccess = false;
            response.responseBody =  JSON.serialize(error.getMessage() + error.getLineNumber() + error.getStackTraceString() );
            return response;
        }
        
        System.debug('RESPONSEEEEEE  '+response);
        
        return response;
    }
    
    
    @AuraEnabled
    public static ResponseWrapper getApplicationDocuments(String applicationId, String loanApplicantId) {
        System.debug('applicationId ==> ' + applicationId);
        ResponseWrapper response = new ResponseWrapper();
        
        try {
            // Step 1: Get Record Type of Application
            Application__c application = [
                SELECT Id, RecordType.Name, Is_Current_User__c,OwnerId 
                FROM Application__c 
                WHERE Id = :applicationId 
                LIMIT 1
            ];
            String recordTypeLabel = application.RecordType.Name;
            
            // Step 2: Determine Stages
            List<String> applicableStages = new List<String>();
            if (recordTypeLabel == 'QDE') {
                applicableStages.add('QDE');
            } else if (recordTypeLabel == 'DDE') {
                applicableStages.addAll(new List<String>{'QDE', 'DDE'});
            } else if (recordTypeLabel == 'Credit Evaluation') {
                applicableStages.addAll(new List<String>{'QDE', 'DDE', 'Credit Evaluation'});
            } else if (recordTypeLabel == 'Pre-Disbursement') {
                applicableStages.addAll(new List<String>{'QDE', 'DDE', 'Credit Evaluation', 'Pre-Disbursement Document Collection'});
            } else if (recordTypeLabel == 'Post Disbursal') {
                applicableStages.addAll(new List<String>{'QDE', 'DDE', 'Credit Evaluation', 'Pre-Disbursement Document Collection', 'Post Disbursal'});
            }
            System.debug('Final applicableStages => ' + applicableStages);
            System.debug('Running SOQL with applicationId: ' + applicationId + ', loanApplicantId: ' + loanApplicantId);
            
            List<Document__c> documentList;
            if (String.isBlank(loanApplicantId)) {
                documentList = [ SELECT Id, Name, Document_Category__c, Document_Type__c,File_Name__c,
                                Document_Received_Date__c, Document_Source__c, Status__c, Mandatory_Document__c,
                                RCU_Verification_Status__c, CreatedBy.Name, Application__r.OwnerId, RCU_Required__c
                                FROM Document__c
                                WHERE Application__c = :applicationId
                                AND Loan_Applicant__c = null
                                AND Stage__c IN :applicableStages
                               ];
            } else {
                documentList = [ SELECT Id, Name, Document_Category__c, Document_Type__c,File_Name__c,
                                Document_Received_Date__c, Document_Source__c, Status__c, Mandatory_Document__c,
                                RCU_Verification_Status__c, CreatedBy.Name, Application__r.OwnerId, RCU_Required__c
                                FROM Document__c
                                WHERE Application__c = :applicationId
                                AND Loan_Applicant__c = :loanApplicantId
                                AND Stage__c IN :applicableStages
                               ];
            }   
            if (!documentList.isEmpty()) {
                response.responseBody = JSON.serialize(documentList);
                response.isSuccess = true;
                response.totalRecords = documentList.size();
            } else {
                response.isSuccess = false;
                response.responseBody = 'No document records found';
                response.totalRecords = 0;
            }
            
        } catch (Exception ex) {
            response.isSuccess = false;
            response.responseBody = ex.getMessage();
        }
        
        return response;
    }
    
    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getDocumentsForRecord(Id recordId, String objectApiName) {
        ResponseWrapper response = new ResponseWrapper();
        Set<Id> recordIds = new Set<Id>{recordId};
        try {
            if (String.isBlank(recordId) || String.isBlank(objectApiName)) {
                response.isSuccess = false;
                response.responseBody = 'Record Id or Object Name is missing';
                return response;
            }          
            // Map object name to relevant lookup field on Document__c
            String lookupField;
            if (objectApiName == 'Query__c') {
                lookupField = 'Query__c';
            } else if (objectApiName == 'E_Verification__c') {
                lookupField = 'Verification__c';
            } else if (objectApiName == 'Verification_Activity__c') {
                lookupField = 'Verification_Activity__c';
            } else if (objectApiName == 'Verification__c') {
                lookupField = 'Id';
                for(Document_Activity__c doc : [SELECT id, Document__c FROM Document_Activity__c WHERE Verification__c =: recordId]){
                    recordIds.add(doc.Document__c);
                }
            } else if (objectApiName == 'Verification_Activity__c') {
                lookupField = 'Id';
                for(Document_Activity__c doc : [SELECT id, Document__c FROM Document_Activity__c WHERE Verification_Activity__c =: recordId]){
                    recordIds.add(doc.Document__c);
                }
            } else {
                response.isSuccess = false;
                response.responseBody = 'Unsupported object type: ' + objectApiName;
                return response;
            }
            
            // Dynamic SOQL to fetch documents
            String soql = 'SELECT Id, Name, File_Name__c, Document_Type__c, Document_Category__c, ' +
                'Stage__c, Mandatory_Document__c, Acknowledge_Status__c, Status__c, ' +
                'Document_Received_Date__c, Document_Source__c, RCU_Verification_Status__c, ' + 'RCU_Required__c, ' +
                'CreatedBy.Name ' +
                'FROM Document__c WHERE ' + lookupField + ' IN :recordIds';
            
            List<Document__c> docs = Database.query(soql);
            
            if (!docs.isEmpty()) {
                response.isSuccess = true;
                response.responseBody = JSON.serialize(docs);
                response.totalRecords = docs.size();
            } else {
                response.isSuccess = false;
                response.responseBody = 'No document records found';
                response.totalRecords = 0;
            }
        } catch (Exception ex) {
            response.isSuccess = false;
            response.responseBody = ex.getMessage();
        }
        
        return response;
    }
    
    
    @AuraEnabled
    public static List<Document_Checklist__c> getChecklistOptions(Id applicationId, Id applicantId, String forWhom) {
        if (applicationId == null) return new List<Document_Checklist__c>();
        
        Application__c application = [SELECT Id, RecordType.Name FROM Application__c WHERE Id = :applicationId LIMIT 1];
        String appStage = application.RecordType.Name;
        if (appStage == 'Pre-Disbursement') {
            appStage = 'Pre-Disbursement Document Collection';
        }
        
        String profileId;
        if (forWhom == 'Applicant' && applicantId != null) {
            Loan_Applicant__c applicant = [SELECT Id, Customer_Profile__c FROM Loan_Applicant__c WHERE Id = :applicantId LIMIT 1];
            profileId = applicant.Customer_Profile__c;
        }
        
        List<Document_Checklist__c> checklist = new List<Document_Checklist__c>();
        
        if (forWhom == 'Application') {
            checklist = [
                SELECT Id, Document_Category__c, Document_Type__c, Name
                FROM Document_Checklist__c
                WHERE Applicable_For__c = 'Loan'
                AND Mandatory_Optional__c = 'Non Mandatory'
                AND Document_Stage__c = :appStage
                AND Id NOT IN (
                    SELECT Document_Checklist__c
                    FROM Document__c
                    WHERE Application__c = :applicationId
                )
            ];
        } else if (forWhom == 'Applicant'){ //&& profileId != null) {
            checklist = [
                SELECT Id, Document_Category__c, Document_Type__c, Name
                FROM Document_Checklist__c
                WHERE Applicable_For__c = 'All Applicants'
                AND Mandatory_Optional__c = 'Non Mandatory'
                //AND Customer_Profile_FinnOne__c = :profileId
                AND Document_Stage__c = :appStage
                AND Id NOT IN (
                    SELECT Document_Checklist__c
                    FROM Document__c
                    WHERE Application__c = :applicationId
                    AND Loan_Applicant__c = :applicantId
                )
            ];
        }
        System.debug('>>>>checklist' +checklist);
        return checklist;
    }
    
    @AuraEnabled
    public static ResponseWrapper createDocumentRecord(Id applicationId, Id applicantId, String documentFor, String category, String type, String docName,Id parentRecordId,String parentObjectName) {
        ResponseWrapper res = new ResponseWrapper();
        String applicationIdPrefix = String.valueOf(applicationId).substring(0,3);
        System.debug('>>>>prefix'+applicationIdPrefix);
        try {
            Document__c doc = new Document__c();
            doc.Document_Category__c = category;
            doc.Document_Type__c = type;
            doc.File_Name__c = docName;
            if(applicationIdPrefix != '500'){
                System.debug('Assingn Application Id');
                doc.Application__c = applicationId;
            }
            doc.Mandatory_Document__c = false;
            doc.Status__c = 'Not Uploaded';
            doc.Stage__c = 'QDE';
            if (documentFor == 'Application') {
                doc.Applicable_For__c = 'Loan Application';
            } else if (documentFor == 'Applicant') {
                doc.Loan_Applicant__c = applicantId;
                doc.Applicable_For__c = 'Loan Applicants';
            }    
            
            //Handle dynamic parent lookup
            if (parentRecordId != null && parentObjectName != null) {
                if (parentObjectName == 'Query__c') {
                    doc.Query__c = parentRecordId;
                } else if (parentObjectName == 'Verification_Activity__c') {
                    doc.Verification_Activity__c = parentRecordId;
                }
                // extend for other objects in future
            }
            insert doc;
            res.isSuccess = true;
            res.responseBody = 'Document created successfully';
            res.recordId = doc.Id;
        } catch (Exception ex) {
            res.isSuccess = false;
            res.responseBody = ex.getMessage();
            System.debug('>>>>errorLineNumber'+ex.getLineNumber());
        }
        
        return res;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getAcknowledgementStatusOptions() {
        List<String> options = new List<String>();
        
        // Fetch picklist options from Document__c.Acknowledge_Status__c
        Schema.DescribeSObjectResult describeResult = Document__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fieldsMap.get('Acknowledge_Status__c').getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistValues) {
            if (entry.isActive() && entry.getValue() != 'OTC' && entry.getValue() != 'PDD') {
                options.add(entry.getLabel());
            }
        }
        return options;
    }
    
    
    @AuraEnabled
    public static void updateAcknowledgementStatus(List<Id> documentIds, String status, String comment) {
        List<Document__c> documentsToUpdate = [
            SELECT Id, Acknowledge_Status__c  FROM Document__c WHERE Id IN :documentIds
        ];
        for (Document__c doc : documentsToUpdate) {
            doc.Acknowledge_Status__c = status;
            //doc.Comments__c = comment;
        }
        if (!documentsToUpdate.isEmpty()) {
            update documentsToUpdate;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Document__c> getDocuments(Id verificationActivityId) {
        return [SELECT Id, Name, Document_Category__c, CreatedDate ,Status__c FROM Document__c 
                WHERE Verification_Activity__c = :verificationActivityId ORDER BY CreatedDate DESC];
    }
    
    public class ResponseWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String responseBody;
        @AuraEnabled public String loanApplicationStage;
        @AuraEnabled public String recordId;
        @AuraEnabled public Integer totalRecords;
        
    }
    
}