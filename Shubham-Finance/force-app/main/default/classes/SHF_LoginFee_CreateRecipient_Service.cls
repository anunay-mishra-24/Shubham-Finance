/**
 * @File Name          : SHF_LoginFee_CreateRecipient_Service.cls
 * @Description        : Service class to create login fee recipient and generate E-Verification records.
 * @Author             : Kunal Soni
 * 
 * ==============================================================================
 * Ver         Date              Author           Modification
 * ==============================================================================
 * 1.0         31-07-2025        Kunal Soni        Initial Version
 */
public class SHF_LoginFee_CreateRecipient_Service {

    public SHF_HTTPCalloutService service;

    /**
     * Calls the Login Fee API to create a recipient and creates an E-Verification record.
     *
     * @param applicationId The ID of the Loan Application.
     * @return A message indicating the result of the operation.
     */
    public static String createRecipient(Id applicationId) {
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('LOGIN_FEE_API');
        Savepoint sp;

        try {
            sp = Database.setSavepoint();

            // Fetch Application record
            Application__c appObj = new SHF_ApplicationSelector().selectApplicationForCIBIL(applicationId);
            if (appObj == null) {
                Logger.error('Application not found for Id: ' + applicationId);
                return null;
            }

            // Get business date
            List<String> businessDateData = SHF_LoginFee_FetchBusinessDate_Service.getBusinessDate(appObj.Branch__r.Branch_Code__c);
            String accessToken = SHF_LMSCommonUtil.generateAccessToken();

            if (String.isNotBlank(accessToken) && businessDateData.size() >= 2) {

                fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new Schema.SObjectType[] { E_Verification__c.SObjectType });
                fflib_SObjectUnitOfWork appUow = new fflib_SObjectUnitOfWork(new List<SObjectType> { Application__c.SObjectType });

                // Initialize service
                SHF_LoginFee_CreateRecipient_Service loginRecipient = new SHF_LoginFee_CreateRecipient_Service();
                loginRecipient.service = new SHF_HTTPCalloutService('LoginFee_Create_Recipient');
                loginRecipient.service.setHeaderParameter('access_token', accessToken);
                loginRecipient.service.setRequestBody(
                    loginRecipient.service.getRequestBody()
                        .replace('<branchCode>', appObj.Branch__r.Branch_Code__c)
                        .replace('<businessDate>', businessDateData[1])
                        .replace('<loanApplicant>', appObj.Name)
                );

                HttpResponse response;

                if (loginRecipient.service.getIsActive()) {
                    response = loginRecipient.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setStatusCode(200);
                    response.setBody(loginRecipient.service.getmockRespnse());
                }

                // Create E-Verification record
                E_Verification__c eVerification = SHF_CommonUtil.createVerfication(
                    null, SHF_ConstantsUtil.LOGIN_FEE_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS
                );
                eVerification.Loan_Application__c = applicationId;
                eVerification.Business_Date__c = businessDateData[1];

                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                    if (rootMap.containsKey('success')) {
                        List<Object> successList = (List<Object>) rootMap.get('success');

                        for (Object successObj : successList) {
                            Map<String, Object> accessMap = (Map<String, Object>) successObj;

                            if (accessMap.containsKey('value')) {
                                List<String> valueParts = String.valueOf(accessMap.get('value')).split(':');
                                if (valueParts.size() > 1) {
                                    eVerification.Description__c = valueParts[1];
                                }
                            } else {
                                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                                Logger.error('Missing "value" field. Request Body: ' + loginRecipient.service.getRequestBody());
                            }

                            if (accessMap.containsKey('messageArguments')) {
                                List<Object> messageArgs = (List<Object>) accessMap.get('messageArguments');
                                if (!messageArgs.isEmpty()) {
                                    eVerification.Receipt_Number__c = String.valueOf(messageArgs[0]);
                                }
                            } else {
                                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                                Logger.error('Missing "messageArguments" field. Request Body: ' + loginRecipient.service.getRequestBody());
                            }
                        }

                        Logger.info('Request Body: ' + loginRecipient.service.getRequestBody());
                        message = messageConfigMap.get('Login_Fee_API_Success').Message__c;

                    } else {
                        eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                        message = messageConfigMap.get('Login_Fee_API_Error').Message__c;
                        Logger.error('Missing "success" field in response. Request Body: ' + loginRecipient.service.getRequestBody());
                    }

                } else {
                    eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    message = messageConfigMap.get('Login_Fee_API_Error').Message__c;
                    Logger.error('Invalid API response. Request Body: ' + loginRecipient.service.getRequestBody());
                }

                // Save records
                if (eVerification != null) {
                    uow.registerNew(eVerification);
                    uow.commitWork();

                    appObj.Login_Fee_Verification__c = eVerification.Id;
                    appUow.registerDirty(appObj);
                    appUow.commitWork();

                    Logger.info('E-Verification record: ' + eVerification);
                    Logger.info('Status Code: ' + response.getStatusCode());
                    Logger.info('Status: ' + response.getStatus());
                    Logger.info('Body: ' + response.getBody());
                }
            }

        } catch (Exception ex) {
            if (sp != null) Database.rollback(sp);
            Logger.error('Login Fee Verification Error: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }

        return message;
    }
}