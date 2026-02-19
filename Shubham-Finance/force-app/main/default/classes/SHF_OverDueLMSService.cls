/**
* @File Name          : SHF_OverDueLMSService.cls
* @Description        : Get Over Due For Loan Applicant.
* @Author             : Kunal Soni
* 
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         18-07-2025   Kunal Soni   Initial Version
*/
public class SHF_OverDueLMSService {
    
    SHF_HTTPCalloutService service;
    
    public static SHF_ServiceConsoleLMSControllerWrapper getOverDueDetails(String accountNumber, SHF_ServiceConsoleLMSControllerWrapper wrappers) {
        SHF_ServiceConsoleLMSControllerWrapper wrapper = wrappers;
        try {
            // Initialize service
            SHF_OverDueLMSService getOverdue = new SHF_OverDueLMSService();
            getOverdue.service = new SHF_HTTPCalloutService('Get_Over_Due');
            String accessToken = SHF_LMSCommonUtil.generateAccessToken();
            
            if(Test.isRunningTest() && accessToken == null){
                accessToken = '6b9711a1-9f5f-42cf-9116-eded1f63649f';
            }
            
            if (String.isNotBlank(accessToken)) {
                // Replace loan account placeholder
                String requestBody = getOverdue.service.getRequestBody();
                requestBody = requestBody.replace('<LoanAccountNumber>', accountNumber);
                getOverdue.service.setRequestBody(requestBody);
                
                getOverdue.service.setHeaderParameter('Content-Type', 'application/json');
                getOverdue.service.setHeaderParameter('access_token', accessToken);
                
                HttpResponse response;
                Map<String, Object> responseMap;
                
                // Perform callout or use mock
                if (getOverdue.service.getIsActive()) {
                    response = getOverdue.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setBody(getOverdue.service.getmockRespnse());
                    response.setStatusCode(200);
                }
                
                // Parse response
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    System.debug('responseMap --> ' + responseMap);
                    
                    if (responseMap.containsKey('success')) {
                        Map<String, Object> successMap = (Map<String, Object>) responseMap.get('success');
                        List<Object> overDueList = (List<Object>) successMap.get('overDueDetails');
                        if (!overDueList.isEmpty()) {
                            Map<String, Object> overDueDetail = (Map<String, Object>) overDueList[0]; // first element
                            
                            // Assign values
                            wrapper.chargeCodeDescription = (String) overDueDetail.get('chargeCodeDescription');
                            wrapper.totalOutstandingReceivableAmount = successMap.containsKey('totalOutstandingReceivableAmount')
                                ? Decimal.valueOf(String.valueOf(successMap.get('totalOutstandingReceivableAmount')))
                                : 0;
                            wrapper.totalOutstandingPayableAmount = successMap.containsKey('totalOutstandingPayableAmount')
                                ? Decimal.valueOf(String.valueOf(successMap.get('totalOutstandingPayableAmount')))
                                : 0;
                            wrapper.netOverDueAmount = successMap.containsKey('netOverDueAmount')
                                ? Decimal.valueOf(String.valueOf(successMap.get('netOverDueAmount')))
                                : 0;
                            System.debug('wrapperList Loan Detail-->'+wrapper);
                        }
                    }
                }
                String reqBodyLog = getOverdue.service.getRequestBody();
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
        } catch (Exception e) {
            Logger.error('Error in SHF_OverDueLMSService: ' + e.getMessage()+ ' '+ e.getLineNumber());
        } finally {
            Logger.saveLog();
        }
        return wrapper;
    }
}