/**
* @File Name          : SHF_RepaymentScheduleLMSService.cls
* @Description        : Get repayment schedule.
* @Author             : Kunal Soni
* 
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         24-07-2025   Kunal Soni   Initial Version
*/
public class SHF_RepaymentScheduleLMSService {
    
    SHF_HTTPCalloutService service;
    @AuraEnabled(cacheable=false)
    public static List<SHF_RepaymentWrapper> getLoanDetails(String loanApplicationName) {
        List<SHF_RepaymentWrapper> listOfRepaymentWrapper = new List<SHF_RepaymentWrapper>();
        
        try {
            String accessToken = SHF_LMSCommonUtil.generateAccessToken();
            
            if(Test.isRunningTest() && accessToken == null){
                accessToken = '6b9711a1-9f5f-42cf-9116-eded1f63649f';
            }
            
            if (String.isNotBlank(accessToken)) {
                SHF_RepaymentScheduleLMSService rcs = new SHF_RepaymentScheduleLMSService();
                rcs.service = new SHF_HTTPCalloutService('Repayment_Schedule');
                rcs.service.setHeaderParameter('Content-Type', 'application/json');
                rcs.service.setHeaderParameter('access_token', accessToken);
                
                String requestBody = rcs.service.getRequestBody().replace('<LoanAccountNumber>', loanApplicationName);
                rcs.service.setRequestBody(requestBody);
                
                HttpResponse response;
                if (rcs.service.getIsActive()) {
                    response = rcs.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setBody(rcs.service.getmockRespnse());
                    response.setStatusCode(200);
                }
                
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    
                    if (parsed.containsKey('payload')) {
                        List<Object> payLoads = (List<Object>) parsed.get('payload');
                        System.debug('payLoads ---> ' + payLoads);
                        
                        for (Object obj : payLoads) {
                            Map<String, Object> payLoadMap = (Map<String, Object>) obj;
                            
                            if (payLoadMap.containsKey('repaymentSchedule')) {
                                List<Object> listOfRepaymentSch = (List<Object>) payLoadMap.get('repaymentSchedule');
                                System.debug('listOfRepaymentSch ---> ' + listOfRepaymentSch);
                                
                                for (Object rePayment : listOfRepaymentSch) {
                                    Map<String, Object> replaymentMap = (Map<String, Object>) rePayment;
                                    SHF_RepaymentWrapper repaymentWrapper = new SHF_RepaymentWrapper();
                                    
                                    repaymentWrapper.installmentNumber = (Decimal) replaymentMap.get('installmentNumber');
                                    repaymentWrapper.openingBalance = (Decimal) replaymentMap.get('openingPrincipalBalance');
                                    repaymentWrapper.Installment = (Decimal) replaymentMap.get('installmentAmount');
                                    repaymentWrapper.Principal = (Decimal) replaymentMap.get('principalComponent');
                                    repaymentWrapper.Interest = (Decimal) replaymentMap.get('interestComponent');
                                    repaymentWrapper.effectiveRate = (Decimal) replaymentMap.get('effectiveInterestRate');
                                    repaymentWrapper.days = (Decimal) replaymentMap.get('numberOfDaysBetweenInstallments');
                                    repaymentWrapper.dueDate = SHF_LMSCommonUtil.parseDateFormate(String.valueOf(replaymentMap.get('dueDate')));
                                    
                                    listOfRepaymentWrapper.add(repaymentWrapper);
                                    system.debug('listOfRepaymentWrapper--> '+listOfRepaymentWrapper);
                                }
                            }
                        }
                    }
                }
                String reqBodyLog = rcs.service.getRequestBody();
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
            Logger.error('Error: ' + e.getMessage() + ' '+ e.getLineNumber());
        } finally {
            Logger.saveLog();
        }
        
        // System.debug('repaymentWrapper --> ' + listOfRepaymentWrapper);
        return listOfRepaymentWrapper;
    }
    
    public class SHF_RepaymentWrapper {
        @AuraEnabled public Decimal installmentNumber;
        @AuraEnabled public Date dueDate;
        @AuraEnabled public Decimal openingBalance;
        @AuraEnabled public Decimal installment;
        @AuraEnabled public Decimal principal;
        @AuraEnabled public Decimal interest;
        @AuraEnabled public Decimal effectiveRate;
        @AuraEnabled public Decimal days;
    }
}