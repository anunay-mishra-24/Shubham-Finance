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
@RestResource(urlMapping='/LitigationReport/*')
global class SHF_LitigationService {
    @HttpPost
    global static void webhookListner(){
        try{
            RestResponse response = RestContext.response;
            RestRequest request = RestContext.request;
            RestContext.response.responseBody = Blob.valueOf('{ "status":"success", "message": "' + 'Logs created successfully!" }');
            // Log the info for request body
             Logger.info(String.valueOf(request.requestBody.toString()));
        }catch (Exception e) {
            // Log the exception for visibility
            Logger.error('Error' + e.getMessage());
        }finally{
            Logger.saveLog();
        }
    }
}