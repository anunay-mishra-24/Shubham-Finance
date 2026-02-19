/**
* @File Name          : SHF_Employment_Verification_PDF_Service.cls
* @Description        : Step 2 - Download PDF and create Document record (DMS call moved to LWC).
* @Author             : Akshi Sharma 
*/
public with sharing class SHF_Employment_Verification_PDF_Service {

    public class PDFProcessResponse {
        @AuraEnabled public String message;
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String base64Pdf;
        @AuraEnabled public Id docId;
        @AuraEnabled public String docCategory;
        @AuraEnabled public Id applicationId;
    }

    @AuraEnabled
    public static Map<String, Object> processEmploymentVerificationPDF(Id applicantId, String pdfLink) {
        System.debug('=== [PDF Service] START processEmploymentVerificationPDF ===');
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (String.isBlank(pdfLink)) {
                result.put('isSuccess', false);
                result.put('message', 'No PDF link provided.');
                return result;
            }
            
            List<Loan_Applicant__c> applicants = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{applicantId});
            if (applicants.isEmpty()) {
                result.put('isSuccess', false);
                result.put('message', 'Loan Applicant not found.');
                return result;
            }
            
            Loan_Applicant__c applicant = applicants[0];
            Http pdfReq = new Http();
            HttpRequest pdfRequest = new HttpRequest();
            pdfRequest.setEndpoint(pdfLink);
            pdfRequest.setMethod('GET');
            HttpResponse pdfRes = pdfReq.send(pdfRequest);
            
            if (pdfRes.getStatusCode() != 200) {
                result.put('isSuccess', false);
                result.put('message', 'Failed to download PDF. Status: ' + pdfRes.getStatusCode());
                return result;
            }
            
            Blob pdfBlob = pdfRes.getBodyAsBlob();
            String base64Pdf = EncodingUtil.base64Encode(pdfBlob);
            
            Document__c doc = new Document__c(
                Loan_Applicant__c = applicant.Id,
                Application__c = applicant.Application__c,
                File_Name__c = 'Employment Verification Report',
                Document_Source__c = 'API',
                Document_Category__c = 'Others',
                Status__c = 'Uploaded',
                Stage__c = 'DDE',
                Document_Received_Date__c = System.today()
            );
            insert doc;
            
            // Return details for DMS
            result.put('isSuccess', true);
            result.put('message', 'PDF downloaded successfully.');
            result.put('documentId', doc.Id);
            result.put('applicationId', applicant.Application__c);
            result.put('documentCategory', doc.File_Name__c);
            result.put('base64Pdf', base64Pdf);
            return result;
            
        } catch (Exception ex) {
            result.put('isSuccess', false);
            result.put('message', 'Error: ' + ex.getMessage());
            return result;
        }
    }
}