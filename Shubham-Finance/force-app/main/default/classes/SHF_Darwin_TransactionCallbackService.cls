@RestResource(urlMapping='/DarwinTransactionCallback/*')
global class SHF_Darwin_TransactionCallbackService {

    @HttpPost
    global static void darwinWebhookListner() {
        try {
            RestResponse response = RestContext.response;
            RestRequest request = RestContext.request;

            // Success response
            RestContext.response.responseBody =
                Blob.valueOf('{ "status":"success", "message": "Logs created successfully!" }');

            // Log request body
            Logger.info(String.valueOf(request.requestBody));

        } catch (Exception e) {
            // Log the exception
            Logger.error('Error: ' + e.getMessage());

        } finally {
            Logger.saveLog();
        }
    }
}