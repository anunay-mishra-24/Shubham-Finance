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
public class HTTPCalloutService {
    
    public Callout_Framework__mdt calloutMetadata;
    
    String endpointURL, requestMethod, requestBody, requestCertificate, namedCredential,mockRespnse,host;
    Blob requestBodyAsBlob;
    Dom.Document requestBodyAsDocument;
    Integer requestTimeout;
    Boolean isCompressedRequest;
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
    /////////////////////////////
    public String getHeaderParameter(String key) {
        return headerParametersMap.get(key);
    }
    
    public Map<String, String> getHeaderParameters() {
        return headerParametersMap;
    }
    /////////////////////
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
    
    public HTTPCalloutService(String customMetadataName) {
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
            mockRespnse = calloutMetadata.Mock_Response__c;
            requestMethod = calloutMetadata.HTTP_Method__c;
            requestBody = calloutMetadata.Body__c;
            requestTimeout = Integer.valueOf(calloutMetadata.Timeout_Time__c);
            setUrlOrHeaderParameters(TYPE_HEADER_PARAMETERS, calloutMetadata.HeaderParams__c);
            setUrlOrHeaderParameters(TYPE_EXTRA_PARAMETERS, calloutMetadata.Extra_Param_s__c);
            setUrlOrHeaderParameters(TYPE_URL_PARAMETERS, calloutMetadata.URL_Parameter_s__c);
            
            System.debug('endpoint url '+ endpointURL);
             System.debug('mockRespnse url '+ mockRespnse);
             System.debug('requestMethod url '+ requestMethod);
            System.debug('requestBody url '+ requestBody);
            System.debug('here');
        }
    }
   /* @AuraEnabled
    public static String initiateVerification(Id customerId, String apiName,String actionName) {
        system.debug('customerId'+customerId);
        system.debug('apiName'+apiName);
        system.debug('actionName'+actionName);
        if (String.isNotBlank(apiName) && customerId != null) {
            system.debug('apiName'+apiName);
            if (apiName == ConstantsUtil.PAN_API) {
                return PAN_API.validatePANNumber(customerId);
            } else if (apiName == ConstantsUtil.Mobile_MNRL_API) {
                return Mobile_MNRL_API.validateMobileNumber(customerId);
            } else if (apiName == ConstantsUtil.KYC_DigiLocker_API) {
                if(actionName == ConstantsUtil.Retrieve_DigiLocker_API){
                    return KYC_DigiLocker_API.validateDigilockerKYCDetails(customerId);
                }else{
                    return KYC_DigiLocker_API.validateDigilockerKYC(customerId);                   
                }
            }
            
        }
        return null;
    }*/
    
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
            obj =  http.send(request);
            system.debug('obj===>'+obj);
        }else{
            obj = new HTTPResponse();
            obj.setBody(calloutMetadata.Mock_Response__c);
            obj.setStatus('OK');
            obj.setStatusCode(200);
        }
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
}