/**
* @File Name          : SHF_CreateDMS_Service.cls
* @Description        : Handles integration with external DMS service to create, export and get the accessToken.
* @Author             : Riteek Tiwari
*
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         08-07-2025        Riteek Tiwari    Initial Version
*/
//Added by Ranjeet without sharing for Public Site Upload Documents
public without sharing class SHF_DMS_Service {
    public SHF_HTTPCalloutService service;
    @TestVisible private static String testAccessToken;
    
    //Get Access Token
    @AuraEnabled
    public static String generateAccessToken() {
        try {
            SHF_DMS_Service dmsAccessToken = new SHF_DMS_Service();
            dmsAccessToken.service = new SHF_HTTPCalloutService('DMS_Access_Token');
            HttpResponse response;
            String responseBody;
            if (Test.isRunningTest() && testAccessToken != null) {
                return testAccessToken;
            }
            
            if (dmsAccessToken.service.getIsActive()) {
                response = dmsAccessToken.service.sendRequest();
                system.debug('Body '+response.getBody());
                system.debug('Response '+response);
            } else {
                response = new HttpResponse();
                response.setBody(dmsAccessToken.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            responseBody = response != null ? response.getBody() : null;
            Logger.error('responseBody:'+response.getBody());
            system.debug('responseBody<>< '+ responseBody);
            if (String.isBlank(responseBody) || !responseBody.contains('Encrypted Text :')) {
                Logger.error('Access token API response is missing or invalid.');
            }
            
            if (String.isNotBlank(responseBody) && responseBody.contains('Encrypted Text :')) {
                return responseBody.substringAfter('Encrypted Text :').trim();
            }
            
        } catch (Exception e) {
            System.debug('Error in generateAccessToken: ' + e.getMessage());
            Logger.error('Error: '+e.getMessage());
        } finally {
            Logger.saveLog();
        }
        return null;
    }
    
    
    //create DMS Doc
    @AuraEnabled
    public static void createDoc(String docCategory, String base64Doc, String loanApplicationId, String docId) {
        Savepoint sp;
        List<Loan_Applicant__c> primaryApplicant = new List<Loan_Applicant__c>();
        try {
            // Initialize Unit of Work
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Document__c.SObjectType});
            
            List<Application__c> applicationList = new SHF_ApplicationSelector().selectBranchCodeByApplicationId(new Set<Id>{ loanApplicationId });
            if (applicationList.isEmpty()) {
                Logger.error('Loan Application not found for Id: ' + loanApplicationId);
                System.debug('Loan Application not found for Id: ' + loanApplicationId);
                return;
            }
            If(!applicationList[0].Loan_Applicants__r.isEmpty()){
                for(Loan_Applicant__c applicant : applicationList[0].Loan_Applicants__r ){
                    if(applicant.Applicant_Type__c == SHF_ConstantsUtil.APPPLICANT){
                        primaryApplicant.add(applicant);
                    }
                }
            }
            
            String branchCode = applicationList[0].Branch__r != null && applicationList[0].Branch__r.Branch_Code__c != null
                ? applicationList[0].Branch__r.Branch_Code__c : ' ';
            String productCode = applicationList[0].Product__r != null && applicationList[0].Product__r.Name != null
                ? applicationList[0].Product__r.Name : ' ';
            String pathValue = 	branchCode + '/' + productCode;
            
            String accessToken = generateAccessToken();
            if (String.isBlank(accessToken)) {
                Logger.error('Access token is empty. Cannot proceed with export.');
                return;
            }
            SHF_DMS_Service dmsCreate = new SHF_DMS_Service();
            dmsCreate.service = new SHF_HTTPCalloutService('DMS_Create_API');
            String clientId = dmsCreate.service.getExtraParameter('clientId');
            
            String boundary = '---------------------------FORM_BOUNDARY';
            String crlf = '\r\n';
            String body = '';
            
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="docCategory"' + crlf + crlf + docCategory + crlf;
            
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="token"' + crlf + crlf + accessToken + crlf;
            
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="path"' + crlf + crlf + pathValue + crlf;
            
            //Added By Mohit
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="data"' + crlf + crlf + '{"DOC_STAGE":" '+ applicationList[0].Application_Stage__c +'","DOC_CUST_NAME":"'+ primaryApplicant[0].Name +'","DOC_CUST_ID":"'+ primaryApplicant[0].Id +'","DOC_COPY":"'+ SHF_ConstantsUtil.ORIGINAL +'"}' + crlf;
            
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="subPath"' + crlf + crlf;
            body += DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)).format('yyyy/MMM').toUpperCase() + crlf;
            
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="clientId"' + crlf + crlf + SHF_ConstantsUtil.SHUBHAMOP + crlf;
            
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="file"' + crlf + crlf + applicationList[0].Id + crlf;
            
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="document"' + crlf + crlf + base64Doc + crlf;
            
            body += '--' + boundary + '--' + crlf;
            
            dmsCreate.service.setHeaderParameter('Content-Type', 'multipart/form-data; boundary=' + boundary);
            dmsCreate.service.setRequestBody(body);
            system.debug('requestBody@ '+dmsCreate.service.getRequestBody());
            //system.debug('Extra Params@ '+dmsCreate.service.getExtraParameters());
            
            HttpResponse response;
            if (dmsCreate.service.getIsActive()) {
                response = dmsCreate.service.sendRequest();
                //sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setBody(dmsCreate.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            Map<String, Object> dmsResponseMap = new Map<String, Object>();
            System.debug('DMS raw response: ' + response.getBody());
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                dmsResponseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('dmsResponseMap------'+dmsResponseMap);
                
                if (!dmsResponseMap.isEmpty() && String.isNotBlank(loanApplicationId)) {
                    Document__c documentObj = SHF_CommonUtil.createDocument( SHF_ConstantsUtil.AADHAAR_DOCUMENT, loanApplicationId , SHF_ConstantsUtil.AADHAAR_DOCUMENT);
                    if (!String.isBlank(docId) && String.valueOf(docId).length() == 18) {
                        documentObj.Parent_Document__c = docId;
                        
                        List<Document__c> parentDocs = new SHF_DocumentsSelector().selectByIdsApplicantName(new Set<Id>{docId});
                        if (!parentDocs.isEmpty()) {
                            String parentDocName = parentDocs[0].File_Name__c;
                            String version = dmsResponseMap.containsKey('version') ? String.valueOf(dmsResponseMap.get('version')) : '';
                            documentObj.File_Name__c = parentDocName + ' ' + version;
                        }
                    }
                    if (!String.isEmpty(docCategory)) {
                        documentObj.Document_Category__c = docCategory;
                    }
                    if (dmsResponseMap.containsKey('version')) {
                        documentObj.Document_Version__c = String.valueOf(dmsResponseMap.get('version'));
                    }
                    
                    if (dmsResponseMap.containsKey('documentId')) {
                        documentObj.DMS_Document_ID__c = String.valueOf(dmsResponseMap.get('documentId'));
                    }
                    
                    uow.registerNew(documentObj);
                    uow.commitWork();
                    
                    String reqBodyLog = dmsCreate.service.getRequestBody();
                    if (reqBodyLog != null && reqBodyLog.length() > 5000) {
                        reqBodyLog = reqBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                    }
                    Logger.info('Request Body ' + reqBodyLog);
                    
                    Logger.info('status code ' + response.getStatusCode());
                    Logger.info('status ' + response.getStatus());
                    
                    String respBodyLog = response.getBody();
                    if (respBodyLog != null && respBodyLog.length() > 5000) {
                        respBodyLog = respBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                    }
                    Logger.info('Response Body ' + respBodyLog);
                    
                }
            } else {
                Logger.error('DMS response body is empty or missing.');
                
                String reqBodyLog = dmsCreate.service.getRequestBody();
                if (reqBodyLog != null && reqBodyLog.length() > 5000) {
                    reqBodyLog = reqBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.error('Request Body ' + reqBodyLog);
                
                Logger.error('status code ' + response.getStatusCode());
                Logger.error('status ' + response.getStatus());
                
                String respBodyLog = response.getBody();
                if (respBodyLog != null && respBodyLog.length() > 5000) {
                    respBodyLog = respBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.error('Response Body ' + respBodyLog);
                
            }
            
        } catch (Exception e) {
            // Roll back if anything fails
            if (sp != null) {
                Database.rollback(sp);
            }
            Logger.error('Exception: ' + e.getMessage());
            System.debug('Error: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
        } finally {
            Logger.saveLog();
        }
    }
    
    //invocable method to create DMS Document
    @InvocableMethod(label='Create DMS Document' description='Uploads document to DMS and creates related record')
    public static void invokeCreateDoc(List<DocumentInput> inputs) {
        for (DocumentInput input : inputs) {
            SHF_DMS_Service.createDoc(input.docCategory,input.base64Doc,input.loanApplicantId,input.docId);
        }
    }
    public class DocumentInput {
        @InvocableVariable(label='Document Category' required=true)
        public String docCategory;
        
        @InvocableVariable(label='Base64 Document Content' required=true)
        public String base64Doc;
        
        @InvocableVariable(label='Loan Applicant Id' required=true)
        public String loanApplicantId;
        
        @InvocableVariable(label='Parent Document Id' required=true)
        public String docId;
    }
    
    @AuraEnabled(cacheable=true)
    public static ApplicantInfoWrapper getApplicantInfo(Id applicationId, Id applicantId) {
        ApplicantInfoWrapper wrapper = new ApplicantInfoWrapper();
        System.debug('applicantId @ '+ applicantId);
        System.debug('applicationId @ '+ applicationId);
        wrapper.message = 'SUCCESS';
        // Query Application
        List<Application__c> apps = [ SELECT Id,Name, Application_Stage__c, Product__r.Name, Branch__r.Branch_Code__c,Product__r.Sub_Product__c,CreatedDate
            FROM Application__c WHERE Id = :applicationId LIMIT 1 ];
        
        Callout_Framework__mdt calloutMetadata = [Select Id,Active__c,HeaderParams__c,URL_Parameter_s__c,Timeout_Time__c,Body__c,HTTP_Method__c,Mock_Response__c,Endpoint__c,Extra_Param_s__c FROM Callout_Framework__mdt WHERE DeveloperName =: SHF_ConstantsUtil.DMS_CREATE_APINAME];
        
        if (!apps.isEmpty()) {
            Application__c app = apps[0];
            wrapper.applicationStage = app.Application_Stage__c;
            wrapper.branchCode = (app.Branch__r != null ? app.Branch__r.Branch_Code__c : null);
            // wrapper.productCode = (app.Product__r != null ? app.Product__r.Name : null);
            wrapper.productCode = (app.Product__r != null ? app.Product__r.Sub_Product__c : null);
            wrapper.appName = app.Name;
            
            if(calloutMetadata != null){
                wrapper.endPoint = calloutMetadata.Endpoint__c;
                wrapper.apiMethod = calloutMetadata.HTTP_Method__c;
                wrapper.clientId = getClientId(calloutMetadata.HeaderParams__c);
                String subPathValue =getSubPath(app.CreatedDate);
                wrapper.subPath = subPathValue.toUpperCase();
            }
        }

        if(String.isBlank(wrapper.branchCode)){
                wrapper.message = 'Branch value is blank. Please select a Branch on the Application record.';
            }
            
            if(String.isBlank(wrapper.productCode)){
                wrapper.message = 'Product value is blank. Please select a Product on the Application record.';
            }
        
        Loan_Applicant__c applicant;
        
        if (applicantId == null) {
            List<Loan_Applicant__c> primaryApplicants = [ SELECT Id, Name, Applicant_Type__c FROM Loan_Applicant__c
                                                         WHERE Application__c = :applicationId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
            
            if (!primaryApplicants.isEmpty()) {
                applicant = primaryApplicants[0];
            }
            
        } else {
            List<Loan_Applicant__c> applicants = [ SELECT Id, Name FROM Loan_Applicant__c WHERE Id = :applicantId LIMIT 1 ];
            
            if (!applicants.isEmpty()) {
                applicant = applicants[0];
            }
        }
        
        if (applicant != null) {
            wrapper.applicantName = applicant.Name;
            wrapper.applicantId = applicant.Id;
            wrapper.docCopy = 'Original';
        }
        System.debug('wrapper @ '+wrapper);
        return wrapper;
    }
    
    private static String getSubPath(Datetime createdDate){
        if(createdDate == null){
            return '';
        }
        return createdDate.format('yyyy/MMM');
    }    
    
    private static String getClientId(String parameterInfo){
        if(String.isBlank(parameterInfo)){
            return '';
        }
        Map<String, String> parametersMap = new Map<String, String>();
        List<String> parameters = parameterInfo.split('\n');
        for(String urlParam : parameters) {
            List<String> keyValuePair = urlParam.trim().split(':');
            if(!keyValuePair.isEmpty()) {
                if(keyValuePair.size() == 2) {
                    if(String.isNotEmpty(keyValuePair[0]) && String.isNotEmpty(keyValuePair[1])) {
                        parametersMap.put(keyValuePair[0], keyValuePair[1]);
                    }
                }
            }
        }
        
        return parametersMap.containsKey('clientId') ? parametersMap.get('clientId') : '';
    }
    
    public class ApplicantInfoWrapper {
        @AuraEnabled public String applicationStage;
        @AuraEnabled public String branchCode;
        @AuraEnabled public String productCode;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String applicantId;
        @AuraEnabled public String endPoint;
        @AuraEnabled public String apiMethod;
        @AuraEnabled public String subPath;
        @AuraEnabled public String clientId;
        @AuraEnabled public String appName;
        @AuraEnabled public String docCopy;
        @AuraEnabled public String message;
    }
    
    @AuraEnabled
    public static void updateDocumentWithDmsResponse(Id docId, String versionId, String dmsDocId) {
        if (String.isBlank(docId) || String.isBlank(versionId) || String.isBlank(dmsDocId)) {
            return;
        }
        
        // Fetch parent document
        List<Document__c> parentDocs = new SHF_DocumentsSelector().selectByIdsApplicantName(new Set<Id>{docId});
        if (parentDocs.isEmpty()) {
            return;
        }
        
        Document__c parentDoc = parentDocs[0];
        
        parentDoc.Status__c = 'Uploaded';
        parentDoc.Document_Received_Date__c = Date.today();
        parentDoc.Document_Source__c = 'Manual';
        
        // Create a child document for DMS version tracking
        Document__c childDoc = new Document__c(
            Parent_Document__c   = parentDoc.Id,
            Document_Category__c = parentDoc.Document_Category__c,
            Document_Version__c  = versionId,
            DMS_Document_ID__c   = dmsDocId,
            File_Name__c         = parentDoc.File_Name__c + ' ' + versionId
        );
        
        update parentDoc;
        insert childDoc;
    }
    
    
    //Export DMS
    @AuraEnabled
    public static void exportDoc(String documentId) {
        try {
            String accessToken = generateAccessToken();  //this pulls token from method above
            
            if (String.isBlank(accessToken)) {
                Logger.error('Access token is empty. Cannot proceed with export.');
                return;
            }
            
            SHF_DMS_Service dmsExport = new SHF_DMS_Service();
            dmsExport.service = new SHF_HTTPCalloutService('DMS_Export_API');
            String clientId = dmsExport.service.getExtraParameter('clientId');
            String boundary = '---------------------------FORM_BOUNDARY';
            String crlf = '\r\n';
            String body = '';
            
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="token"' + crlf + crlf;
            body += accessToken + crlf;
            
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="documentId"' + crlf + crlf;
            body += documentId + crlf;
            
            body += '--' + boundary + crlf;
            body += 'Content-Disposition: form-data; name="clientId"' + crlf + crlf;
            body +=  clientId + crlf;
            
            body += '--' + boundary + '--' + crlf;
            
            dmsExport.service.setHeaderParameter('Content-Type', 'multipart/form-data; boundary=' + boundary);
            dmsExport.service.setRequestBody(body);
            
            if(dmsExport.service.getIsActive()){
                HttpResponse response =  dmsExport.service.sendRequest();
                logger.info('status code '+response.getStatusCode());
                logger.info('status '+response.getStatus());
                logger.info('Body '+response.getBody());
            }else{
                HttpResponse response = new HttpResponse();
                response.setBody(dmsExport.service.getmockRespnse());
                response.setStatusCode(200);
                logger.info('Mock Response '+dmsExport.service.getmockRespnse());
            }
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            Logger.error('error ' + e.getMessage());
        }finally {
            Logger.saveLog();
        }
    }
}