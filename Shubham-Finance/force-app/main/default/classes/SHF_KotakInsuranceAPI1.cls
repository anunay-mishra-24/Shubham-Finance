/*
* @File Name       : SHF_KotakInsuranceAPI.cls
* @Author          : Preeti
* @Created Date    : Sept 19, 2025
* @Description     : This class handles integration with the Kotak Insurance API. 
*                    It provides methods to generate authorization tokens, build dynamic
*                    request payloads, calculate insurance premiums, and update E-Verification 
*                    records with the API response. It supports both live API calls and 
*                    mock responses via metadata configuration.
* @Last Modified By: Preeti
* @Last Modified On: Sept 19, 2025
* @Modification Log:
*==============================================================================
* Ver | Date       | Author | Modification
*==============================================================================
* 1.0 | Sept-19-25  | Preeti | Initial Version
*/



public class SHF_KotakInsuranceAPI1 {
    
    
    /*
* @description Generates an authorization token for Kotak Insurance API.
*              Uses metadata configuration to determine whether to use a live API call or a mock response.
* @return String - Generated token ID if successful, otherwise null.
*/
    
    
    // Generate Auth Token
    public static String generateAccessToken() {
        String tokenId;
        try {
            Callout_Framework__mdt tokenConfiguration = SHF_CommonUtil.getCalloutMetadata('Kotak_Insurance_Access_Token').get('Kotak_Insurance_Access_Token');
            
            if (tokenConfiguration == null) {
                logger.error('Auth config not found.');
                return null;
            }
            
            // If inactive then use mock response from metadata instead of calling API
            if (!tokenConfiguration.Active__c) {
                logger.info('Using MOCK Auth Token response from metadata');
                if (String.isBlank(tokenConfiguration.Mock_Response__c)) {
                    logger.error('Mock response not configured in metadata for Auth Token');
                    return null;
                }
                Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(tokenConfiguration.Mock_Response__c);
                if (respMap.containsKey('TokenDetails')) {
                    Map<String, Object> tokenDetails = (Map<String, Object>) respMap.get('TokenDetails');
                    if (tokenDetails.containsKey('TokenId')) {
                        tokenId = String.valueOf(tokenDetails.get('TokenId'));
                    }
                }
                return tokenId;
            }
            
            // If active then hit the actual API
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(tokenConfiguration.Endpoint__c);
            req.setMethod(tokenConfiguration.HTTP_Method__c);
            req.setTimeout(60000);
            
            if (String.isNotBlank(tokenConfiguration.HeaderParams__c)) {
                Map<String, Object> headers =
                    (Map<String, Object>) JSON.deserializeUntyped(tokenConfiguration.HeaderParams__c);
                for (String key : headers.keySet()) {
                    req.setHeader(key, String.valueOf(headers.get(key)));
                }
            }
            
            HttpResponse res = http.send(req);
            logger.info('Auth Response Code: ' + res.getStatusCode());
            logger.info('Auth Response Body: ' + res.getBody());
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (respMap.containsKey('TokenDetails')) {
                    Map<String, Object> tokenDetails = (Map<String, Object>) respMap.get('TokenDetails');
                    if (tokenDetails.containsKey('TokenId')) {
                        tokenId = String.valueOf(tokenDetails.get('TokenId'));
                    }
                }
            }
            return tokenId;
        } catch (Exception e) {
            logger.error('Auth API Error: ' + e.getMessage());
            return null;
        } finally {
            logger.saveLog();
        }
    }
    
    
    /*
* @description Calculates the insurance premium for a given applicant and application.
*              Uses the provided authorization token and sends a request to Kotak API or 
*              returns a mock response if configured.
*              Updates the E-Verification record with the API response.
* @param token           - Authorization token for Kotak API.
* @param eVerificationId - Salesforce Id of the E-Verification record.
* @param application     - Application record associated with the applicant.
* @param applicant       - Loan Applicant record.
* @return String - API response body or error message.
*/
    
    public static String calculatePremium(String token, Id eVerificationId,Application__c application,Loan_Applicant__c applicant) {
        String responseBody = '';
        try {
            Callout_Framework__mdt requestConfiguration = SHF_CommonUtil.getCalloutMetadata('Kotak_Insurance_Request').get('Kotak_Insurance_Request');
            
            if (requestConfiguration == null) {
                logger.error('CalculatePrem config not found.');
                return null;
            }
            
            // If inactive then use mock response from metadata instead of calling API
            if (!requestConfiguration.Active__c) {
                logger.info('Using MOCK Premium response from metadata');
                if (String.isBlank(requestConfiguration.Mock_Response__c)) {
                    logger.error('Mock response not configured in metadata for Premium API');
                    return null;
                }
                responseBody = requestConfiguration.Mock_Response__c;
                if (eVerificationId != null) {
                    updateEVerification(responseBody, eVerificationId);
                }
                return responseBody;
            }
            
            // If token is missing then stop here
            if (String.isBlank(token)) {
                logger.error('Token generation failed.');
                return null;
            }
            
            // If active then hit the actual API
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(requestConfiguration.Endpoint__c);
            req.setMethod(requestConfiguration.HTTP_Method__c);
            req.setTimeout((Integer) requestConfiguration.Timeout_Time__c);
            
            if (String.isNotBlank(requestConfiguration.HeaderParams__c)) {
                Map<String, Object> headers =
                    (Map<String, Object>) JSON.deserializeUntyped(requestConfiguration.HeaderParams__c);
                for (String key : headers.keySet()) {
                    String value = String.valueOf(headers.get(key));
                    if (value == '${token}') {
                        value = token;
                    }
                    req.setHeader(key, value);
                }
            }
            
            String dynamicBody = buildDynamicRequest(eVerificationId,application,applicant,requestConfiguration);
            System.debug('dynamicBody###===='+dynamicBody);
            logger.info('Premium API Request Body: ' + dynamicBody);

            req.setBody(dynamicBody);
            
            HttpResponse res = http.send(req);
            responseBody = res.getBody();
            
            logger.info('CalcPrem Response Code: ' + res.getStatusCode());
            logger.info('CalcPrem Response Body: ' + responseBody);
            
            if (res.getStatusCode() == 200 && eVerificationId != null) {
                updateEVerification(responseBody, eVerificationId);
            }
            
            return responseBody;
        } catch (Exception e) {
            logger.error('Error in calculatePremium: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        } finally {
            logger.saveLog();
        }
    }
    
    /*
* @description Builds the dynamic JSON request body for the Kotak Insurance API.
*              Replaces placeholders in the request template with actual values from
*              applicant and application records.
* @param eVerificationId - Salesforce Id of the E-Verification record.
* @param application     - Application record associated with the applicant.
* @param applicant       - Loan Applicant record.
* @param requestConfig   - Metadata configuration containing request template.
* @return String - Final request body ready to be sent to the API.
*/
    
    
    public static String buildDynamicRequest(Id eVerificationId,Application__c application,Loan_Applicant__c applicant,Callout_Framework__mdt requestConfig) {
        
        // Values
        String dob       = applicant.Date_of_Birth__c != null ? formatDateDDMMYYYY(applicant.Date_of_Birth__c) : '';
        String disbDate = formatDateDDMMYYYY(Date.today());
        String nowVal    = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String loanAmt = application.Applied_Loan_Amount__c != null? String.valueOf(application.Applied_Loan_Amount__c.setScale(0, RoundingMode.DOWN).intValue()) : '0';
        String tenure    = application.Tenure__c != null ? String.valueOf(application.Tenure__c) : '';
        String prodType  = (application.Product__r != null && application.Product__r.Product_Type__c != null) ? application.Product__r.Product_Type__c : '';
        String gender    = applicant.Gender__c != null ? applicant.Gender__c : '';
        String stateCode = (application.Branch__r != null && application.Branch__r.City__r != null && application.Branch__r.City__r.State_Master__r != null && application.Branch__r.City__r.State_Master__r.State_Code__c != null) ? application.Branch__r.City__r.State_Master__r.State_Code__c : '';
        
        // username 
        String username = System.Label.Kotak_Insurance_Username;
        String requestTemplate = requestConfig != null && requestConfig.Body__c != null ? requestConfig.Body__c : '{}';
        
        // Replace placeholders safely
        Map<String, String> replacements = new Map<String, String>{
            '${now}'          => nowVal,
                '${dob}'          => dob,
                '${loanAmount}'   => loanAmt,
                '${loanDisbDate}' => disbDate,
                '${tenure}'       => tenure,
                '${productType}'  => prodType,
                '${gender}'       => gender,
                '${stateCode}'    => stateCode,
                '${username}'     => username
                };
                    
                    for (String key : replacements.keySet()) {
                        requestTemplate = requestTemplate.replace(key, replacements.get(key));
                    }
        
        System.debug('Final Request Body ==== ' + requestTemplate);
        return requestTemplate;
    }
    
    
    /*
* @description Helper method to format a Date into DD/MM/YYYY string format.
* @param dob - Date to format.
* @return String - Formatted date string or empty string if input is null.
*/
    
    
    private static String formatDateDDMMYYYY(Date dob) {
        if (dob == null) return '';
        
        String day   = dob.day()   < 10 ? '0' + dob.day()   : String.valueOf(dob.day());
        String month = dob.month() < 10 ? '0' + dob.month() : String.valueOf(dob.month());
        String year  = String.valueOf(dob.year());
        
        return day + '/' + month + '/' + year;
    }
    
    /*
* @description Updates the E-Verification record with details from the Kotak API response.
*              Extracts relevant fields such as premium amount, policy number, cover note dates, etc.
* @param responseBody   - JSON response body from Kotak API.
* @param eVerificationId - Salesforce Id of the E-Verification record to update.
*/
    
    
    
    public static void updateEVerification(String responseBody, Id eVerificationId) {
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> { E_Verification__c.SObjectType });
            
            Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            if (!respMap.containsKey('Response')) return;
            
            Map<String, Object> response = (Map<String, Object>) respMap.get('Response');
            Map<String, Object> responseInfo = (Map<String, Object>) response.get('ResponseInfo');
            
            String creationDate   = (String) responseInfo.get('CreationDate');
            String transactionId  = (String) responseInfo.get('TransactionId');
            
            Map<String, Object> responsePayload = (Map<String, Object>) response.get('ResponsePayload');
            List<Object> transactions = (List<Object>) responsePayload.get('Transactions');
            Map<String, Object> txn = (Map<String, Object>) transactions[0]; 
            Map<String, Object> transactionData = (Map<String, Object>) txn.get('TransactionData');
            Map<String, Object> premiumInfo = (Map<String, Object>) transactionData.get('PremiumInfoDetails');
            
            Decimal totalPremium = (Decimal) premiumInfo.get('TotalPremium');
            String jobId         = String.valueOf(premiumInfo.get('JobId'));
            String coverEndDate  = (String) premiumInfo.get('CoverEndDate');
            
            Date endDate;
            if (String.isNotBlank(coverEndDate)) {
                List<String> parts = coverEndDate.split('/');
                endDate = Date.newInstance(Integer.valueOf(parts[2]), Integer.valueOf(parts[1]), Integer.valueOf(parts[0]));
            }
            
            E_Verification__c records = new E_Verification__c(
                Id = eVerificationId,
                Cover_Note_Creation_Date__c = Date.valueOf(creationDate),
                Start_Date__c               = Date.valueOf(creationDate),
                Cover_Note_Number__c        = transactionId,
                Premium_Amount__c           = totalPremium,
                Policy_Number__c            = jobId,
                End_Date__c                 = endDate,
                Type_Of_Insurance__c        = 'Life Insurance'
            );
            
            System.debug('Response Node: ' + respMap.get('Response'));
System.debug('ResponseInfo Node: ' + response.get('ResponseInfo'));
System.debug('ResponsePayload Node: ' + response.get('ResponsePayload'));
System.debug('TransactionData Node: ' + txn.get('TransactionData'));
System.debug('PremiumInfo Node: ' + transactionData.get('PremiumInfoDetails'));


            uow.registerDirty(records);
            uow.commitWork();
            logger.info('E-Verification updated successfully for Id: ' + eVerificationId);
        } catch (Exception ex) {
            logger.error('Mapping Error in updateEVerification: ' + ex.getMessage());
        } finally {
            logger.saveLog();
        }
    }
    /*
* @description Executes the full Kotak Insurance API flow:
*              Generates token, calculates premium, and updates the E-Verification record.
* @param eVerificationId - Salesforce Id of the E-Verification record.
* @param application     - Application record associated with the applicant.
* @param applicant       - Loan Applicant record.
* @return String - API response body or error message.
*/
    
    // Execute full flow
    public static String callKotakService(Id eVerificationId,Application__c application,Loan_Applicant__c applicant) {
        try {
            String token = generateAccessToken();
            if (String.isBlank(token)) {
                logger.error('Token generation failed for eVerificationId: ' + eVerificationId);
                return 'Token generation failed';
            }
            return calculatePremium(token, eVerificationId,application,applicant);
        } catch (Exception e) {
            logger.error('Error in callKotakService: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        } finally {
            logger.saveLog();
        }
    }
}