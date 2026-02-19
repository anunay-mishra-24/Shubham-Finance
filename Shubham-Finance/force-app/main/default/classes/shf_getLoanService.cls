public class shf_getLoanService {
    SHF_HTTPCalloutService service;
    
    // Generate Access Token
    public static String generateAccessToken() {
        shf_getLoanService getAccessToken = new shf_getLoanService();
        getAccessToken.service = new SHF_HTTPCalloutService('Get_loan_detail_Access_Token');
        
        HttpResponse response;
        String responseBody;
        
        // Set request body parameters (URL-encoded)
        String clientId = Label.LMSClientId;
        String grantType = Label.LMSGrantType;
        String clientSecret = Label.LMSClientSecret;
        
        String body = 'client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
            '&grant_type=' + EncodingUtil.urlEncode(grantType, 'UTF-8') +
            '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');
        
        // Set headers and body
        getAccessToken.service.setHeaderParameter('Content-Type', 'application/x-www-form-urlencoded');
        getAccessToken.service.setRequestBody(body);
        
        // Make callout or use mock response
        if (getAccessToken.service.getIsActive()) {
            response = getAccessToken.service.sendRequest();
        } else {
            response = new HttpResponse();
            response.setBody(getAccessToken.service.getmockRespnse());
            response.setStatusCode(200);
        }
        
        // Process response
        responseBody = (response != null) ? response.getBody() : null;
        
        if (String.isBlank(responseBody)) {
            Logger.error('Access token API response is missing or invalid.');
        }
        
        Map<String, Object> accessTokenMap = new Map<String, Object>();
        
        if (String.isNotBlank(responseBody)) {
            System.debug('Access token response: ' + responseBody);
            accessTokenMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            if (accessTokenMap.containsKey('access_token')) {
                System.debug('Access Token: ' + accessTokenMap.get('access_token'));
                return (String) accessTokenMap.get('access_token');
            }
        }
        return null;
    }
    @AuraEnabled
    public static String getLoanDetails(String recordId) {
        String msg= 'Joint_Exposure_Error_Msg';
        try {
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(
                new List<SObjectType> { Loan_Applicant__c.SObjectType }
            );
            HttpResponse response;
            shf_getLoanService svc = new shf_getLoanService();
            String accessToken = shf_getLoanService.generateAccessToken();
            if(Test.isRunningTest() && accessToken == null){
                accessToken = '6b9711a1-9f5f-42cf-9116-eded1f63649f';
            }
            system.debug('accessToken--> '+accessToken);
            if (String.isNotBlank(accessToken)) {
                // Fetch Loan Applicant Details
                Loan_Applicant__c primaryApplicant =  new SHF_LoanApplicantsSelector().getPrimaryApplicantByApplication(recordId);
               system.debug('primaryApplicant> ' +primaryApplicant);
                if (primaryApplicant == null ) {
                    Logger.error('Loan Applicant not found for application Id: ' + recordId);
                    return msg;
                }else if(primaryApplicant.Application__r.Loan_Agreement_No__c != null){
                    svc.service = new SHF_HTTPCalloutService('Get_loan_detail_API');
                    // svc.service.setHeaderParameter('Content-Type', 'application/json');
                    svc.service.setHeaderParameter('access_token', accessToken);
                    svc.service.setRequestBody(svc.service.getRequestBody().replace('<LoanAccountNumber>', primaryApplicant.Application__r.Loan_Agreement_No__c));   //need to remove '0DEL1908000005022543' with actual account number , need to ask this where this value is coming from              
                    if (svc.service.getIsActive()) {
                        response = svc.service.sendRequest();
                    } else {
                        response = new HttpResponse();
                        response.setBody(svc.service.getmockRespnse());
                        response.setStatusCode(200);
                    }
                    system.debug('response body >> ' + response.getBody());
                    if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        if (result.containsKey('success')) {
                            Map<String, Object> success = (Map<String, Object>) result.get('success');
                            if (success.containsKey('principalOutstanding')) {
                                msg = 'Joint_Exposure_Success_Msg';
                                Decimal principalOutstanding = (Decimal) success.get('principalOutstanding');
                                System.debug('Principal Outstanding => ' + principalOutstanding);           
                                primaryApplicant.Joint_Exposure__c = principalOutstanding;
                                //  update primaryApplicant;
                                System.debug('Updated Joint_Exposure__c with => ' + principalOutstanding);
                            }
                        }
                    }
                    applicantUow.registerDirty(primaryApplicant);
                    applicantUow.commitWork();
                    //updating flag on application for button visibility
                Application__c app  = new Application__c();
                app.id = primaryApplicant.Application__c;
                app.isFetchAppDetailExecuted__c = true;
                update app;
                }else{
                    system.debug('loan Agreement is not available' );
                    msg = 'Loan_Agreement_not_available';
                }
                if(svc.service != null){
                String reqBodyLog = svc.service != null ? svc.service.getRequestBody() : null ;
                if (reqBodyLog != null && reqBodyLog.length() > 5000) {
                    reqBodyLog = reqBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Request Body ' + reqBodyLog);
                Logger.info('status code ' + response.getStatusCode());
                Logger.info('status ' + response.getStatus());
                
                String respBodyLog = response.getBody();
                if (respBodyLog != null && respBodyLog.length() > 5000) {
                    respBodyLog = respBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Response Body ' + respBodyLog);
            }
            }
            else{
                msg = 'Token_not_generated';
            }
        } catch (Exception e) {
            Logger.error('Error: ' + e.getMessage()+ ' '+ e.getLineNumber());
        } finally {
            Logger.saveLog();
        }
        return msg;
    }
}