/**
 * @File Name          : SHF_LMS_DeleteReciept_Service.cls
 * @Description        : API to delete reciept and updating the response in everificatin record for now
 * @Author             : Vikas Soni
 * @Test Class         :
 *==============================================================================
 * Ver          Date            Author            Modification
 *==============================================================================
 * 1.0       08-01-2026      Vikas Soni       Initial Version
 */public with sharing class SHF_LMS_DeleteReciept_Service {
    public SHF_HTTPCalloutService service;
    
    public static String deleteReciept(String applicationId){
        String message = '';
        
        try {
            if(String.isNotBlank(applicationId)){
                Application__c application = new SHF_ApplicationSelector().selectApplicationForLoanCancellationLMS(applicationId);
                fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
                String recieptId = '';
                if(application != null){
                    recieptId = application.Login_Fee_Verification__r.Receipt_Number__c;
                }
                if(String.isNotBlank(recieptId)){
                    E_Verification__c everficationObj = new E_Verification__c(Id = application.Login_Fee_Verification__c);
                    String accessToken = SHF_LMSCommonUtil.generateAccessToken();
                    Logger.info('Access Token : '+accessToken);
                    if(String.isNotBlank(accessToken)){
                        SHF_LMS_DeleteReciept_Service deleteRecieptService = new SHF_LMS_DeleteReciept_Service();
                        deleteRecieptService.service = new SHF_HTTPCalloutService('LMS_Delete_Reciept');
                        deleteRecieptService.service.setHeaderParameter('access_token', accessToken);
                        deleteRecieptService.service.setRequestBody(deleteRecieptService.service.getRequestBody().replace('<recieptNumber>', recieptId));
                        
                        HttpResponse response;
                        if (deleteRecieptService.service.getIsActive()) {
                            response = deleteRecieptService.service.sendRequest();
                        } else {
                            response = new HttpResponse();
                            response.setStatusCode(200);
                            response.setBody(deleteRecieptService.service.getmockRespnse());
                        }
                        Logger.info('DeleteReciept Request : '+deleteRecieptService.service.getRequestBody());
                        Logger.info('DeleteReciept Endpoint : '+deleteRecieptService.service.getEndpointURL());
                        Logger.info('DeleteReciept Method : '+deleteRecieptService.service.getRequestMethod());
                        Logger.info('DeleteReciept Response Status Code : '+response.getStatusCode());
                        Logger.info('DeleteReciept Response : '+response.getBody());
                        
                        if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                            SHF_DeleteReciptParser deleteRecieptParser = new SHF_DeleteReciptParser();
                            deleteRecieptParser = SHF_DeleteReciptParser.parse(response.getBody());
                            if(deleteRecieptParser != null && deleteRecieptParser.responseCode.equals('success')){
                                Logger.info('Recipt successully delete from LMS');
                                everficationObj.Status__c = 'Deleted';
                                everficationObj.IsDeleted__c = true;
                                everficationObj.Description__c = deleteRecieptParser.payload.get(0).value;
                                
                            }
                            else{
                                everficationObj.Status__c = 'Failed';
                                everficationObj.Description__c = deleteRecieptParser.payload.get(0).value;
                                Logger.error('Getting error in Deleting Recipt : '+deleteRecieptParser.payload.get(0).value);
                            }
                            // Map<String, Object> payloadObj = new Map<String, Object>();
                            // List<Object> payload = new List<Object>();
                            // Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                            // system.debug('res - '+res);
                            // if (res != null && res.containsKey('acknowledgement')) {
                                //     String acknowledgement =  String.valueOf(res.get('acknowledgement'));
                                //     system.debug('acknowledgement - '+acknowledgement);
                            // }
                            // if (res != null && res.containsKey('responseCode')) {
                                //     String responseCode =  String.valueOf(res.get('responseCode'));
                                //     system.debug('responseCode - '+responseCode);
                            // }
                            // if (res != null && res.containsKey('responseString')) {
                                //     String responseString =  String.valueOf(res.get('responseString'));
                                //     system.debug('responseString - '+responseString);
                            // }
                            // if (res != null && res.containsKey('payload')) {
                                //     payload = (List<Object>) res.get('payload');
                                //     // stringPayload = String.valueOf(payload);
                                //     system.debug('payload - '+payload.get(0));
                            // }
                            // if(!payload.isEmpty()){
                                //     System.debug('inside payload not empty');
                                //     payloadObj = (Map<String, Object>) payload.get(0);
                                //     system.debug('payloadObj - '+payloadObj);
                                
                                //     if (payloadObj != null && payloadObj.containsKey('i18nCode')) {
                                    //         String i18nCode =  String.valueOf(payloadObj.get('i18nCode'));
                                    //         system.debug('i18nCode - '+i18nCode);
                                //     }
                                //     if (res != null && payloadObj.containsKey('type')) {
                                    //         String type =  String.valueOf(payloadObj.get('type'));
                                    //         system.debug('type - '+type);
                                //     }if (res != null && payloadObj.containsKey('isParent')) {
                                    //         String isParent =  String.valueOf(payloadObj.get('isParent'));
                                    //         system.debug('isParent - '+isParent);
                                //     }if (res != null && payloadObj.containsKey('value')) {
                                    //         String value =  String.valueOf(payloadObj.get('value'));
                                    //         system.debug('value - '+value);
                                //     }
                                //     system.debug('payloadObj.containsKey ' + payloadObj.get('messageArguments'));
                                //     // if(res != null && payloadObj.containsKey('messageArguments')){
                                    //         //     Object messageArguments =  payloadObj.get('messageArguments');
                                    //         //     system.debug('messageArguments - '+messageArguments);
                                //     // }
                            // }
                            
                            message = 'Success';
                        }
                        else{
                            Logger.error('Getting this error : ' );
                        }
                        e_verificationUOW.registerDirty(everficationObj);
                        e_verificationUOW.commitWork();
                    }
                    else{
                        Logger.error('Access token is blank');
                        return 'Access token is blank';
                    }
                }
                else {
                    message = 'Reciept Id is blank';
                    Logger.error('Reciept Id is blank');
                }
            }else{
                message = 'Applicant Id Not present';
                Logger.error('Applicant Id Not present');
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