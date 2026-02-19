public class BankStatementProcess {  
    static String privateKey = 
    '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';
    
    String host = 'demo.perfios.com';
    String perfiosDate = '20230315T050234Z'; //Datetime.now().formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
    String txnID ='TXNUKSB01';
    String algorithm = 'PERFIOS1-RSA-SHA256';
    
    public AuthPayload createCanonicalRequest(string method, string path, string payload){
        AuthPayload cPayload = new AuthPayload();
        system.debug('payload: \n '+payload);
        String payloadHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(payload)));
    	String canonicalUri = path; 
        String canonicalQueryString = '';
        string canonicalHeaders= 'host:' + host + '\n' 
            + 'x-perfios-content-sha256:' + payloadHash + '\n' 
            + 'x-perfios-date:' + perfiosDate;
        String signedHeaders = 'host;x-perfios-content-sha256;x-perfios-date';
        String canonicalRequest = method + '\n' 
            + canonicalUri + '\n'  
            + canonicalQueryString + '\n' 
            + canonicalHeaders + '\n' 
            + signedHeaders + '\n' 
            + payloadHash;
        
        System.debug('canonicalRequest: \n'+canonicalRequest);        
        String stringToSign = algorithm + '\n' +  perfiosDate + '\n' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', Blob.valueOf(canonicalRequest)));
        System.debug('stringToSign: \n'+stringToSign);
        
        String Checksum = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(StringToSign))) ; 
        System.debug('Checksum: \n'+Checksum);        
        
        Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey);
        String signature = EncodingUtil.convertToHex(Crypto.sign('RSA-SHA256', Blob.valueOf(Checksum), privateKeyBlob)).toLowerCase();
        
        System.debug('Updated signature: \n'+signature);
        cPayload.signature = signature;
        cPayload.perfdate = perfiosDate;
        cPayload.payloadHash = payloadHash;
        return cPayload;
        
    }
    
    public AuthPayload createCanonicalRequest1(string method, string path, string payload){
         AuthPayload cPayload = new AuthPayload();
        system.debug('payload: \n '+payload);
        String payloadHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(payload)));
    	String canonicalUri = path; 
        String canonicalQueryString = 'types=json';
        string canonicalHeaders= 'host:' + host + '\n' 
            + 'x-perfios-content-sha256:' + payloadHash + '\n' 
            + 'x-perfios-date:' + perfiosDate;
        String signedHeaders = 'host;x-perfios-content-sha256;x-perfios-date';
        String canonicalRequest = method + '\n' 
            + canonicalUri + '\n'  
            + canonicalQueryString + '\n' 
            + canonicalHeaders + '\n' 
            + signedHeaders + '\n' 
            + payloadHash;
        
        System.debug('canonicalRequest: \n'+canonicalRequest);        
        String stringToSign = algorithm + '\n' +  perfiosDate + '\n' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', Blob.valueOf(canonicalRequest)));
        System.debug('stringToSign: \n'+stringToSign);
        
        String Checksum = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(StringToSign))) ; 
        System.debug('Checksum: \n'+Checksum);        
        
        Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey);
        String signature = EncodingUtil.convertToHex(Crypto.sign('RSA-SHA256', Blob.valueOf(Checksum), privateKeyBlob)).toLowerCase();
        
        System.debug('Updated signature: \n'+signature);
        cPayload.signature = signature;
        cPayload.perfdate = perfiosDate;
        cPayload.payloadHash = payloadHash;
        return cPayload;
        
    }
    public void createTransaction(){
        String method = 'POST';
        String payload = '{"payload": {"loanAmount": "100000","loanDuration": "24","loanType": "Home","processingType":"STATEMENT","transactionCompleteCallbackUrl": "https://example.com/callback","txnId": "PQ1342687YTX","acceptancePolicy": "atLeastOneTransactionPerMonthInRange","yearMonthFrom": "2023-11","yearMonthTo": "2024-02","proposedEmi": "234536","employmentType": "Salaried","employerName": "ABCD.ltd"}}';  
    	String path = '/KuberaVault/api/v3/organisations/salesforceLOS/transactions';
    	String endpoint = 'https://demo.perfios.com/KuberaVault/api/v3/organisations/shubhamHF/transactions';
    
        AuthPayload cPayload = createCanonicalRequest(method, path, payload);
    	HTTP http = new HTTP();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('content-type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Host', host);
        req.setHeader('X-Perfios-Algorithm', algorithm);
        req.setHeader('X-Perfios-Content-Sha256', cPayload.payloadHash);
        req.setHeader('X-Perfios-Date', cPayload.perfdate);
        req.setHeader('X-Perfios-Signature', cPayload.signature);
        req.setHeader('X-Perfios-Signed-Headers', 'host;x-perfios-content-sha256;x-perfios-date');
        req.setBody(payload);
        system.debug('Request: \n'+req);
        HTTPResponse res = http.send(req);
        System.debug('Response: \n'+res.getStatus()+'---'+res.getBody());
    }    

    /** public void uploadFiles(String transId, String fileName){
    	String method = 'POST';	
        String transactionId = transId;
    	String endpoint = 'https://demo.perfios.com/KuberaVault/api/v3/organisations/shubhamHF/transactions/'+transactionId+'/files';
        String path = '/KuberaVault/api/v3/organisations/shubhamHF/transactions/'+transactionId+'/files';
    	 
    	Document doc = [SELECT id, name, body, type FROM document WHERE Name=: fileName][0];
        
        String contentType = FormData.GetContentType();
        string form64 = '';
        //adding documents metadata or properties
        
        form64 += FormData.append('key','Value');
        form64 += FormData.append('key','value');
        
        //adding documents body with file parameter
        blob formBlob= FormData.makeBlobWithFile('file',doc.body,doc.Name+'.'+doc.Type,form64);
        string contentLength = string.valueOf(formBlob.size());
        
        AuthPayload cPayload = createCanonicalRequest(method, path, '');
    	HTTP http = new HTTP();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        //Additional Headers
        req.setHeader('Connection', 'keep-alive');
        req.setHeader('Content-Length', contentLength);
        req.setHeader('Content-Type', contentType);
        req.setTimeout(120000);
        req.setHeader('Host', host);
        req.setHeader('X-Perfios-Algorithm', algorithm);
        req.setHeader('x-perfios-content-sha256', cPayload.payloadHash);
        req.setHeader('x-perfios-date', cPayload.perfdate);
        req.setHeader('X-Perfios-Signature', cPayload.signature);
        req.setHeader('X-Perfios-Signed-Headers', 'host;x-perfios-content-sha256;x-perfios-date');
        req.setHeader('cache-control', 'no-cache');
        req.setHeader('Accept', 'application/json');
        req.setBodyAsBlob(formBlob);
        system.debug('Request: \n'+req);
        HTTPResponse res = http.send(req);
        System.debug('Response: \n'+res.getStatus()+'---'+res.getBody());
    } **/
    public void processFiles(String transId, String fileId){
    	String method = 'POST';	
        String transactionId = transId;
    	String endpoint = 'https://demo.perfios.com/KuberaVault/api/v3/organisations/shubhamHF/transactions/'+transactionId+'/bank-statements';
        String path = '/KuberaVault/api/v3/organisations/shubhamHF/transactions/'+transactionId+'/bank-statements';
        String payload = '{"payload": {"fileId": "'+fileId+'"}}';  
    	
        AuthPayload cPayload = createCanonicalRequest(method, path, payload);
    	HTTP http = new HTTP();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('content-type', 'application/json');
        req.setHeader('Host', host);
        req.setHeader('X-Perfios-Algorithm', algorithm);
        req.setHeader('X-Perfios-Content-Sha256', cPayload.payloadHash);
        req.setHeader('X-Perfios-Date', cPayload.perfdate);
        req.setHeader('X-Perfios-Signature', cPayload.signature);
        req.setHeader('X-Perfios-Signed-Headers', 'host;x-perfios-content-sha256;x-perfios-date');
        req.setHeader('cache-control', 'no-cache');
        req.setHeader('Accept', 'application/json');
        req.setBody(payload);
        system.debug('Request: \n'+req);
        HTTPResponse res = http.send(req);
        System.debug('Response: \n'+res.getStatus()+'---'+res.getBody());
    }
    public void generateReport(String transId){
    	String method = 'POST';	
        String transactionId = transId;
    	String endpoint = 'https://demo.perfios.com/KuberaVault/api/v3/organisations/shubhamHF/transactions/'+transactionId+'/reports';
        String path = '/KuberaVault/api/v3/organisations/shubhamHF/transactions/'+transactionId+'/reports';
    	String payload = '';  
    	Document doc = [SELECT id, name, body FROM document][0];
        
        AuthPayload cPayload = createCanonicalRequest(method, path, payload);
    	HTTP http = new HTTP();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('content-type', 'application/json');
        req.setHeader('Host', host);
        req.setHeader('X-Perfios-Algorithm', algorithm);
        req.setHeader('X-Perfios-Content-Sha256', cPayload.payloadHash);
        req.setHeader('X-Perfios-Date', cPayload.perfdate);
        req.setHeader('X-Perfios-Signature', cPayload.signature);
        req.setHeader('X-Perfios-Signed-Headers', 'host;x-perfios-content-sha256;x-perfios-date');
        req.setHeader('cache-control', 'no-cache');
        req.setHeader('Accept', 'application/json');
        req.setBody(payload);
        system.debug('Request: \n'+req);
        HTTPResponse res = http.send(req);
        System.debug('Response: \n'+res.getStatus()+'---'+res.getBody());
    }
    public void retrieveReport(String transId){
    	String method = 'GET';	
        String transactionId = transId;
    	String endpoint = 'https://demo.perfios.com/KuberaVault/api/v3/organisations/shubhamHF/transactions/'+transactionId+'/reports?types=json';
        String path = '/KuberaVault/api/v3/organisations/shubhamHF/transactions/'+transactionId+'/reports';
    	String payload = '';  
    	
        AuthPayload cPayload = createCanonicalRequest1(method, path, payload);
    	HTTP http = new HTTP();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('content-type', 'application/json');
        req.setHeader('Host', host);
        req.setHeader('X-Perfios-Algorithm', algorithm);
        req.setHeader('X-Perfios-Content-Sha256', cPayload.payloadHash);
        req.setHeader('X-Perfios-Date', cPayload.perfdate);
        req.setHeader('X-Perfios-Signature', cPayload.signature);
        req.setHeader('X-Perfios-Signed-Headers', 'host;x-perfios-content-sha256;x-perfios-date');
        req.setHeader('cache-control', 'no-cache');
        req.setHeader('Accept', 'application/json');
        req.setBody(payload);
        system.debug('Request: \n'+req);
        HTTPResponse res = http.send(req);
        System.debug('Response: \n'+res.getStatus()+'---'+res.getBody());
    }
    public class AuthPayload{
        public string signature;
        public string perfdate;
        public string payloadHash;
    }
}