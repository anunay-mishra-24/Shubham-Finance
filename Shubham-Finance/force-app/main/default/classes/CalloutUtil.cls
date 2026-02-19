public with sharing class CalloutUtil {

    public static String callApi(
        Callout_Framework__mdt config,
        String body,
        Boolean isAuthRequired
    ){
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        String endpoint =
            config.Host__c.removeEnd('/') + '/' +
            config.Endpoint__c.removeStart('/');

        req.setEndpoint(endpoint);
        req.setMethod(config.HTTP_Method__c);
        req.setBody(body);

        Map<String,String> headers = new Map<String,String>();
        headers.put('Content-Type', 'application/json');

        if(isAuthRequired && !String.isBlank(config.Auth_Token_c__c)){
            String token = config.Auth_Token_c__c.trim();
            if(!token.startsWithIgnoreCase('Bearer')){
                token = 'Bearer ' + token;
            }
            headers.put('Authorization', token);
        }

        if(!String.isBlank(config.HeaderParams__c)){
            for(String h : config.HeaderParams__c.split(';')){
                List<String> kv = h.split(':',2);
                if(kv.size()==2){
                    headers.put(kv[0].trim(), kv[1].trim());
                }
            }
        }

        for(String k : headers.keySet()){
            req.setHeader(k, headers.get(k));
        }

        // -------- REQUEST DEBUG --------
        System.debug('===== API REQUEST =====');
        System.debug('Endpoint => ' + endpoint);
        System.debug('Method   => ' + config.HTTP_Method__c);
        System.debug('Body     => ' + body);
        for(String k : headers.keySet()){
            System.debug('Header => ' + k + '=' + headers.get(k));
        }
        System.debug('=======================');

        try{
            HttpResponse res = http.send(req);
            System.debug('Status => ' + res.getStatusCode());
            System.debug('Response => ' + res.getBody());

            if(res.getStatusCode() == 200){
                return res.getBody();
            }
        }catch(Exception e){
            System.debug('Callout Exception => ' + e.getMessage());
        }
        return null;
    }
}