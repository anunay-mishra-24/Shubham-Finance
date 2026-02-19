/**
 * @File Name          : SHF_LoginFee_LinkReceipt_Service.cls
 * @Description        : Service class to link login fee receipt and create E-Verification records.
 * @Author             : Kunal Soni
 * 
 * ==============================================================================
 * Ver         Date              Author           Modification
 * ==============================================================================
 * 1.0         31-07-2025        Kunal Soni        Initial Version
 */
public class SHF_LoginFee_LinkReceipt_Service {
    
    public SHF_HTTPCalloutService service;
    
    public static String linkReceipt(Id applicationId) {
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('LOGIN_FEE_API');
        
        try {
            // Savepoint sp = Database.setSavepoint();
            
            // Fetch application details
            String receiptId = '';
            Application__c appObj = new SHF_ApplicationSelector().selectApplicationForCIBIL(applicationId);
            if(appObj != null){
                receiptId = appObj.Login_Fee_Verification__r.Receipt_Number__c;
            }
            
            // Initialize Unit of Work for DML operations
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new Schema.SObjectType[] { E_Verification__c.SObjectType });
            
            // Prepare service call
            SHF_LoginFee_LinkReceipt_Service loginReceiptService = new SHF_LoginFee_LinkReceipt_Service();
            loginReceiptService.service = new SHF_HTTPCalloutService('Login_Fee_Link_Receipt');
            loginReceiptService.service.setRequestBody(
                loginReceiptService.service.getRequestBody().replace('<applicationName>', appObj.Name)
            );
            loginReceiptService.service.setRequestBody(
                loginReceiptService.service.getRequestBody().replace('<receiptId>', receiptId)
            );
            
            HttpResponse response;
            if (loginReceiptService.service.getIsActive()) {
                response = loginReceiptService.service.sendRequest();
                System.debug('Response Body --> ' + response.getBody());
                
            } else {
                response = new HttpResponse();
                response.setBody(loginReceiptService.service.getmockRespnse());
                response.setStatusCode(200);
            }
            Logger.info('Response Body : '+response.getBody());
            Logger.info('Request Body : '+loginReceiptService.service.getRequestBody());
            Logger.info('EndPoint Url : '+loginReceiptService.service.getEndpointURL());
            Logger.info('Request  Method : '+loginReceiptService.service.getRequestMethod());
            Logger.info('Response status code : '+response.getStatusCode());
        
            // Create verification record
            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(
                null,
                SHF_ConstantsUtil.LOGIN_FEE_RECORD_TYPE,
                SHF_ConstantsUtil.COMPLETEDSTATUS
            );
            eVerification.Loan_Application__c = applicationId;

            // E_Verification__c eVerification = [SELECT Id,Name,Link_Receipt__c FROM E_Verification__c WHERE Receipt_Number__c = :receiptId LIMIT 1];
            // eVerification.Id = eVerification.Id;
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                eVerification.Link_Receipt__c = true;
                message = messageConfigMap.get('Login_Fee_API_Success').Message__c;
                eVerification.Link_Receipt__c = true;
                
            } else {
                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                
                Map<String, Object> errorBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (errorBody.containsKey('error')) {
                    eVerification.Status__c = String.valueOf(errorBody.get('error'));
                }
                if (errorBody.containsKey('message')) {
                    eVerification.Description__c = String.valueOf(errorBody.get('message'));
                }
                
                message = messageConfigMap.get('Login_Fee_API_Error').Message__c;
                eVerification.Link_Receipt__c = false;
            }
            
            // Register and commit verification record
            if (eVerification != null) {
                System.debug('E-Verification Record --> ' + eVerification);
                uow.registerDirty(eVerification);
                uow.commitWork();
                Logger.info('E-Verification record saved: ' + eVerification);
            }
            
        } catch (Exception ex) {
            Logger.error('Login Fee Verification Error: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }
        
        return message;
    }
}