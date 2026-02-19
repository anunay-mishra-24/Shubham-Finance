/**
* @File Name     : SHF_PennyDrop_Service.cls
* @Description   : Service class to verify Penny Drop details and create E-Verification records.
* @Author        : Kunal Soni
* ==============================================================================
* Ver   Date          Author        Modification
* ==============================================================================
* 1.0   30-07-2025    Kunal Soni    Initial Version
*/
public class SHF_PennyDrop_Service {
    
    public SHF_HTTPCalloutService service;
    
    public static String validatePennyDetails(Id applicantId) {
        Savepoint sp;
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('PENNY_API');
        
        try {
            String reason = '';
            String rspns = '';
            sp = Database.setSavepoint();
            
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new Schema.SObjectType[] { E_Verification__c.SObjectType });
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType> { Loan_Applicant__c.SObjectType });
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ applicantId });
            
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + applicantId);
                return null;
            }
            
            SHF_PennyDrop_Service pennyVerification = new SHF_PennyDrop_Service();
            pennyVerification.service = new SHF_HTTPCalloutService('Penny_Drop');
            HttpResponse response;
            
            if (pennyVerification.service.getIsActive()) {
                response = pennyVerification.service.sendRequest();
            } else {
                response = new HttpResponse();
                response.setBody(pennyVerification.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(
                loanAppList[0].Id,
                SHF_ConstantsUtil.PENNY_DROP_RECORD_TYPE,
                SHF_ConstantsUtil.COMPLETEDSTATUS
            );
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (rootMap != null && rootMap.containsKey('result')) {
                    Map<String, Object> resultMap = (Map<String, Object>) rootMap.get('result');
                    
                    if (resultMap != null) {
                        if (resultMap.containsKey('reason')) {
                            reason = String.valueOf(resultMap.get('reason'));
                        }
                        else {
                            eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                            message = messageConfigMap.get('GST_API_Error').Message__c;
                        }
                        
                        if (resultMap.containsKey('nameMatchScore')) {
                            eVerification.Name_Match_Score__c = String.valueOf(resultMap.get('nameMatchScore'));
                        }
                        else {
                            eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                            message = messageConfigMap.get('GST_API_Error').Message__c;
                        }
                        
                        if (resultMap.containsKey('auditTrail')) {
                            Map<String, Object> auditTrailMap = (Map<String, Object>) resultMap.get('auditTrail');
                            if (auditTrailMap != null && auditTrailMap.containsKey('timestamp')) {
                                String dateToParse = String.valueOf(auditTrailMap.get('timestamp')).left(10);
                                eVerification.Penny_Date__c = dateToParse;
                            }
                            else {
                                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                                message = messageConfigMap.get('GST_API_Error').Message__c;
                            }
                        }
                        else {
                            eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                            message = messageConfigMap.get('GST_API_Error').Message__c;
                        }
                        
                        if (resultMap.containsKey('bankTransfer')) {
                            Map<String, Object> bankTrnfrMap = (Map<String, Object>) resultMap.get('bankTransfer');
                            if (bankTrnfrMap != null && bankTrnfrMap.containsKey('response')) {
                                rspns = String.valueOf(bankTrnfrMap.get('response'));
                            }
                            else {
                                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                                message = messageConfigMap.get('GST_API_Error').Message__c;
                            }
                        }
                        else {
                            eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                            message = messageConfigMap.get('GST_API_Error').Message__c;
                        }
                        
                        eVerification.Description__c = reason + ' ' + rspns;
                        Logger.info('Request Body: ' + pennyVerification.service.getRequestBody());
                    } else {
                        eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                        message = messageConfigMap.get('Penny_API_Error').Message__c;
                        
                        Map<String, Object> errorBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        if (errorBody.containsKey('error')) {
                            Map<String, Object> errorMap = (Map<String, Object>) errorBody.get('error');
                            if (errorMap.containsKey('message')) {
                                eVerification.Error_Message__c = String.valueOf(errorMap.get('message'));
                            }
                        }
                        Logger.error('Request Body: ' + pennyVerification.service.getRequestBody());
                    }
                    
                    message = messageConfigMap.get('Penny_API_Success').Message__c;
                } else {
                    eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    message = messageConfigMap.get('GST_API_Error').Message__c;
                }
            }
            
            if (eVerification != null) {
                uow.registerNew(eVerification);
                uow.commitWork();
                
                loanAppList[0].Penny_Drop_Verification__c = eVerification.Id;
                applicantUow.registerDirty(loanAppList);
                applicantUow.commitWork();
                
                Logger.info('eVerification record: ' + eVerification);
                Logger.info('Status Code: ' + response.getStatusCode());
                Logger.info('Status: ' + response.getStatus());
                Logger.info('Body: ' + response.getBody());
            }
            
        } catch (Exception ex) {
            Database.rollBack(sp);
            Logger.error('Penny Drop Verification Error: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }
        
        return message;
    }
}