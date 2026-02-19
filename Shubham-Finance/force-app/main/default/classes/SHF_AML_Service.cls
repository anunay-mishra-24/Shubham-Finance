/**
 * @File Name     : SHF_AML_Service.cls
 * @Description   : Service class to fetch AML (Anti-Money Laundering) details for a loan applicant.
 * @Author        : Kunal Soni
 *
 * ==============================================================================
 * Ver   Date          Author        Modification
 * ==============================================================================
 * 1.0   08-08-2025    Kunal Soni    Initial Version
 */
public class SHF_AML_Service {
    
    public SHF_HTTPCalloutService service;

    @AuraEnabled
    public static List<Loan_Applicant__c> getAllapplicants(Id applicationId) {
        if (applicationId == null) {
            return new List<Loan_Applicant__c>();
        }

        List<Loan_Applicant__c> applicants = [SELECT Id,AML_Verification__c, AML_Verification__r.AML_Request_Hash__c, Address__c, Address__r.Country__c, Address__r.State__c,
                                                          Address__r.City__c, Address__r.Address_Line_1__c, Address__r.Pincode__r.Name, Name, Entity_Name__c, Pan_Number__c, GST_Number__c,
                                                          Date_of_Birth__c, Date_Of_Incorporation1__c, Gender__c, Mobile_Number__c, Customer_Type__c FROM Loan_Applicant__c 
                                                          WHERE Application__c = :applicationId AND IsDeleted__c = false];

        return applicants;
    }
    
    public static String generateAccessToken() {
        SHF_AML_Service amlAccessToken = new SHF_AML_Service();
        amlAccessToken.service = new SHF_HTTPCalloutService('ALM_Access_Token');
        
        HttpResponse response;
        
        // Send API request only if the service is active
        if (amlAccessToken.service.getIsActive()) {
            response = amlAccessToken.service.sendRequest();
        }
        
        String responseBody = (response != null) ? response.getBody() : null;
        
        if (String.isBlank(responseBody)) {
            Logger.error('Access token API response is missing or invalid.');
            return null;
        }
        
        // Parse JSON response
        Map<String, Object> accessTokenMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        if (accessTokenMap.containsKey('data')) {
            Map<String, Object> dataMap = (Map<String, Object>) accessTokenMap.get('data');
            
            if (dataMap.containsKey('access_token')) {
                system.debug('access token - '+dataMap.get('access_token'));
                Logger.info('AML access token - ' + dataMap.get('access_token'));
                return (String) dataMap.get('access_token');
            }
        }
        
        return null;
    }
    
   
    /*====Fetches AML details for the given Loan Applicant====*/
    public static String fetchAMLDetails(Id applicantId) {
        
        String formattedDate;
        String incorporationFormattedDate;
        String message = '';
        Savepoint sp;
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('AML_API');
        
        try {
            // Prepare Unit of Work for record operations
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new Schema.SObjectType[] { E_Verification__c.SObjectType }
            );
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> { Loan_Applicant__c.SObjectType }
            );
            
