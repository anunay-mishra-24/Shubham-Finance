public with sharing class UB_TokenService {
    public static void getAccessToken() {
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint('callout:PerfiosToken/oauthnew2/v1.0.0/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        req.setBody(
            '{"grant_type":"client_credentials","clientInfo":"STRIMHFSQmYxa3Zwbk9JNk1zZ0pfSmNUVGZBYTp1SEhhSzRIbWZsRDhSb2ZWeWU0UWRrOFZ6cWNh"}'
        );

        HttpResponse res = http.send(req);
        System.debug('RAW: ' + res.getBody());

        if(res.getStatusCode() == 200){
            Map<String,Object> m = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
            System.debug('ACCESS TOKEN → ' + m.get('access_token'));
        }
    }
}