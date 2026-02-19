/**
 * @File Name          : SHF_NameMatch_Service.cls
 * @Description        : Service class to compare and match names from Aadhaar and PAN.
 * @Author             : Riteek Tiwari
 *
 *==============================================================================
 * Ver         Date              Author           Modification
 *==============================================================================
 * 1.0         23-07-2025        Riteek Tiwari    Initial Version
 */
public with sharing class SHF_NameMatch_Service {
    SHF_HTTPCalloutService service;
    
    public static void validateNameMatch(Id everificationId,Id applicantId, String nameCompareFirst, String nameCompareSecond) {
        Savepoint sp;
        try {
            fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ applicantId });
            if (String.isBlank(nameCompareFirst) || String.isBlank(nameCompareSecond)) {
                Logger.error('Missing nameCompareFirst or nameCompareSecond.');
                // return 'Names are Missing, please check and try again.';
            }
            
            // if (loanAppList.isEmpty()) {
                //     Logger.error('Loan Applicant not found for Id: ' + applicantId);
                //     return 'Loan Applicant Not Found, please check and try again.';
            // }
            // Loan_Applicant__c applicant = loanAppList[0];
            
            SHF_NameMatch_Service nameMatcherAPI = new SHF_NameMatch_Service();
            nameMatcherAPI.service = new SHF_HTTPCalloutService('Name_Match_API');
            
            String requestBody = nameMatcherAPI.service.getRequestBody();
            
            requestBody = requestBody.replace('<Param1>', nameCompareFirst);
            requestBody = requestBody.replace('<Param2>', nameCompareSecond);
            nameMatcherAPI.service.setRequestBody(requestBody);
            
            HttpResponse response;
            if (nameMatcherAPI.service.getIsActive()) {
                response = nameMatcherAPI.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(nameMatcherAPI.service.getmockRespnse());
            }
            
            String responseBody = response.getBody();
            System.debug('Name Match Response: ' + responseBody);
            
            // E_Verification__c verificationObj = SHF_CommonUtil.createVerfication(applicantId, SHF_ConstantsUtil.PAN_VERIFICATION_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS);
            E_Verification__c verificationObj = new E_Verification__c();
            // if(String.isNotBlank(everificationId)){
            //     verificationObj.Id = everificationId;
            // }
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                
                if (responseMap != null && responseMap.containsKey('result')) {
                    Map<String, Object> resultMap = (Map<String, Object>) responseMap.get('result');
                    
                    if (resultMap.containsKey('name1_vs_name2_matchResult')) {
                        verificationObj.Name_Match_Result__c = String.valueOf(resultMap.get('name1_vs_name2_matchResult'));
                    }
                    
                    if (resultMap.containsKey('name1_vs_name2_matchScore')) {
                        verificationObj.Name_Match_Score__c = String.valueOf(resultMap.get('name1_vs_name2_matchScore'));
                    }
                    if (resultMap.containsKey('name1_vs_name2_matchReason')) {
                        verificationObj.Name_Match_Reason__c = String.valueOf(resultMap.get('name1_vs_name2_matchReason'));
                    }
                }
            } else {
                // verificationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                verificationObj.Failed_Reason__c = 'Name match API returned non-200 status.';
            }
            
            if (String.isNotBlank(everificationId)) {
                verificationObj.Id = everificationId;
            }
            system.debug('everificationrecord - '+verificationObj);
            if (String.isNotBlank(everificationId)) {
                // record exists → update it
                e_verificationUOW.registerDirty(verificationObj);
            } else {
                // new record → insert it
                e_verificationUOW.registerNew(verificationObj);
            }
            
            e_verificationUOW.commitWork();
            
            Logger.info('API Request - Body: ' + nameMatcherAPI.service.getRequestBody());
            Logger.info('Status Code: ' + response.getStatusCode());
            Logger.info('Status: ' + response.getStatus());
            Logger.info('Response Body: ' + response.getBody());
            
        } catch (Exception ex) {
            if (sp != null) {
                Database.rollback(sp);
            }
            Logger.error('NameMatch Exception: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }
        // return null;
    }
}