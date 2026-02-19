/**
 * @File Name          : SHF_LMSCommonUtil.cls
 * @Description        : Common methods that need to be reused across multiple classes should be defined here.
 * @Author             : Kunal Soni
 * ==============================================================================
 * Ver         Date         Author       Modification
 * ==============================================================================
 * 1.0         22-07-2025   Kunal Soni   Initial Version
 */

public class SHF_LMSCommonUtil {
    
    public SHF_HTTPCalloutService service;
    
    // Generate Access Token
    public static String generateAccessToken() {
        SHF_LMSCommonUtil lmsAccessToken = new SHF_LMSCommonUtil();
        lmsAccessToken.service = new SHF_HTTPCalloutService('LMS_Access_Token');
        
        HttpResponse response;
        String responseBody;
        
        // Set request body parameters (URL-encoded)
        String clientId = Label.LMSClientId;
        String grantType = Label.LMSGrantType;
        String clientSecret = Label.LMSClientSecret;
        
        String body = 'client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
            '&grant_type=' + EncodingUtil.urlEncode(grantType, 'UTF-8') +
            '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');
        
        // Set headers and body
        lmsAccessToken.service.setHeaderParameter('Content-Type', 'application/x-www-form-urlencoded');
        lmsAccessToken.service.setRequestBody(body);
        
        // Make callout or use mock response
        if (lmsAccessToken.service.getIsActive()) {
            response = lmsAccessToken.service.sendRequest();
        } else {
            response = new HttpResponse();
            response.setBody(lmsAccessToken.service.getmockRespnse());
            response.setStatusCode(200);
        }
        
        // Process response
        responseBody = (response != null) ? response.getBody() : null;
        
        if (String.isBlank(responseBody)) {
            Logger.error('Access token API response is missing or invalid.');
        }
        
        Map<String, Object> accessTokenMap = new Map<String, Object>();
        
        if (String.isNotBlank(responseBody)) {
            System.debug('Access token response: ' + responseBody);
            accessTokenMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            if (accessTokenMap.containsKey('access_token')) {
                System.debug('Access Token: ' + accessTokenMap.get('access_token'));
                return (String) accessTokenMap.get('access_token');
            }
        }
        return null;
    }
    /**
     * Utility method to split comma-separated placeholders into a List<String>
     */
    public static List<String> getPlaceholdersList(String placeholderString) {
        List<String> result = new List<String>();
        if (String.isNotBlank(placeholderString)) {
          //  Remove square brackets if present
     //   placeholderString = placeholderString.remove('[').remove(']').remove('.').remove('(').remove(')').trim();
        placeholderString = placeholderString.remove('[').remove(']').remove('(').remove(')').trim();
            for (String token : placeholderString.split(',')) {
               result.add(token.trim());
            }
        }
        return result;
    }
    
    // change date formate
    
    public static Date parseDateFormate(String inputDateStr) {
        if (String.isBlank(inputDateStr)) {
            return null;
        }
        
        try {
            List<String> parts = inputDateStr.trim().split('/');
            if (parts.size() != 3) {
                return null;
            }
            
            Integer day = Integer.valueOf(parts[0]);
            Integer month = Integer.valueOf(parts[1]);
            Integer year = Integer.valueOf(parts[2]);
            
            return Date.newInstance(year, month, day);
        } catch (Exception e) {
            // Log error if needed: System.debug('Invalid date format: ' + e.getMessage());
            return null;
        }
    }

    public class PlaceholderInput {
        @InvocableVariable(required=true label='Raw Placeholder String')
        public String placeholderRaw;
    }

    public class PlaceholderOutput {
        @InvocableVariable(label='Parsed Placeholder List')
        public List<String> placeholders;
    }

    @InvocableMethod(label='Get Placeholder List from String' description='Parses comma-separated placeholders')
    public static List<List<String>> parsePlaceholders(List<PlaceholderInput> inputs) {
       List<List<String>> results = new List<List<String>>();

        for (PlaceholderInput input : inputs) {
            List<String> outstring = SHF_LMSCommonUtil.getPlaceholdersList(input.placeholderRaw);
            results.add(outstring);
        }
        return results;
    }
}