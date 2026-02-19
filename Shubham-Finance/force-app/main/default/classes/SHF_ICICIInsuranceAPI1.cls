public with sharing class SHF_ICICIInsuranceAPI1 {
    private static final String AES_ALGO = 'AES256';
    private static final String JWT_METADATA_NAME = 'ICICI_JWT_API';
    private static final String QUOTE_METADATA_NAME = 'ICICI_QUOTE_API';

    // Public orchestrator - call this from your service layer
    public static String processICICIQuote(Id eVerificationId, Application__c application, Loan_Applicant__c applicant) {
        try {
            System.debug('ICICI: process start for eVerificationId=' + eVerificationId + ' applicant=' + (applicant != null ? applicant.Id : 'null'));
            String jwt = generateJWTFromMetadata();
            if (String.isBlank(jwt)) {
                System.debug('ICICI: JWT generation returned blank');
                return 'Error: JWT generation failed';
            }
            String response = callQuoteApiWithJwt(jwt, eVerificationId, application, applicant);
            System.debug('ICICI: final response (decrypted or raw) -> ' + response);
            return response;
        } catch (Exception ex) {
            System.debug('ICICI: Exception in processICICIQuote -> ' + ex.getMessage());
            return 'Error: ' + ex.getMessage();
        }
    }

    // -----------------------
    // 1) Generate JWT using metadata
    // -----------------------
     public static String generateJWTFromMetadata() {
    try {
        Callout_Framework__mdt jwtConfig = SHF_CommonUtil.getCalloutMetadata('ICICI_Insurance_JWT')
            .get('ICICI_Insurance_JWT');
        
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

        // ✅ Derive Basic Auth Header from Auth_Token_c__c
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

        // --- Optional empty body for POST ---
        if (jwtConfig.HTTP_Method__c == 'POST') {
            tokenReq.setBody('{}');
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



    // -----------------------
    // 2) Build encrypted request and call Quote API
    // -----------------------
    private static String callQuoteApiWithJwt(String jwtToken, Id eVerificationId, Application__c application, Loan_Applicant__c applicant) {
        Map<String, Callout_Framework__mdt> metaMap = SHF_CommonUtil.getCalloutMetadata(QUOTE_METADATA_NAME);
        Callout_Framework__mdt cfg = metaMap != null ? metaMap.get(QUOTE_METADATA_NAME) : null;
        if (cfg == null) {
            System.debug('ICICI: Quote metadata not found for ' + QUOTE_METADATA_NAME);
            return 'Error: Quote metadata missing';
        }

        try {
            // If metadata inactive -> return mock
            if (!cfg.Active__c) {
                System.debug('ICICI: Quote metadata inactive, using mock response if provided.');
                if (!String.isBlank(cfg.Mock_Response__c)) {
                    // If mock is encryptedResponse JSON, just return it
                    return cfg.Mock_Response__c;
                }
                return 'Error: Quote metadata inactive and no mock provided';
            }

            // 1) Prepare SOAP by replacing placeholders from cfg.Body__c
            String soapTemplate = cfg.Body__c != null ? cfg.Body__c : '';
            // Placeholders you used earlier - update/add if needed
            Map<String, String> replacements = new Map<String, String>{
                '{FirstName}' => applicant != null && applicant.First_Name__c != null ? applicant.First_Name__c : '',
                '{LastName}'  => applicant != null && applicant.Last_Name__c != null ? applicant.Last_Name__c : '',
                '{DateOfBirth}' => applicant != null && applicant.Date_of_Birth__c != null ? String.valueOf(applicant.Date_of_Birth__c) : '',
                '{Gender}' => applicant != null && applicant.Gender__c != null ? applicant.Gender__c : '',
                '{Term}' => application != null && application.Tenure__c != null ? String.valueOf(application.Tenure__c) : '',
                //'{DeathBenefit}' => application != null && application.Death_Benefit__c != null ? String.valueOf(application.Death_Benefit__c) : '',
                '{LoanTenure}' => application != null && application.Tenure__c != null ? String.valueOf(application.Tenure__c) : '',
                '{LoanAmount}' => application != null && application.Applied_Loan_Amount__c != null ? String.valueOf(application.Applied_Loan_Amount__c.setScale(0, RoundingMode.DOWN).intValue()) : '0',
                '{MasterCode}' => 'EF0001BL' // if master code is static
            };

            for (String k : replacements.keySet()) {
                soapTemplate = soapTemplate.replace(k, replacements.get(k));
            }
            System.debug('ICICI: final SOAP to be encrypted -> ' + soapTemplate);

            // 2) Get key/iv from Extra_Param_s__c (expected JSON: {"key":"...", "iv":"..."})
            String key = null;
            String iv = null;
            if (!String.isBlank(cfg.Extra_Param_s__c)) {
                try {
                    Map<String, Object> extra = (Map<String, Object>) JSON.deserializeUntyped(cfg.Extra_Param_s__c);
                    if (extra.containsKey('key')) key = String.valueOf(extra.get('key'));
                    if (extra.containsKey('iv')) iv = String.valueOf(extra.get('iv'));
                } catch (Exception ex) {
                    System.debug('ICICI: Error parsing Extra_Param_s__c -> ' + ex.getMessage());
                }
            }

            if (String.isBlank(key) || String.isBlank(iv)) {
                System.debug('ICICI: AES key/iv missing in metadata Extra_Param_s__c');
                return 'Error: AES key or IV not configured in metadata';
            }

            Blob keyBlob = Blob.valueOf(key);
            Blob ivBlob = Blob.valueOf(iv);
            Blob dataBlob = Blob.valueOf(soapTemplate);

            Blob encryptedBlob = Crypto.encrypt(AES_ALGO, keyBlob, ivBlob, dataBlob);
            String base64Encrypted = EncodingUtil.base64Encode(encryptedBlob);
            System.debug('ICICI: base64Encrypted length -> ' + (base64Encrypted != null ? base64Encrypted.length() : 0));

            // 3) Build request JSON: include metadata name and encryptedRequest
            Map<String, Object> requestWrapper = new Map<String, Object>{
                'metadata' => cfg.DeveloperName != null ? cfg.DeveloperName : QUOTE_METADATA_NAME,
                'encryptedRequest' => base64Encrypted
            };
            String requestBody = JSON.serialize(requestWrapper);
            System.debug('ICICI: Quote request body -> ' + requestBody);

            // 4) Setup HttpRequest
            HttpRequest req = new HttpRequest();
            req.setEndpoint(cfg.Host__c + cfg.Endpoint__c);
            req.setMethod(cfg.HTTP_Method__c != null ? cfg.HTTP_Method__c : 'POST');

            // Add headers from metadata HeaderParams__c (if any)
            if (!String.isBlank(cfg.HeaderParams__c)) {
                try {
                    Map<String, Object> headers = (Map<String, Object>) JSON.deserializeUntyped(cfg.HeaderParams__c);
                    for (String keyHdr : headers.keySet()) {
                        String val = headers.get(keyHdr) != null ? String.valueOf(headers.get(keyHdr)) : null;
                        if (!String.isBlank(val)) req.setHeader(keyHdr, val);
                    }
                } catch (Exception ex) {
                    System.debug('ICICI: Error parsing HeaderParams__c for quote -> ' + ex.getMessage());
                }
            }

            // Ensure Content-Type and Authorization are present/overridden
            if (String.isBlank(req.getHeader('Content-Type'))) req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + jwtToken);
            req.setBody(requestBody);

            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('ICICI: Quote call status -> ' + res.getStatus());
            System.debug('ICICI: Quote call statusCode -> ' + res.getStatusCode());
            System.debug('ICICI: Quote call raw body -> ' + res.getBody());

            String resBody = res.getBody();

            // 5) If response contains encryptedResponse -> decrypt it
            String decrypted = tryDecryptResponse(resBody, keyBlob, ivBlob);
            System.debug('ICICI: decrypted response -> ' + decrypted);

            // 6) If eVerificationId provided, update E_Verification record using existing logic
            if (!String.isBlank(decrypted) && eVerificationId != null) {
                updateEVerificationFromDecrypted(decrypted, eVerificationId);
            }

            // Return decrypted if available otherwise raw response
            return !String.isBlank(decrypted) ? decrypted : resBody;
        } catch (Exception ex) {
            System.debug('ICICI: Exception in callQuoteApiWithJwt -> ' + ex.getMessage());
            return 'Error: ' + ex.getMessage();
        }
    }

    // -----------------------
    // 3) Decrypt helper - attempts to parse JSON and decrypt encryptedResponse field
    // -----------------------
    private static String tryDecryptResponse(String body, Blob keyBlob, Blob ivBlob) {
        if (String.isBlank(body)) return null;
        try {
            // Try parse as JSON with encryptedResponse
            Map<String, Object> mapResp = (Map<String, Object>) JSON.deserializeUntyped(body);
            if (mapResp != null && mapResp.containsKey('encryptedResponse')) {
                String enc = String.valueOf(mapResp.get('encryptedResponse'));
                if (!String.isBlank(enc)) {
                    Blob encBlob = EncodingUtil.base64Decode(enc);
                    Blob decBlob = Crypto.decrypt(AES_ALGO, keyBlob, ivBlob, encBlob);
                    String decrypted = decBlob.toString();
                    return decrypted;
                }
            }

            // If not JSON or no encryptedResponse, try if the body itself is base64 encryptedResponse container
            // (some mocks return {"encryptedResponse":"..."} as we handled) else try to detect base64 and decrypt
            // but avoid false positives - only attempt base64->decrypt if looks like base64 and body length reasonable
            if (looksLikeBase64(body) && body.length() > 20) {
                try {
                    Blob encBlob2 = EncodingUtil.base64Decode(body);
                    Blob decBlob2 = Crypto.decrypt(AES_ALGO, keyBlob, ivBlob, encBlob2);
                    return decBlob2.toString();
                } catch (Exception nested) {
                    // ignore - can't decrypt raw body
                }
            }

            return null;
        } catch (Exception e) {
            System.debug('ICICI: tryDecryptResponse - not JSON or decryption failed -> ' + e.getMessage());
            return null;
        }
    }

    private static Boolean looksLikeBase64(String s) {
        if (String.isBlank(s)) return false;
        // naive check: base64 contains letters/numbers, +, /, = and no xml-like chars
        Pattern p = Pattern.compile('^[A-Za-z0-9+/=\\r\\n]+$');
        return p.matcher(s).matches();
    }

    // -----------------------
    // 4) parse decrypted SOAP and update E_Verification__c (similar to your earlier logic)
    // -----------------------
    private static void updateEVerificationFromDecrypted(String decryptedSoap, Id eVerificationId) {
        try {
            if (String.isBlank(decryptedSoap)) {
                System.debug('ICICI: updateEVerificationFromDecrypted - decryptedSoap blank');
                return;
            }

            // The decrypted SOAP likely includes <soap:Envelope>.. <GenerateEBIDigitalResult> .. inner XML
            // Extract inner between <GenerateEBIDigitalResult> and </GenerateEBIDigitalResult>
            String innerXml = decryptedSoap;
            if (decryptedSoap.contains('<GenerateEBIDigitalResult>') && decryptedSoap.contains('</GenerateEBIDigitalResult>')) {
                innerXml = decryptedSoap.substringBetween('<GenerateEBIDigitalResult>', '</GenerateEBIDigitalResult>');
            } else if (decryptedSoap.contains('&lt;') && decryptedSoap.contains('&gt;')) {
                // if encoded entities
                innerXml = decryptedSoap.replace('&lt;', '<').replace('&gt;', '>');
            }

            if (String.isBlank(innerXml)) {
                System.debug('ICICI: no GenerateEBIDigitalResult inner XML found');
                return;
            }

            // If innerXml still contains wrapping tags, attempt to load into DOM
            Dom.Document doc = new Dom.Document();
            try {
                doc.load(innerXml);
            } catch (Exception loadEx) {
                // Try to wrap innerXml with root if it isn't a single root
                innerXml = '<root>' + innerXml + '</root>';
                doc.load(innerXml);
            }

            Dom.XmlNode root = doc.getRootElement();

            // Helper extraction using tag names (fall back to searching text)
            String masterCode = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'MasterCode');
            String productCode = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'ProductCode');
            String totalPrem = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'TotalFirstPremium');
            String dob = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'DateOfBirth');
            String loanTenure = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'LoanTenure');
            String age = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'Age');

            System.debug('ICICI: Parsed values -> masterCode:' + masterCode + ' totalPrem:' + totalPrem);

            // Prepare record update (use UOW if available)
            E_Verification__c ev = new E_Verification__c(Id = eVerificationId);
            if (!String.isBlank(masterCode)) ev.Policy_Number__c = masterCode;
            if (!String.isBlank(productCode)) ev.Cover_Note_Number__c = productCode;
            if (!String.isBlank(totalPrem)) {
                try { ev.Premium_Amount__c = Decimal.valueOf(totalPrem); } catch (Exception ex){ System.debug('ICICI: Premium parse error -> '+ex.getMessage()); }
            }
            ev.Type_Of_Insurance__c = 'Life Insurance';
            ev.Start_Date__c = System.today();
            ev.End_Date__c = System.today();

            // Use fflib UnitOfWork if present as in your earlier code
            try {
                fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
                uow.registerDirty(ev);
                uow.commitWork();
                System.debug('ICICI: E_Verification updated via UOW for Id: ' + eVerificationId);
            } catch (Exception uowEx) {
                // fallback to plain DML
                try {
                    update ev;
                    System.debug('ICICI: E_Verification updated via DML for Id: ' + eVerificationId);
                } catch (Exception dmlEx) {
                    System.debug('ICICI: Error updating E_Verification -> ' + dmlEx.getMessage());
                }
            }
        } catch (Exception ex) {
            System.debug('ICICI: Exception in updateEVerificationFromDecrypted -> ' + ex.getMessage());
        } finally {
            // if you have logger.saveLog() pattern, call it
            try { logger.saveLog(); } catch (Exception ignore) {}
        }
    }
}