/**
* @File Name          : SHF_CancelLoan_Service.cls
* @Description        : API to Cancel Loan
* @Author             : David Saini
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       17-07-2025      David Saini       Initial Version
*/

public with sharing class SHF_CancelLoan_Service {
    public SHF_HTTPCalloutService service;
    
    public static String cancelLoan(String loanId, String cancelationReason) {
        Savepoint sp;
        String message = '';
        try {
            Callout_Framework__mdt metadata = SHF_CommonUtil.getCalloutMetadata('Cancel_Loan_API').get('Cancel_Loan_API');
            String accesstoken = SHF_LMSCommonUtil.generateAccessToken();
            
            if(String.isNotBlank(accessToken)){
                String requestBody = metadata.Body__c;
                Application__c loanApp = new SHF_ApplicationSelector().selectApplicationForLoanCancellationLMS(loanId);
                API_codes__mdt apiCodesMetadata = [SELECT Id, DeveloperName, Label,Value__c
                                                    FROM API_codes__mdt 
                                                    WHERE Label = 'Dispute with Seller' AND
                                                    API_Name__c ='Cancel_Loan_API'];
                requestBody = requestBody.replace('<cancellationReasonCode>', apiCodesMetadata.Value__c);
                requestBody = requestBody.replace('<loanAccountNumber>', loanApp.Name);
                // requestBody = requestBody.replace('<cancelationReason>', loanApp.cancelationReason);
                SHF_HTTPCalloutService callout = new SHF_HTTPCalloutService('Cancel_Loan_API');
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
                
                if (response.getStatusCode() == 200 && String.isNotBlank(responseBody)) {
                    Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    System.debug('responseBody: ' + res);
                }
                
                String reqBodyLog = callout.getRequestBody();
                if (reqBodyLog != null && reqBodyLog.length() > 5000) {
                    reqBodyLog = reqBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Request Body: ' + reqBodyLog);
                
                Logger.info('Response Status Code: ' + response.getStatusCode());
                Logger.info('Response Status: ' + response.getStatus());
                system.debug('Response Status: ' + response.getStatus());
                Logger.info('Endpoint : '+callout.getEndpointURL());
                Logger.info('Method : '+callout.getRequestMethod());
                
                String respBodyLog = response.getBody();
                if (respBodyLog != null && respBodyLog.length() > 5000) {
                    respBodyLog = respBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Response Body: ' + respBodyLog);
                system.debug('Response Body: ' + respBodyLog);
            }

        } catch (Exception e) {
            if (sp != null) {
                Database.rollback(sp);
            }
            Logger.error('Error: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
        system.debug('message : '+message);
        return message;
    }
}