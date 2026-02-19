/**
 * @File Name          : SHF_LitigationAccessToken_Service.cls
 * @Description        : Use to get the access token for litigation api
 * @Author             : Vikas Soni
 * @Test Class         :
 *==============================================================================
 * Ver          Date            Author            Modification
 *==============================================================================
 * 1.0       12-01-2026      Vikas Soni       Initial Version
 */
public with sharing class SHF_LitigationAccessToken_Service {
    public SHF_HTTPCalloutService service;
    public static String generateAccessToken(){
        String accessToken = '';
        
        try {
            SHF_LitigationAccessToken_Service accessTokenService = new SHF_LitigationAccessToken_Service();
            accessTokenService.service = new SHF_HTTPCalloutService('Litigation_Access_Token');
            
            
            HttpResponse response;
            // String responseBody;
            
            // Set headers and body
            
            // Make callout or use mock response
            if (accessTokenService.service.getIsActive()) {
                response = accessTokenService.service.sendRequest();
            } else {
                response = new HttpResponse();
                response.setBody(accessTokenService.service.getmockRespnse());
                response.setStatusCode(200);
            }
            
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                SHF_LitigationAccessTokenParser litigationTokenParser = new SHF_LitigationAccessTokenParser();
                litigationTokenParser = SHF_LitigationAccessTokenParser.parse(response.getBody());
                if(litigationTokenParser.statusMsg.equals('Success')){
                    accessToken = litigationTokenParser.apiKey;
                    Logger.info('SHF_LitigationAccessToken_Service: Access Token : ' + accessToken);
                    System.debug('SHF_LitigationAccessToken_Service: Access Token : ' + accessToken);
                }
            } else {
                System.debug('Error in SHF_LitigationAccessToken_Service : ' + response.getStatusCode() + ' ' + response.getStatus());
                Logger.error('Error in SHF_LitigationAccessToken_Service : ' + response.getStatusCode() + ' ' + response.getStatus());
            }
        } catch (Exception e) {
            Logger.error('Exception in SHF_LitigationAccessToken_Service : ' + e.getMessage() + ' ' + e.getLineNumber());
        }
        finally {
            Logger.saveLog();
        }
        return accessToken;
    }
    // not need now may be in future so commenting
    // public static String generateAccessTokenInstant(){
    //     String accessToken = '';
        
    //     try {
    //         SHF_LitigationAccessToken_Service accessTokenService = new SHF_LitigationAccessToken_Service();
    //         accessTokenService.service = new SHF_HTTPCalloutService('Litigation_Access_Token');
            
            
    //         HttpResponse response;
    //         // String responseBody;
            
    //         // Set headers and body
            
    //         // Make callout or use mock response
    //         if (accessTokenService.service.getIsActive()) {
    //             response = accessTokenService.service.sendRequest();
    //         } else {
    //             response = new HttpResponse();
    //             response.setBody(accessTokenService.service.getmockRespnse());
    //             response.setStatusCode(200);
    //         }
            
            
    //         if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
    //             SHF_LitigationAccessTokenParser litigationTokenParser = new SHF_LitigationAccessTokenParser();
    //             litigationTokenParser = SHF_LitigationAccessTokenParser.parse(response.getBody());
    //             if(litigationTokenParser.statusMsg.equals('Success')){
    //                 accessToken = litigationTokenParser.apiKey;
    //                 Logger.info('SHF_LitigationAccessToken_Service: Access Token : ' + accessToken);
    //                 System.debug('SHF_LitigationAccessToken_Service: Access Token : ' + accessToken);
    //             }
    //         } else {
    //             System.debug('Error in SHF_LitigationAccessToken_Service : ' + response.getStatusCode() + ' ' + response.getStatus());
    //             Logger.error('Error in SHF_LitigationAccessToken_Service : ' + response.getStatusCode() + ' ' + response.getStatus());
    //         }
    //     } catch (Exception e) {
    //         Logger.error('Exception in SHF_LitigationAccessToken_Service : ' + e.getMessage() + ' ' + e.getLineNumber());
    //     }
    //     finally {
    //         Logger.saveLog();
    //     }
    //     return accessToken;
    // }
}