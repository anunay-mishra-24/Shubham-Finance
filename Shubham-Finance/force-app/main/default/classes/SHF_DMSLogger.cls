//Added by Ranjeet without sharing for Public Site Upload Documents
public without sharing class SHF_DMSLogger {
    
    @AuraEnabled
    public static void logDMSCall(String requestBody, String responseBody, Integer statusCode, Boolean isError) {
        try {
            system.debug('requestBody 11 '+requestBody);
            String reqLog = requestBody;
            if (reqLog != null && reqLog.length() > 5000) {
                reqLog = reqLog.substring(0, 5000) + '... [TRUNCATED]';
            }
            system.debug('responseBody 11 '+responseBody);
            String respLog = responseBody;
            if (respLog != null && respLog.length() > 5000) {
                respLog = respLog.substring(0, 5000) + '... [TRUNCATED]';
            }
            if (isError) {
                Logger.error('DMS Request Body: ' + reqLog);
                Logger.error('DMS Response Body: ' + respLog);
                Logger.error('DMS Status Code: ' + statusCode);
            } else {
                Logger.info('DMS Request Body: ' + reqLog);
                Logger.info('DMS Response Body: ' + respLog);
                Logger.info('DMS Status Code: ' + statusCode);
            }
        } catch (Exception e) {
            Logger.error('Logging exception: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }
}