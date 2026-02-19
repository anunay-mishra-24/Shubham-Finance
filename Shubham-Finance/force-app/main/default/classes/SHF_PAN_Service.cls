/**
 * @File Name          : PANVerify.cls
 * @Description        : API to check PAN Details for customer.
 * @Author             : Riteek
 * @Test CLass         :
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0         19-06-2025               Riteek                 Initial Version
 */
public with sharing class SHF_PAN_Service {
    SHF_HTTPCalloutService service;
    
    @AuraEnabled
    public static string validatePANNumber (Id customerId){
        String message = '';
        Map<String,Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('PAN_API');
        Savepoint sp;
        Boolean isPanVerified = false;
        try{
            // Unit of Work
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType> {Loan_Applicant__c.SObjectType});
            fflib_SObjectUnitOfWork e_verificationUOW =new fflib_SObjectUnitOfWork( new Schema.SObjectType[] {E_Verification__c.SObjectType});
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
            List<E_Verification__c> insertRecords = new List<E_Verification__c>();
            
            if (String.isBlank(loanAppList[0].Pan_Number__c)) {
                logger.info('pan number is blank.');
                message = messageConfigMap.get('PAN_Not_Found').Message__c;
                return message;
            }
            
            if(String.isNotBlank(loanAppList[0].Pan_Number__c)){
                SHF_PAN_Service panStatusCheck = new SHF_PAN_Service();
                panStatusCheck.service = new SHF_HTTPCalloutService('PAN_API');
                
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('panNumber',String.isNotBlank(loanAppList[0].Pan_Number__c) ? loanAppList[0].Pan_Number__c : '');
                gen.writeEndObject();
                panStatusCheck.service.setRequestBody(gen.getAsString());
                
                HttpResponse response;
                String responseBody = '';
                
                if (panStatusCheck.service.getIsActive()) {
                    response = panStatusCheck.service.sendRequest();
                    sp = Database.setSavepoint();
                } else {
                    response = new HttpResponse();
                    response.setStatusCode(200);
                    response.setBody(panStatusCheck.service.getmockRespnse());
                }
                
                E_Verification__c everficationObj = SHF_CommonUtil.createVerfication(
                    loanAppList[0].Id,
                SHF_ConstantsUtil.PAN_VERIFICATION_RECORD_TYPE,
                SHF_ConstantsUtil.COMPLETEDSTATUS
                    );
                
                if(response.getStatusCode() == 200){
                    Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                    
                    if (mapResponseResult.containsKey('message')) {
                        everficationObj.Message__c = (String) String.valueOf(mapResponseResult.get('message'));
                        message = (String) mapResponseResult.get('message');
                        if (message == 'PAN Number FOUND') {
                            loanAppList[0].Is_Pan_Verified__c = true;
                        }
                    }
                    Integer codeVal;
                    if (mapResponseResult.containsKey('statusCode')) {
                        everficationObj.Warning_Code__c = String.valueOf(mapResponseResult.get('statusCode'));
                        codeVal = Integer.valueOf(String.valueOf(mapResponseResult.get('statusCode')));
                    }
                    
                    if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('result')){
                        Map<String,Object> mapResponseBody = (Map<String,Object>) (mapResponseResult.get('result'));
                        if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && codeVal == 200){
                            isPanVerified = true;
                            if(mapResponseBody.containsKey('name')){
                                everficationObj.PAN_Full_Name__c = (String) String.valueOf(mapResponseBody.get('name'));
                            }
                            if(mapResponseBody.containsKey('firstName')){
                                everficationObj.PAN_First_Name__c = (String) String.valueOf(mapResponseBody.get('firstName'));
                            }
                            if(mapResponseBody.containsKey('middleName')){
                                everficationObj.PAN_Middle_Name__c = (String) String.valueOf(mapResponseBody.get('middleName'));
                            }
                            if(mapResponseBody.containsKey('lastName')){
                                everficationObj.PAN_Last_Name__c = (String) String.valueOf(mapResponseBody.get('lastName'));
                            }
                            if(mapResponseBody.containsKey('fatherName')){
                                everficationObj.PAN_Father_Name__c = (String) String.valueOf(mapResponseBody.get('fatherName'));
                            }
                            if (mapResponseBody.containsKey('dateOfBirth')) {
                                String dobStr = String.valueOf(mapResponseBody.get('dateOfBirth'));
                                if (String.isNotBlank(dobStr)) {
                                    List<String> parts = dobStr.split('-');
                                    if (parts.size() == 3) {
                                        Integer day = Integer.valueOf(parts[0]);
                                        Integer month = Integer.valueOf(parts[1]);
                                        Integer year = Integer.valueOf(parts[2]);
                                        Date dob = Date.newInstance(year, month, day);
                                        everficationObj.Date_of_Birth__c = dob;
                                        if(loanAppList[0].Customer_Type__c == 'Individual'){
                                            loanAppList[0].Date_of_Birth__c = dob;
                                        }
                                        else if(loanAppList[0].Customer_Type__c == 'Non-Individual'){
                                            loanAppList[0].Date_Of_Incorporation1__c = dob;
                                        }
                                    } else {
                                        logger.info('Unexpected date format: ' + dobStr);
                                        System.debug('Unexpected date format: ' + dobStr);
                                    }
                                }
                            }
                            if(mapResponseBody.containsKey('typeOfHolder')){
                                everficationObj.Type_Of_Holder__c = (String) String.valueOf(mapResponseBody.get('typeOfHolder'));
                            }
                            if(mapResponseBody.containsKey('gender')){
                                everficationObj.Gender__c = (String) String.valueOf(mapResponseBody.get('gender'));
                            }
                            if (mapResponseBody.containsKey('isIndividual')) {
                                String isIndStr = String.valueOf(mapResponseBody.get('isIndividual'));
                                if (String.isNotBlank(isIndStr)) {
                                    everficationObj.Is_Individual__c = isIndStr.toLowerCase() == 'true';
                                }
                            }
                            if(mapResponseBody.containsKey('category')){
                                everficationObj.Category__c = (String) String.valueOf(mapResponseBody.get('category'));
                            }
                            if(mapResponseBody.containsKey('maskedAadhaarNumber')){
                                everficationObj.Masked_Aadhar_No__c = (String) String.valueOf(mapResponseBody.get('maskedAadhaarNumber'));
                            }
                            if(mapResponseBody.containsKey('emailId')){
                                everficationObj.Email__c = (String) String.valueOf(mapResponseBody.get('emailId'));
                            }
                            if(mapResponseBody.containsKey('mobileNumber')){
                                everficationObj.Mobile__c = (String) String.valueOf(mapResponseBody.get('mobileNumber'));
                            }
                            if (mapResponseBody.containsKey('aadhaarLinked')) {
                                String aadharlinkStr = String.valueOf(mapResponseBody.get('aadhaarLinked'));
                                if (String.isNotBlank(aadharlinkStr)) {
                                    everficationObj.Aadhar_linked__c = aadharlinkStr.toLowerCase() == 'true';
                                }
                            }
                            message = MessageConfigMap.get('Success').Message__c;
                            
                        }else{
                            if(mapResponseBody.containsKey('message')){
                                everficationObj.Message__c = (String) String.valueOf(mapResponseBody.get('message'));
                                everficationObj.Failed_Reason__c = (String) String.valueOf(mapResponseBody.get('message'));
                            }
                            if(mapResponseBody.containsKey('statusCode')){
                                everficationObj.Warning_Code__c = (String) String.valueOf(mapResponseBody.get('statusCode'));
                            }
                            everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                            message = messageConfigMap.get('Pan_Detail_Are_Incorrect').Message__c;
                        }
                    }else{
                        everficationObj.Failed_Reason__c = messageConfigMap.get('PAN_API_Issue').Message__c;
                        everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                        message = messageConfigMap.get('Error').Message__c;
                    }
                    
                }else{
                    everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    message = messageConfigMap.get('PAN_API_Issue').Message__c;
                }
                insertRecords.add(everficationObj);
                if (!insertRecords.isEmpty()) {
                    e_verificationUOW.registerNew(insertRecords[0]);
                    e_verificationUOW.commitWork();
                    loanAppList[0].Pan_Verification__c = insertRecords[0].Id;
                    List<SObjectField> lstOfObj = new List<SObjectField>{
                        Loan_Applicant__c.Pan_Verification__c,
                        Loan_Applicant__c.Is_Pan_Verified__c
                    };
                    uow.registerDirty(loanAppList,lstOfObj);
                    uow.commitWork();
                    if(isPanVerified){
                        // Call Queueable Class for next API
                        List<Loan_Applicant__c> loanAppLists = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
                        String verificationId = loanAppList[0].PAN_Verification__c;
                        String applicantFullName = loanAppList[0].Name;
                        String panFullName = loanAppList[0].PAN_Verification__r.PAN_Full_Name__c;

                        System.enqueueJob(new NameComparisonQueueable(
                            applicantFullName,panFullName,verificationId,customerId
                        ));
                    }
                }
                logger.info('Request Body '+panStatusCheck.service.getRequestBody());
                logger.info('status code '+response.getStatusCode());
                logger.info('status '+response.getStatus());
                logger.info('Response Body '+response.getBody());
            }
        }catch(Exception e) {
            if (sp != null) {
                Database.rollback(sp);
            }
            Logger.error('error '+e.getMessage());
        }finally{
            Logger.saveLog();
        }
        return message;
    }
}