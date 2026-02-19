/**
* @File Name          : SHF_PublicSiteDocumentController.cls
* @Description        : This class is used to fetch/query not uploaded Document__c records based on conditions 
                        and send public site link to customer.
* @Author             : Ranjeet Pandit
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         16-01-2026              Ranjeet Pandit          
*/
public class SHF_PublicSiteDocumentController {

    @AuraEnabled(Cacheable=true)
    public static ResponseWrapper getNotUploadedDocumentsRecords(String applicationId){
        ResponseWrapper response = new ResponseWrapper();
        try {
            List<Document__c>   documentList = [ SELECT Id, Name, Document_Checklist__r.Name, Document_Category__c, Document_Type__c,File_Name__c,
                    Document_Received_Date__c, Document_Source__c, Status__c, Mandatory_Document__c, Type__c, Condition_Description__c, Type_Of_Condition__c,
                    RCU_Verification_Status__c, CreatedBy.Name, Application__r.OwnerId, RCU_Required__c, 
                    Loan_Applicant__r.Name, Loan_Applicant__r.Applicant_Type__c, Loan_Applicant__r.Mobile_Number__c,Loan_Applicant__r.Id ,Applicable_For__c
                    FROM Document__c
                    WHERE Application__c = :applicationId
                    AND Status__c = 'Not Uploaded' AND   Selected_for_Public_Site_Upload__c = FALSE AND File_Name__c!='RM Selfie'
                ];
               
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
    
    //SHF-1559 Added to handle calling this modal from Special Condition Screen
    @AuraEnabled(Cacheable=true)
    public static ResponseWrapper getPreDisbursementDocumentsRecords(String applicationId){
        ResponseWrapper response = new ResponseWrapper();
        try {
            List<Document__c>   documentList = [ SELECT Id, Name, Document_Checklist__r.Name, Document_Category__c, Document_Type__c,File_Name__c,
                    Document_Received_Date__c, Document_Source__c, Status__c, Mandatory_Document__c, Type__c, Condition_Description__c, Type_Of_Condition__c,
                    RCU_Verification_Status__c, CreatedBy.Name, Application__r.OwnerId, RCU_Required__c, 
                    Loan_Applicant__r.Name, Loan_Applicant__r.Applicant_Type__c, Loan_Applicant__r.Mobile_Number__c,Loan_Applicant__r.Id ,Applicable_For__c
                    FROM Document__c
                    WHERE Application__c = :applicationId
                    AND Status__c = 'Not Uploaded' AND   Selected_for_Public_Site_Upload__c = FALSE AND Type__c = 'Special Condition'
            ];
               
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


   
    @AuraEnabled
    public static void sendLinkToCustomer(String docList) {
        List<Object> documents = (List<Object>) JSON.deserializeUntyped(docList);
        System.debug(' docList==>' + docList);
        
        Id appId;
        String docType;     

        for (Object obj : documents) {
            Map<String, Object> docMap = (Map<String, Object>) obj;
            docType =(String) docMap.get('Type__c');
            System.debug('>>>type'+docType);
            if (docMap.get('Application__c') != null) {
                appId = (Id) docMap.get('Application__c');
                break;
            }           
        }

        Application__c app = [SELECT Id, Public_Site_Upload_SMS_Link_Status__c, Public_Site_Upload_SMS_Link_Status_SC__c FROM Application__c WHERE Id = :appId LIMIT 1];
    
        if (app.Public_Site_Upload_SMS_Link_Status__c == 'Active' && docType != 'Special Condition') {
                throw new AuraHandledException(
                    'A document upload link for customer is already active.'
                );
        }

        if (app.Public_Site_Upload_SMS_Link_Status_SC__c == 'Active' && docType == 'Special Condition') {
                throw new AuraHandledException(
                    'A document upload link for customer is already active.'
                );
        }

        Map<String, ApplicantInfo> mobileToApplicantMap = new Map<String, ApplicantInfo>();
        
        for (Object obj : documents) {
            Map<String, Object> docMap = (Map<String, Object>) obj;
            String documentCategory = (String) docMap.get('Document_Category__c');
            System.debug('>>>category'+documentCategory);
            String applicantId;
            String applicantName;
            String mobile;
            
            if (documentCategory != 'Loan Specific Documents') {
                Map<String, Object> applicant = (Map<String, Object>) docMap.get('Loan_Applicant__r');
                if(applicant!=null){
                    applicantId = (String) applicant.get('Id');
                    mobile      = (String) applicant.get('Mobile_Number__c');
                    applicantName = (String) applicant.get('Name');
                }
            }
            
            //Loan Specific → Primary Applicant
            else if (docMap.get('Application__c') != null && documentCategory == 'Loan Specific Documents') {
                String applicationId = (String) docMap.get('Application__c');
                List<Loan_Applicant__c> primaryApplicants = [ SELECT Id, Name, Mobile_Number__c FROM Loan_Applicant__c WHERE Application__c = :applicationId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
                System.debug('>>>primaryApplicant'+primaryApplicants[0]);
                if (!primaryApplicants.isEmpty()) {
                    applicantId = primaryApplicants[0].Id;
                    applicantName = primaryApplicants[0].Name;
                    mobile      = primaryApplicants[0].Mobile_Number__c;
                }
            }

            else if (docMap.get('Application__c') != null && docType == 'Special Condition') {
                String applicationId = (String) docMap.get('Application__c');
                List<Loan_Applicant__c> primaryApplicants = [ SELECT Id, Name, Mobile_Number__c FROM Loan_Applicant__c WHERE Application__c = :applicationId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
                System.debug('>>>primaryApplicant'+primaryApplicants[0]);
                if (!primaryApplicants.isEmpty()) {
                    applicantId = primaryApplicants[0].Id;
                    applicantName = primaryApplicants[0].Name;
                    mobile      = primaryApplicants[0].Mobile_Number__c;
                }
            }
            
            // Avoid duplicate SMS for same mobile
            if (!String.isBlank(mobile) && !mobileToApplicantMap.containsKey(mobile)) {
                ApplicantInfo info = new ApplicantInfo();
                info.applicantId   = applicantId;
                info.applicantName = applicantName;
                mobileToApplicantMap.put(mobile, info);
            }
        }
        
        Map<String, String> templateData = SHF_CommonUtil.getNotificationTemplate('Public_Site_Upload_Document_SMS');
        if (templateData == null) {
            throw new AuraHandledException('Notification template not found');
        }
        String smsTemplate = SHF_CommonUtil.formatSMSTemplate(templateData.get('SMS_Notification'));
   
        for (String mobile : mobileToApplicantMap.keySet()) {
            System.debug('mobileToApplicantMap.keySet()===>'+mobileToApplicantMap.keySet());
            ApplicantInfo info = mobileToApplicantMap.get(mobile);
            System.debug('ApplicantInfo==>'+info);
            String urlLabelValue = System.Label.Public_Site_Upload_URL;
            String url = urlLabelValue + info.applicantId;
            
            String finalMessage = smsTemplate.replace('<var1>', info.applicantName)
                                             .replace('<var2>', url);
            Message_Service__e evt = new Message_Service__e();
            evt.Receiver__c = mobile;
            evt.Message_Template__c = finalMessage;
            EventBus.publish(evt);
        }
    }
            
        
    @AuraEnabled
    public static void captureSendSmsTime(String applicationId) {

          if (applicationId == null) {
        throw new AuraHandledException('Application Id is missing.');
        }

        Application__c app = [
            SELECT Id, Public_Site_Upload_SMS_Link_Time__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
        
        app.Public_Site_Upload_SMS_Link_Time__c = System.now();
        update app;
        system.debug(' app.Public_Site_Upload_SMS_Link_Time__c ===>' +  app.Public_Site_Upload_SMS_Link_Time__c );
    }

    @AuraEnabled
    public static void captureSendSmsTimeForSC(String applicationId) {

          if (applicationId == null) {
        throw new AuraHandledException('Application Id is missing.');
        }

        Application__c app = [
            SELECT Id, Public_Site_Upload_SMS_Link_Time_For_SC__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
        
        app.Public_Site_Upload_SMS_Link_Time_For_SC__c = System.now();
        update app;
        system.debug(' app.Public_Site_Upload_SMS_Link_Time_For_SC__c ===>' +  app.Public_Site_Upload_SMS_Link_Time_For_SC__c );
    }


   @AuraEnabled
    public static void uploadForPublicSiteTrue(List<Id> documentId){
        List<Document__c> docList = [SELECT Id ,  Selected_for_Public_Site_Upload__c FROM Document__c WHERE ID IN :documentId];
        for(Document__c doc : docList){
             doc.Selected_for_Public_Site_Upload__c = TRUE;
        }
        if(!docList.isEmpty()){
         update docList;
        }
    }

    public class ApplicantInfo {
        public String applicantId;
        public String applicantName;
    }

    public class ResponseWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String responseBody;
        @AuraEnabled public String loanApplicationStage;
        @AuraEnabled public String recordId;
        @AuraEnabled public Integer totalRecords;
    }

}