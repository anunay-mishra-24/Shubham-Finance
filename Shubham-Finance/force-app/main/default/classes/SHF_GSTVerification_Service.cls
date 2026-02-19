/**
* @File Name          : SHF_GSTVerification_Service.cls
* @Description        : Service class to verify GST details and create E-Verification records.
* @Author             : kunal soni
* 
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         28-07-2025        Kunal Soni    Initial Version
*/
public class SHF_GSTVerification_Service {
    public SHF_HTTPCalloutService service;
    
    public static String validateGSTDetails(Id applicantId) {
        Savepoint sp;
        String message = ''; //return API error/success/validation message
        Map<String,Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('GST_API');
        
        try{
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new Schema.SObjectType[] {E_Verification__c.SObjectType});
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork( new List<SObjectType> {Loan_Applicant__c.SObjectType});
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ applicantId });
            
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + applicantId);
                message = MessageConfigMap.get('GST_Loan_Applicant_Error').Message__c;
                return message;
            }
            
            Loan_Applicant__c applicant = loanAppList[0];
            if(applicant.GST_Number__c == null || applicant.GST_Number__c == ''){
                Logger.error('GST Number not found for Id: ' + applicantId);
                message = MessageConfigMap.get('GST_Number_Error').Message__c;
                return message;
            }

            SHF_GSTVerification_Service GSTVerification = new SHF_GSTVerification_Service();
            GSTVerification.service = new SHF_HTTPCalloutService('GST_Verification_Api');
            GSTVerification.service.setRequestBody(GSTVerification.service.getRequestBody().replace('<GSTIn>', applicant.GST_Number__c));
            
            HttpResponse response;
            if (GSTVerification.service.getIsActive()) {
                response = GSTVerification.service.sendRequest();
                sp = database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(GSTVerification.service.getmockRespnse());
            }
            
            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(applicantId, SHF_ConstantsUtil.GST_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS);
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> resultMap = (Map<String, Object>) rootMap.get('result');
                system.debug('resultMap---> '+ resultMap);
                if (resultMap != null && resultMap.containsKey('gstnDetailed')) {
                    Map<String, Object> gstDetailMap = (Map<String, Object>) resultMap.get('gstnDetailed');
                    if (gstDetailMap.containsKey('gstinStatus')) {
                        eVerification.Description__c = String.valueOf(gstDetailMap.get('gstinStatus'));
                        message = MessageConfigMap.get('GST_API_Success').Message__c;
                    }
                    else{
                        eVerification.Status__c =  SHF_ConstantsUtil.FAILED_STATUS;
                        message = MessageConfigMap.get('GST_API_Error').Message__c;
                    }
                    Logger.info('Request Body: ' + GSTVerification.service.getRequestBody());
                }
                else {
                    eVerification.Status__c =  SHF_ConstantsUtil.FAILED_STATUS;
                    Map<String, Object> errorBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if (errorBody.containsKey('error')) {
                        Map<String, Object> errorMap = (Map<String, Object>) errorBody.get('error');
                        if (errorMap.containsKey('message')) {
                            eVerification.Error_Message__c = String.valueOf(errorMap.get('message'));
                        }
                        message = MessageConfigMap.get('GST_API_Error').Message__c;
                    }
                    Logger.error('Request Body: ' + GSTVerification.service.getRequestBody());
                }
            }
            else{
                eVerification.Status__c =  SHF_ConstantsUtil.FAILED_STATUS;
                message = MessageConfigMap.get('GST_API_Error').Message__c;
            }
            if (eVerification != null) {
                uow.registerNew(eVerification);                        
                uow.commitWork(); 
                loanAppList[0].GST_Verification__c = eVerification.Id;                        
                applicantUow.registerDirty(loanAppList);
                applicantUow.commitWork(); 
                sp = database.setSavepoint();
                Logger.info('eVerification record: ' + eVerification);
                Logger.info('Status Code: ' + response.getStatusCode());
                Logger.info('Status: ' + response.getStatus());
                Logger.info('Body: ' + response.getBody());
                
            }
            
            
        } Catch(Exception ex){
            if (sp != null) Database.rollback(sp);
            Logger.error('GST Verification Error: ' + ex.getMessage());
            message = 'Getting error while calling GST Verification API. Please contact your system administrator.';
        } finally{
            Logger.saveLog();
        }
        return message;
    }
}