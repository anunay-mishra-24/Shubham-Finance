/**
 * @File Name          : SHF_Perfios_Upload_Files_Integration
 * @Description        : Class to Trigger Perfios Upload Files
 * @Author             : Karan Keswani
 * 
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0                           Initial Version
 */
public without sharing class SHF_Perfios_Upload_Files_Integration implements Queueable, Database.AllowsCallouts {
    
    // Class level variables
    public Id customerDocId;
    public String transactionID;
    public List<ContentVersion> conVerList;
    public String verificationId;
    private HTTPCalloutService service;
    
    // Constants for status and messages
    private static final String STATUS_SUFFIX = 'Bank Statement';
    private static final Integer STATUS_CODE_OK = 200;
    
    /**
     * Parameterized Constructor
     * 
     * @param customerDocId - The ID of the customer document.
     * @param transactionID - The transaction ID.
     * @param conVerList - List of ContentVersion objects.
     * @param isRetry - Flag to indicate if it's a retry.
     */
    public SHF_Perfios_Upload_Files_Integration(ID customerDocId, String transactionID, List<ContentVersion> conVerList, string verificationId) {
        this.customerDocId = customerDocId;
        this.transactionID = transactionID;
        this.conVerList = conVerList;
        this.verificationId = verificationId;
        this.service = new HTTPCalloutService('Perfios_Upload_Files');
    }
    
    /**
     * Method to execute the Queueable job
     */
    public void execute(QueueableContext context) {
        System.debug('this.customerDocId>>> ' + this.customerDocId + ' this.conVerList.size()>>> ' + this.conVerList.size());
        if (isValidInput()) {
            ContentVersion cvObj = this.conVerList[0];
            String fileName = cvObj.Title;
            E_Verification__c verification = [SELECT Id,Perfios_API_Status__c,Loan_Applicant__c,FIle_Id__c,Is_Report_available__c, Processing_File_Done__c, Password__c FROM E_Verification__c WHERE Transaction_Id__c =:transactionId AND Loan_Applicant__c =:customerDocId LIMIT 1];
            if (String.isNotEmpty(this.transactionID) && String.isNotEmpty(fileName)) {                
                String fileID = uploadFiles(this.transactionID, fileName, cvObj);
                
                /**
                if (fileID != null) {
                    enqueueProcessFilesJob(fileID, verification);
                }
				**/
            } 
        }
    }
    /**
     * Method to check if the input is valid
     */
    private Boolean isValidInput() {
        return String.isNotEmpty(this.customerDocId) && String.isNotBlank(this.customerDocId) && this.conVerList.size() > 0;
    }
    
    /**
     * Method to upload files
     * 
     * @param transactionId - The transaction ID.
     * @param fileName - The name of the file.
     * @param cvObj - ContentVersion object.
     * @return fileID - The ID of the uploaded file.
     */
    public String uploadFiles(String transactionId, String fileName, ContentVersion cvObj) {
         E_Verification__c verification = [SELECT Id,Perfios_API_Status__c,Loan_Applicant__c,FIle_Id__c,Is_Report_available__c, Processing_File_Done__c, Password__c FROM E_Verification__c WHERE Transaction_Id__c =:transactionId AND Loan_Applicant__c =:customerDocId LIMIT 1];
        String fileID;
        try {            
            HTTPResponse res = Perfios_IntegrationUtil.uploadFiles(transactionId, fileName, cvObj,customerDocId);
            System.debug('Response: \n' + res.getStatusCode() + '---' + res.getBody());

            if (res.getStatusCode() == STATUS_CODE_OK) {
                fileID = parseFileIdFromResponse(res.getBody());
                verification.FIle_Id__c = fileID;
                update verification;
            } else {
                handleErrorResponse(res);
                fileID = null;
            }
        } catch (Exception e) {
            System.debug('Error :' + e.getMessage());
            System.debug('In Line Number :' + e.getLineNumber());    
            /**
			UB_LogException error = new UB_LogException();
            error.log(e, '');
			**/
            fileID = null;
        }
        return fileID;
    }
	 /**
     * Method to parse file ID from the response
     * 
     * @param responseBody - The response body.
     * @return fileID - The parsed file ID.
     */
   @TestVisible private String parseFileIdFromResponse(String responseBody) {
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        if (responseMap.containsKey('file')) {
            Map<String, Object> fileIdMap = (Map<String, Object>)responseMap.get('file');
            system.debug('fileIdMap===>'+fileIdMap);
            return String.valueOf(fileIdMap.get('fileId'));
        }
        return null;
    }
    /**
     * Method to handle error response
     * 
     * @param res - The HTTP response.
     */
    private void handleErrorResponse(HTTPResponse res) {
        System.debug('status code not 200');
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        if (responseMap.containsKey('error')) {
            Map<String, Object> responseDataMap = (Map<String, Object>)responseMap.get('error');
            System.debug('code: ' + String.valueOf(responseDataMap.get('code')));
            System.debug(String.valueOf(responseDataMap.get('message')));
             // call for creating API Logger
        }
    }
    
    /**
     * Method to enqueue the process files job
     * 
     * @param fileID - The ID of the uploaded file.
     
    private void enqueueProcessFilesJob(String fileID, Verification__c verification) {
        if (!Test.isRunningTest()) {
            System.enqueueJob(new UB_Perfios_Process_Files_Integration(this.customerDocId, fileID, verification.Password__c, verificationId, this.conVerList, this.transactionID));
        }
    }

	*/
}