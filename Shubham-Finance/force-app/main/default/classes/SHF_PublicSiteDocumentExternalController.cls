/**
* @File Name          : SHF_PublicSiteDocumentExternalController.cls
* @Description        : This class is used to fetch/query not uploaded Document__c records based on conditions for public site                   
* @Author             : Ranjeet Pandit
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         16-01-2026              Ranjeet Pandit          
*/


public without sharing class SHF_PublicSiteDocumentExternalController {
    public Id actualApplicantId { get; set; }
    public Boolean isExpired { get; set; }
    public String message { get; set; }
    
    public void onPageLoad() {
        actualApplicantId = ApexPages.currentPage().getParameters().get('applicantId');
        isExpired = false;
        message = '';
        checkInitialStatus();
        if (isExpired == true) {
            afterExpiredUpdateDocuments();
        }
    }
    
    private void checkInitialStatus() {
        try {
            Loan_Applicant__c applicantRec = [SELECT Id, Application__c FROM Loan_Applicant__c WHERE Id = :actualApplicantId LIMIT 1];
            Application__c appRec = [SELECT Id, RecordType.DeveloperName, Public_Site_Upload_SMS_Link_Status__c FROM Application__c WHERE Id = :applicantRec.Application__c LIMIT 1];
            
            if (appRec.RecordType.DeveloperName != 'QDE' && appRec.RecordType.DeveloperName != 'Pre_Disbursement') {
                message = 'Link Expired.';
                isExpired = true;
                return;
            }
            
            if (appRec.Public_Site_Upload_SMS_Link_Status__c != 'Active') {
                message = 'Link Expired.';
                isExpired = true;
                return;
            }
            
        } 
        catch (Exception ex) {
            message = 'Link Expired.';
            isExpired = true;
        }
    }
    
    @AuraEnabled(Cacheable=true)
    public static ResponseWrapper getDocumentsForApplicant(Id applicantId){
        ResponseWrapper response = new ResponseWrapper();
        try {
            List<Document__c> documentList = new List<Document__c>();
            Loan_Applicant__c   applicantType = [SELECT Id, Applicant_Type__c, Application__c FROM Loan_Applicant__c where Id = :applicantId LIMIT 1];
            String appId =  applicantType.Application__c;
            if(applicantId != null && applicantType.Applicant_Type__c != 'Primary Applicant'){
                documentList = [SELECT Id, Name, Document_Checklist__r.Name, Document_Category__c, Document_Type__c,File_Name__c,
                                Document_Received_Date__c, Document_Source__c, Status__c, Mandatory_Document__c,
                                RCU_Verification_Status__c, CreatedBy.Name, Application__r.OwnerId, RCU_Required__c, 
                                Loan_Applicant__r.Name,Loan_Applicant__r.Mobile_Number__c,Loan_Applicant__r.Id
                                FROM Document__c
                                WHERE Loan_Applicant__r.Id = :applicantId AND Status__c = 'Not Uploaded' AND   Selected_for_Public_Site_Upload__c = TRUE
                               ];
            }else if(applicantType.Applicant_Type__c == 'Primary Applicant'){
                documentList = [SELECT Id, Name, Document_Checklist__r.Name, Document_Category__c, Document_Type__c,File_Name__c,
                                Document_Received_Date__c, Document_Source__c, Status__c, Mandatory_Document__c,
                                RCU_Verification_Status__c, CreatedBy.Name, Application__r.OwnerId, RCU_Required__c, 
                                Loan_Applicant__r.Name,Loan_Applicant__r.Mobile_Number__c,Loan_Applicant__r.Id
                                FROM Document__c  Where Status__c = 'Not Uploaded' AND Selected_for_Public_Site_Upload__c = TRUE AND (Application__c =:appId OR Loan_Applicant__r.Id =: applicantId)];   
            }
            response.responseBody = JSON.serialize(documentList);
            response.isSuccess = true;
            response.totalRecords = documentList.size();
        } 
        catch (Exception ex) {
            response.isSuccess = false;
            response.responseBody = ex.getMessage();
            response.totalRecords = 0;
        }
        return response;
    }
    
    public ResponseWrapper afterExpiredUpdateDocuments(){
        ResponseWrapper response = new ResponseWrapper();
        try {
             Id applicantId = actualApplicantId;
            if(applicantId == null){
                throw new AuraHandledException('Applicant Id is required');
            }
            
            List<Document__c> documentsToUpdate = new List<Document__c>();
            Loan_Applicant__c applicantType = [SELECT Id, Applicant_Type__c, Application__c FROM Loan_Applicant__c WHERE Id = :applicantId LIMIT 1];
            String appId = applicantType.Application__c;
            
            if(applicantType.Applicant_Type__c != 'Primary Applicant'){
                documentsToUpdate = [SELECT Id, Selected_for_Public_Site_Upload__c FROM Document__c WHERE Loan_Applicant__r.Id = :applicantId AND Status__c = 'Not Uploaded' AND Selected_for_Public_Site_Upload__c = TRUE];
            } 
            else if(applicantType.Applicant_Type__c == 'Primary Applicant'){
                documentsToUpdate = [SELECT Id, Selected_for_Public_Site_Upload__c FROM Document__c WHERE Status__c = 'Not Uploaded' AND Selected_for_Public_Site_Upload__c = TRUE AND (Application__c = :appId OR Loan_Applicant__r.Id = :applicantId) ];
            }
            if(!documentsToUpdate.isEmpty()){
                for(Document__c doc : documentsToUpdate){
                    doc.Selected_for_Public_Site_Upload__c = false;
                }
            }
            
            if(!documentsToUpdate.isEmpty()){
                update documentsToUpdate;
            }
            
            response.isSuccess = true;
            response.totalRecords = documentsToUpdate.size();
            response.responseBody = 'Documents updated successfully';
            
        } catch (Exception ex) {
            response.isSuccess = false;
            response.totalRecords = 0;
            response.responseBody = ex.getMessage();
        }
        
        return response;
    }
    
    public class ResponseWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String responseBody;
        @AuraEnabled public String loanApplicationStage;
        @AuraEnabled public String recordId;
        @AuraEnabled public Integer totalRecords;
    }
    
}