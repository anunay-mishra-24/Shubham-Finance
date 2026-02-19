@RestResource(urlMapping='/api/hdfcPaymentWebhook/*')
global with sharing class HdfcPaymentWebHookHandler {
    @HttpPost
    global static void handlePost(){
        RestRequest requestContext = RestContext.request;
        RestResponse responseContext = RestContext.response;
        //Request
        System.debug('###Post');
    }
}