@RestResource(urlMapping='/enachWebhook')
global without sharing class EnachWebhookAPI {

    @HttpPost
    global static void handleResponse() {

        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();

        System.debug('Webhook Raw Body: ' + body);

        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(body);

        String msgId  = (String) data.get('MsgId');
        String status = (String) data.get('Status');
        String umrn   = (String) data.get('UMRN');

        if(String.isBlank(msgId)){
            throw new AuraHandledException('MsgId missing');
        }

        List<E_Nach__c> records = [
            SELECT Id, Status__c
            FROM E_Nach__c
            WHERE Id = :msgId
            LIMIT 1
        ];

        if(!records.isEmpty()){
         System.debug('Testing==>Enach==>');
        }
    }
}