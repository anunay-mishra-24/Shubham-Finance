/**
* @File Name          : SHF_GetLoanDetailsLMSService.cls
* @Description        : Get Loan Details For Loan Applicant.
* @Author             : Kunal Soni
* 
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         18-07-2025   Kunal Soni   Initial Version
*/

public class SHF_GetLoanDetailsLMSService {
    SHF_HTTPCalloutService service;
    
    @AuraEnabled(cacheable=false)
    public static SHF_ServiceConsoleLMSControllerWrapper getLoanDetails(String accountNumber) {
        SHF_ServiceConsoleLMSControllerWrapper wrapper = new SHF_ServiceConsoleLMSControllerWrapper();
        try {
            String accessToken = SHF_LMSCommonUtil.generateAccessToken();
            if(Test.isRunningTest() && accessToken == null){
                accessToken = '6b9711a1-9f5f-42cf-9116-eded1f63649f';
            }
            system.debug('accessToken--> '+accessToken);
            if (String.isNotBlank(accessToken)) {
                SHF_GetLoanDetailsLMSService svc = new SHF_GetLoanDetailsLMSService();
                svc.service = new SHF_HTTPCalloutService('Get_Loan_Details');
                svc.service.setHeaderParameter('Content-Type', 'application/json');
                svc.service.setHeaderParameter('access_token', accessToken);
                svc.service.setRequestBody(svc.service.getRequestBody().replace('<LoanAccountNumber>', accountNumber));
                
                HttpResponse response;
                if (svc.service.getIsActive()) {
                    response = svc.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setBody(svc.service.getmockRespnse());
                    response.setStatusCode(200);
                }
                
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if (result.containsKey('success')) {
                        Map<String, Object> success = (Map<String, Object>) result.get('success');
                        wrapper.financedAmount              = (Decimal) success.get('financedAmount');
                        wrapper.futurePrincipal             = (Decimal) success.get('futurePrincipal');
                        wrapper.principalOutstanding        = (Decimal) success.get('principalOutstanding');
                        wrapper.totalOverdue                = (Decimal) success.get('amountOverdue');
                        wrapper.loanStatus                  = String.valueOf(success.get('status'));
                        wrapper.applicationNumber           = String.valueOf(success.get('applicationFileNumber'));
                        wrapper.contractType                = String.valueOf(success.get('contractType'));
                        wrapper.businessSegment             = String.valueOf(success.get('businessSegment'));
                        wrapper.loanBranchCode              = String.valueOf(success.get('loanBranchCode'));
                        wrapper.loanBranchName              = String.valueOf(success.get('loanBranchName'));
                        wrapper.maturityDate                = SHF_LMSCommonUtil.parseDateFormate(String.valueOf(success.get('maturityDate')));
                        wrapper.nextInstallmentDate         = SHF_LMSCommonUtil.parseDateFormate(String.valueOf(success.get('nextDueDate')));
                        wrapper.agreementDate               = SHF_LMSCommonUtil.parseDateFormate(String.valueOf(success.get('agreementDate')));
                        wrapper.sanctionedAmount            = (Decimal) success.get('finalSanctionedAmount');
                        wrapper.disbursedAmount             = (Decimal) success.get('disbursedAmount');
                        wrapper.disbursalStatus             = String.valueOf(success.get('disbursalStatus'));
                        wrapper.originalTenure              = String.valueOf(success.get('tenure'));
                        wrapper.balanceTenure               = String.valueOf(success.get('balanceTenure'));
                        wrapper.ltvRatio                    = String.valueOf(success.get('ltv'));
                        wrapper.anchorType                  = String.valueOf(success.get('anchorCode'));
                        wrapper.anchorRate                  = String.valueOf(success.get('anchorRate'));
                        wrapper.anchorMarkUp                = String.valueOf(success.get('netMarkup'));
                        wrapper.numberOfInstallments        = String.valueOf(success.get('numberOfInstallmentUnpaid'));
                        
                        if (success.containsKey('loanRepaymentDetailMO')) {
                            Map<String, Object> repay = (Map<String, Object>) success.get('loanRepaymentDetailMO');
                            wrapper.rateType             = String.valueOf(repay.get('interestChargeMode'));
                            wrapper.effectiveInterestRate= String.valueOf(repay.get('effectiveRateOfInterest'));
                            wrapper.dueDay               = String.valueOf(repay.get('repaymentDueDay'));
                            wrapper.repaymentFrequency   = String.valueOf(repay.get('repaymentFrequency'));
                        }
                        
                        if (success.containsKey('customerDetailMO')) {
                            Map<String, Object> cust = (Map<String, Object>) success.get('customerDetailMO');
                            wrapper.customerName = String.valueOf(cust.get('fullName'));
                        }
                        
                        System.debug('wrapperList Loan Detail-->'+wrapper);
                    }
                }
                String reqBodyLog = svc.service.getRequestBody();
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
        system.debug('wrapper--'+wrapper);
        return wrapper;
    }
}