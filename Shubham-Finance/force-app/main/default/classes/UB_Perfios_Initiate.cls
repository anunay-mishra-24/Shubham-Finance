public with sharing class UB_Perfios_Initiate {
    public class PerfiosResult {
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String rawBody;
        @AuraEnabled public Map<String, Object> jsonParsed;
        @AuraEnabled public String error;
    }
    
    @AuraEnabled
    public static PerfiosResult initiateTransaction(String accessToken, String requestJson, String partnerId, String callbackUrl) {
        PerfiosResult out = new PerfiosResult();
        if (String.isBlank(accessToken)) {
            out.error = 'Access token is required';
            return out;
        }

        // defaults
        if (String.isBlank(partnerId)) partnerId = 'Techmatrix'; 
        if (String.isBlank(callbackUrl)) callbackUrl = 'https://shubhamhousingfinance--dev.sandbox.my.salesforce.com/services/apexrest/TransactionCallback';

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://apiuat.utkarsh.bank/Bank_Statment_v3/v1.0.0/transactions'); 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('partnerID', partnerId);
        req.setHeader('callBackUrl', callbackUrl);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setTimeout(120000); 
        
        if (String.isBlank(requestJson)) {
            Map<String, Object> defaultPayload = new Map<String, Object>{
                'payload' => new Map<String, Object>{
                    'txnId' => 'txn_' + Datetime.now().getTime(),
                    'institutionId' => '20',
                    'processingType' => 'STATEMENT',
                    'loanAmount' => '0',
                    'yearMonthFrom' => '2024-01',
                    'yearMonthTo' => '2024-04',
                    'transactionCompleteCallbackUrl' => callbackUrl
                }
            };
            requestJson = JSON.serialize(defaultPayload);
        }

        req.setBody(requestJson);

        try {
            HttpResponse res = http.send(req);
            out.statusCode = res.getStatusCode();
            out.rawBody = res.getBody();

            // try parse JSON response
            if (res.getBody() != null && res.getBody().trim().startsWith('{')) {
                try {
                    out.jsonParsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                } catch (Exception e) {
                    out.error = 'Response JSON parse error: ' + e.getMessage();
                }
            }

            System.debug('Perfios Initiate - status: ' + out.statusCode + ' body: ' + out.rawBody);
            return out;
        } catch (CalloutException ce) {
            out.error = 'CalloutException: ' + ce.getMessage();
            System.debug('Perfios Initiate - CalloutException: ' + ce.getMessage());
            return out;
        } catch (Exception ex) {
            out.error = 'Exception: ' + ex.getMessage();
            System.debug('Perfios Initiate - Exception: ' + ex.getMessage());
            return out;
        }
    }
}