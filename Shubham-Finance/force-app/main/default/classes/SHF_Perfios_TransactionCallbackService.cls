/**
 * @author            : 
 * @group             : TechMatrix Consulting
 * @description       : 
 * @created on        : 
 * @last modified on  : 11-12-2025
 * @last modified by  : Karan Singh Soni
 * @Contributor       : 
 * @Version History   : 
**/
@RestResource(urlMapping='/TransactionCallback/*')
global class SHF_Perfios_TransactionCallbackService {

    @HttpPost
    global static void perfiosWebhookListner() {
        try {
            RestResponse response = RestContext.response;
            RestRequest request = RestContext.request;
            RestContext.response.responseBody = Blob.valueOf('{ "status":"success", "message": "Logs created successfully!" }');
            // Log request body
             Logger.info(String.valueOf(request.requestBody.toString()));

        } catch (Exception e) {
            // Log the exception
            Logger.error('Error: ' + e.getMessage());

        } finally {
            Logger.saveLog();
        }
    }
}