/**
 * @File Name          : SHF_LMS_LoanCancellation_Service.cls
 * @Description        : API to Cancel Loan
 * @Author             : Vikas Soni
 * @Test Class         :
 *==============================================================================
 * Ver          Date            Author            Modification
 *==============================================================================
 * 1.0       08-01-2026      Vikas Soni       Initial Version
 */
public with sharing class SHF_LMS_LoanCancellation_Service {
    public SHF_HTTPCalloutService service;
    public static String getCancelLoan(String applicationId) {
        String message = '';
        try {
            if(String.isNotBlank(applicationId)){
                Application__c application = new SHF_ApplicationSelector().selectApplicationForLoanCancellationLMS(applicationId);
                if(application != null){

                    String accessToken = SHF_LMSCommonUtil.generateAccessToken();
                    Logger.info('Access Token : '+accessToken);
                    if(String.isNotBlank(accessToken)){
                        SHF_LMS_LoanCancellation_Service loanCancellationService = new SHF_LMS_LoanCancellation_Service();
                        loanCancellationService.service = new SHF_HTTPCalloutService('LMS_Cancellation_Loan');
                        loanCancellationService.service.setHeaderParameter('access_token', accessToken);
                        loanCancellationService.service.setRequestBody(loanCancellationService.service.getRequestBody().replace('<remarks>', String.isNotBlank(application.Cancel_Remarks__c) ? application.Cancel_Remarks__c : ''));
                        
                        HttpResponse response;
                        if (loanCancellationService.service.getIsActive()) {
                            response = loanCancellationService.service.sendRequest();
                        } else {
                            response = new HttpResponse();
                            response.setStatusCode(200);
                            response.setBody(loanCancellationService.service.getmockRespnse());
                        }
                        Logger.info('LoanCancellation Request : '+loanCancellationService.service.getRequestBody());
                        Logger.info('LoanCancellation Response : '+response.getBody());
                        Logger.info('LoanCancellation Endpoint : '+loanCancellationService.service.getEndpointURL());
                        Logger.info('LoanCancellation Method : '+loanCancellationService.service.getRequestMethod());
                        
                        if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                            message = 'Success';
                        }
                        else{
                            Logger.error('Getting this error : ' );
                        }
                    }
                    else{
                        Logger.error('Access token is blank');
                        return 'Access token is blank';
                    }
                }
            }
            else{
                Logger.error('Application id is blank');
                return 'Application id is blank';
            }
        } catch (Exception e) {
            Logger.error('Getting Error : ' + e.getMessage() + 'at line - ' +e.getLineNumber() );
        }
        finally {
            Logger.saveLog();
        }
        
        system.debug('message - '+message);
        return message;
    }
}