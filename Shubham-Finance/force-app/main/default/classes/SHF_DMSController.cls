public with sharing class SHF_DMSController {
    
    @AuraEnabled
    public static String uploadFileAndGetDocId(String fileName, String base64Data) {
        if (String.isBlank(fileName) || String.isBlank(base64Data)) {
            throw new AuraHandledException('File name and data are required.');
        }
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = '/' + fileName;
        cv.VersionData = fileBlob;
        insert cv;
        
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        System.debug('Inserted ContentDocumentId: ' + cv.ContentDocumentId);
        return cv.ContentDocumentId;
    }
    
    @AuraEnabled
    public static void publishPlatformEvent(String contentDocId,Id applicationId,Id docId,String docCategory) {
        try {
            // Publish event
            Create_DMS_Document__e event = new Create_DMS_Document__e(
                Base__c               = contentDocId,
                Loan_Application_ID__c = applicationId,
                Document_ID__c        = docId,
                Document_Category__c  = docCategory
            );
            Database.SaveResult sr = EventBus.publish(event);
            if (!sr.isSuccess()) {
                throw new AuraHandledException('Failed to publish DMS Document Event');
            }
            
            
        } catch (Exception ex) {
            throw new AuraHandledException('Error while publishing DMS Document Event: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getPreviewUrl(Id documentId) {
        try {
            // Get access token
            String accessToken = SHF_DMS_Service.generateAccessToken();
            if (String.isBlank(accessToken)) {
                throw new AuraHandledException('Failed to generate access token');
            }
            
            // Query required details from Document__c
            Document__c doc = [
                SELECT Name, Application__r.Name,Document_Category__c,File_Name__c
                FROM Document__c
                WHERE Id = :documentId
                LIMIT 1
            ];
            
            Callout_Framework__mdt calloutMetadata = [Select Id,Active__c,HeaderParams__c,URL_Parameter_s__c,Timeout_Time__c,Body__c,HTTP_Method__c,Mock_Response__c,Endpoint__c,Extra_Param_s__c FROM Callout_Framework__mdt WHERE DeveloperName =: SHF_ConstantsUtil.DMS_Preview_URL];
            String endPoint;
            String clientId;
            String clientUserId;
            
            if(calloutMetadata != null){
                endPoint = calloutMetadata.Endpoint__c;
                clientId = calloutMetadata.HeaderParams__c;
                clientUserId = calloutMetadata.Extra_Param_s__c;
            }
            //String endpoint = 'http://13.127.33.202:8080/Deep/deep-rest/ddfs/service/view';
            //String clientId = 'SHUBHAM/OP';
            //String clientUserId = '07708';
            String fileParam = doc.Application__r.Name;
            String docCategory = EncodingUtil.urlEncode(doc.File_Name__c, 'UTF-8'); // URL-encode spaces
            
            // Build URL
            String previewUrl = endPoint
                + '?clientId=' + clientId
                + '&token=' + EncodingUtil.urlEncode(accessToken, 'UTF-8')
                + '&file=' + fileParam
                + '&docCategory=' + docCategory
                + '&clientUserId=' + clientUserId;
            System.debug('>>>previewUrl'+previewUrl);
            return previewUrl;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error building preview URL: ' + e.getMessage());
        }
    }
    
    @InvocableMethod(label='Get Document URL' description='Use to get the DMS URL')
    public static List<OutputWrapper> getDMSDocumentUrlFlow(List<DocumentInput> inputList) {
        List<OutputWrapper> outputList = new List<OutputWrapper>();
        if (!inputList.isEmpty()) {
            DocumentInput input = inputList[0];
            
            String documentId = input.documentId;
            OutputWrapper outputWrap = new OutputWrapper();
            outputWrap.result = getPreviewUrl(documentId);
            outputList.add(outputWrap);
        }
        return outputList;
    }
    
    
    @AuraEnabled
    public static void assignToCurrentUser(List<Id> recordIds) {
        List<Application__c> apps = [
            SELECT Id FROM Application__c WHERE Id IN :recordIds
        ];
        for (Application__c app : apps) {
            app.OwnerId = UserInfo.getUserId();
        }
        update apps;
    }
    
    public class DocumentInput {
        @InvocableVariable(label='Document Id' required=true)
        public String documentId;
        
    }
    public class OutputWrapper {
        @InvocableVariable
        public String result;
    }
    
    //* Get Loan Application details and Document file name from a Document record
    @AuraEnabled(cacheable=true)
    public static DocumentLoanWrapper getDocumentLoanDetails(Id documentId) {
        if (documentId == null) {
            throw new AuraHandledException('Document Id is required.');
        }
        
        // Only select primitive Ids, no nested SObjects
        Document__c doc = [
            SELECT Id, Name, File_Name__c, Loan_Applicant__c, Loan_Applicant__r.Application__c, E_Verification_line_item__c, E_Verification_line_item__r.Pan__c
            FROM Document__c 
            WHERE Id = :documentId LIMIT 1];
        
        // Create wrapper
        DocumentLoanWrapper wrapper = new DocumentLoanWrapper();
        wrapper.loanApplicationId = doc.Loan_Applicant__c;
        wrapper.parentApplicationId = doc.Loan_Applicant__r != null ? doc.Loan_Applicant__r.Application__c : null;
        wrapper.documentFileName = String.isNotBlank(doc.File_Name__c) ? doc.File_Name__c : doc.Name;
        wrapper.panFromLineItem = doc.E_Verification_line_item__r != null ? doc.E_Verification_line_item__r.Pan__c : null;
        // Step 2: If Line Item exists, find related file
        if (doc.E_Verification_line_item__c != null) {
            
            List<ContentDocumentLink> cdlList = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :doc.E_Verification_line_item__c
                LIMIT 1
            ];
            
            if (!cdlList.isEmpty()) {
                
                // Step 3: Get latest ContentVersion
                ContentVersion cv = [
                    SELECT Id, Title, FileExtension, VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId = :cdlList[0].ContentDocumentId
                    ORDER BY VersionNumber DESC
                    LIMIT 1
                ];
                
                // Step 4: Read text file content
                if (cv.FileExtension == 'txt') {
                    String fileText = cv.VersionData.toString();
                    wrapper.fileTextContent = fileText;
                    
                    // Optional: Extract PAN from filename
                    // Example: Account_Statement_AAAAA0000A
                    String extractedPan = extractPanFromFileName(cv.Title);
                    wrapper.panFromFileName = extractedPan;
                }
            }
        }
        
        return wrapper;
    }
    
    // Example: Account_Statement_AAAAA0000A → AAAAA0000A
    private static String extractPanFromFileName(String fileName) {
        if (String.isBlank(fileName)) {
            return null;
        }
        
        List<String> parts = fileName.split('_');
        if (parts.size() >= 3) {
            return parts[2];
        }
        return null;
    }
    
    // Wrapper class (only primitives, no nested SObjects)
    public class DocumentLoanWrapper {
        @AuraEnabled public Id loanApplicationId;
        @AuraEnabled public Id parentApplicationId;
        @AuraEnabled public String documentFileName;
        
        @AuraEnabled public String panFromLineItem;
        @AuraEnabled public String panFromFileName;
        @AuraEnabled public String fileTextContent;
    }
    
}