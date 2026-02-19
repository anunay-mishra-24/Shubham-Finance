/**
* @File Name          : SHF_GetExposureLMSService.cls
* @Description        : Get Exposure For Loan Applicant.
* @Author             : Kunal Soni
* 
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         18-07-2025   Kunal Soni   Initial Version
*/
public class SHF_GetExposureLMSService {
    
    SHF_HTTPCalloutService service;
    
    public static SHF_ServiceConsoleLMSControllerWrapper getExposure(String accountNumber, SHF_ServiceConsoleLMSControllerWrapper wrappers) {
        SHF_ServiceConsoleLMSControllerWrapper wrapper = wrappers;
        try {
            
            SHF_GetExposureLMSService getCustomerLoanDetail = new SHF_GetExposureLMSService();
            getCustomerLoanDetail.service = new SHF_HTTPCalloutService('Get_Exposure');
            String accessToken = SHF_LMSCommonUtil.generateAccessToken();
            
            if(Test.isRunningTest() && accessToken == null){
                accessToken = '6b9711a1-9f5f-42cf-9116-eded1f63649f';
            }
            
            if (String.isNotBlank(accessToken)) {
                getCustomerLoanDetail.service.setRequestBody(
                    getCustomerLoanDetail.service.getRequestBody().replace('<LoanAccountNumber>', accountNumber)
                );
                
                getCustomerLoanDetail.service.setHeaderParameter('Content-Type', 'application/json');
                getCustomerLoanDetail.service.setHeaderParameter('access_token', accessToken);
                
                HttpResponse response;
                if (getCustomerLoanDetail.service.getIsActive()) {
                    response = getCustomerLoanDetail.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setBody(getCustomerLoanDetail.service.getmockRespnse());
                    response.setStatusCode(200);
                }
                
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    
                    if (responseMap.containsKey('Customer Exposure Details')) {
                        List<Object> listOfCustomer = (List<Object>) responseMap.get('Customer Exposure Details');
                        
                        for (Object obj : listOfCustomer) {
                            Map<String, Object> customerMap = (Map<String, Object>) obj;
                            
                            // Create Applicant record
                            wrapper.customerId = (String) customerMap.get('customerNumber');
                            wrapper.customerName = (String) customerMap.get('customerName');
                            
                            // Get loanDetails list
                            if (customerMap.containsKey('loanDetails')) {
                                List<Object> loanDetails = (List<Object>) customerMap.get('loanDetails');
                                
                                for (Object loanObj : loanDetails) {
                                    Map<String, Object> loanMap = (Map<String, Object>) loanObj;
                                    
                                    wrapper.currentTenure = (loanMap.get('tenure') != null) ? String.valueOf(loanMap.get('tenure')) : null;
                                    wrapper.Product = (String) loanMap.get('productName');
                                }
                            }
                            System.debug('wrapperList Loan Detail-->'+wrapper);
                        }
                    }
                }
                String reqBodyLog = getCustomerLoanDetail.service.getRequestBody();
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
            Logger.error('Error: ' + e.getMessage()+ ' '+ e.getLineNumber());
        } finally {
            Logger.saveLog();
        }
        return wrapper;
    }
}