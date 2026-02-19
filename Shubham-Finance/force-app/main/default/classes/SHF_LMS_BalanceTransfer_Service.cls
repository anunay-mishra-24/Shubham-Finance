/**
* @File Name          : SHF_LMS_BalanceTransfer_Service.cls
* @Description        : API for Balance Transfer
* @Author             : David Saini
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       17-07-2025      David Saini       Initial Version
*/
public with sharing class SHF_LMS_BalanceTransfer_Service {
    public static String balanceTransferCallout(String loanId) {
        Savepoint sp;
        String message = '';
        try {   
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
            Callout_Framework__mdt metadata = SHF_CommonUtil.getCalloutMetadata('Balance_Transfer_API').get('Balance_Transfer_API');
            String requestBody = metadata.Body__c;
            Application__c loanApp = new Application__c ();
            if(LoanId != null) {
                loanApp = [SELECT Id, Name,Branch__r.Branch_Code__c,Login_Fee_Verification__c,Login_Fee_Verification__r.Amount_Payable__c,Login_Fee_Verification__r.Name FROM Application__c WHERE Id =: loanId];
            }
            // String input = loanApp.Login_Fee_Verification__r.Name;
            // String[] parts = input.split('-');

            // String recieptNumer = parts.size() > 2 ? parts[2] : null;

            requestBody = requestBody.replace('<accountNumber>', String.isNotBlank(loanApp.Name) ? String.valueOf(loanApp.Name) : '');
            // requestBody = requestBody.replace('<branchId>', String.isNotBlank(loanApp.Branch__r.Branch_Code__c) ? String.valueOf(loanApp.Branch__r.Branch_Code__c) : '');
            // requestBody = requestBody.replace('<allocatedAmount>', String.isNotBlank(loanApp.Login_Fee_Verification__r.Amount_Payable__c) ? String.valueOf(loanApp.Login_Fee_Verification__r.Amount_Payable__c) : '');
            // requestBody = requestBody.replace('<receiptOrPayoutAmount>', String.isNotBlank(loanApp.Login_Fee_Verification__r.Amount_Payable__c) ? String.valueOf(loanApp.Login_Fee_Verification__r.Amount_Payable__c) : '');
            String accesstoken = SHF_LMSCommonUtil.generateAccessToken();
            System.debug('access token -- '+accesstoken);
            Logger.info('Access Token : '+accesstoken);
            if(String.isNotBlank(accessToken)){
                SHF_HTTPCalloutService callout = new SHF_HTTPCalloutService('Balance_Transfer_API');
                callout.setRequestMethod(metadata.HTTP_Method__c);
                callout.setEndpointURL(metadata.Endpoint__c);
                callout.setRequestBody(requestBody);
                callout.setHeaderParameter('access_token',accesstoken);
                callout.setHeaderParameter('Content-Type', 'application/json');
                

                
                HttpResponse response;
                if (metadata.Active__c) {
                    response = callout.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setBody(callout.getmockRespnse());
                    response.setStatusCode(200);
                }
                
                String responseBody = response.getBody();
                Logger.info('Request Body : '+callout.getRequestBody());
                Logger.info('EndPoint Url : '+callout.getEndpointURL());
                Logger.info('Response Status Code: ' + response.getStatusCode());
                Logger.info('Response Body : '+callout.getRequestMethod());
                if (response.getStatusCode() == 200 && String.isNotBlank(responseBody)) {
                    // Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    // SHF_LMS_CreateRecieptParser createReciptParser = new SHF_LMS_CreateRecieptParser();
                    // createReciptParser = SHF_LMS_CreateRecieptParser.parse(responseBody);
                    // System.debug('BalParser: ' + createReciptParser);

                    // if(createReciptParser.success != null){
                    //     system.debug('Recipt Id - '+ createReciptParser.success.get(0).messageArguments);
                    //     Logger.info('Recipt Id : '+ createReciptParser.success.get(0).messageArguments);
                    //     E_Verification__c eVerification = new 	E_Verification__c();
                    //     eVerification.Id = loanApp.Login_Fee_Verification__c;
                    //     eVerification.Receipt_Number__c = (String) createReciptParser.success.get(0).messageArguments[0];
                    //     uow.registerDirty(eVerification);
                    //     uow.commitWork();
                    // }
                    // else{
                    //     Logger.error('Error in response : '+createReciptParser.error.get(0).value);
                    // }

                }
                
                String reqBodyLog = callout.getRequestBody();
                if (reqBodyLog != null && reqBodyLog.length() > 5000) {
                    reqBodyLog = reqBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                // Logger.info('Request Body: ' + reqBodyLog);
                // Logger.info('Response Status Code: ' + response.getStatusCode());
                // Logger.info('Response Status: ' + response.getStatus());
                // Logger.info('Response Endpoint : '+callout.getEndpointURL());
                // Logger.info('Response Method : '+callout.getRequestMethod());
                
                system.debug('Response Status: ' + response.getStatus());
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    message = 'Success';
                }
                else{
                    Logger.error('Getting this error : ' );
                }
                String respBodyLog = response.getBody();
                if (respBodyLog != null && respBodyLog.length() > 5000) {
                    respBodyLog = respBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Response Body: ' + respBodyLog);
                system.debug('Response Body: ' + respBodyLog);
            }
            else{
                Logger.error('Access token is blank');
                return 'Access token is blank';
            }
        } catch (Exception e) {
            if (sp != null) {
                Database.rollback(sp);
            }
            System.debug('Error in Create_reciept_API: ' + e.getMessage());
            Logger.error('Error: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
        system.debug('message : '+message);
        return message;
    }
}