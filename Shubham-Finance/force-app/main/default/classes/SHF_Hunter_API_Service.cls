/**
* @File Name          : SHF_Hunter_API_Service.cls
* @Description        : API to run Hunter Check for Primary Applicant.
* @Author             : Akshi Sharma
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         14-08-2025               Akshi Sharma           Initial Version
* 1.1         18-08-2025               Akshi Sharma           Defensive XML parsing + Logger fix
* 1.2         18-08-2025               Akshi Sharma           Log full SOAP request/response
* 1.3         27-12-2025               Dimple Kapri           Mapped dynamic fields in Hunter API request
*/
public with sharing class SHF_Hunter_API_Service {
    
    public SHF_HTTPCalloutService service;
    
    public static String callHunterAPI(Id applicationId) {
        String message = '';
        Savepoint sp;
        Logger.info('--- Hunter API Call Started for Application: ' + applicationId + ' ---');
        
        try {
            fflib_SObjectUnitOfWork verificationUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> { E_Verification__c.SObjectType });
            fflib_SObjectUnitOfWork applicantUOW = new fflib_SObjectUnitOfWork(new List<SObjectType> { Loan_Applicant__c.SObjectType });
            fflib_SObjectUnitOfWork hunterUOW = new fflib_SObjectUnitOfWork(new List<SObjectType>{Hunter_Verification__c.SObjectType});
            
            List<String> missingFields = new List<String>();
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ applicationId });
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + applicationId);
                return 'Loan Applicant not found';
            }
            Loan_Applicant__c applicant = loanAppList[0];
            
            List<Address__c> addressList = new SHF_AddressesSelector().selectAddressesForHunter(applicationId);
            
            Address__c Residentialaddress = new Address__c();
            Address__c Permanentaddress = new Address__c();
            String matchesValue;
            Id pendingHunterQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'Pending_Hunter_Activities' AND Type='Queue' LIMIT 1].Id;
            
            
            for (Address__c addr : addressList) {
                if (addr.Mailing_Address__c == 'Residential Address') {
                    Residentialaddress = addr;
                } else if (addr.Mailing_Address__c == 'Permanent Address') {
                    Permanentaddress = addr;
                }
            }
            
            Application__c app = (new SHF_ApplicationSelector()).selectApplicationForInsurance(applicant.Application__c);
            
            String applicationcreatedDate = DateTime.newInstance(app.CreatedDate.year(), app.CreatedDate.month(), app.CreatedDate.day()).format('yyyy-MM-dd');
            
            Map<String,Object> result = new Map<String,Object>();
            missingFields = getMissingMandatoryFields(applicant, app,Residentialaddress,Permanentaddress);
            if (!missingFields.isEmpty()) {
                result.put('status', 'error');
                result.put('missingFields', missingFields);
                System.debug('Missing fields for Applicant Id ' + applicationId + ': ' + missingFields);
                return JSON.serialize(result);
            }
            
            SHF_Hunter_API_Service hunterAPIService = new SHF_Hunter_API_Service();
            hunterAPIService.service = new SHF_HTTPCalloutService('Hunter_API');
            String requestBody = hunterAPIService.service.getRequestBody();
            
            //  requestBody = requestBody.replace('<PRIMARY_APPLICANT_ID>',String.valueOf(applicationId));
            // requestBody = requestBody.replace('<PRODUCT_CODE>',String.valueOf(applicant.Application__r.Product__r.Sub_Product_Code__c));
            requestBody = requestBody.replace('<LOAN_SUBMISSION_DATE>', DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('yyyy-MM-dd'));
            requestBody = requestBody.replace('<LOAN_APPLICATION_DATE>', applicationcreatedDate);
            requestBody = requestBody.replace('<LOAN_TENURE>', String.valueOf(app.Tenure__c));
            requestBody = requestBody.replace('<LOAN_AMOUNT>', String.valueOf(app.Applied_Loan_Amount__c));
            requestBody = requestBody.replace('<LOAN_APPLICANT_NAME>', string.valueOf(applicant.Name));
            
            requestBody = requestBody.replace('<PAN_NUMBER>', String.valueOf(applicant.Pan_Number__c));
            requestBody = requestBody.replace('<FIRST_NAME>', String.valueOf(applicant.First_Name__c));
            requestBody = requestBody.replace('<LAST_NAME>', String.valueOf(applicant.Last_Name__c));
            requestBody = requestBody.replace('<DATE_OF_BIRTH>', String.valueOf(applicant.Date_of_Birth__c));
            requestBody = requestBody.replace('<APPLICANT_AGE>', String.valueOf(applicant.Applicant_Age__c));
            requestBody = requestBody.replace('<MOBILE>', String.valueOf(applicant.Mobile_Number__c));
            requestBody = requestBody.replace('<AADHAR_NO>', String.valueOf(applicant.Aadhar_Number__c));
            requestBody = requestBody.replace('<PAN_NO>', String.valueOf(applicant.Pan_Number__c));
            
            requestBody = requestBody.replace('<RES_ADDRESS>',Residentialaddress.Address_Line_1__c);
            requestBody = requestBody.replace('<RES_CITY>', Residentialaddress.City__c);
            requestBody = requestBody.replace('<RES_STATE>', Residentialaddress.State__c);
            requestBody = requestBody.replace('<RES_COUNTRY>', Residentialaddress.Country__c);
            requestBody = requestBody.replace('<RES_PINCODE>', Residentialaddress.Pincode__c);
            
            requestBody = requestBody.replace('<PER_ADDRESS>', Permanentaddress.Address_Line_1__c);
            requestBody = requestBody.replace('<PER_CITY>', Permanentaddress.City__c);
            requestBody = requestBody.replace('<PER_STATE>', Permanentaddress.State__c);
            requestBody = requestBody.replace('<PER_COUNTRY>', Permanentaddress.Country__c);
            requestBody = requestBody.replace('<PER_PINCODE>', Permanentaddress.Pincode__c);
            
            Logger.debug('Hunter API Request Body: ' + (requestBody.length() > 10000 ? requestBody.substring(0, 10000) + '...[truncated]' : requestBody));
            
            hunterAPIService.service.setHeaderParameter('Content-Type', 'text/xml; charset=UTF-8');
            hunterAPIService.service.requestCertificate = 'HunterClientCert';
            
            hunterAPIService.service.setRequestBody(requestBody);
            
            //sp = Database.setSavepoint();
            HttpResponse response = hunterAPIService.service.sendRequest();
            
            E_Verification__c everficationObj = SHF_CommonUtil.createVerfication(
                applicant.Id,
                SHF_ConstantsUtil.HUNTER_VERIFICATION_RECORD_TYPE,
                SHF_ConstantsUtil.COMPLETEDSTATUS
            );
            
            if (response != null && response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                
                Logger.debug('Hunter API Raw Response: ' + (response.getBody().length()>10000 ? response.getBody().substring(0,10000)+'...[truncated]' : response.getBody()));
                try {
                    Dom.Document doc = new Dom.Document();
                    doc.load(response.getBody());
                    
                    Dom.XmlNode bodyNode = doc.getRootElement().getChildElement('Body','http://schemas.xmlsoap.org/soap/envelope/');
                    if (bodyNode != null) {
                        Dom.XmlNode matchResponse = bodyNode.getChildElement('MatchResponse','http://www.mclsoftware.co.uk/HunterII/WebServices');
                        if (matchResponse != null) {
                            Dom.XmlNode matchResultNode = matchResponse.getChildElement('MatchResult', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
                            if (matchResultNode != null) {
                                String escapedXml = matchResultNode.getText();
                                String unescapedXml = escapedXml
                                    .replace('&amp;', '&')
                                    .replace('&lt;', '<')
                                    .replace('&gt;', '>')
                                    .replace('&quot;', '"');
                                
                                everficationObj.Raw_Response__c = unescapedXml;
                                
                                Dom.Document innerDoc = new Dom.Document();
                                innerDoc.load(unescapedXml);
                                
                                Dom.XmlNode resultBlock = innerDoc.getRootElement();
                                Dom.XmlNode matchSummary = resultBlock.getChildElement('MatchSummary', null);
                                if (matchSummary != null) {
                                    matchesValue = matchSummary.getAttribute('matches', null);
                                    everficationObj.Hunter_Match__c = matchSummary.getAttribute('matches', null);
                                    Dom.XmlNode totalScoreNode = matchSummary.getChildElement('TotalMatchScore', null);
                                    if (totalScoreNode != null) {
                                        everficationObj.Hunter_Total_Match_Score__c = totalScoreNode.getText();
                                    }
                                }
                                Integer errorCount = Integer.valueOf(resultBlock.getChildElement('ErrorWarnings', null).getChildElement('Errors', null).getAttribute('errorCount',null));
                                everficationObj.Hunter_Status__c = (errorCount > 0) ? 'Error' : 'Completed';
                                Dom.XmlNode warningNode = resultBlock
                                    .getChildElement('ErrorWarnings', null)
                                    .getChildElement('Warnings', null)
                                    .getChildElement('Warning', null);
                                if (warningNode != null) {
                                    everficationObj.Warning_Code__c = warningNode.getChildElement('Number', null).getText();
                                    everficationObj.Warning_Message__c = warningNode.getChildElement('Message', null).getText();
                                    //for values count
                                    List<Dom.XmlNode> valueNodes = warningNode.getChildElement('Values', null).getChildElements();
                                    Integer valueCount = 0;
                                    for (Dom.XmlNode node : valueNodes) {
                                        if (node.getName() == 'Value') {
                                            valueCount++;
                                        }
                                    }
                                    
                                    everficationObj.Hunter_Summary_Match__c = (valueCount > 0) ? 'Match Found' : 'Not Found';
                                    
                                }
                                everficationObj.Status__c = SHF_ConstantsUtil.COMPLETEDSTATUS;
                                message = 'Hunter API Success';
                                Hunter_Verification__c hunterVer;
                                
                                  hunterVer = new Hunter_Verification__c(Loan_Applicant__c = applicant.Id, Application__c    = applicant.Application__c);
                                
                                if (matchesValue == '0') {
                                    hunterVer.Decision__c = 'No Match';
                                    hunterVer.Status__c   = 'Completed';
                                } else if (matchesValue == '1') {
                                    hunterVer.Decision__c = 'Match';
                                    hunterVer.Status__c   = 'Pending';
                                    if(pendingHunterQueueId != null){
                                        hunterVer.OwnerId = pendingHunterQueueId;
                                    }
                                }
                                
                                hunterUOW.registerNew(hunterVer);
                                try {
                                    hunterUOW.commitWork();
                                } catch(Exception e) {
                                    Logger.error('Hunter insert failed: ' + e.getMessage());
                                }
                                  Logger.info('Hunter API Success for Applicant: ' + applicationId);
                            } else {
                                everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                                everficationObj.Failed_Reason__c = 'Missing MatchResult node';
                                message = 'Hunter API failed: Missing MatchResult';
                                Logger.warn('Hunter API failed: Missing MatchResult');
                            }
                        } else {
                            everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                            everficationObj.Failed_Reason__c = 'Missing MatchResponse node';
                            message = 'Hunter API failed: Missing MatchResponse';
                            Logger.warn('Hunter API failed: Missing MatchResponse');
                        }
                    } else {
                        everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                        everficationObj.Failed_Reason__c = 'Missing Body node';
                        message = 'Hunter API failed: Missing Body';
                        Logger.warn('Hunter API failed: Missing Body');
                    }
                    
                } catch (Exception parseEx) {
                    everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    everficationObj.Failed_Reason__c = 'Parsing error: ' + parseEx.getMessage();
                    message = 'Hunter parsing failed';
                    Logger.error('Hunter parsing failed: ' + parseEx.getMessage());
                }
                
            } else {
                everficationObj.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                everficationObj.Failed_Reason__c = 'Invalid HTTP Response: ' + (response == null ? 'null' : String.valueOf(response.getStatusCode()));
                message = 'Hunter API failed with HTTP status';
                Logger.error('Hunter API failed. Response: ' + (response == null ? 'null' : String.valueOf(response.getStatusCode())));
            }
            
            
            // Save Verification
            verificationUOW.registerNew(everficationObj);
            verificationUOW.commitWork();
            Logger.info('E-Verification Inserted: ' + everficationObj.Id);
            
            // Update Applicant
            loanAppList[0].Hunter_Verification__c = everficationObj.Id;
            applicantUOW.registerDirty(loanAppList);
            applicantUOW.commitWork();
            Logger.info('Applicant Updated with Verification: ' + applicant.Id);
            
        } catch (Exception e) {
            if (sp != null) Database.rollback(sp);
            Logger.error('Hunter API error: ' + e.getMessage());
            message = 'Error: ' + e.getMessage();
        } finally {
            Logger.saveLog();
        }
        
        Logger.info('--- Hunter API Call Finished ---');
        Logger.info('Hunter API Final Return Message: ' + message);
        
        return JSON.serialize(message);
    }
    
    public static List<String> getMissingMandatoryFields(Loan_Applicant__c loanApplicant, Application__c application, Address__c ResAddress,Address__c PerAddress) {
        List<String> missing = new List<String>();
        
        
        if (loanApplicant.Date_of_Birth__c == null) missing.add(loanApplicant.Name +': Date of Birth is missing');
        if (loanApplicant.Mobile_Number__c == null) missing.add(loanApplicant.Name +': Mobile Number missing');
        if (loanApplicant.Pan_Number__c == null) missing.add(loanApplicant.Name +': PAN Number is missing');
        if (loanApplicant.Aadhar_Number__c == null) missing.add(loanApplicant.Name +': Aadhar is missing');
        if (loanApplicant.First_Name__c == null) missing.add(loanApplicant.Name +': First Name is missing');
        if (loanApplicant.Last_Name__c == null) missing.add(loanApplicant.Name +': Last Name is missing');
        if (application.Applied_Loan_Amount__c == null) missing.add('Applied Loan Amount missing for :'+ application.Id);
        if (application.Tenure__c == null) missing.add('Tenure is missing for :'+ application.Name);
        if (ResAddress.City__c == null) missing.add(loanApplicant.Name +': Residential Address - City Missing');
        if (ResAddress.State__c == null) missing.add(loanApplicant.Name +': Residential Address - State is missing');
        if (ResAddress.Country__c == null) missing.add(loanApplicant.Name +': Residential Address - Country is missing');
        if (ResAddress.Pincode__c == null) missing.add(loanApplicant.Name +': Residential Address - Pincode is missing');
        if (PerAddress.City__c == null) missing.add(loanApplicant.Name +': Permanent Address - City Missing');
        if (PerAddress.State__c == null) missing.add(loanApplicant.Name +': Permanent Address - State is missing');
        if (PerAddress.Country__c == null) missing.add(loanApplicant.Name +': Permanent Address - Country is missing');
        if (PerAddress.Pincode__c == null) missing.add(loanApplicant.Name +': Permanent Address - Pincode is missing');
        
        
        return missing;
    }
}