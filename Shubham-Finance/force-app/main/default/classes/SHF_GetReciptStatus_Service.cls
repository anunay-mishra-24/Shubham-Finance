/**
 * @File Name          : SHF_GetReciptStatus_Service.cls
 * @Description        : API to Get reciept Status and updating the response in everificatin record for now 
 * @Author             : Vikas Soni
 * @Test Class         :
 *==============================================================================
 * Ver          Date            Author            Modification
 *==============================================================================
 * 1.0       107-01-2026      Vikas Soni       Initial Version
 */
public with sharing class SHF_GetReciptStatus_Service {
    public SHF_HTTPCalloutService service;

    @AuraEnabled
    public static List<String> getReciptIds(String applicationId){
        List<String> feeIds = new List<String>();
        
        try {
            if(String.isNotBlank(applicationId)){
                List<Fees__c> feeList = new SHF_FeeSelector().selectByapplicationID(applicationId);
                if(feeList != null){
                    for(Fees__c fee : feeList){
                        feeIds.add(String.valueOf(fee.Id));
                    }
                }
            }
        }
        catch (Exception e) {
            Logger.error('Getting Error : ' + e.getMessage() + 'at line - ' +e.getLineNumber() );
        }
        finally {
            Logger.info('fee ids - ' + feeIds);
            Logger.saveLog();
        }
        system.debug('fee ids - '+feeIds);
        return feeIds;

    }
    @AuraEnabled
    public static String getReciptStatus(String feeId) {
        // Map<String, Messages_Config__mdt> messageConfigMapSuccess = SHF_CommonUtil.getMessageRecord('LMS_GetReciptStatus');
        String message = '';
        try {
            if(String.isNotBlank(feeId)){
                // Application__c application = new SHF_ApplicationSelector().selectApplicationForLoanCancellationLMS(applicationId);
                fflib_SObjectUnitOfWork feeUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {Fees__c.SObjectType});
                Fees__c feeObj = new SHF_FeeSelector().selectByIds(new Set<String>{feeId});
                String reciptId = '';
                if(feeObj != null){
                    reciptId = feeObj.Receipt_Id__c;
                }
                
                if(String.isBlank(reciptId)){
                    Logger.error('Getting ReciptId blank');
                    return null;
                }
                // E_Verification__c everficationObj = new E_Verification__c(Id = application.Login_Fee_Verification__c);
                
                String accessToken = SHF_LMSCommonUtil.generateAccessToken();
                Logger.info('Access Token : '+accessToken);
                if(String.isNotBlank(accessToken)){
                    SHF_GetReciptStatus_Service getReciptService = new SHF_GetReciptStatus_Service();
                    getReciptService.service = new SHF_HTTPCalloutService('LMS_Get_Receipt_Status');
                    getReciptService.service.setHeaderParameter('access_token', accessToken);
                    
                    String requestJson = getReciptService.service.getRequestBody().replace('<recieptNumber>', reciptId);
                    getReciptService.service.setRequestBody(requestJson);
                    
                    HttpResponse response;
                    if (getReciptService.service.getIsActive()) {
                        response = getReciptService.service.sendRequest();
                    } else {
                        response = new HttpResponse();
                        response.setStatusCode(200);
                        response.setBody(getReciptService.service.getmockRespnse());
                    }
                    Logger.info('GetReciptStatus Request : '+getReciptService.service.getRequestBody());
                    Logger.info('GetReciptStatus Endpoint : '+getReciptService.service.getEndpointURL());
                    Logger.info('GetReciptStatus Method : '+getReciptService.service.getRequestMethod());
                    Logger.info('GetReciptStatus Response Status Code : '+response.getStatusCode());
                    Logger.info('GetReciptStatus Response : '+response.getBody());
                    
                    if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                        SHF_ReciptStatusParser reciptStatusParser = new SHF_ReciptStatusParser();
                        reciptStatusParser = SHF_ReciptStatusParser.parse(response.getBody());
                        System.debug('reciptStatusParser: ' + reciptStatusParser);
                        if(reciptStatusParser.success != null){
                            Logger.info('Recipt Id : '+reciptStatusParser.success.get(0).id);
                            Logger.info('Recipt Number : '+reciptStatusParser.success.get(0).receiptNo);
                            Logger.info('Recipt Status Description : '+reciptStatusParser.success.get(0).statusDescription);
                            Logger.info('Receipt Or Payout Amount : '+reciptStatusParser.success.get(0).receiptOrPayoutAmount);
                            // everficationObj.Description__c = reciptStatusParser.success.get(0).statusDescription;
                            // everficationObj.Amount_Payable__c = String.valueOf(reciptStatusParser.success.get(0).receiptOrPayoutAmount);
                            String recStatus = '';
                            if(reciptStatusParser.success.get(0).status.equals('X')){
                                feeObj.Status__c = 'Cancelled';
                                message = 'Cancelled';
                            }
                            else if(reciptStatusParser.success.get(0).status.equals('D')){
                                feeObj.Status__c = 'Collected';
                                message = 'Collected';
                            }
                            else{
                                feeObj.Status__c = 'Pending';
                                message = 'Pending';
                            }
                        
                            // everficationObj.Status__c = 'Success';
                            // message = reciptStatusParser.success.get(0).status;

                        }
                        else{
                            Logger.error('Error in response : '+reciptStatusParser.error.get(0).value);
                            // everficationObj.Description__c = reciptStatusParser.error.get(0).value;
                            // everficationObj.Status__c = 'Error';
                        }
                        feeUOW.registerDirty(feeObj);
                        feeUOW.commitWork();
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
            else{
                Logger.error('Fee Id is blank');
                return 'Fee Id is blank';
            }
        } catch (Exception e) {
            Logger.error('Getting Error : ' + e.getMessage() + 'at line - ' +e.getLineNumber() );
        }
        finally {
            Logger.saveLog();
        }
        system.debug('message : '+message);
        return message;
    }
     // using as backup
    // public static String getReciptStatus(String applicationId) {
    //     // Map<String, Messages_Config__mdt> messageConfigMapSuccess = SHF_CommonUtil.getMessageRecord('LMS_GetReciptStatus');
    //     String message = '';
    //     try {
    //         if(String.isNotBlank(applicationId)){
    //             Application__c application = new SHF_ApplicationSelector().selectApplicationForLoanCancellationLMS(applicationId);
    //             fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
    //             String reciptId = '';
    //             if(application != null){
    //                 reciptId = application.Login_Fee_Verification__r.Receipt_Number__c;
    //             }
    //             if(String.isBlank(reciptId)){
    //                 Logger.error('Getting ReciptId blank');
    //                 return null;
    //             }
    //             E_Verification__c everficationObj = new E_Verification__c(Id = application.Login_Fee_Verification__c);
    //             String accessToken = SHF_LMSCommonUtil.generateAccessToken();
    //             Logger.info('Access Token : '+accessToken);
    //             if(String.isNotBlank(accessToken)){
    //                 SHF_GetReciptStatus_Service getReciptService = new SHF_GetReciptStatus_Service();
    //                 getReciptService.service = new SHF_HTTPCalloutService('LMS_Get_Receipt_Status');
    //                 getReciptService.service.setHeaderParameter('access_token', accessToken);
                    
    //                 String requestJson = getReciptService.service.getRequestBody().replace('<recieptNumber>', reciptId);
    //                 getReciptService.service.setRequestBody(requestJson);
                    
    //                 HttpResponse response;
    //                 if (getReciptService.service.getIsActive()) {
    //                     response = getReciptService.service.sendRequest();
    //                 } else {
    //                     response = new HttpResponse();
    //                     response.setStatusCode(200);
    //                     response.setBody(getReciptService.service.getmockRespnse());
    //                 }
    //                 Logger.info('GetReciptStatus Request : '+getReciptService.service.getRequestBody());
    //                 Logger.info('GetReciptStatus Endpoint : '+getReciptService.service.getEndpointURL());
    //                 Logger.info('GetReciptStatus Method : '+getReciptService.service.getRequestMethod());
    //                 Logger.info('GetReciptStatus Response Status Code : '+response.getStatusCode());
    //                 Logger.info('GetReciptStatus Response : '+response.getBody());
                    
    //                 if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
    //                     SHF_ReciptStatusParser reciptStatusParser = new SHF_ReciptStatusParser();
    //                     reciptStatusParser = SHF_ReciptStatusParser.parse(response.getBody());
    //                     System.debug('reciptStatusParser: ' + reciptStatusParser);
    //                     if(reciptStatusParser.success != null){
    //                         Logger.info('Recipt Id : '+reciptStatusParser.success.get(0).id);
    //                         Logger.info('Recipt Number : '+reciptStatusParser.success.get(0).receiptNo);
    //                         Logger.info('Recipt Status Description : '+reciptStatusParser.success.get(0).statusDescription);
    //                         Logger.info('Receipt Or Payout Amount : '+reciptStatusParser.success.get(0).receiptOrPayoutAmount);
    //                         everficationObj.Description__c = reciptStatusParser.success.get(0).statusDescription;
    //                         everficationObj.Amount_Payable__c = String.valueOf(reciptStatusParser.success.get(0).receiptOrPayoutAmount);

    //                         everficationObj.Status__c = 'Success';
    //                         message = reciptStatusParser.success.get(0).status;

    //                     }
    //                     else{
    //                         Logger.error('Error in response : '+reciptStatusParser.error.get(0).value);
    //                         everficationObj.Description__c = reciptStatusParser.error.get(0).value;
    //                         everficationObj.Status__c = 'Error';
    //                     }
    //                     e_verificationUOW.registerDirty(everficationObj);
    //                     e_verificationUOW.commitWork();
    //                 }
    //                 else{
    //                     Logger.error('Getting this error : ' );
    //                 }
                    
    //             }
    //             else{
    //                 Logger.error('Access token is blank');
    //                 return 'Access token is blank';
    //             }
    //         }
    //         else{
    //             Logger.error('Application Id is blank');
    //             return 'Application Id is blank';
    //         }
    //     } catch (Exception e) {
    //         Logger.error('Getting Error : ' + e.getMessage() + 'at line - ' +e.getLineNumber() );
    //     }
    //     finally {
    //         Logger.saveLog();
    //     }
    //     system.debug('message : '+message);
    //     return message;
    // }
}