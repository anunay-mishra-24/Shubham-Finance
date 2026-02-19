/**
 * @File Name          : SHF_LitigationInstant_Service.cls
 * @Description        : Use to get the access token for litigation api
 * @Author             : Vikas Soni
 * @Test Class         :
 *==============================================================================
 * Ver          Date            Author            Modification
 *==============================================================================
 * 1.0       12-01-2026      Vikas Soni       Initial Version
 */
public with sharing class SHF_LitigationInstant_Service {
    public SHF_HTTPCalloutService service;
    public static String initateLitigationInstant(String applicantId) {
        system.debug('applicantId - '+applicantId);
        String message = '';
        
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Loan_Applicant__c.SObjectType});
            fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
            if(String.isNotBlank(applicantId)){
                
                // get applicant details
                Loan_Applicant__c loanApplicant = new SHF_LoanApplicantsSelector().selectLitigationApplicant(applicantId);//Added By Vikas Soni
                List<Address__c> addressList = new SHF_AddressesSelector().selectAddressesForLitigation(applicantId);
                Map<String,String> addressMap = new Map<String,String>();
                for(Address__c address : addressList){
                    addressMap.put(address.Mailing_Address__c, address.Full_Address__c);
                }
                system.debug('loanApplicant : '+loanApplicant);
                    if(String.isNotBlank(loanApplicant.Litigation_Instant_Verification__r.Litigation_Verify_Id__c) && loanApplicant.Litigation_Instant_Verification__r.Status__c.equals('In Progress')){
                        
                        message = getLitigationInstantResult(applicantId);
                    }
                    else{
                Boolean isIndividual = false;
                
                //get api details from metadata
                SHF_LitigationInstant_Service advanceLitigationService = new SHF_LitigationInstant_Service();
                advanceLitigationService.service = new SHF_HTTPCalloutService('Litigation_Instant_API');
                //body work pending here
                if(loanApplicant.Customer_Type__c.equals('Individual')){
                    isIndividual = true;
                }
                
                String requestBody = advanceLitigationService.service.getRequestBody();
                if(isIndividual){
                    requestBody = requestBody.replace('<personName>', String.isNotBlank(loanApplicant.Name) ? loanApplicant.Name : '');
                    requestBody = requestBody.replace('<fatherName>',  String.isNotBlank(loanApplicant.Fathers_Name__c) ? loanApplicant.Fathers_Name__c : '');
                    // requestBody = requestBody.replace('<source>', 'ecourt'); // need discussion
                    String address = '';
                    if(addressMap.containsKey('Permanent Address')){
                        address = addressMap.get('Permanent Address');
                    }
                    else if(addressMap.containsKey('Permanent Address')){
                        address = addressMap.get('Permanent Address');
                    }
                    else if(addressMap.containsKey('Current Address')){
                        address = addressMap.get('Current Address');
                    }
                    requestBody = requestBody.replace('<address>', address);
                    requestBody = requestBody.replace('<authToken>', Label.Litigation_Auth_Token);
                    requestBody = requestBody.replace('<userName>', Label.Litigation_User_Name);
                }
                // as per client(prashant and akash) disscussion only for individual
                // else{
                    //     requestBody = requestBody.replace('<applicantName>', String.isNotBlank(loanApplicant.Name) ? loanApplicant.Name : '');
                    //     requestBody = requestBody.replace('<applicantId>', String.isNotBlank(loanApplicant.Id) ? loanApplicant.Id : '');
                    //     requestBody = requestBody.replace('<address>', '');
                    //     String dob = '';
                    //     if(loanApplicant.Date_Of_Incorporation1__c != null){
                        //         Datetime dt = DateTime.newInstance(loanApplicant.Date_Of_Incorporation1__c.year(), loanApplicant.Date_Of_Incorporation1__c.month(), loanApplicant.Date_Of_Incorporation1__c.day());
                        //         dob = dt.format('dd-MM-yyyy');
                    //     }
                    //     requestBody = requestBody.replace('<dob>',  dob);
                    //     requestBody = requestBody.replace('<fatherName>',  '');
                // }
                advanceLitigationService.service.setRequestBody(requestBody);
                
                
                HttpResponse response;
                if (advanceLitigationService.service.getIsActive()) {
                    response = advanceLitigationService.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setStatusCode(200);
                    response.setBody(advanceLitigationService.service.getmockRespnse());
                }
                Logger.info('SHF_LitigationInstant_Service Request : '+advanceLitigationService.service.getRequestBody());
                Logger.info('SHF_LitigationInstant_Service Response : '+response.getBody());
                Logger.info('SHF_LitigationInstant_Service Endpoint : '+advanceLitigationService.service.getEndpointURL());
                Logger.info('SHF_LitigationInstant_Service Method : '+advanceLitigationService.service.getRequestMethod());
                E_Verification__c everficationObj = SHF_CommonUtil.createVerfication(loanApplicant.Id, SHF_ConstantsUtil.LITIGATION_RECORD_TYPE, SHF_ConstantsUtil.INPROGRESS_STATUS);
                system.debug('everficationObj -- '+everficationObj);
                system.debug('everficationObj Status__c -- '+everficationObj.Status__c);
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    
                    SHF_LitigationinstantParser litigationParser = new SHF_LitigationinstantParser();
                    litigationParser = SHF_LitigationinstantParser.parse(response.getBody());
                    if(litigationParser.status == 1){
                        everficationObj.Status__c = 'In Progress';
                        everficationObj.Litigation_Verify_Id__c = litigationParser.verify_id;
                                message = 'Success';
                        // getLitigationInstantResult(applicantId);
                    }
                    else{
                        everficationObj.Status__c = 'Failed';
                        everficationObj.Description__c = litigationParser.error_message;
                        Logger.error('SHF_LitigationInstant_Service Error : '+litigationParser.error_message);
                        message = 'Failed';
                    }
                }
                else{
                    everficationObj.Status__c = 'Failed';
                    Logger.error('SHF_LitigationInstant_Service Error : '+response.getBody());
                    message = 'Failed';
                }
                
                if(String.isNotBlank(loanApplicant.Litigation_Instant_Verification__r.Litigation_Verify_Id__c)){
                    everficationObj.Id = loanApplicant.Litigation_Instant_Verification__c;
                    e_verificationUOW.registerDirty(everficationObj);
                }
                else{
                    e_verificationUOW.registerNew(everficationObj);
                }
                e_verificationUOW.commitWork();
                loanApplicant.Litigation_Instant_Verification__c = everficationObj.Id;
                uow.registerDirty(loanApplicant);
                uow.commitWork();
                    }
                    
                
                
            }
            else {
                message = 'Applicant Id Not present';
                Logger.error('Applicant Id Not present');
            }
        } catch (Exception e) {
            message = 'Exception in SHF_LitigationInstant_Service details : ' + e.getMessage();
            Logger.error('Exception in SHF_LitigationInstant_Service details : ' + e.getMessage() + ' ' + e.getLineNumber());
        }
        finally {
            Logger.saveLog();
        }
        return message;
    }
    public static String getLitigationInstantResult(String applicantId){
        String message = '';
        
        try {
            // fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Loan_Applicant__c.SObjectType});
            fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
            if(String.isNotBlank(applicantId)){
                
                // get applicant details
                Loan_Applicant__c loanApplicant = new SHF_LoanApplicantsSelector().selectLitigationApplicant(applicantId);//Added By Vikas Soni
                
                Boolean isIndividual = false;
                
                //get api details from metadata
                SHF_LitigationInstant_Service advanceLitigationService = new SHF_LitigationInstant_Service();
                advanceLitigationService.service = new SHF_HTTPCalloutService('Litigation_Instant_Result');
                //body work pending here
                if(loanApplicant.Customer_Type__c.equals('Individual')){
                    isIndividual = true;
                }
                
                String requestBody = advanceLitigationService.service.getRequestBody();
                if(isIndividual){
                    requestBody = requestBody.replace('<authToken>', Label.Litigation_Auth_Token);
                    requestBody = requestBody.replace('<userName>', Label.Litigation_User_Name);
                    requestBody = requestBody.replace('<verifyId>',  String.isNotBlank(loanApplicant.Litigation_Instant_Verification__r.Litigation_Verify_Id__c) ? loanApplicant.Litigation_Instant_Verification__r.Litigation_Verify_Id__c : '');
                }
                // as per client(prashant and akash) disscussion only for individual
                // else{
                    //     requestBody = requestBody.replace('<applicantName>', String.isNotBlank(loanApplicant.Name) ? loanApplicant.Name : '');
                    //     requestBody = requestBody.replace('<applicantId>', String.isNotBlank(loanApplicant.Id) ? loanApplicant.Id : '');
                    //     requestBody = requestBody.replace('<address>', '');
                    //     String dob = '';
                    //     if(loanApplicant.Date_Of_Incorporation1__c != null){
                        //         Datetime dt = DateTime.newInstance(loanApplicant.Date_Of_Incorporation1__c.year(), loanApplicant.Date_Of_Incorporation1__c.month(), loanApplicant.Date_Of_Incorporation1__c.day());
                        //         dob = dt.format('dd-MM-yyyy');
                    //     }
                    //     requestBody = requestBody.replace('<dob>',  dob);
                    //     requestBody = requestBody.replace('<fatherName>',  '');
                // }
                advanceLitigationService.service.setRequestBody(requestBody);
                
                
                HttpResponse response;
                if (advanceLitigationService.service.getIsActive()) {
                    response = advanceLitigationService.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setStatusCode(200);
                    response.setBody(advanceLitigationService.service.getmockRespnse());
                }
                Logger.info('SHF_LitigationInstant_Service Result Request : '+advanceLitigationService.service.getRequestBody());
                Logger.info('SHF_LitigationInstant_Service Result Response : '+String.valueOf(response.getBody()).substring(0, 5000) + '... [TRUNCATED]');
                Logger.info('SHF_LitigationInstant_Service Result Endpoint : '+advanceLitigationService.service.getEndpointURL());
                Logger.info('SHF_LitigationInstant_Service Result Method : '+advanceLitigationService.service.getRequestMethod());
                E_Verification__c everficationObj = SHF_CommonUtil.createVerfication(loanApplicant.Id, SHF_ConstantsUtil.LITIGATION_RECORD_TYPE, SHF_ConstantsUtil.INPROGRESS_STATUS);
                everficationObj.Id = loanApplicant.Litigation_Instant_Verification__c;
                system.debug('everficationObj -- '+everficationObj);
                system.debug('everficationObj Status__c -- '+everficationObj.Status__c);
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    system.debug('inside response');
                    
                    SHF_LitigationinstantResultParser litigationParser = new SHF_LitigationinstantResultParser();
                    system.debug('inside response - '+litigationParser);
                    litigationParser = SHF_LitigationinstantResultParser.parse(String.valueOf(response.getBody()));
                    system.debug('inside response - '+litigationParser);
                    if(litigationParser.status == 1){
                        system.debug('inside status');
                        everficationObj.Status__c = 'Completed';
                        // List<String> linksList = new List<String>();
                        String richTextLink = '';
    
                        Integer count = 1;
                        for(SHF_LitigationinstantResultParser.cls_cases ca : litigationParser.cases){
                            if(String.isNotBlank(ca.link)){
                                richTextLink += '<h3>' +count + '. '+ ca.case_no + '</h3>';
                                richTextLink += '<a href="' + ca.link + '" target="_blank">' + ca.link + '</a>';
                                richTextLink += '<br/><br/>';
                                count++;
                                
                                // linksList.add(ca.link);
                            }
                        }
                        // system.debug('inside linksList -- '+linksList);
                        // everficationObj.Cases_Links__c = (linksList.size() > 0 ? String.join(linksList, ',') : '');
                        everficationObj.Cases_Links__c = (String.isNotBlank(richTextLink) ? richTextLink : '');
                        everficationObj.Description__c = litigationParser.message;
                        // link work pending here
                        message = 'Success Report';
                    }
                    else{
                        everficationObj.Status__c = 'Failed';
                        everficationObj.Description__c = litigationParser.message;
                        Logger.error('SHF_LitigationInstant_Service Error : '+litigationParser.message);
                        message = 'Failed';
                    }
                }
                else{
                    everficationObj.Status__c = 'Failed';
                    Logger.error('SHF_LitigationInstant_Service Error : '+response.getBody());
                    message = 'Failed';
                }
                
                e_verificationUOW.registerDirty(everficationObj);
                e_verificationUOW.commitWork();
                // loanApplicant.Litigation_Instant_Verification__c = everficationObj.Id;
                // uow.registerDirty(loanApplicant);
                // uow.commitWork();
                
                
            }
            else {
                message = 'Applicant Id Not present';
                Logger.error('Applicant Id Not present');
            }
        } catch (Exception e) {
            Logger.error('Exception in SHF_LitigationInstant_Service result : ' + e.getMessage() + ' ' + e.getLineNumber());
        }
        finally {
            Logger.saveLog();
        }
        return message;
    }
}