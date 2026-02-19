/**
* @File Name          : HTTPCalloutService.cls
* @Description        : Callout Framework Class.
* @Author             : Riteek Tiwari
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         19-06-2025            Riteek Tiwari         Initial Version
*/
public class SHF_HTTPCalloutService {
    
    public Callout_Framework__mdt calloutMetadata;
    
    public String endpointURL, requestMethod, requestBody, requestCertificate, namedCredential,mockRespnse,host;
    Blob requestBodyAsBlob;
    Dom.Document requestBodyAsDocument;
    Integer requestTimeout;
    Boolean isCompressedRequest, isActive;
    Map<String, String> urlParametersMap;
    Map<String, String> headerParametersMap;
    Map<String, String> extraParametersMap;
    static final String TYPE_URL_PARAMETERS = 'URL_PARAMETERS';
    static final String TYPE_HEADER_PARAMETERS = 'HEADER_PARAMETERS';
    static final String TYPE_EXTRA_PARAMETERS = 'EXTRA_PARAMETERS';
    //
    HTTPRequest request;
    
    public String getmockRespnse() {
        return mockRespnse;
    }
    
    public void setmockRespnse(String mockRespnse) {
        this.mockRespnse = mockRespnse;
    }
    public String getEndpointURL() {
        return endpointURL;
    }
    public Boolean getIsActive() {
        return isActive;
    }
    
    public void setEndpointURL(String endpointURL) {
        this.endpointURL = endpointURL;
    }
    
    public String getRequestMethod() {
        return requestMethod;
    }
    
    public void setRequestMethod(String requestMethod) {
        this.requestMethod = requestMethod;
    }
    
    public String getRequestBody() {
        return requestBody;
    }
    
    public void setRequestBody(String requestBody) {
        this.requestBody = requestBody;
        system.debug('this.requestBody==>'+this.requestBody);
    }
    
    public Blob getRequestBodyAsBlob() {
        return requestBodyAsBlob;
    }
    
    public void setRequestBodyAsBlob(Blob requestBodyAsBlob) {
        this.requestBodyAsBlob = requestBodyAsBlob;
    }
    
    public Dom.Document getRequestBodyAsDocument() {
        return requestBodyAsDocument;
    }
    
    public void setRequestBodyAsDocument(Dom.Document requestBodyAsDocument) {
        this.requestBodyAsDocument = requestBodyAsDocument;
    }
    
    public String getRequestCertificate() {
        return requestCertificate;
    }
    
    public Integer getRequestTimeout() {
        return requestTimeout;
    }
    
    public void setRequestTimeout(Integer requestTimeout) {
        this.requestTimeout = requestTimeout;
    }
    
    public String getURLParameter(String key) {
        return urlParametersMap.get(key);
    }
    
