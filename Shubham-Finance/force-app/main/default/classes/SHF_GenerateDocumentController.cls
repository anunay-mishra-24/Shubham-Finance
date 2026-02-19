/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : SHF_GenerateDocumentController
* Author          : Preeti
* Created Date    : Jan 23, 2026
* Last Modified By: Preeti
* Last Modified On: Jan 23, 2026
* Description     : This class implements for......
*  
* Change History  :
*  Date          │   Author     │   Change
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*  Jan 23, 2026  │ Preeti   │ Initial version
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/

public with sharing class SHF_GenerateDocumentController {
    
    
    /**
 * Returns the Visualforce page API name based on the selected language.
 * This method is used by LWC to construct the VF page preview URL.
 *
 * @param applicationId  Id of the Application record
 * @param language       Preferred language selected by the applicant
 * @return               VF page API name as String
 */
    @AuraEnabled
    public static String getVFPageName(Id applicationId, String language) {
        Map<String, String> vfPages = new Map<String, String>{
            'Hindi'   => 'SHF_Sanction_Letter_Hindi',
                'Kannada' => 'SHF_Sanction_Letter_Kannada',
                'Marathi' => 'SHF_Sanction_Letter_Marathi',
                'Punjabi' => 'SHF_Sanction_Letter_Punjabi',
                'Telugu'  => 'SHF_Sanction_Letter_Telgu',
                'English' => 'SHF_Sanction_Letter'
                };
                    return vfPages.containsKey(language) ? vfPages.get(language) : 'SHF_Sanction_Letter';
    }
    
    /**
 * Generates a PDF document (Sanction Letter / Tentative Repayment Schedule)
 * based on document type and language, and returns the PDF in Base64 format.
 * Also fetches or creates the corresponding Document__c record.
 *
 * @param applicationId  Id of the Application record
 * @param language       Preferred language for document generation
 * @param docType        Type of document (SANCTION / TENTATIVE)
 * @return               Map containing status, document Id, file name and Base64 PDF
 */
    @AuraEnabled
    public static Map<String, Object> generatePDF(Id applicationId, String language, String docType) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            Logger.info('generatePDF ApplicationId: ' + applicationId + ', Language: ' + language);
            
            // VF Page
            PageReference pr = getVFPage(language, docType);
            Logger.info('VF Page: ' + pr.getUrl());
            
            pr.getParameters().put('id', applicationId);
            
            // Generate PDF
            Blob pdfBlob = pr.getContentAsPDF();
            Logger.info('PDF generated → size: ' + pdfBlob.size());
            
            String base64Pdf = EncodingUtil.base64Encode(pdfBlob);
            
            // Fetch or Create Document
            Document__c doc = fetchOrCreateDocument(applicationId, docType);
            
            Logger.info('Document fetched/created Id: ' + doc.Id);
            
            result.put('status', 'SUCCESS');
            result.put('docId', doc.Id);
            result.put('fileName', doc.File_Name__c);
            result.put('fileBase64', base64Pdf);
            
        } catch (Exception e) {
            Logger.error('generatePDF ERROR → ' + e.getMessage() + ' Line:- ' + e.getLineNumber());
            result.put('status', 'ERROR');
            result.put('message', e.getMessage());
        } finally {
            Logger.saveLog();
        }
        
        return result;
    }
    
    
    /**
 * Fetches an existing Document__c record for the given application and
 * document type. If not found, creates a new Document__c record.
 *
 * @param applicationId  Id of the Application record
 * @param docType        Type of document (SANCTION / TENTATIVE)
 * @return               Existing or newly created Document__c record
 */
    
    // DOCUMENT FETCH / CREATE
    private static Document__c fetchOrCreateDocument(Id applicationId,  String docType) {
        try {
            Logger.info('fetchOrCreateDocument START → ApplicationId: ' + applicationId);
            String fileName = docType == 'TENTATIVE' ? 'Tentative Repayment Schedule' : 'Sanction Letter';
            
            List<Document__c> docs = [SELECT Id, File_Name__c FROM Document__c WHERE Application__c = :applicationId AND File_Name__c = :fileName AND Document_Category__c = 'Others' LIMIT 1];
            
            if (!docs.isEmpty()) {
                Logger.info('Existing Document Id: ' + docs[0].Id);
                return docs[0];
            }
            
            Logger.info('No existing Creating new Document');
            
            Document__c doc = new Document__c(
                File_Name__c = fileName,
                Stage__c = 'QDE',
                Mandatory_Document__c = true,
                Document_Category__c = 'Others',
                Application__c = applicationId,
                Status__c = 'Uploaded',
                Document_Received_Date__c = Date.today(),
                Document_Source__c = 'API'
            );
            
            try {
                insert doc;
                Logger.info('Document inserted successfully → Id: ' + doc.Id);
            } catch (Exception e) {
                Logger.error('Document insertion ERROR → ' + e.getMessage() + ' Line:- ' + e.getLineNumber());
                throw e;
            }
            
            return doc;
            
        } catch (Exception e) {
            Logger.error('fetchOrCreateDocument ERROR → ' + e.getMessage() + ' Line:- ' + e.getLineNumber());
            throw e;
        } finally {
            Logger.saveLog();
        }
    }
    
    /**
 * Returns the Id of the Primary Applicant associated with the given application.
 * If no primary applicant exists, returns null.
 *
 * @param applicationId  Id of the Application record
 * @return               Id of Primary Loan_Applicant__c or null
 */
    
    @AuraEnabled(cacheable=true)
    public static Id getPrimaryApplicant(Id applicationId) {
        
        List<Loan_Applicant__c> listOfLoanApplicant = [SELECT Id FROM Loan_Applicant__c WHERE Application__c = :applicationId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        
        return listOfLoanApplicant.isEmpty() ? null : listOfLoanApplicant[0].Id;
    }
    
    /**
 * Returns the Visualforce PageReference based on document type and language.
 * Tentative Repayment Schedule always uses the English VF page.
 * Sanction Letter VF page is selected based on applicant's preferred language.
 *
 * @param language       Preferred language for the document
 * @param docType        Type of document (SANCTION / TENTATIVE)
 * @return               PageReference for the selected VF page
 */
      
    private static PageReference getVFPage(String language, String docType) {
        
        // Tentative Repayment ALWAYS English VF
        if (docType == 'TENTATIVE') {
            return Page.SHF_Tentative_Repayment_Schedule;
        }
        
        // Sanction Letter Language based
        Map<String, PageReference> vfMap = new Map<String, PageReference>{
            'Hindi'    => Page.SHF_Sanction_Letter_Hindi,
                'Kannada'  => Page.SHF_Sanction_Letter_Kannada,
                'Marathi'  => Page.SHF_Sanction_Letter_Marathi,
                'Punjabi'  => Page.SHF_Sanction_Letter_Punjabi,
                'Telugu'   => Page.SHF_Sanction_Letter_Telgu,
                'English'  => Page.SHF_Sanction_Letter
                };
                    
                    return vfMap.containsKey(language) ? vfMap.get(language) : Page.SHF_Sanction_Letter;
    }

    /**
 * Returns the preferred language of the Primary Applicant for the application.
 * Defaults to English if no language is found.
 *
 * @param applicationId  Id of the Application record
 * @return               Preferred language as String (default: English)
 */
    
    @AuraEnabled(cacheable=true)
    public static String getPrimaryApplicantLanguage(Id applicationId) {
        
        List<Loan_Applicant__c> listOfLoanApplicant = [SELECT Preferred_Language__c FROM Loan_Applicant__c WHERE Application__c = :applicationId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        
        if (listOfLoanApplicant.isEmpty() || listOfLoanApplicant[0].Preferred_Language__c == null) {
            return 'English';
        }
        
        return listOfLoanApplicant[0].Preferred_Language__c;
    }
    



    @AuraEnabled
public static Boolean validateLMSData(Id applicationId) {

    List<Collateral__c> collateralList = [
        SELECT Id, Global_Collateral_Number__c
        FROM Collateral__c
        WHERE Application__c = :applicationId
    ];

    for (Collateral__c col : collateralList) {
        if (String.isBlank(col.Global_Collateral_Number__c)) {
            return false;
        }
    }

    List<Loan_Applicant__c> applicantList = [
        SELECT Id, Customer_Info_File_Number__c
        FROM Loan_Applicant__c
        WHERE Application__c = :applicationId
    ];

    for (Loan_Applicant__c la : applicantList) {
        if (String.isBlank(la.Customer_Info_File_Number__c)) {
            return false;
        }
    }

    return true; 
}      

         @AuraEnabled
public static void markDocumentUploaded(Id applicationId, String conditionLabel) {

    // 1. Application ke documents lao
    List<Document__c> docs = [
        SELECT Id, Status__c
        FROM Document__c
        WHERE Application__c = :applicationId
        AND Condition_Description__c = :conditionLabel
        LIMIT 1
    ];

    if (!docs.isEmpty()) {
        docs[0].Status__c = 'Uploaded';
        update docs;
    }
}


    
    
}