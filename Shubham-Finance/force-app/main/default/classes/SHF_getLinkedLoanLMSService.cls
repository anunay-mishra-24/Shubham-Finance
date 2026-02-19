/**
* @File Name          : SHF_getLinkedLoanLMSService.cls
* @Author             : Kunal Soni
* @Last Modified By   : Kunal Soni
* @Last Modified On   : 05-12-2025
* @Description        : This class is used to fetch linked loan detail for LMS.
**/

public class SHF_getLinkedLoanLMSService {

    SHF_HTTPCalloutService service;

    @AuraEnabled(cacheable = false)
    public static List<LinkedLoanWrapper> getLinkedLoanDetails(String accountNumber, String mobile) {

        List<LinkedLoanWrapper> listOfWrapper = new List<LinkedLoanWrapper>();
        LinkedLoanWrapper wrapper = new LinkedLoanWrapper();

        // Log start
        Logger.info('LMS Linked Loan API invoked. Account=' + accountNumber + ', Mobile=' + mobile);

        try {
            // STEP 1: Generate access token
            String accessToken = SHF_LMSCommonUtil.generateAccessToken();
            Logger.info('Access token generated successfully');

            // Test fallback
            if (Test.isRunningTest() && accessToken == null) {
                accessToken = '6b9711a1-9f5f-42cf-9116-eded1f63649f';
                Logger.info('Test mode: fallback access token applied');
            }

            if (String.isBlank(accessToken)) {
                Logger.error('Access token generation failed. API call aborted.');
                listOfWrapper.add(wrapper);
                return listOfWrapper;
            }

            // STEP 2: Initialize callout service
            SHF_getLinkedLoanLMSService svc = new SHF_getLinkedLoanLMSService();
            svc.service = new SHF_HTTPCalloutService('Linked_Loan_Details');

            svc.service.setHeaderParameter('Content-Type', 'application/json');
            svc.service.setHeaderParameter('access_token', accessToken);

            svc.service.setRequestBody(
                svc.service.getRequestBody()
                .replace('<accountNumber>', accountNumber)
                .replace('<mobile>', mobile)
            );

            Logger.info('API Request Prepared. Endpoint=' + svc.service.endPointUrl);

            HttpResponse response;

            // STEP 3: Execute callout or mock response
            if (svc.service.getIsActive()) {
                response = svc.service.sendRequest();
                Logger.info('API callout executed successfully. Status=' + response.getStatusCode());
            } else {
                response = new HttpResponse();
                response.setBody(svc.service.getmockRespnse());
                response.setStatusCode(200);
                Logger.info('Mock response returned for inactive service configuration.');
            }

            // STEP 4: Handle Response
            if (response.getStatusCode() != 200) {
                Logger.error('API returned non-200 status: ' + response.getStatusCode());
                listOfWrapper.add(wrapper);
                return listOfWrapper;
            }

            if (String.isBlank(response.getBody())) {
                Logger.error('API response body is empty.');
                listOfWrapper.add(wrapper);
                return listOfWrapper;
            }

            Logger.info('API response received. Parsing JSON.');

            Map<String, Object> result =
                (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            if (result.containsKey('success')) {

                List<Object> successes = (List<Object>) result.get('success');

                for (Object obj : successes) {

                    Map<String, Object> successMap = (Map<String, Object>) obj;
                    
                    String customerName = (String) successMap.get('customerName');

                    if (successMap.containsKey('loanDetails')) {

                        List<Object> loanList = (List<Object>) successMap.get('loanDetails');

                        for (Object loanObj : loanList) {

                            wrapper = new LinkedLoanWrapper();
                            Map<String, Object> loanMap = (Map<String, Object>) loanObj;
                            wrapper.customerName = customerName;
                            wrapper.loanAccountNumber = (String) loanMap.get('loanAccountNumber');
                            wrapper.disbursalStatus = (String) loanMap.get('loanDisbursalStatus');
                            String status = (String) loanMap.get('loanStatus');
                            if(status == 'A'){
                                wrapper.loanStatus = 'Active';
                            }else if(status == 'C'){
                                wrapper.loanStatus = 'Closed';
                            }else if(status == 'X'){
                                wrapper.loanStatus = 'Cancelled';
                            }
                            wrapper.relationshipType = (String) loanMap.get('customerRelationship');
                            listOfWrapper.add(wrapper);
                            
                        }
                    }
                    else {
                        Logger.error('API response does not contain "success" key.');
                    }
                }

                Logger.info('Parsed Wrapper: LoanNo=' + wrapper.loanAccountNumber +
                            ', LoanStatus=' + wrapper.loanStatus);
            } else {
                Logger.error('API response does not contain "loanDetails" key.');
            }

        } catch (Exception e) {

            Logger.error('Exception: ' + e.getMessage() +
                         ' | Line: ' + e.getLineNumber());

        } finally {
            Logger.saveLog();
        }
        
        return listOfWrapper;
    }

    // Wrapper class for LWC
    public class LinkedLoanWrapper {
        @AuraEnabled public String loanAccountNumber;
        @AuraEnabled public String disbursalStatus;
        @AuraEnabled public String loanStatus;
        @AuraEnabled public String relationshipType;
        @AuraEnabled public String customerName;
    }
}