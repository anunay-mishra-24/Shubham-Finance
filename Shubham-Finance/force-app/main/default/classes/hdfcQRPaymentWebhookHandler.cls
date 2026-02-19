@RestResource(urlMapping='/api/hdfcQRPaymentWebhook/*')
global with sharing class hdfcQRPaymentWebhookHandler {
    @HttpPost
    global static void handlePost(){
        RestRequest requestContext = RestContext.request;
        RestResponse responseContext = RestContext.response;
        //Request
        System.debug('###Post');
    }
}