/**
 * @File Name          : SHF_LitigationAdvance_Service.cls
 * @Description        : Use to get the access token for litigation api
 * @Author             : Vikas Soni
 * @Test Class         :
 *==============================================================================
 * Ver          Date            Author            Modification
 *==============================================================================
 * 1.0       12-01-2026      Vikas Soni       Initial Version
 */
public with sharing class SHF_LitigationAdvance_Service {
    public SHF_HTTPCalloutService service;
    public static String initateLitigationAdvance(String applicantId) {
        String message = '';
        
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Loan_Applicant__c.SObjectType});
            fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
            if(String.isNotBlank(applicantId)){
                String accessToken = SHF_LitigationAccessToken_Service.generateAccessToken();
                Logger.info('Access Token : '+accessToken);
                if(String.isNotBlank(accessToken)){
                    // get applicant details
                    Loan_Applicant__c loanApplicant = new SHF_LoanApplicantsSelector().selectLitigationApplicant(applicantId);//Added By Vikas Soni
                    List<Address__c> addressList = new SHF_AddressesSelector().selectAddressesForLitigation(applicantId);
                    Map<String,String> addressMap = new Map<String,String>();
                    for(Address__c address : addressList){
                        addressMap.put(address.Mailing_Address__c, address.Full_Address__c);
                    }
                    system.debug('loanApplicant : '+loanApplicant);
                    if(String.isNotBlank(loanApplicant.Litigation_Advance_Verification__r.Status__c) && loanApplicant.Litigation_Advance_Verification__r.Status__c.equals('In Progress')){
                        message = 'Already in progress';
                    }
                    else if(String.isNotBlank(loanApplicant.Litigation_Advance_Verification__r.Status__c) && loanApplicant.Litigation_Advance_Verification__r.Status__c.equals('Completed')){
                        message = 'Already completed';
                    }
                    else{
                        Boolean isIndividual = false;
                        
                        //get api details from metadata
                        SHF_LitigationAdvance_Service advanceLitigationService = new SHF_LitigationAdvance_Service();
                        advanceLitigationService.service = new SHF_HTTPCalloutService('Litigation_Advance');
                        advanceLitigationService.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
                        //body work pending here
                        if(loanApplicant.Customer_Type__c.equals('Individual')){
                            isIndividual = true;
                        }
                        
                        String requestBody = advanceLitigationService.service.getRequestBody();
                        String address = '';
                        if(isIndividual){
                            requestBody = requestBody.replace('<applicantName>', String.isNotBlank(loanApplicant.Name) ? loanApplicant.Name : '');
                            requestBody = requestBody.replace('<applicantId>', String.isNotBlank(loanApplicant.Id) ? loanApplicant.Id : '');
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
                            String dob = '';
                            if(loanApplicant.Date_of_Birth__c != null){
                                Datetime dt = DateTime.newInstance(loanApplicant.Date_of_Birth__c.year(), loanApplicant.Date_of_Birth__c.month(), loanApplicant.Date_of_Birth__c.day());
                                dob = dt.format('dd-MM-yyyy');
                            }
                            requestBody = requestBody.replace('<dob>',  dob);
                            requestBody = requestBody.replace('<fatherName>',  String.isNotBlank(loanApplicant.Name) ? loanApplicant.Name : '');
                        }
                        else{
                            requestBody = requestBody.replace('<applicantName>', String.isNotBlank(loanApplicant.Name) ? loanApplicant.Name : '');
                            requestBody = requestBody.replace('<applicantId>', String.isNotBlank(loanApplicant.Id) ? loanApplicant.Id : '');
                            
                            if(addressMap.containsKey('Office Address')){
                                address = addressMap.get('Office Address');
                            }
                            requestBody = requestBody.replace('<address>', '');
                            String dob = '';
                            if(loanApplicant.Date_Of_Incorporation1__c != null){
                                Datetime dt = DateTime.newInstance(loanApplicant.Date_Of_Incorporation1__c.year(), loanApplicant.Date_Of_Incorporation1__c.month(), loanApplicant.Date_Of_Incorporation1__c.day());
                                dob = dt.format('dd-MM-yyyy');
                            }
                            requestBody = requestBody.replace('<dob>',  dob);
                            requestBody = requestBody.replace('<fatherName>',  '');
                        }
                        advanceLitigationService.service.setRequestBody(requestBody);
                        
                        
                        HttpResponse response;
                        if (advanceLitigationService.service.getIsActive()) {
                            response = advanceLitigationService.service.sendRequest();
                        } else {
                            response = new HttpResponse();
                            response.setStatusCode(200);
                            response.setBody(advanceLitigationService.service.getmockRespnse());
                        }
                        Logger.info('SHF_LitigationAdvance_Service Request : '+advanceLitigationService.service.getRequestBody());
                        Logger.info('SHF_LitigationAdvance_Service Response : '+response.getBody());
                        Logger.info('SHF_LitigationAdvance_Service Endpoint : '+advanceLitigationService.service.getEndpointURL());
                        Logger.info('SHF_LitigationAdvance_Service Method : '+advanceLitigationService.service.getRequestMethod());
                        E_Verification__c everficationObj = SHF_CommonUtil.createVerfication(loanApplicant.Id, SHF_ConstantsUtil.LITIGATION_RECORD_TYPE, SHF_ConstantsUtil.INPROGRESS_STATUS);
                        if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                            
                            SHF_LitigationAdvanceParser litigationParser = new SHF_LitigationAdvanceParser();
                            litigationParser = SHF_LitigationAdvanceParser.parse(response.getBody());
                            if(litigationParser.statusCode == 200){
                                everficationObj.Description__c = litigationParser.statusMsg;
                                everficationObj.Status__c = 'In Progress';
                                everficationObj.Litigation_Verify_Id__c = litigationParser.verifyId;
                                everficationObj.Litigation_Job_Name__c = litigationParser.jobName;
                                everficationObj.Litigation_Advance_API_Timestamp__c = System.now();
                                message = 'Success';
                            }
                        }
                        else{
                            everficationObj.Status__c = 'Failed';
                            message = 'Failed';
                        }
                        
                        e_verificationUOW.registerNew(everficationObj);
                        e_verificationUOW.commitWork();
                        loanApplicant.Litigation_Advance_Verification__c = everficationObj.Id;
                        uow.registerDirty(loanApplicant);
                        uow.commitWork();
                    }
                }
                else{
                    Logger.error('Access token is blank');
                    return 'Access token is blank';
                }
            }
            else {
                message = 'Applicant Id Not present';
                Logger.error('Applicant Id Not present');
            }
        } catch (Exception e) {
            Logger.error('Exception in SHF_LitigationAdvance_Service : ' + e.getMessage() + ' ' + e.getLineNumber());
            message = 'Exception in SHF_LitigationAdvance_Service : ' + e.getMessage();
        }
        finally {
            Logger.saveLog();
        }
        return message;
    }
    public static String getLitiagationAdvanceReport(String verifyId, String eVerificationId){
        String message = '';
        String applicantId = '';
        String applitionId = '';
        Logger.info('SHF_LitigationAdvance_Service');
        try {
            if(String.isNotBlank(verifyId) && String.isNotBlank(eVerificationId)){
                Loan_Applicant__c loanApplicant = [SELECT Id,Application__c FROM Loan_Applicant__c WHERE Litigation_Advance_Verification__c =: eVerificationId];
                if(loanApplicant != null){
                    applicantId = loanApplicant.Id;
                    applitionId = loanApplicant.Application__c;
                }
                String accessToken = SHF_LitigationAccessToken_Service.generateAccessToken();
                Logger.info('Access Token : '+accessToken);
                if(String.isNotBlank(accessToken)){
                    fflib_SObjectUnitOfWork e_verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
                    //get api details from metadata
                    SHF_LitigationAdvance_Service advanceLitigationService = new SHF_LitigationAdvance_Service();
                    advanceLitigationService.service = new SHF_HTTPCalloutService('Litigation_Advance_Report');
                    advanceLitigationService.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
                    String requestBody = advanceLitigationService.service.getRequestBody();
                    requestBody = requestBody.replace('<userName>', Label.Litigation_Advance_User_Name);
                    requestBody = requestBody.replace('<verifyId>', verifyId);
                    
                    advanceLitigationService.service.setRequestBody(requestBody);
                    
                    
                    HttpResponse response;
                    if (advanceLitigationService.service.getIsActive()) {
                        response = advanceLitigationService.service.sendRequest();
                    } else {
                        response = new HttpResponse();
                        response.setStatusCode(200);
                        response.setBody(advanceLitigationService.service.getmockRespnse());
                    }
                    Logger.info('SHF_LitigationAdvance_Service Request : '+advanceLitigationService.service.getRequestBody());
                    Logger.info('SHF_LitigationAdvance_Service Response : '+response.getBody());
                    Logger.info('SHF_LitigationAdvance_Service Endpoint : '+advanceLitigationService.service.getEndpointURL());
                    Logger.info('SHF_LitigationAdvance_Service Method : '+advanceLitigationService.service.getRequestMethod());
                    Logger.info('SHF_LitigationAdvance_Service code : '+response.getStatusCode());
                    E_Verification__c everficationObj = new E_Verification__c();
                    everficationObj.Id = eVerificationId;
                    if ((response.getStatusCode() == 200 || response.getStatusCode() == 201) && String.isNotBlank(response.getBody())) {
                        SHF_LitigationAdvanceReportParser reportParser = new SHF_LitigationAdvanceReportParser();
                        reportParser = SHF_LitigationAdvanceReportParser.parse(response.getBody());
                        if(reportParser.statusCode == 201 && String.isNotBlank(reportParser.reportUrl)){
                            Http http = new Http();
                            HttpRequest req = new HttpRequest();
                            req.setEndpoint(reportParser.reportUrl);
                            req.setMethod('GET');
                            req.setTimeout(60000);
                            
                            HttpResponse res = http.send(req);
                            if(res.getStatusCode() == 200) {
                                
                                
                                Document__c doc;
                                if (applicantId != null) {
                                    doc = new Document__c();
                                    doc.Loan_Applicant__c = applicantId;
                                    doc.Application__c = applitionId;
                                    doc.Stage__c = 'QDE';
                                    doc.File_Name__c = 'Litigation Advance Report';
                                    doc.Document_Source__c = 'API';
                                    doc.Document_Category__c = 'Others';
                                    // doc.Status__c = 'Uploaded';
                                    //doc.Stage__c = 'QDE';
                                    doc.Document_Received_Date__c = System.today();
                                    insert doc;
                                    Logger.info('Document record created: ' + doc.Id);
                                    
                                    Blob pdfBlob = res.getBodyAsBlob();
                                    ContentVersion pdfCV = new ContentVersion();
                                    pdfCV.Title = 'Litigation_Advance_Report';
                                    pdfCV.PathOnClient = 'LitigationAdvanceReport.pdf';
                                    pdfCV.VersionData = pdfBlob;
                                    pdfCV.FirstPublishLocationId = doc.Id;
                                    insert pdfCV;
                                }
                                
                                
                            }
                            everficationObj.Status__c = 'Completed';
                        }
                    }
                    else{
                        everficationObj.Status__c = 'Failed';
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
                message = 'Verify Id Not present';
                Logger.error('Verify Id Not present');
            }
        } catch (Exception e) {
            Logger.error('Exception in SHF_LitigationAdvance_Service : ' + e.getMessage() + ' ' + e.getLineNumber());
        }
        finally {
            Logger.saveLog();
        }
        return message;
    }
}