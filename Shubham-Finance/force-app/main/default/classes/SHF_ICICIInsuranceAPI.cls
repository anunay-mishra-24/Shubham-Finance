/*
* @File Name       : SHF_ICICIInsuranceAPI.cls
* @Author          : Preeti
* @Created Date    : Sept 19, 2025
* @Description     : This class handles integration with the ICICI Insurance API. 
*                    It provides methods to generate JWT tokens, build dynamic SOAP requests, 
*                    call SOAP API endpoints, and update E-Verification records with the API response.
*                    Supports both live API calls and mock responses via metadata configuration.
* @Last Modified By: Preeti
* @Last Modified On: Sept 19, 2025
* @Modification Log:
*==============================================================================
* Ver | Date       | Author | Modification
*==============================================================================
* 1.0 | 19-sept-25  | Preeti | Initial Version
*/


public class SHF_ICICIInsuranceAPI {
    
    /*
* @description Generates a JWT token for ICICI Insurance API authentication.
*              Uses metadata configuration to decide between live API call or mock response.
* @return String - JWT token if successful, otherwise null.
*/
    
    // Generate JWT Token
     public static String generateJWTToken() {
    try {
        Callout_Framework__mdt jwtConfig = SHF_CommonUtil.getCalloutMetadata('ICICI_Insurance_JWT').get('ICICI_Insurance_JWT');
        
        if (jwtConfig == null) {
            logger.error('JWT config not found.');
            return null;
        }

        // --- If inactive → return mock response ---
        if (!jwtConfig.Active__c) {
            logger.info('Using MOCK JWT Token response from metadata');
            if (String.isBlank(jwtConfig.Mock_Response__c)) {
                logger.error('Mock response not configured in metadata for JWT');
                return null;
            }
            Map<String, Object> mockMap = (Map<String, Object>) JSON.deserializeUntyped(jwtConfig.Mock_Response__c);
            return (String) mockMap.get('token');
        }

        // --- If active → call API ---
        Http http = new Http();
        HttpRequest tokenReq = new HttpRequest();

        tokenReq.setEndpoint(jwtConfig.Host__c + jwtConfig.Endpoint__c);
        tokenReq.setMethod(jwtConfig.HTTP_Method__c);

        if (String.isBlank(jwtConfig.Auth_Token_c__c) || !jwtConfig.Auth_Token_c__c.contains(':')) {
            logger.error('Invalid Auth_Token_c__c in metadata. Must be in username:password format.');
            return null;
        }
        String[] creds = jwtConfig.Auth_Token_c__c.split(':');
        String auth = EncodingUtil.base64Encode(Blob.valueOf(creds[0] + ':' + creds[1]));

        // --- Apply headers from HeaderParams__c ---
        if (String.isNotBlank(jwtConfig.HeaderParams__c)) {
            Map<String, Object> headers = (Map<String, Object>) JSON.deserializeUntyped(jwtConfig.HeaderParams__c);
            for (String key : headers.keySet()) {
                String val = (String) headers.get(key);
                // Replace placeholder {{auth}} with actual encoded value
                if (val.contains('{{auth}}')) {
                    val = val.replace('{{auth}}', auth);
                }
                tokenReq.setHeader(key, val);
            }
        } else {
            // Default header fallback
            tokenReq.setHeader('Authorization', 'Basic ' + auth);
            tokenReq.setHeader('Content-Type', 'application/json');
        }

        // --- Send request ---
        HttpResponse tokenRes = http.send(tokenReq);

        logger.info('JWT Response Status: ' + tokenRes.getStatus());
        logger.info('JWT Response Body: ' + tokenRes.getBody());

        // --- Parse JWT token ---
        if (tokenRes.getStatusCode() == 200) {
            try {
                Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(tokenRes.getBody());
                if (resMap.containsKey('token')) {
                    String jwtToken = (String) resMap.get('token');
                    logger.info('JWT token successfully generated.');
                    return jwtToken;
                } else {
                    logger.error('Token key missing in response JSON.');
                }
            } catch (Exception ex) {
                logger.error('Error parsing JWT response: ' + ex.getMessage());
            }
        } else {
            logger.error('JWT call failed. StatusCode: ' + tokenRes.getStatusCode() + ' Body: ' + tokenRes.getBody());
        }

        return null;
    } catch (Exception e) {
        logger.error('JWT API Error: ' + e.getMessage());
        return null;
    } finally {
        logger.saveLog();
    }
}
    