    public Map<String, String> getURLParameters() {
        return urlParametersMap;
    }
    public void setHeaderParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            headerParametersMap.put(key, value);
        }
    }
    
    /*public void setURLParameter(String key, String value) {
if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
urlParametersMap.put(key, value);
} else if(String.isNotEmpty(key)) {
urlParametersMap.put(key, value);
}
} */
    
    public void setURLParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            urlParametersMap.put(key, value);
        } else if(String.isNotEmpty(key)) {
            urlParametersMap.put(key, value);
        }
        else if(String.isEmpty(key) && String.isNotEmpty(value)) {
            urlParametersMap.put(null, value);
        }
        appendURLParameters();
    }
    
    public String customMetadataName { get; set; }
    
    public SHF_HTTPCalloutService(String customMetadataName) {
        try {
            calloutMetadata = [Select Id,Active__c,HeaderParams__c,URL_Parameter_s__c,Timeout_Time__c,Body__c,HTTP_Method__c,Mock_Response__c,Endpoint__c,Extra_Param_s__c FROM Callout_Framework__mdt WHERE DeveloperName =: customMetadataName];
            //UB_Callout_Framework__mdt.getInstance(customMetadataName);
        } catch (Exception ex) {
            throw ex;
        }
        initialize();
    }
    private void initialize() {
        urlParametersMap = new Map<String, String>();
        headerParametersMap = new Map<String, String>();
        extraParametersMap = new Map<String, String>();
        //
        if(calloutMetadata != null) {
            endpointURL = calloutMetadata.Endpoint__c;
            isActive = calloutMetadata.Active__c;
            mockRespnse = calloutMetadata.Mock_Response__c;
            requestMethod = calloutMetadata.HTTP_Method__c;
            requestBody = calloutMetadata.Body__c;
            requestTimeout = Integer.valueOf(calloutMetadata.Timeout_Time__c);
            setUrlOrHeaderParameters(TYPE_HEADER_PARAMETERS, calloutMetadata.HeaderParams__c);
            setUrlOrHeaderParameters(TYPE_EXTRA_PARAMETERS, calloutMetadata.Extra_Param_s__c);
            setUrlOrHeaderParameters(TYPE_URL_PARAMETERS, calloutMetadata.URL_Parameter_s__c);
            //requestCertificate = calloutMetadata.Certificate_Name__c;
            // namedCredential = calloutMetadata.Named_Credential__c;
            // host = calloutMetadata.Host__c;
            System.debug('here');
        }
    }
    @AuraEnabled
    public static String initiateVerification(String inputString) {
        VerificationInputWrapper inputs = (VerificationInputWrapper)JSON.deserialize(inputString, VerificationInputWrapper.class);
        
        if (String.isNotBlank(inputs.apiName) && inputs.customerId != null) {
            if (inputs.apiName == SHF_ConstantsUtil.PAN_API) {
                return SHF_PAN_Service.validatePANNumber(inputs.customerId);
            } /*else if (inputs.apiName == SHF_ConstantsUtil.Mobile_MNRL_API) {
            return SHF_Mobile_MNRL_Service.validateMobileNumber(inputs.customerId);
            }*/ else if(inputs.apiName == SHF_ConstantsUtil.AADAR_DIGILOCKER_API){
                if(inputs.actionName == SHF_ConstantsUtil.Retrieve_DigiLocker_API){
                    return SHF_KYC_DigiLocker_Service.validateDigilockerKYCDetails(inputs.customerId);
                }else if(inputs.actionName == SHF_ConstantsUtil.Initiate_via_DigiLocker_API){
                    return SHF_KYC_DigiLocker_Service.validateDigilockerKYC(inputs.customerId); 
                } 
                else if(inputs.actionName == SHF_ConstantsUtil.AADHAAR_OCR_API){
                    return SHF_AadhaarOCR_Service.initiateAadhaarOCR(inputs.customerId); 
                } 
            }
            else if (inputs.apiName == SHF_ConstantsUtil.KYC_DigiLocker_API) {
                if(inputs.actionName == SHF_ConstantsUtil.INITIATE_VIA_AADHAAR_API){
                    return SHF_CKYC_Service.cKYCSearchCustomer(inputs.customerId,SHF_ConstantsUtil.AADHAAR,inputs.finalOutputAadhaarString); 
                }
                else if(inputs.actionName == SHF_ConstantsUtil.INITIATE_VIA_PAN_API){
                    return SHF_CKYC_Service.cKYCSearchCustomer(inputs.customerId,SHF_ConstantsUtil.PAN,inputs.panNo); 
                }
                else if(inputs.actionName == 'Download CKYC via PAN or Aadhaar'){
                    return SHF_CKYC_Service.cKYCCustomerDetails(inputs.customerId);
                }
                else if (inputs.actionName == 'Verify OTP') {
                    return SHF_CKYC_Service.cKYCSendOTPtoCustomer(inputs.customerId,inputs.otpValue);
                }
               
            }
            else if(inputs.apiName == SHF_ConstantsUtil.GST_API){
                return SHF_GSTVerification_Service.validateGSTDetails(inputs.customerId); 
            }
            else if(inputs.apiName == SHF_ConstantsUtil.PENNY_DROP_API){
                return SHF_PennyDrop_Service.validatePennyDetails(inputs.customerId); 
            }
            else if(inputs.apiName == SHF_ConstantsUtil.ELECTRICITY_API){
                return SHF_ElectricityBill_Service.electricityBill(inputs.customerId, inputs.consumerId,inputs.serviceProvider,inputs.mobileNumber,inputs.serviceProviderName); 
            }
            else if(inputs.apiName == SHF_ConstantsUtil.LOGIN_FEE_API){
                return SHF_LoginFee_CreateRecipient_Service.createRecipient(inputs.customerId); 
            }
            //Added by Dimple for Udyam API
            else if(inputs.apiName == SHF_ConstantsUtil.UDYAM_API && inputs.actionName == SHF_ConstantsUtil.UDYAM_REGISTRATION_API){
                return SHF_Udyam_Registrartion_Service.initiateUdyamRegistration(inputs.customerId,inputs.udyamRegNo);
            }
            else if(inputs.apiName == SHF_ConstantsUtil.UDYAM_API && inputs.actionName == SHF_ConstantsUtil.UDYAM_ADVANCE_API){
             return SHF_Udyam_Advance_Service.fetchUdyamAdvDetails(inputs.customerId, inputs.udyamRegNo); 
            }
            //Added By Dimple for Hunter API
            else if(inputs.apiName == SHF_ConstantsUtil.Hunter_API && inputs.actionName == SHF_ConstantsUtil.Hunter_Verification_API){
                return SHF_Hunter_API_Service.callHunterAPI(inputs.customerId); 
            }
            else if(inputs.apiName == SHF_ConstantsUtil.AML_API){
                return SHF_AML_Service.fetchAMLDetails(inputs.customerId); 
            }
            else if(inputs.apiName == SHF_ConstantsUtil.INSURANCE_API){
                return SHF_InsuranceAPIService.callInsuranceAPI(inputs.customerId); 
            }
            else if(inputs.apiName == SHF_ConstantsUtil.VOTERID_API){
                return SHF_VoterIdVerification_Service.voterIdVerification(inputs.customerId); 
            }
            else if(inputs.apiName == SHF_ConstantsUtil.PASSPORT_API){
                return SHF_PassportVerification_Service.validatePassportDetails(inputs.customerId); 
            }
            else if(inputs.apiName == SHF_ConstantsUtil.DLVERIFICATION_API){
                return SHF_DLAuthentication_Service.validateDLDetails(inputs.customerId); 
            }
            else if(inputs.apiName == SHF_ConstantsUtil.SMSConsent_API){
                return SHF_SMSConsent_Service.initiateSMSConsentVerification(inputs.customerId, inputs.otpValue); 
            }
            else if(inputs.apiName == SHF_ConstantsUtil.EMAIL_VERIFICATION){
                return SHF_EmailVerification_Service.initiateEmailVerification(inputs.customerId); 
            }
            else if (inputs.apiName == SHF_ConstantsUtil.BANKING_ANALYSIS) {
                if(inputs.actionName == SHF_ConstantsUtil.INITIATE_ACCOUNT_AGGREGATOR){
                    return SHF_AccountAggregator_Service.getInitiateAccountAggregator(inputs.customerId); 
                }
                else if(inputs.actionName == SHF_ConstantsUtil.RE_FETCH){
                    return SHF_AccountAggregator_Service.getManualFetchAccountDetails(inputs.customerId); 
                }                
            }
            else if(inputs.apiName == SHF_ConstantsUtil.CIBIL_CRIF_Bureau_Individual_API){
                System.debug('Calling CIBIL API with customerId: ' + inputs.customerId);
                System.debug('Aadhaar being passed: ' + inputs.finalOutputAadhaarString);
                return SHF_CIBIL_CRIF_Bureau_Individual_API.callCIBILAPI(inputs.customerId, inputs.finalOutputAadhaarString);
            }
            else if(inputs.apiName == SHF_ConstantsUtil.DISCOVER_API){
                System.debug('Discover API with customerId: ' + inputs.customerId);
                return SHF_Discover_Service.callDiscoverAPI(inputs.customerId);
            }
            else if(inputs.apiName == SHF_ConstantsUtil.INSTANT_LITIGATION){
                System.debug('INSTANT_LITIGATION API with customerId: ' + inputs.customerId);
                return SHF_LitigationInstant_Service.initateLitigationInstant(inputs.customerId);
            }
            else if(inputs.apiName == SHF_ConstantsUtil.INSTANT_LITIGATION_RESULT){
                System.debug('INSTANT_LITIGATION Result API with customerId: ' + inputs.customerId);
                return SHF_LitigationInstant_Service.getLitigationInstantResult(inputs.customerId);
            }
            else if(inputs.apiName == SHF_ConstantsUtil.ADVANCE_LITIGATION){
                System.debug('INSTANT_LITIGATION Details API with customerId: ' + inputs.customerId);
                return SHF_LitigationAdvance_Service.initateLitigationAdvance(inputs.customerId);
            }
        }
        return null;
    } 
    
    public class VerificationInputWrapper {
        @AuraEnabled public Id customerId;
        @AuraEnabled public String apiName;
        @AuraEnabled public String actionName;
        @AuraEnabled public String panNo;
        @AuraEnabled public String finalOutputAadhaarString;
        @AuraEnabled public String consumerId;
        @AuraEnabled public String serviceProvider;
        @AuraEnabled public String serviceProviderName;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String applicationId;
        @AuraEnabled public String otpValue;
        @AuraEnabled public String udyamRegNo;
    }
    
    
    /*
* This method is used to set URL or Header parameters from Custom Metadata
*/
    private void setUrlOrHeaderParameters(String parameterType, String parameterInfo) {
        if(String.isNotEmpty(parameterInfo)) {
            Map<String, String> parametersMap = new Map<String, String>();
            List<String> parameters = parameterInfo.split('\n');
            for(String urlParam : parameters) {
                List<String> keyValuePair = urlParam.trim().split(':');
                if(!keyValuePair.isEmpty()) {
                    if(keyValuePair.size() == 2) {
                        if(String.isNotEmpty(keyValuePair[0]) && String.isNotEmpty(keyValuePair[1])) {
                            parametersMap.put(keyValuePair[0], keyValuePair[1]);
                        }
                    } else if(
                        (keyValuePair.size() == 1) &&
                        (parameterType != TYPE_HEADER_PARAMETERS)
                    ) {
                        if(String.isNotEmpty(keyValuePair[0])) {
                            parametersMap.put(keyValuePair[0], '');
                        }
                    }
                }
            }
            System.debug('keyValuePair'+parametersMap+parameterType);
            if(parameterType == TYPE_URL_PARAMETERS) {
                urlParametersMap.putAll(parametersMap);
            } else if(parameterType == TYPE_HEADER_PARAMETERS) {
                headerParametersMap.putAll(parametersMap);
            }
            else if(parameterType == TYPE_EXTRA_PARAMETERS) {
                extraParametersMap.putAll(parametersMap);
            }
            
        }
    }
    
    /*
* This method is used to append the URL parameters at the end of URL
*/
    private void appendURLParameters() {
        Set<String> urlParamKeys = urlParametersMap.keySet();
        List<String> urlParamVals = urlParametersMap.values();
        urlParamKeys.remove(null);
        if(!urlParamKeys.isEmpty() && urlParamKeys.size() > 0) {
            endpointURL += '?';
            for(String urlParamKey : urlParamKeys) {
                endpointURL += urlParamKey + '=' + urlParametersMap.get(urlParamKey) + '&';
            }
            endpointURL = endpointURL.substringBeforeLast('&');
        }
        else if(!urlParamVals.isEmpty() && urlParamVals.size() > 0 ) {
            for(String urlParamVal : urlParamVals) {
                endpointURL += urlParamVal + '&';
            }
            endpointURL = endpointURL.substringBeforeLast('&');
        }
        System.debug('endpoint : ' + endpointURL);
    }
    
    /*
* This method is used to set Header parameters using headerParametersMap
*/
    private void addHeaderParameters() {
        System.debug('headerParametersMap.keySet()==>'+headerParametersMap.keySet());
        for(String key : headerParametersMap.keySet()) {
            request.setHeader(key, headerParametersMap
                              .get(key));
        }
    }
    
    public String getExtraParameter(String key) {
        return extraParametersMap.get(key);
    }
    
    public Map<String, String> getExtraParameters() {
        return extraParametersMap;
    }
    
    /*
* This method is used to form HTTP Request
*/
    public void formHTTPRequest() {
        request = new HTTPRequest();
        addHeaderParameters();
        if(String.isNotEmpty(endpointURL)) {
            //endpointURL = endpointURL.substringBefore('?');
            appendURLParameters();
            request.setEndpoint(endpointURL);
        }
        if(String.isNotEmpty(requestMethod)) {
            request.setMethod(requestMethod);
        }
        if(String.isNotEmpty(requestBody)) {
            request.setBody(requestBody);
        } else if((requestBodyAsBlob != null) &&  String.isNotEmpty(requestBodyAsBlob.toString())) {
            request.setBodyAsBlob(requestBodyAsBlob);
        } else if((requestBodyAsDocument != null) && String.isNotEmpty(requestBodyAsDocument.toXmlString())) {
            request.setBodyDocument(requestBodyAsDocument);
        }
        if(requestTimeout!=null) {
            request.setTimeout(requestTimeout);
        }
        if(String.isNotEmpty(requestCertificate)) {
            request.setClientCertificateName(requestCertificate);
        }
        if(isCompressedRequest!=null) {
            request.setCompressed(isCompressedRequest);
        }
        system.debug('final body - '+request.getBody());
    }
    /*
* This method forms and returns the HTTP Request without sending (for debugging purposes)
*/
    public HTTPRequest getRequest() {
        formHTTPRequest();
        return request;
    }
    
    /*
* This method is used to send HTTP Request and return the response
*/
    public HTTPResponse sendRequest() {
        formHTTPRequest();
        Http http = new Http();
        HTTPResponse obj;
        if(true){
            system.debug('obj===>'+request);
            obj =  http.send(request);
        }else{
            obj = new HTTPResponse();
            obj.setBody(calloutMetadata.Mock_Response__c);
            obj.setStatus('OK');
            obj.setStatusCode(200);
        }
        System.debug('obj final response===>'+obj.getBody());
        System.debug('obj final response2===>'+obj);
        return obj;
    }
    
    /*
* This method is used to send HTTP Request received in parameter and return the response
*/
    public HTTPResponse sendRequest(HTTPRequest request) {
        Http http = new Http();
        HTTPResponse obj;
        
        obj =  http.send(request);
        
        return obj;
    }
    
    public static Callout_Framework__mdt getAPIMetadataDetails(String apiServiceClassName){
        Boolean isApiCalledFromSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String serviceName = /*SUD_ConstantService.getServiceClass(apiServiceClassName)*/  '' ;
        serviceName = isApiCalledFromSandbox ? serviceName+'_sandbox': '';
        System.debug('serviceName ### '+serviceName);
        Callout_Framework__mdt  objData = Callout_Framework__mdt.getInstance(apiServiceClassName);
        RETURN objData;
    }
    
    public SHF_HTTPCalloutService(Callout_Framework__mdt testMetadata) {
        this.calloutMetadata = testMetadata;
        initialize();
    }
}