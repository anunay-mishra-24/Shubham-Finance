public class SHF_MergeReportController {
    
    @AuraEnabled
    public static String getPdfFilesAsBase64(Id verificationId){
        try{
            List<Map<String, String>> pdfFiles = new List<Map<String, String>>();
            List<Verification_Activity__c> activityList = [
                SELECT Id, Vendor_Status__c, Verification__r.Type__c
                FROM Verification_Activity__c
                WHERE Verification__c = :verificationId
            ];
            if (activityList.isEmpty()) return 'No Verification Activity Found';
            String verificationType = activityList[0].Verification__r.Type__c;
            String vfPageName;
            if(activityList[0].Verification__r.Type__c == 'Seller'){
                vfPageName = 'SHF_RCU_Report_PDF';
            }else {
                vfPageName = 'SHF_Applicant_RCU_Report';
            }
            for(Verification_Activity__c verActivity : activityList){
                if(verActivity.Vendor_Status__c != 'Completed'){
                    return 'There are some child activities pending for closure';
                }
                Map<String, String> pdfData = new Map<String, String>();
                PageReference pr = new PageReference('/apex/' + vfPageName);
                pr.getParameters().put('id', verActivity.Id);
                Blob pdfBlob = pr.getContentAsPDF();
                pdfData.put('Base64Data', EncodingUtil.base64Encode(pdfBlob));
                pdfFiles.add(pdfData);
            }
            return JSON.serialize(pdfFiles);
        }catch (Exception e){
            system.debug(e.getMessage() + ' at line ' + e.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled
    public static DocumentVerificationWrapper saveMergedPdf(Id verificationId) {
        DocumentVerificationWrapper docVerification = new DocumentVerificationWrapper();
        try {
            Verification__c verification = [SELECT Id, Name, Application__c FROM Verification__c WHERE Id =: verificationId];
            docVerification.verification = verification;
            List<Document__c> docs = [
                SELECT Id, File_Name__c, Application__c, Document_Category__c  
                FROM Document__c
                WHERE Application__c = :verification.Application__c
                AND File_Name__c LIKE '%RCU Combined Report%'
                LIMIT 1
            ];
            Document__c doc;
            if(!docs.isEmpty()){
                doc = docs[0];
            } else {
                doc = new Document__c(
                    File_Name__c = 'RCU Combined Report',
                    Stage__c = 'QDE',
                    Mandatory_Document__c = true,
                    Document_Category__c = 'Loan Specific Documents',
                    Application__c = verification.Application__c,
                    Verification__c = verificationId,
                    Status__c = 'Uploaded',
                    Document_Received_Date__c = Date.today(),
                    Document_Source__c = 'API'
                );
                insert doc;
                
                Document_Activity__c docActivity = new Document_Activity__c();
                docActivity.Document__c = doc.Id;
                docActivity.Verification__c = verificationId;
                Insert docActivity;
            }
            docVerification.document = doc;
            return docVerification; 
        } catch (Exception e) {
            system.debug(e.getMessage() + ' at line ' + e.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getPrimaryApplicant(Id applicationId) {
        List<Loan_Applicant__c> listOfLoanApplicant = [SELECT Id FROM Loan_Applicant__c WHERE Application__c = :applicationId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        return listOfLoanApplicant.isEmpty() ? null : listOfLoanApplicant[0].Id;
    }
    
    public class DocumentVerificationWrapper {
        public Document__c document;
        public Verification__c verification;
    }
}