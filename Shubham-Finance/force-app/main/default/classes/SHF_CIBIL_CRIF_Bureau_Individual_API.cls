/*
* @File Name : CIBIL_CRIF_Bureau_Individual_API.cls
* @Author :  Preeti
* @Created Date : June 30, 2025
* @Description : This class is responsible for integrating with the CIBIL/CRIF Bureau API 
* for individual verification requests. It dynamically builds the API request 
* using metadata, performs HTTP callouts, and processes the API response to create 
* verification records and attach bureau reports as ContentVersion files.
* @Last Modified By :  Preeti
* @Last Modified On : July 03, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 30, 2025 | Preeti| Initial Version
*/


public with sharing class SHF_CIBIL_CRIF_Bureau_Individual_API {
    
    /*
* @description Public API method to call CIBIL/CRIF Bureau using applicationId and Aadhaar number.
* It builds a dynamic request using metadata, sends an HTTP callout, and processes the response.
* @param applicationId - Salesforce Id of the Loan Application.
* @param aadhaarNumber - Aadhaar number of the Loan Applicant.
* @return API response body or error message.
*/
    
    @AuraEnabled
    public static String callCIBILAPI(String loanApplicantId, String aadhaarNumber) {
        
        // Reusable Objects
        SHF_LoanApplicantsSelector loanApplicantSelector = new SHF_LoanApplicantsSelector(); 
        //SHF_ApplicationSelector applicationSelector = new SHF_ApplicationSelector();         
        
        // Fetching metadata
        Callout_Framework__mdt metadataConfig =  SHF_CommonUtil.getCalloutMetadata('CIBIL_CRIF_Bureau_Individual').get('CIBIL_CRIF_Bureau_Individual');
        
        // Variable Declarations
        Loan_Applicant__c loanApplicant;
        Application__c application;
        String addressJson;
        String requestBody;
        HttpResponse response;
        String currentTime;
        List<String> missingFields = new List<String>();
        System.debug('Aadhaar being passed from JS: ' + aadhaarNumber);
        System.debug('Loan Applicant Id: ' + loanApplicantId);
        
        
        try {
            
            // Fetch Loan Applicant
            loanApplicant = loanApplicantSelector.selectLoanApplicantForCIBIL(loanApplicantId);
            
            // Fetch Loan Application
            //application = applicationSelector.selectApplicationForCIBIL(applicationId);
            
            // Build Dynamic Address JSON 
            addressJson = buildDynamicAddressJson(loanApplicant.Application__c, loanApplicant, metadataConfig);
            
            missingFields = validateCIBILMandatoryFields(loanApplicant, addressJson);
            if (!missingFields.isEmpty()) {
                Map<String, Object> result = new Map<String, Object>();
                result.put('status', 'error');
                result.put('missingFields', missingFields);
                return JSON.serialize(result);
            }
            
            // Prepare Request Body by replacing metadata placeholders with actual values
            requestBody = metadataConfig.Body__c;
            requestBody = requestBody.replace('<APPLICATION_ID>', loanApplicant.Application__r.Name);
            requestBody = requestBody.replace('<FIRST_NAME>', loanApplicant.First_Name__c != null ? loanApplicant.First_Name__c : '');
            requestBody = requestBody.replace('<MIDDLE_NAME>', loanApplicant.Middle_Name__c != null ? loanApplicant.Middle_Name__c : '');
            requestBody = requestBody.replace('<LAST_NAME>', loanApplicant.Last_Name__c != null ? loanApplicant.Last_Name__c : '');
            requestBody = requestBody.replace('<GENDER>', loanApplicant.Gender__c != null ? loanApplicant.Gender__c : '');
            requestBody = requestBody.replace('<ADHAAR_NUMBER>', String.isNotBlank(aadhaarNumber) ? aadhaarNumber : '');
            Integer age = calculateAge(loanApplicant.Date_of_Birth__c);
            requestBody = requestBody.replace('<AGE>', String.valueOf(age));
            requestBody = requestBody.replace('<AGE_ON_DATE>', String.valueOf(age));
            requestBody = requestBody.replace('<DOB>', loanApplicant.Date_of_Birth__c != null ? formatDateDDMMYYYY(loanApplicant.Date_of_Birth__c) : '');
            requestBody = requestBody.replace('<PAN>', loanApplicant.Pan_Number__c != null ? loanApplicant.Pan_Number__c : '');
            requestBody = requestBody.replace('<MOBILE>', loanApplicant.Mobile_Number__c != null ? loanApplicant.Mobile_Number__c : '');
            String productType = (loanApplicant.Application__r.Product__r != null && loanApplicant.Application__r.Product__r.Product_Type__c != null)? loanApplicant.Application__r.Product__r.Product_Type__c : '';
            requestBody = requestBody.replace('<PRODUCT_TYPE>', productType);
            requestBody = requestBody.replace('<LOAN_AMOUNT>', loanApplicant.Application__r.Applied_Loan_Amount__c != null ? String.valueOf(Integer.valueOf(loanApplicant.Application__r.Applied_Loan_Amount__c)) : '');
            
            currentTime = System.now().format('dd/MM/yyyy hh:mm:ss a');
            requestBody = requestBody.replace('<REQUEST_TIME>', currentTime);
            requestBody = requestBody.replace('<ADDRESS_JSON_PLACEHOLDER>', addressJson);
            
            requestBody = requestBody.replace('"30": {"02": ""}', '"30": {"02": "' + aadhaarNumber + '"}');
            System.debug('Request body########' + requestBody);
            
            // Send HTTP Callout
            SHF_HTTPCalloutService calloutService = new SHF_HTTPCalloutService('CIBIL_CRIF_Bureau_Individual');
            if (metadataConfig == null || metadataConfig.Active__c == false) {
                // MOCK RESPONSE
                // system.debug('mockkkkk ' + metadataConfig.Mock_Response__c);
                logger.info('Metadata inactive → using mock response');
                response = new HttpResponse();
                response.setStatusCode(200); 
                response.setBody(metadataConfig != null ? metadataConfig.Mock_Response__c : 'No mock response configured');
                system.debug('mockkkkk response ' + response.getBody());
            } else {
                //SHF_HTTPCalloutService calloutService = new SHF_HTTPCalloutService('CIBIL_CRIF_Bureau_Individual');
                calloutService.setRequestMethod('POST');
                calloutService.setEndpointURL(metadataConfig.Endpoint__c);
                calloutService.setRequestTimeout(120000);
                calloutService.setRequestBody(requestBody);
                calloutService.setHeaderParameter('Content-Type', 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW');
                response = calloutService.sendRequest();
                system.debug('mockkkkk ' + metadataConfig.Mock_Response__c);
            }
            
            System.debug('response-->' + response);
            System.debug('Request body########' + requestBody);
            
            // Process response if successful
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                system.debug('processResponse');
                processResponse(response.getBody(), loanApplicant.Application__c,loanApplicantId);
            }
            System.debug('Request response.getBody########' + response.getBody());
            logger.info('status code '+response.getStatusCode());
            logger.info('status '+response.getStatus());
            // logger.info('Body '+response.getBody());
            return response.getBody();
            
            
        } catch(Exception e) {
            Logger.error('error '+e.getMessage());
            return 'Error: ' + e.getMessage();
        }finally{
            Logger.saveLog();
        }
    }
    
    private static List<String> validateCIBILMandatoryFields(Loan_Applicant__c loanApplicant, String addressJson) {
        List<String> missing = new List<String>();
        Boolean hasValidAddress = false;
        
        
        if (String.isBlank(loanApplicant.First_Name__c)) {
            missing.add('First Name');
            Logger.info('Missing: First Name');
        }
        if (String.isBlank(loanApplicant.Last_Name__c)) {
            missing.add('Last Name');
            Logger.info('Missing: Last Name');
        }
        if (loanApplicant.Date_of_Birth__c == null) {
            missing.add('Date of Birth');
            Logger.info('Missing: Date of Birth');
        }
        if (String.isBlank(loanApplicant.Gender__c)) {
            missing.add('Gender');
            Logger.info('Missing: Gender');
        }
        if (String.isBlank(loanApplicant.Pan_Number__c)) {
            missing.add('PAN');
            Logger.info('Missing: PAN');
        }
        if (String.isBlank(loanApplicant.Mobile_Number__c)) {
            missing.add('Mobile Number');
            Logger.info('Missing: Mobile Number');
        }
        
        if (loanApplicant.Application__r == null || loanApplicant.Application__r.Applied_Loan_Amount__c == null) {
            missing.add('Applied Loan Amount');
            Logger.info('Missing: Applied Loan Amount');
        }
        
        if (loanApplicant.Application__r != null && 
            (loanApplicant.Application__r.Product__r == null || String.isBlank(loanApplicant.Application__r.Product__r.Product_Type__c))) {
                missing.add('Product Type');
                Logger.info('Missing: Product Type');
            }
        
        // Validate address JSON
        
        try {
            List<Object> addresses = (List<Object>)JSON.deserializeUntyped(addressJson);
            for (Object addrObj : addresses) {
                Map<String, Object> addrMap = (Map<String, Object>)addrObj;
                for (String key : addrMap.keySet()) {
                    if (addrMap.get(key) != null && String.valueOf(addrMap.get(key)).trim() != '') {
                        hasValidAddress = true;
                        break;
                    }
                }
                if (hasValidAddress) break;
            }
        } catch (Exception e) {
            hasValidAddress = false;
        }
        
        if (!hasValidAddress) {
            missing.add('At least one valid Address');
            Logger.info('No valid address found');
        }
        
        return missing;
    }
    
    
    
    
    /*
* @description Builds dynamic JSON for the address section based on metadata and available addresses.
* @param applicationId - Salesforce Id of the Loan Application.
* @param loanApplicant - Loan Applicant record.
* @param metadataConfig - Metadata configuration for the API call.
* @return Serialized JSON string for the address block.
*/
    private static String buildDynamicAddressJson(String applicationId, Loan_Applicant__c loanApplicant, Callout_Framework__mdt metadataConfig) {
        try{
            
            List<Map<String, Object>> addressNodeList = new List<Map<String, Object>>();
            String staticValueFor02;
            
            List<Address__c> addressList = new SHF_AddressesSelector().selectAddressesForCIBIL(loanApplicant.Id);
            
            if (addressList == null || addressList.isEmpty()) {
                Logger.info('Step 4: Address list is empty. Adding empty node.');
                Map<String, Object> emptyAddressNode = new Map<String, Object>{
                    '01' => '',
                        '02' => '',
                        '03' => '',
                        '04' => '',
                        '05' => '',
                        '06' => ''
                        };
                            addressNodeList.add(emptyAddressNode);
                return JSON.serialize(addressNodeList);
            }
            else{
                Logger.info('Step 5: Fetching address metadata.');
                Map<String, Loan_Applicant_Address__mdt> addressMetaMap = SHF_CommonUtil.getAddressMetadata(metadataConfig.Id);
                staticValueFor02 = addressMetaMap.containsKey('02') ? addressMetaMap.get('02').Static_Value__c : '';
                Logger.info('Step 6: Static value for 02: ' + staticValueFor02);
                
                Integer lineCounter = 0;
                for (Address__c address : addressList) {
                    
                    Map<String, Object> addressNode = new Map<String, Object>();
                    
                    String addrType = address.Mailing_Address__c != null ? address.Mailing_Address__c : '';
                    String static02 = staticValueFor02 != null ? staticValueFor02 : '';
                    
                    
                    addressNode.put('01', SHF_ConstantsUtil.addressTypeMap.get(addrType));
                    addressNode.put('02', static02);
                    
                    String fullAddress = String.join(new List<String>{
                        address.Address_Line_1__c != null ? address.Address_Line_1__c : '',
                            address.Address_Line_2__c != null ? address.Address_Line_2__c : '',
                                address.Address_Line_3__c != null ? address.Address_Line_3__c : ''
                                    }, ' ').trim();
                    
                    String city = address.City__c != null ? address.City__c : '';
                    String pincode = '';
                    if (address.Pincode__c != null) {
                        pincode = address.Pincode__r != null && address.Pincode__r.Name != null ? address.Pincode__r.Name : String.valueOf(address.Pincode__c);
                    }
                    
                    String state = address.State__c != null ? address.State__c : '';
                    
                    Logger.info('City: ' + city + ', Pincode: ' + pincode + ', State: ' + state);
                    
                    addressNode.put('03', fullAddress);
                    addressNode.put('04', city);
                    addressNode.put('05', pincode);
                    addressNode.put('06', state);
                    
                    addressNodeList.add(addressNode);
                    
                }         
                return JSON.serialize(addressNodeList);
            }
            
        } catch (Exception ex) {
            Logger.error('Exception at buildDynamicAddressJson. Message: ' + ex.getMessage());
            Logger.error('Stack Trace: ' + ex.getlineNumber());
            return 'Error: ' + ex.getMessage();
        } finally {
            Logger.saveLog();
        }
    }
    
    
    /*
* @description Calculates the age based on the provided date of birth.
* @param dob - Date of birth.
* @return Calculated age as an integer.
*/
    
    private static Integer calculateAge(Date dob) {
        Date today = Date.today();
        Integer age = 0;
        
        if (dob != null) {
            age = today.year() - dob.year();
            
            if (today.month() < dob.month() || (today.month() == dob.month() && today.day() < dob.day())) {
                age--;
            }
        }
        
        return age;
    }
    
    /*
* @description Formats a Date value to DDMMYYYY string format.
* @param dob - Date of birth.
* @return Formatted date string.
*/
    
    private static String formatDateDDMMYYYY(Date dob) {
        
        String formattedDate = '';
        
        if (dob != null) {
            String day = dob.day() < 10 ? '0' + dob.day() : String.valueOf(dob.day());
            String month = dob.month() < 10 ? '0' + dob.month() : String.valueOf(dob.month());
            String year = String.valueOf(dob.year());
            
            formattedDate = day + month + year;
        }
        
        return formattedDate;
    }
    
    /*
* @description Processes the CIBIL API response and stores verification and document records.
* Creates E_Verification__c records based on finished or rejected responses.
* @param responseBody - API response body as string.
* @param applicationId - Salesforce Id of the Loan Application.
*/
    
    private static void processResponse(String responseBody, String applicationId,String loanApplicantId) {
        try{
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {E_Verification__c.SObjectType});
            
            List<Application__c> listOfApplication = new SHF_ApplicationSelector().listOfselectApplicationForCIBIL(applicationId);
            if (listOfApplication.isEmpty()) return;
            
            Id applicationRecordId = listOfApplication[0].Id;
            String applicationName = listOfApplication[0].Name;
            
            // Id eVerificationRecordTypeId = SHF_CommonUtil.selectRecordTypeId('E_Verification__c', 'CIBIL_CRIF_Bureau_Individual');
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            Map<String, String> bureauToJsonMap = new Map<String, String>();
            List<Document__c> documentsToInsert = new List<Document__c>();
            
            Map<Document__c, String> docToBase64Map = new Map<Document__c, String>();
            
            
            String status = (String) responseMap.get('STATUS');
            
            List<Object> finishedList = (List<Object>) (responseMap.containsKey('FINISHED') && responseMap.get('FINISHED') != null ? responseMap.get('FINISHED') : new List<Object>());
            
            List<Object> rejectList = (List<Object>) (responseMap.containsKey('REJECT') && responseMap.get('REJECT') != null ? responseMap.get('REJECT') : new List<Object>());
            Map<String, Document__c> fileNameToDocMap = new Map<String, Document__c>();
            
            List<Document__c> existingDocs = [SELECT Id, File_Name__c FROM Document__c WHERE Application__c = :applicationRecordId AND Loan_Applicant__c = :loanApplicantId AND Document_Category__c = 'Others'];
            
            for (Document__c d : existingDocs) {
                fileNameToDocMap.put(d.File_Name__c, d);
            }
            
            
            List<E_Verification__c> verificationRecords = new List<E_Verification__c>();
            //List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            if(finishedList != null && !finishedList.isEmpty()){
                for (Object item : finishedList) {
                    Map<String, Object> itemMap = (Map<String, Object>) item;
                    
                    
                    String bureau = (String) itemMap.get('BUREAU');
                    String bureauString = (String) itemMap.get('BUREAU-STRING');
                    
                    if (String.isNotBlank(bureauString)) {
                        bureauToJsonMap.put(bureau, bureauString);
                    }
                    
                    String encodedPdf = (String) itemMap.get('ENCODED STRING');
                    String fileName = itemMap.get('BUREAU') + ' Report';
                    Document__c doc;
                    if (!String.isEmpty(encodedPdf)) {
                        // ContentVersion contentVersion = new ContentVersion();
                        // contentVersion.Title = applicationName + '_' + itemMap.get('PRODUCT');
                        // contentVersion.PathOnClient = applicationName + '_' + itemMap.get('PRODUCT') + '.pdf';
                        // contentVersion.VersionData = EncodingUtil.base64Decode(encodedPdf);
                        // contentVersion.FirstPublishLocationId = applicationRecordId;
                        
                        // contentVersions.add(contentVersion);
                        if (fileNameToDocMap.containsKey(fileName)) {
                            doc = fileNameToDocMap.get(fileName);
                        }
                        else {
                            doc = new Document__c(
                                Application__c = applicationRecordId,
                                Loan_Applicant__c = loanApplicantId,
                                File_Name__c = fileName,
                                Document_Source__c = 'API',
                                Document_Category__c = 'Others',
                                Status__c = 'Uploaded',
                                Stage__c = 'QDE',
                                Document_Received_Date__c = System.today()
                            );
                            documentsToInsert.add(doc);
                            fileNameToDocMap.put(fileName, doc); 
                        }
                        docToBase64Map.put(doc, encodedPdf);
                    }
                }
                if (!documentsToInsert.isEmpty()) {
                    insert documentsToInsert;        
                }
                for (Document__c document : docToBase64Map.keySet()) {
                    System.enqueueJob(new SHF_CIBILCRIFDMS_Queueable(document.File_Name__c,docToBase64Map.get(document),applicationRecordId,document.Id));
                }
                
            }
            if (rejectList != null && !rejectList.isEmpty()) {
                
                for (Object item : rejectList) {
                    Map<String, Object> itemMap = (Map<String, Object>) item;
                    
                    List<Object> errors = (List<Object>) itemMap.get('ERRORS');
                    String combinedErrors = '';
                    
                    // Store the entire errors block as JSON string 
                    if (errors != null && !errors.isEmpty()) {
                        combinedErrors = JSON.serialize(errors);
                    }
                    
                    String subStatus = (String) itemMap.get('STATUS');
                    
                    E_Verification__c verificationRecord = new E_Verification__c();
                    verificationRecord.RecordTypeId =  ((String) itemMap.get('BUREAU') == SHF_ConstantsUtil.CIBIL ? SHF_ConstantsUtil.CIBIL_RECORDTYPE_ID : ((String) itemMap.get('BUREAU') == SHF_ConstantsUtil.HIGHMARK ? SHF_ConstantsUtil.CRIF_RECORDTYPE_ID : null) );
                    verificationRecord.Status__c = deriveFinalStatus(subStatus, status);
                    verificationRecord.Bureau_Status__c = status;
                    verificationRecord.Sub_Status__c = subStatus;
                    verificationRecord.Loan_Application__c = applicationRecordId;
                    verificationRecord.Loan_Applicant__c = loanApplicantId;
                    verificationRecord.Error_Message__c = combinedErrors;
                    verificationRecord.Description__c = (String) itemMap.get('BUREAU');
                    
                    verificationRecords.add(verificationRecord);
                }
            }
            
            
            // Insert PDF files
            //if (!contentVersions.isEmpty()) {insert contentVersions;}
            
            // Calling processCibilObligations
            if (bureauToJsonMap.containsKey('CIBIL')) {
                system.debug('in processCibilObligations');
                processCibilObligations(bureauToJsonMap.get('CIBIL'), applicationRecordId, 'CIBIL',loanApplicantId);
                
                //create e-verification record for Crif
                E_Verification__c verificationRecord = new E_Verification__c();
                verificationRecord.RecordTypeId = SHF_ConstantsUtil.CIBIL_RECORDTYPE_ID;
                verificationRecord.Bureau_Status__c = status;
                verificationRecord.Status__c = deriveFinalStatus(null, status);
                verificationRecord.Loan_Application__c = applicationRecordId;
                verificationRecord.Loan_Applicant__c = loanApplicantId;
                verificationRecord.Description__c = SHF_ConstantsUtil.CIBIL ;
                verificationRecords.add(verificationRecord);
            }
            
            //  processHighmarkObligations
            if (bureauToJsonMap.containsKey('HIGHMARK')) {
                String xmlString = bureauToJsonMap.get('HIGHMARK');
                
                String cleanedXML = SHF_XmlToJsonParser.removePrintableReport(xmlString);
                system.debug('cleanedXML > ' + cleanedXML);
                String IndRepostData = SHF_XmlToJsonParser.convertXmlToJson(cleanedXML);
                system.debug('IndRepostData > ' + IndRepostData);
                
                //added by mansur
                String scoreValue = '';
                String newAccountsIn6Months = '';
                String primaryNumberOfAccounts = '';
                Integer AvgMaxDPD = 0;
                Integer crdCount = 0;
                Integer plnCount = 0;
                Integer nbfCount = 0;
                Integer inquiryCount = 0;
                Integer currentBal = 0;
                Integer currentBalcount = 0;
                Integer responseListSize = 0;
                Set<String> nbfSet = new Set<String>();
                Set<String> crdSet = new Set<String>();
                Set<String> plnSet = new Set<String>();
                boolean creditBureauException1 = false;
                boolean creditBureauException2 = false;
                boolean creditBureauDeviation = false;
                //query the metadata 
                For(SHF_Risk_Score__mdt riskScoreMdt:  [SELECT Id,ACCT_TYPE__c,Credit_Card__c,NBF_Type__c,PLN_Type__c FROM SHF_Risk_Score__mdt ]){
                    if(riskScoreMdt.NBF_Type__c == SHF_ConstantsUtil.NBF){
                        nbfSet.add(riskScoreMdt.ACCT_TYPE__c);
                    }
                    if(riskScoreMdt.Credit_Card__c == SHF_ConstantsUtil.CRD){
                        crdSet.add(riskScoreMdt.ACCT_TYPE__c);
                    }
                    if(riskScoreMdt.PLN_Type__c == SHF_ConstantsUtil.PLN){
                        plnSet.add(riskScoreMdt.ACCT_TYPE__c);
                    }
                }
                // Fetch custom setting map
                Map<String, SObject> productTypeMap = SHF_CommonUtil.getCustomSettingMap('CIBIL_CRIF_Bureau_Product_Type__c');
                List<Obligation__c> obligationsToInsert = new List<Obligation__c>();
                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(IndRepostData);
                //Map<String, Object> file = (Map<String, Object>) root.get('INDV-REPORT-FILE');
                Map<String, Object> reports = (Map<String, Object>) root.get('INDV-REPORTS');
                Map<String, Object> report = (Map<String, Object>) reports.get('INDV-REPORT');
                
                //Extract LOAN-DETAILS***********
                Map<String, Object> responses = (Map<String, Object>) report.get('RESPONSES');
                if (responses != null && responses.containsKey('RESPONSE')) {
                    
                    List<Object> responseList = (List<Object>) responses.get('RESPONSE');
                    responseListSize = responseList.size();
                    if(!responseList.isEmpty()){
                        for (Object r : responseList) {
                            Map<String, Object> responseMapData = (Map<String, Object>) r;
                            if(responseMapData.containsKey('LOAN-DETAILS')){
                                Map<String, Object> loanDetails = (Map<String, Object>) responseMapData.get('LOAN-DETAILS');
                                
                                if (loanDetails != null) {
                                    String accountType = '';
                                    Obligation__c obl = new Obligation__c();
                                    obl.Tradeline__c = JSON.serialize(loanDetails); // storing trdline into the longtext area 
                                    obl.Application__c = applicationId;
                                    obl.Loan_Applicant__c = loanApplicantId;
                                    obl.Source__c = 'CRIF';
                                    obl.Loan_Id__c = (String) loanDetails.get('ACCT-NUMBER');
                                    obl.Loan_Status__c = (String) loanDetails.get('ACCOUNT-STATUS');
                                    obl.Tenor__c = String.valueOf(loanDetails.get('ORIGINAL-TERM'));
                                    if (loanDetails.containsKey('INSTALLMENT-AMT')){
                                        String instAmount = String.valueOf(loanDetails.get('INSTALLMENT-AMT')).replaceAll('[^0-9]', '');
                                        obl.EMI__c = Decimal.valueOf(instAmount);
                                    }
                                    if (loanDetails.containsKey('CURRENT-BAL')){
                                        Boolean isCurrentBalance = isTradlinLiesBetweenMonths((String)loanDetails.get('DATE-REPORTED'),18 );
                                        if(isCurrentBalance){
                                            currentBal = currentBal + Integer.valueOf(String.valueOf(loanDetails.get('CURRENT-BAL')).replaceAll('[^0-9]', ''));
                                            currentBalcount++;
                                        }
                                        
                                        obl.Outstanding_Amount__c = Decimal.valueOf(String.valueOf(String.valueOf(loanDetails.get('CURRENT-BAL')).replaceAll('[^0-9]', '')));
                                    }
                                    if (loanDetails.containsKey('DISBURSED-AMT')){
                                        obl.Sanctioned_Amount__c = Decimal.valueOf(String.valueOf(String.valueOf(loanDetails.get('DISBURSED-AMT'))).replaceAll('[^0-9]', ''));
                                    }
                                    if (loanDetails.containsKey('ACCT-TYPE')) {
                                        accountType = String.valueOf(loanDetails.get('ACCT-TYPE'));
                                        if (productTypeMap.containsKey(accountType)) {
                                            CIBIL_CRIF_Bureau_Product_Type__c customSetting = (CIBIL_CRIF_Bureau_Product_Type__c) productTypeMap.get(accountType);
                                            obl.Product__c = customSetting.Value__c;
                                        }
                                        //Total PLN Tradelines in last 6 months
                                        if(plnSet.contains(accountType)){
                                            Boolean isPLN = isTradlinLiesBetweenMonths((String)loanDetails.get('DATE-REPORTED'),6 );
                                            if(isPLN){
                                                plnCount ++;
                                            }
                                        }
                                        //Total CRD Tradelines in Last 12 Months
                                        if(crdSet.contains(accountType)){
                                            Boolean isCRD = isTradlinLiesBetweenMonths((String)loanDetails.get('DATE-REPORTED'),12);
                                            if(isCRD){
                                                crdCount ++;
                                            }
                                        }
                                        //Average utilization for NBF in last 24 months
                                        if(nbfSet.contains(accountType)){
                                            Boolean isNbf = isTradlinLiesBetweenMonths((String)loanDetails.get('DATE-REPORTED'),24);
                                            if(isNbf){
                                                nbfCount ++;
                                            }
                                        }
                                    }
                                    if (loanDetails.containsKey('COMBINED-PAYMENT-HISTORY')) {
                                        String combinedPaymentHistory = (String) loanDetails.get('COMBINED-PAYMENT-HISTORY');
                                        //parsing dpd
                                        if (!String.isBlank(combinedPaymentHistory)){
                                            Integer MaxDPD = Integer.valueOf(parseDPDForMaxDPD(combinedPaymentHistory));
                                            obl.DPD__c  = String.valueOf(AvgMaxDPD);
                                            //parsing Average Max DPD with in 15th months
                                            if(AvgMaxDPD < MaxDPD){
                                                AvgMaxDPD = MaxDPD;
                                            }
                                            //parsing DPD to fetch max DPD value.
                                            if(!creditBureauException1){
                                                decimal dpdValueInYears = parseDPDForValue(combinedPaymentHistory);
                                                if(!SHF_ConstantsUtil.loanSetforSuperCondition.contains(accountType)){
                                                    if(dpdValueInYears > 2){
                                                        creditBureauException1 = true;
                                                    }else{
                                                        if(SHF_ConstantsUtil.loanSet.contains(accountType)){
                                                            creditBureauException2 = true;
                                                        } else{
                                                            creditBureauDeviation = true;
                                                        }
                                                    }
                                                }
                                            }
                                            
                                        }
                                        
                                    }
                                    obligationsToInsert.add(obl);
                                }
                                
                            }
                        }
                    }
                }
                
                if (!obligationsToInsert.isEmpty()) {
                    insert obligationsToInsert;
                }
                
             /*   //Extract SCORE-VALUE******************
                if(report.containsKey('SCORES')){
                    Map<String, Object> scores = (Map<String, Object>) report.get('SCORES');
                    if(scores.containsKey('SCORE')){
                        Map<String, Object> score = (Map<String, Object>) scores.get('SCORE');
                        if(score.containsKey('SCORE-VALUE')){
                            scoreValue = (String) score.get('SCORE-VALUE');
                        }
                    }
                }*/
                
                if(report.containsKey('INQUIRY-HISTORY')){
                    Map<String, Object> inquiryHistory = (Map<String, Object>) report.get('INQUIRY-HISTORY');
                    if(inquiryHistory.containsKey('HISTORY')){
                        List<Object> historyList = (List<Object>) inquiryHistory.get('HISTORY');
                        if(!historyList.isEmpty()){
                            for (Object obj : historyList) {
                                Map<String, Object> record = (Map<String, Object>) obj;
                                String purpose = (String) record.get('PURPOSE');
                                String inquiryDate = (String) record.get('INQUIRY-DATE');
                                boolean isInquiry = isTradlinLiesBetweenMonths(inquiryDate,6 );
                                if(isInquiry && purpose != SHF_ConstantsUtil.CRD){
                                    inquiryCount ++;
                                }
                                System.debug('Purpose: ' + purpose);
                            }
                        }
                    }
                }
                
                
                if(report.containsKey('ACCOUNTS-SUMMARY')){
                    Map<String, Object> accountSummary = (Map<String, Object>) report.get('ACCOUNTS-SUMMARY');
                    // Extract PRIMARY-NUMBER-OF-ACCOUNTS******************
                    if(accountSummary.containsKey('PRIMARY-ACCOUNTS-SUMMARY')){
                        Map<String, Object> primarySummary = (Map<String, Object>) accountSummary.get('PRIMARY-ACCOUNTS-SUMMARY');
                        if(primarySummary.containsKey('PRIMARY-NUMBER-OF-ACCOUNTS')){
                            primaryNumberOfAccounts = (String) primarySummary.get('PRIMARY-NUMBER-OF-ACCOUNTS');
                        }
                    }
                    //Extract NEW-ACCOUNTS-IN-LAST-SIX-MONTHS**********
                    if(accountSummary.containsKey('DERIVED-ATTRIBUTES')){
                        Map<String, Object> derivedAttributes =(Map<String, Object>) accountSummary.get('DERIVED-ATTRIBUTES'); 
                        if(derivedAttributes.containsKey('NEW-ACCOUNTS-IN-LAST-SIX-MONTHS')){
                            newAccountsIn6Months = (String) derivedAttributes.get('NEW-ACCOUNTS-IN-LAST-SIX-MONTHS');
                        }
                    }
                }               
                
                // Debug  the extracted values*********
                System.debug('SCORE VALUE = ' + scoreValue);
                System.debug('PRIMARY NUMBER OF ACCOUNTS = ' + primaryNumberOfAccounts);
                System.debug('NEW ACCOUNTS IN LAST 6 MONTHS = ' + newAccountsIn6Months);
                
                //create e-verification record for Crif
                E_Verification__c verificationRecord = new E_Verification__c();
                verificationRecord.RecordTypeId = SHF_ConstantsUtil.CRIF_RECORDTYPE_ID;
                verificationRecord.Bureau_Status__c = status;
                verificationRecord.Status__c = deriveFinalStatus(null, status);
                verificationRecord.Loan_Application__c = applicationRecordId;
                verificationRecord.Loan_Applicant__c = loanApplicantId;
                verificationRecord.Description__c = SHF_ConstantsUtil.HIGHMARK ;
                
                verificationRecord.Score__c = scoreValue;
                verificationRecord.Main_applicant_s_credit_score__c = scoreValue;
                verificationRecord.Total_PLN_Tradelines_in_last_6_months__c = String.valueOf(plnCount);
                verificationRecord.Primary_number_of_Accounts__c = primaryNumberOfAccounts;
                verificationRecord.Total_CRD_Tradelines_in_Last_12_Months__c = String.valueOf(crdCount);
                verificationRecord.Average_utilization_for_NBF_in_last_24_m__c =responseListSize != 0 ? String.valueOf(nbfCount/responseListSize) : '';
                verificationRecord.Number_of_enquires_by_Main_applicant__c = String.valueOf(inquiryCount);
                verificationRecord.New_Accounts_in_last_six_months__c = newAccountsIn6Months;
                verificationRecord.Maximum_DPD_in_CRIF_for_last_15_months__c = String.valueOf(AvgMaxDPD);
                verificationRecord.Average_Current_balance_in_last_18_month__c = currentBalcount != 0 ? String.valueOf(currentBal/currentBalcount) : '';
                
                verificationRecord.Credit_Bureau_Deviations__c = creditBureauDeviation ;
                verificationRecord.Credit_Bureau_Exception__c = creditBureauException1 ? creditBureauException1 : creditBureauException2;
                verificationRecords.add(verificationRecord);
            }   
            system.debug('verificationRecords >  ' + verificationRecords);
            // Commit verification records
            if (!verificationRecords.isEmpty()) {
                system.debug('verificationRecords size>  ' + verificationRecords.size());
                //insert verificationRecords;
                uow.registerNew(verificationRecords);
                uow.commitWork();
                Set<Loan_Applicant__c> updateApplicants = new Set<Loan_Applicant__c>();
                Loan_Applicant__c applicant = new Loan_Applicant__c();
                applicant.Id = loanApplicantId;
                for(E_Verification__c ver : verificationRecords){
                    if(ver.Id != null){
                        system.debug('veri recor >>> ' + ver.RecordTypeId);
                        if(ver.RecordTypeId == SHF_ConstantsUtil.CRIF_RECORDTYPE_ID ){
                            applicant.CRIF_Verification__c = ver.Id;
                        }else if(ver.RecordTypeId == SHF_ConstantsUtil.CIBIL_RECORDTYPE_ID){
                            applicant.CIBIL_Verification__c =  ver.Id;
                        }
                    }
                    Update applicant;
                }
            }   
            
            Logger.info('Start processResponse for Application Id: ' + applicationId);
            Logger.info('Response STATUS: ' + status);
            Logger.info('FINISHED size: ' + finishedList.size());
            Logger.info('REJECT size: ' + rejectList.size());
            Logger.info('bureauToJsonMap keys: ' + bureauToJsonMap.keySet());
            
        }catch(Exception e) {
            Logger.error('error '+e.getMessage());
            Logger.error('error> ' + e.getMessage()+' Line:- '+ e.getlineNumber());
            
            system.debug('error> ' + e.getMessage()+' Line:- '+ e.getlineNumber());
            
        }finally{
            Logger.saveLog();
        }
    }
    
    
    /*
* Processes bureau response JSON to create unique obligation records for the given application.
* Extracts, deduplicates, maps account data to products, and inserts obligations using Unit of Work.
* @param bureauResponseJson JSON response from the credit bureau.
* @param applicationId ID of the related Application__c record.
* @param bureau Name of the credit bureau (e.g., 'CIBIL' or 'HIGHMARK').
*/
    public static void processCibilObligations(String bureauResponseJson, Id applicationId, String bureau,String loanApplicantId) {       
        try {
            
            // Initialize Unit of Work for DML
            
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Obligation__c.SObjectType});
            
            //Deserialize the input JSON to a map
            //Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(bureauResponseJson);
            //List<Object> finishedList = (List<Object>) responseMap.get('FINISHED');
            //if (finishedList == null || finishedList.isEmpty()) {return;}
            
            if (bureau != 'CIBIL') {
                return; 
            }
            
            
            // Extract BUREAU-STRING JSON from the FINISHED block
            //Map<String, Object> finishedMap = (Map<String, Object>) finishedList[0];
            //String bureauStringJson = (String) finishedMap.get('BUREAU-STRING');
            
            // Deserialize the BUREAU-STRING JSON
            Map<String, Object> bureauMap = (Map<String, Object>) JSON.deserializeUntyped(bureauResponseJson);
            List<Object> consumerCreditDataList = (List<Object>) bureauMap.get('consumerCreditData');
            
            if (consumerCreditDataList == null || consumerCreditDataList.isEmpty()) {
                return;
            }
            
            Map<String, Object> consumerCreditData = (Map<String, Object>) consumerCreditDataList[0];
            List<Object> accountsList = (List<Object>) consumerCreditData.get('accounts');
            
            if (accountsList == null || accountsList.isEmpty()) {
                return;
            }
            
            
            // Deduplicate accounts based on unique key
            Set<String> uniqueKeys = new Set<String>();
            List<Map<String, Object>> uniqueAccounts = new List<Map<String, Object>>();
            
            for (Object accObj : accountsList) {
                Map<String, Object> accountMap = (Map<String, Object>) accObj;
                String uniqueKey = accountMap.get('accountType') + '_' + String.valueOf(accountMap.get('highCreditAmount')) + '_' + accountMap.get('dateOpened');
                
                if (uniqueKeys.add(uniqueKey)) {
                    uniqueAccounts.add(accountMap);
                }
            }
            
            
            // Prepare Custom Setting map
            Map<String, SObject> productTypeMap = SHF_CommonUtil.getCustomSettingMap('CIBIL_CRIF_Bureau_Product_Type__c');
            
            
            String source =  'CIBIL';
            List<Obligation__c> obligationsToInsert = new List<Obligation__c>();
            
            for (Map<String, Object> accountMap : uniqueAccounts) {
                String accountType = (String) accountMap.get('accountType');
                Decimal highCreditAmount = (Decimal) accountMap.get('highCreditAmount');
                Decimal emiAmount = (Decimal) accountMap.get('emiAmount');
                String accountNumber = (String) accountMap.get('accountNumber');
                String suitFiled = (String) accountMap.get('suitFiled');
                Integer paymentTenure = (Integer) accountMap.get('paymentTenure');
                Decimal currentBalance = (Decimal) accountMap.get('currentBalance');
                
                
                Obligation__c obligation = new Obligation__c();
                obligation.Application__c = applicationId;
                obligation.Loan_Applicant__c = loanApplicantId;
                obligation.Sanctioned_Amount__c = highCreditAmount;
                obligation.Source__c = source;
                obligation.EMI__c = emiAmount;
                obligation.Loan_Id__c = accountNumber;
                obligation.Loan_Status__c = suitFiled;
                obligation.Tenor__c = String.valueOf(paymentTenure);
                obligation.Outstanding_Amount__c = currentBalance;
                
                // Map account type to product using custom setting
                
                if (productTypeMap.containsKey(accountType)) {
                    CIBIL_CRIF_Bureau_Product_Type__c customSetting = (CIBIL_CRIF_Bureau_Product_Type__c) productTypeMap.get(accountType);
                    obligation.Product__c = customSetting.Value__c;                   
                }
                
                obligationsToInsert.add(obligation);
            }
            
            Logger.info('Start processCibilObligations for Application Id: ' + applicationId + ', Bureau: ' + bureau);
            Logger.info('Accounts before deduplication: ' + (accountsList != null ? accountsList.size() : 0));
            Logger.info('Accounts after deduplication: ' + uniqueAccounts.size());
            Logger.info('Obligations to insert: ' + obligationsToInsert.size());
            
            
            // Commit obligations records
            if (!obligationsToInsert.isEmpty()) {
                uow.registerNew(obligationsToInsert);
                uow.commitWork();
            } else {
                System.debug('### No obligations to insert');
            } 
            
        } catch(Exception e) {
            Logger.error('error '+e.getMessage());
            system.debug('error> ' + e.getMessage()+' Line:- '+ e.getlineNumber());
            
        }finally{
            Logger.saveLog();
        }
    }
    
    /*
* Creates Obligation__c records from HIGHMARK loan data.
* Maps ACCT-TYPE to Product__c using custom setting.
* Uses Unit of Work for efficient DML.
* @param applicationId Application__c record Id.
* @param loanDataList  Parsed HIGHMARK loan data.
* @param bureau        Bureau name ('HIGHMARK').
*/
    
    
    private static void processHighmarkObligations(Id applicationId, List<Map<String, Object>> loanDataList, String bureau) {
        try{
            
            if (loanDataList == null || loanDataList.isEmpty()) 
            {
                return;
            }  
            // Fetch custom setting map
            Map<String, SObject> productTypeMap = SHF_CommonUtil.getCustomSettingMap('CIBIL_CRIF_Bureau_Product_Type__c');
            
            // Initialize Unit of Work for DML
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Obligation__c.SObjectType});
            
            
            String source = (bureau == 'HIGHMARK') ? 'CRIF' : 'CIBIL';
            List<Obligation__c> obligationsToInsert = new List<Obligation__c>();
            
            for (Map<String, Object> loanData : loanDataList) {
                if (loanData == null || loanData.isEmpty()) continue;
                
                Obligation__c obl = new Obligation__c();
                obl.Application__c = applicationId;
                obl.Source__c = source;
                obl.Loan_Id__c = (String) loanData.get('ACCT-NUMBER');
                obl.Loan_Status__c = (String) loanData.get('ACCOUNT-STATUS');
                obl.Tenor__c = String.valueOf(loanData.get('ORIGINAL-TERM'));
                
                try {
                    if (loanData.containsKey('INSTALLMENT-AMT')){
                        obl.EMI__c = Decimal.valueOf(String.valueOf(loanData.get('INSTALLMENT-AMT')));
                    }
                    if (loanData.containsKey('CURRENT-BAL')){
                        obl.Outstanding_Amount__c = Decimal.valueOf(String.valueOf(loanData.get('CURRENT-BAL')));
                    }
                    if (loanData.containsKey('DISBURSED-AMT')){
                        obl.Sanctioned_Amount__c = Decimal.valueOf(String.valueOf(loanData.get('DISBURSED-AMT')));
                    }
                    
                } catch(Exception e) {
                    Logger.error('error '+e.getMessage());
                    system.debug('error> ' + e.getMessage()+' Line:- '+ e.getlineNumber());
                    
                }finally{
                    Logger.saveLog();
                }
                
                // Map account type to product using custom setting
                
                if (loanData.containsKey('ACCT-TYPE')) {
                    String accountType = String.valueOf(loanData.get('ACCT-TYPE'));
                    if (productTypeMap.containsKey(accountType)) {
                        CIBIL_CRIF_Bureau_Product_Type__c customSetting = (CIBIL_CRIF_Bureau_Product_Type__c) productTypeMap.get(accountType);
                        obl.Product__c = customSetting.Value__c;
                    }
                }
                
                obligationsToInsert.add(obl);
            }
            Logger.info('Start processHighmarkObligations for Application Id: ' + applicationId + ', Bureau: ' + bureau);
            Logger.info('Loan Data List size: ' + (loanDataList != null ? loanDataList.size() : 0));
            Logger.info('Obligations to insert: ' + obligationsToInsert.size());
            
            
            // Register and commit obligations using UOW
            
            if (!obligationsToInsert.isEmpty()) {
                uow.registerNew(obligationsToInsert);
                uow.commitWork();
            } else {
                System.debug('### No obligations to insert');
            }   
        }catch(Exception e) {
            Logger.error('error '+e.getMessage());
            system.debug('error> ' + e.getMessage()+' Line:- '+ e.getlineNumber());
            
        }finally{
            Logger.saveLog();
        }
    }
    
    public static String parseDPDForMaxDPD(String combinedPaymentData){
        Integer maxDPD = 0;
        // STEP 1: Build last 15 months list (MMM:YYYY format)
        Set<String> last15Months = new Set<String>();
        try{
            Date today = Date.today();
            for (Integer i = 0; i < Integer.valueOf(Label.dpd_last_N_months); i++) {
                Date d = today.addMonths(-i);
                
                // Convert Date → DateTime → format MMM
                String monthName = DateTime.newInstance(d.year(), d.month(), d.day()).format('MMM');
                
                String key = monthName + ':' + d.year();
                last15Months.add(key);
            }
            System.debug('Last 15 months: ' + last15Months);
            // STEP 2: Check if tradeline contains any of last 15 months
            Boolean foundRecent = false;
            List<String> entries = combinedPaymentData.split('\\|');
            for (String entry : entries) {
                if (String.isBlank(entry)) continue;
                // We check before parsing
                if (entry.contains(':')) {
                    String datePart = entry.split(',')[0]; // "Nov:2008"
                    if (last15Months.contains(datePart)) {
                        foundRecent = true;
                        break;
                    }
                }
            }
            
            if (!foundRecent) {
                System.debug('No month found in last 15 months → Skipping');
                return String.valueOf(maxDPD);
            }
            System.debug('Recent month found → Executing full parsing...');
            
            // STEP 3: Your original parsing logic
            for (String entry : entries) {
                if (String.isBlank(entry)) continue;
                List<String> parts = entry.split(',');
                if (parts.size() < 2) continue;
                String datePart = parts[0];   // "Nov:2008"
                String valuePart = parts[1];  // "123/045"
                
                // Extract month and year
                List<String> dateTokens = datePart.split(':');
                String monthName = dateTokens[0];
                String year = dateTokens.size() > 1 ? dateTokens[1] : null;
                
                // Extract amount and dpd
                List<String> valueTokens = valuePart.split('/');
                String amount = Pattern.matches('^[0-9]+$', valueTokens[0]) ? valueTokens[0] : '0';
                String dpd = valueTokens.size() > 1 ? (Pattern.matches('^[0-9]+$', valueTokens[0]) ?  valueTokens[0] : '0' /*getDPDValue(valueTokens[0])*/) : '0';
                
                System.debug('---- One Iteration ----');
                System.debug('Month: ' + monthName);
                System.debug('Year: ' + year);
                System.debug('Amount: ' + amount);
                System.debug('DPD: ' + dpd);
                
                // comparision
                if(maxDPD < Integer.valueOf(dpd)){
                    maxDPD = Integer.valueOf(dpd);
                }
            }
        }catch(exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
        }
        
        return String.valueOf(maxDPD);
    }
    
    public static decimal parseDPDForValue(String combinedPaymentData){
        boolean dpdValueMorethan = false;
        try{
            // STEP 1: Your original parsing logic
            List<String> entries = combinedPaymentData.split('\\|');
            for (String entry : entries) {
                if (String.isBlank(entry)) continue;
                List<String> parts = entry.split(',');
                if (parts.size() < 2) continue;
                String datePart = parts[0];   // "Nov:2008"
                String valuePart = parts[1];  // "123/045"
                
                // Extract month and year
                List<String> dateTokens = datePart.split(':');
                String monthName = dateTokens[0];
                String year = dateTokens.size() > 1 ? dateTokens[1] : null;
                
                // Extract amount and dpd
                List<String> valueTokens = valuePart.split('/');
                Decimal dpdValue = 0.00;
                if(Pattern.matches('^[0-9]+$', valueTokens[0])){
                    dpdValue = Decimal.valueOf(valueTokens[0]);
                }else{
                    // fetching metadata to check dpd value with the help of dpd code
                    Map<String, DPD_Values__mdt> dpdMetaMap = DPD_Values__mdt.getAll();
                    if(dpdMetaMap != null){
                        for(DPD_Values__mdt dpdmeta : dpdMetaMap.values()){
                            if(dpdmeta.Short_Name__c == valueTokens[0]){
                                dpdValue =  Decimal.valueOf(dpdmeta.max_Days__c);
                            }
                        }
                    }
                }
                
                return dpdValue/365;
                
            }
        }
        catch(exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
        }
        
        return 0;
    }
    
    public static Boolean isTradlinLiesBetweenMonths(String inputDateStr, Integer range){
        Boolean isWithinLast6Months = false;
        try{
            
            // Convert string date "dd-MM-yyyy" to Date
            List<String> tokens = inputDateStr.split('-');
            Date reportedDate = Date.newInstance(
                Integer.valueOf(tokens[2]), 
                Integer.valueOf(tokens[1]), 
                Integer.valueOf(tokens[0])
            );
            // Today
            Date today = Date.today();
            // Exact 6 months ago from today (same day of month)
            Date sixMonthsAgo = today.addMonths(- range);
            // Check within range
            isWithinLast6Months = (reportedDate >= sixMonthsAgo && reportedDate <= today);
        }catch(exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
        }
        return isWithinLast6Months;
        
    }
    
    private static String deriveFinalStatus(String subStatus, String bureauStatus) {
        if (String.isNotBlank(subStatus) && subStatus.equalsIgnoreCase('ERROR')) {
            return 'Failed';
        }
        return bureauStatus;
    }
    
    
    
}