    /*
* @description Calls the ICICI Insurance SOAP API using a JWT token.
*              Builds a dynamic request, sends the SOAP call, and updates E-Verification 
*              record if response is successful.
* @param jwtToken       - JWT token for authentication.
* @param eVerificationId - Salesforce Id of the E-Verification record.
* @param application     - Application record associated with the applicant.
* @param applicant       - Loan Applicant record.
* @return String - API response body or error message.
*/  
    public static String callSOAPWithJWT(String jwtToken, Id eVerificationId, Application__c application, Loan_Applicant__c applicant, Map<String, Object> insuranceData ) {
        String responseBody = '';
        try {
            if (String.isBlank(jwtToken)) {
                logger.error('JWT token is blank, cannot call SOAP API.');
                return null;
            }
    
            // Load metadata
            Callout_Framework__mdt soapConfig = SHF_CommonUtil.getCalloutMetadata('ICICI_QUOTE_API').get('ICICI_QUOTE_API');
            if (soapConfig == null) {
                logger.error('SOAP config not found.');
                return null;
            }
    
            // If inactive → use mock SOAP response
            if (!soapConfig.Active__c) {
                logger.info('Using MOCK SOAP response from metadata');
                if (String.isBlank(soapConfig.Mock_Response__c)) {
                    logger.error('Mock response not configured in metadata for SOAP API');
                    return null;
                }
                responseBody = soapConfig.Mock_Response__c;
                if (eVerificationId != null) updateEVerification(responseBody, eVerificationId);
                return responseBody;
            }
    
            // --- Build the SOAP XML body dynamically ---
            String soapXML = soapConfig.Body__c;
    
            soapXML = soapXML.replace('{FirstName}', applicant.First_Name__c != null ? applicant.First_Name__c : '');
            soapXML = soapXML.replace('{LastName}', applicant.Last_Name__c != null ? applicant.Last_Name__c : '');
            soapXML = soapXML.replace('{DateOfBirth}', applicant.Date_of_Birth__c != null ? String.valueOf(applicant.Date_of_Birth__c) : '');
            soapXML = soapXML.replace('{Gender}', applicant.Gender__c != null ? applicant.Gender__c : '');
    
            soapXML = soapXML.replace('{Term}', application.Tenure__c != null ? String.valueOf(application.Tenure__c) : '');
    
            // SAFE numeric conversions (no cast exception even if null or string)
            Decimal outstandingAmt = toDecimalSafe(insuranceData.get('Outstanding_Loan_Amount__c'));
            soapXML = soapXML.replace('{DeathBenefit}', String.valueOf(Math.round(outstandingAmt)));
    
            soapXML = soapXML.replace('{LoanTenure}', insuranceData.get('Outstanding_Loan_Tenure__c') != null ? String.valueOf(insuranceData.get('Outstanding_Loan_Tenure__c')) : '');
    
            Decimal appliedLoan = application.Applied_Loan_Amount__c != null ? application.Applied_Loan_Amount__c : 0;
            soapXML = soapXML.replace('{LoanAmount}', String.valueOf(Math.round(appliedLoan)));
    
            soapXML = soapXML.replace('{Cover}', insuranceData.get('Cover__c') != null ? String.valueOf(insuranceData.get('Cover__c')) : '');
    
            logger.info('Final SOAP XML Before Encryption: ' + soapXML);
            System.debug('Final SOAP XML Before Encryption: ' + soapXML);
    
            // --- Encrypt the SOAP XML using AES256 + IV from metadata ---
            Map<String, Object> extraParams = new Map<String, Object>();
            if (String.isNotBlank(soapConfig.extra_param_s__c)) {
                extraParams = (Map<String, Object>) JSON.deserializeUntyped(soapConfig.extra_param_s__c);
            }
    
            String key = (String) extraParams.get('key');
            String iv  = (String) extraParams.get('iv');
    
            Blob keyBlob = Blob.valueOf(key);
            Blob ivBlob = Blob.valueOf(iv);
            Blob dataBlob = Blob.valueOf(soapXML);
            Blob encryptedBlob = Crypto.encrypt('AES256', keyBlob, ivBlob, dataBlob);
            String base64Encrypted = EncodingUtil.base64Encode(encryptedBlob);
    
            System.debug('Encrypted SOAP Request: ' + base64Encrypted);
    
            // --- Call the ICICI Quote API ---
            Http http = new Http();
            HttpRequest soapReq = new HttpRequest();
            soapReq.setEndpoint(soapConfig.Auth_Token_c__c + soapConfig.Endpoint__c); // Host__c is empty, using Auth_Token_c__c
            soapReq.setMethod(soapConfig.HTTP_Method__c);
            soapReq.setHeader('Content-Type', 'application/json');
            soapReq.setHeader('Authorization', 'Bearer ' + jwtToken);
    
            // Prepare JSON body
            Map<String, String> bodyMap = new Map<String, String>{ 'encryptedRequest' => base64Encrypted };
            soapReq.setBody(JSON.serialize(bodyMap));
    
            HttpResponse soapRes = http.send(soapReq);
            logger.info('SOAP Response Status: ' + soapRes.getStatus());
            logger.info('SOAP Response Body: ' + soapRes.getBody());
            responseBody = soapRes.getBody();
    
            if (soapRes.getStatusCode() != 200) {
                logger.error('SOAP call failed: ' + soapRes.getBody());
                return soapRes.getBody();
            }
    
            // --- Decrypt the response ---
            Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(soapRes.getBody());
            String encryptedResponse = (String) resMap.get('encryptedResponse');
    
            if (String.isNotBlank(encryptedResponse)) {
                Blob decryptedBlob = Crypto.decrypt('AES256', keyBlob, ivBlob, EncodingUtil.base64Decode(encryptedResponse));
                String decryptedResponse = decryptedBlob.toString();
                System.debug('Decrypted SOAP Response: ' + decryptedResponse);
                // unescape
                String cleanXml = decryptedResponse
                                    .replace('&lt;', '<')
                                    .replace('&gt;', '>')
                                    .replace('&amp;', '&');

                System.debug('Clean XML: ' + cleanXml);
                logger.info('SOAP Decrypted Response : ' + cleanXml);

                // --------------------
                // BUSINESS ERROR CHECK
                // --------------------
                String resultXml = cleanXml.substringBetween(
                    '<GenerateEBIDigitalResult>',
                    '</GenerateEBIDigitalResult>'
                );

                if (String.isNotBlank(resultXml)) {
                    Dom.Document doc = new Dom.Document();
                    doc.load(resultXml);
                    Dom.XMLNode root = doc.getRootElement();

                    String errorCode = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'ErrorCode');
                    String errorMessage = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'ErrorMessage');

                    if (!String.isBlank(errorCode) && errorCode != 'E00') {
                        logger.error('ICICI Business Error: ' + errorCode + ' | ' + errorMessage);

                        //DO NOT update E-Verification
                        return 'ERROR|' + errorMessage;
                    }
                }
                if (responseBody.contains('<ErrorCode>')) {
                    logger.error('Skipping E-Verification update due to ICICI error');
                }

                // --------------------
                // SUCCESS PATH ONLY
                // --------------------
                if (eVerificationId != null) {
                    updateEVerification(cleanXml, eVerificationId);
                }

                return 'SUCCESS';
            } else {
                logger.error('Encrypted response not found in API response.');
                return responseBody;
            }
    
        } catch (Exception e) {
            logger.error('SOAP API Error: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        } finally {
            logger.saveLog();
        }
    }
    
    
    private static Decimal toDecimalSafe(Object val) {
        if (val == null) return 0;
        try {
            return Decimal.valueOf(String.valueOf(val).replace(',', ''));
        } catch (Exception e) {
            return 0;
        }
    }


    
    /*
* @description Updates the E-Verification record based on SOAP response from ICICI API.
*              Parses the XML response, extracts relevant fields, and commits updates.
* @param responseBody   - SOAP response body.
* @param eVerificationId - Salesforce Id of the E-Verification record to update.
*/
    
    
    public static void updateEVerification(String responseBody, Id eVerificationId) {
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> { E_Verification__c.SObjectType });
            if (String.isBlank(responseBody)) {
                logger.error('Empty SOAP response body, skipping update.');
                return;
            }
            
            // Extract <GenerateEBIDigitalResult>
            String innerXml = responseBody.substringBetween('<GenerateEBIDigitalResult>', '</GenerateEBIDigitalResult>');
            if (String.isBlank(innerXml)) {
                logger.error('GenerateEBIDigitalResult tag not found in SOAP response');
                return;
            }
            innerXml = innerXml.replace('&lt;', '<').replace('&gt;', '>');
            
            Dom.Document doc = new Dom.Document();
            doc.load(innerXml);
            Dom.XMLNode root = doc.getRootElement();
            
            // Extract values using helper
            String masterCode   = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'MasterCode');
            String dob          = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'DateOfBirth');
            String loanTenure   = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'LoanTenure');
            String productCode  = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'ProductCode');
            String age          = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'Age');
            String totalPrem    = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'TotalFirstPremium');
            System.debug('totalPrem: '+totalPrem);
            System.debug('masterCode: '+masterCode);
            System.debug('productCode: '+productCode);

            // Update record
            E_Verification__c records = new E_Verification__c(
                Id = eVerificationId,
                Policy_Number__c = !String.isBlank(masterCode) ? masterCode : null,
                Start_Date__c = System.Today(),
                End_Date__c =  System.Today(),
                Cover_Note_Number__c = !String.isBlank(productCode) ? productCode : null,
                Cover_Note_Creation_Date__c =  System.Today(),
                Premium_Amount__c = (totalPrem != null ? Decimal.valueOf(totalPrem) : null),
                Type_Of_Insurance__c = 'Life Insurance',
                Status__c = 'Completed'
            );
            
            uow.registerDirty(records);
            uow.commitWork();
            
            logger.info('Mapped and updated E-Verification for Id: ' + eVerificationId);
        } catch (Exception e) {
            logger.error('Error in updateEVerification: ' + e.getMessage());
        } finally {
            logger.saveLog();
        }
    }
    
    /*
* @description Executes the full ICICI Insurance API flow: generates JWT token,
*              builds dynamic SOAP request, calls the SOAP API, and updates E-Verification record.
* @param eVerificationId - Salesforce Id of the E-Verification record.
* @param application     - Application record associated with the applicant.
* @param applicant       - Loan Applicant record.
* @return String - API response body or error message.
*/
    
    @AuraEnabled
    public static String callICICIService(Id eVerificationId,Application__c application,Loan_Applicant__c applicant,Map<String, Object> insuranceData) {
        try {
            String jwt = generateJWTToken();
            if (String.isBlank(jwt)) {
                logger.error('JWT generation failed for eVerificationId: ' + eVerificationId);
                return 'JWT generation failed';
            }
            return callSOAPWithJWT(jwt, eVerificationId,application,applicant,insuranceData);
        } catch (Exception e) {
            logger.error('Error in callICICIService: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        } finally {
            logger.saveLog();
        }
    }
}