            // Generate API Access Token
            String accessToken = SHF_AML_Service.generateAccessToken();
            system.debug('inside screanning access token  '+accessToken);
            if (String.isNotBlank(accessToken)) {
                
                // Fetch Loan Applicant Details
                List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ applicantId });
                Loan_Applicant__c applicant ;
                system.debug('loanAppList -- '+loanAppList);
                if (loanAppList.isEmpty()) {
                    Logger.error('Loan Applicant not found for Id: ' + applicantId);
                    return 'Loan Applicant not found';
                }
                else{
                    applicant = loanAppList[0];
                    
                }
                String applicantType = '';
                Boolean isIndividual = false;
                String appId = applicant.Id;
                if(appId.length() >=15 )
                {
                    appId = appId.subString(0,15);
                }
                
                String timeStamp = Datetime.now().format('ddMMyyHHmmss');
                String finalValue = appId + '-' + timeStamp;
                System.debug(finalValue);
                
                if(applicant.Customer_Type__c == 'Individual'){
                    applicantType = 'Individual';
                    isIndividual = true;
                }else{
                    applicantType = 'Organization';
                    isIndividual = false;
                }
                // Format DOB into dd-MM-yyyy format if available
                if (applicant.Date_of_Birth__c != null) {
                    List<String> parts = String.valueOf(applicant.Date_of_Birth__c).split('-');
                    formattedDate = parts[2] + '-' + parts[1] + '-' + parts[0];
                }
                //Format Date_Of_Incorporation1__c into DD-MM-YYYY by Ranjeet
                if(applicant.Date_Of_Incorporation1__c!=null){
                    List<String> parts = String.valueOf(applicant.Date_Of_Incorporation1__c).split('-');
                    incorporationFormattedDate = parts[2] + '-' + parts[1] + '-' + parts[0];
                }
                
                // Initialize HTTP Service for AML API
                SHF_AML_Service amlService = new SHF_AML_Service();
                amlService.service = new SHF_HTTPCalloutService('AML_API');
                amlService.service.setHeaderParameter('Authorization', 'Bearer '+ accessToken);
                
                // Replace Request Body Placeholders with Applicant Data
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<applicantName>', isIndividual ? applicant.Name : applicant.Entity_Name__c));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<panNumber>', applicant.Pan_Number__c != null ? applicant.Pan_Number__c : ''));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<applicantId>', finalValue != null ? finalValue : ''));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<gst>', isIndividual ? '' : applicant.GST_Number__c != null ? '"'+applicant.GST_Number__c+'"' : ''));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<phoneNumber>', applicant.Mobile_Number__c != null ? applicant.Mobile_Number__c : ''));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<gender>', isIndividual ? applicant.Gender__c : ''));
                // amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<gender>', ''));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<dob>', isIndividual ? formattedDate != null ? formattedDate : '' : ''));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<passport>', isIndividual ? applicant.Passport_File_Number__c != null ? applicant.Passport_File_Number__c : '' : ''));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<doi>', !isIndividual ? incorporationFormattedDate != null ? incorporationFormattedDate: '' : ''));//Changed date format by Ranjeet
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<type>', applicantType));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<country>', String.isNotBlank(applicant.Address__c) ? applicant.Address__r?.Country__c != null ? applicant.Address__r.Country__c : 'India' : 'India'));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<state>', String.isNotBlank(applicant.Address__c) ? applicant.Address__r?.State__c != null ? applicant.Address__r.State__c : '' : ''));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<city>', String.isNotBlank(applicant.Address__c) ? applicant.Address__r?.City__c != null ? applicant.Address__r.City__c : '' : ''));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<address>', String.isNotBlank(applicant.Address__c) ? applicant.Address__r?.Address_Line_1__c != null ? applicant.Address__r.Address_Line_1__c : '' : ''));
                amlService.service.setRequestBody(amlService.service.getRequestBody().replace('<zipCode>', String.isNotBlank(applicant.Address__c) ? applicant.Address__r?.Pincode__c != null ? applicant.Address__r.Pincode__r.Name : '' : ''));
                
                // Call API or return mock response if inactive
                system.debug('amlService.service request - '+amlService.service.getRequestBody());
                HttpResponse response;
                if (amlService.service.getIsActive()) {
                    response = amlService.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setStatusCode(200);
                    response.setBody(amlService.service.getmockRespnse());
                }
                
                // Create E-Verification Record
                E_Verification__c eVerification = SHF_CommonUtil.createVerfication(
                                                   applicantId,
                                                   SHF_ConstantsUtil.AML_RECORD_TYPE,
                                                   SHF_ConstantsUtil.PENDING
                    );
                
                // Handle API Response
                system.debug('aml response - '+response);
                system.debug('aml response getBody - '+response.getBody());
                system.debug('aml response sttus code - '+response.getStatusCode());
                Logger.info('data value getBody response- '+response.getBody());
                Logger.info('data value getBody request - '+amlService.service.getRequestBody());
                    
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    Logger.info('data value getBody- '+response.getBody());
                    
                    Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    System.debug('rootMap - '+rootMap);
                    if (rootMap.containsKey('data')) {
                        System.debug('rootMap.get - '+rootMap.get('data'));
                        String errorMessage = String.valueof(rootMap.get('data'));
                        System.debug('errorMessage - '+errorMessage);
                        Logger.info('data value - '+errorMessage);
                        if(errorMessage.contains('CustomerID Already Exists')){
                            message = errorMessage;
                            return message;
                        }
                        Map<String, Object> dataMap = (Map<String, Object>) rootMap.get('data');
                        
                        if (dataMap.containsKey('Case_Outcome')) {
                            Map<String, Object> caseMap = (Map<String, Object>) dataMap.get('Case_Outcome');
                            
                            // Extract Score
                            if (caseMap.containsKey('Score')) {
                                eVerification.Score__c = String.valueOf(caseMap.get('Score'));
                            } else {
                                eVerification.Status__c = SHF_ConstantsUtil.PENDING;
                                message = messageConfigMap.get('AML_API_Error').Message__c;
                            }
                            
                            // Extract Status
                            if (caseMap.containsKey('Status')) {
                                eVerification.Status__c = SHF_ConstantsUtil.COMPLETEDSTATUS;
                                eVerification.Sub_Status__c = String.valueOf(caseMap.get('Status'));
                                //Added by Ranjeet for SHF - 1224 AML
                                String amlHash = SHF_AML_Service.buildAMLRequestHash(applicant);
                                eVerification.AML_Request_Hash__c = amlHash;
                            } else {
                                eVerification.Status__c = SHF_ConstantsUtil.PENDING;
                                message = messageConfigMap.get('AML_API_Error').Message__c;
                            }
                        } else {
                            eVerification.Status__c = SHF_ConstantsUtil.PENDING;
                            message = messageConfigMap.get('AML_API_Error').Message__c;
                        }
                    } else {
                        eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                        message = messageConfigMap.get('AML_API_Error').Message__c;
                    }
                    
                    message = messageConfigMap.get('AML_API_Success').Message__c;
                    Logger.info('Request Body: ' + amlService.service.getRequestBody());
                } else if (response.getStatusCode() == 400 && String.isNotBlank(response.getBody())){
                    Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    System.debug('rootMap - '+rootMap);
                    if (rootMap.containsKey('data')) {
                        String errorMessage = String.valueof(rootMap.get('data'));
                        System.debug('errorMessage - '+errorMessage);
                        Logger.info('data value - '+errorMessage);
                        if(errorMessage.contains('CustomerID Already Exists')){
                            message = errorMessage;
                            return message;
                        }
                    }
                }
                else {
                    eVerification.Status__c = SHF_ConstantsUtil.PENDING;
                    message = messageConfigMap.get('AML_API_Error').Message__c;
                    Logger.error('Request Body: ' + amlService.service.getRequestBody());
                }
                
                // Commit records in Unit of Work
                if (eVerification != null) {
                    uow.registerNew(eVerification);
                    uow.commitWork();
                    
                    loanAppList[0].AML_Verification__c = eVerification.Id;
                    applicantUow.registerDirty(loanAppList);
                    applicantUow.commitWork();
                    
                    Logger.info('Status Code: ' + response.getStatusCode());
                    Logger.info('Status: ' + response.getStatus());
                    Logger.info('Body: ' + response.getBody());
                }
            }
        } catch (Exception ex) {
            if (sp != null) Database.rollback(sp);
            Logger.error('AML Verification Error: ' + ex.getMessage() + ex.getLineNumber());
            message = 'Getting error while calling AML Verification API. Please contact your system administrator.';
        } finally {
            Logger.saveLog();
        }
        
        return message;
    }

    // START - Added by Ranjeet for SHF -1224 AML Verification
    @AuraEnabled
    public static String buildAMLRequestHash(Loan_Applicant__c applicant) {
       if (applicant == null) return null;
        try{
           String country     = applicant.Address__c != null ? safeString(applicant.Address__r.Country__c) : '';
           String state       = applicant.Address__c != null ? safeString(applicant.Address__r.State__c) : '';
           String city        = applicant.Address__c != null ? safeString(applicant.Address__r.City__c) : '';
           String addressLine = applicant.Address__c != null ? safeString(applicant.Address__r.Address_Line_1__c) : '';
           String pincode     = (applicant.Address__c != null && applicant.Address__r.Pincode__c != null) ? safeString(applicant.Address__r.Pincode__r.Name) : '';
       
           String amlSignature = String.join(new List<String>{
               safeString(applicant.Customer_Type__c),        
               safeString(applicant.Name),
               safeString(applicant.Entity_Name__c),
               safeString(applicant.Pan_Number__c),
               safeString(applicant.GST_Number__c),
               String.valueOf(applicant.Date_of_Birth__c),
               String.valueOf(applicant.Date_Of_Incorporation1__c),
               safeString(applicant.Gender__c),
               safeString(applicant.Mobile_Number__c),
               country,
               state,
               city,
               addressLine,
               pincode
           }, '|');
       
           // SHA-256 hash
           return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(amlSignature)));
       }
       catch(Exception e){
           System.debug('Exception in buildAMLRequestHash: '+e.getMessage());
           return null;
       }
    }

    @AuraEnabled
    public static String amlAutoTrigger(Id applicantId) {
        String message = '';
        if (applicantId == null) {
            throw new AuraHandledException('Applicant Id is required');
        }
        Loan_Applicant__c amlApplicant = [SELECT Id, AML_Verification__c, AML_Verification__r.AML_Request_Hash__c, Address__c, Address__r.Country__c, Address__r.State__c,
                                                          Address__r.City__c, Address__r.Address_Line_1__c, Address__r.Pincode__r.Name, Name, Entity_Name__c, Pan_Number__c, GST_Number__c,
                                                         Date_of_Birth__c, Date_Of_Incorporation1__c, Gender__c, Mobile_Number__c, Customer_Type__c FROM Loan_Applicant__c 
                                                         WHERE Id = :applicantId AND IsDeleted__c = false];

        String newHash = SHF_AML_Service.buildAMLRequestHash(amlApplicant);
         
        if(amlApplicant.AML_Verification__c == null){
            System.debug('applicantAmlVerificationFirstTime==>'+amlApplicant);
            message = fetchAMLDetails(amlApplicant.Id);
            return message;
        }
        if(newHash != null && newHash != amlApplicant.AML_Verification__r.AML_Request_Hash__c){
            System.debug('AmlVerification2ndTime==>'+amlApplicant);
            message = fetchAMLDetails(amlApplicant.Id);
        }
        return message;
    }

    private static String safeString(String val) {
        return val == null ? '' : val.trim();
    }
   // END - Added by Ranjeet for SHF -1224 AML Verification
}