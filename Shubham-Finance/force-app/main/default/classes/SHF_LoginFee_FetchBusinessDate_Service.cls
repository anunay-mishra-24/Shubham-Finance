/**
 * @File Name          : SHF_LoginFee_FetchBusinessDate_Service.cls
 * @Description        : Service class to fetch login fee business date and create E-Verification records.
 * @Author             : Kunal Soni
 * 
 * ==============================================================================
 * Ver         Date              Author           Modification
 * ==============================================================================
 * 1.0         31-07-2025        Kunal Soni        Initial Version
 */
public class SHF_LoginFee_FetchBusinessDate_Service {

    public SHF_HTTPCalloutService service;

    /**
     * Fetches the current business date for a given branch code.
     *
     * @param branchCode The branch code to fetch the business date for.
     * @return List<String> containing the response code and business date, if available.
     */
    public static List<String> getBusinessDate(String branchCode) {
        List<String> resultData = new List<String>();

        try {
            // Generate access token
            String accessToken = SHF_LMSCommonUtil.generateAccessToken();

            if (String.isNotBlank(accessToken)) {
                // Initialize the service
                SHF_LoginFee_FetchBusinessDate_Service serviceInstance = new SHF_LoginFee_FetchBusinessDate_Service();
                serviceInstance.service = new SHF_HTTPCalloutService('LoginFee_Fetch_Business_Date');

                // Set headers and request body
                serviceInstance.service.setHeaderParameter('access_token', accessToken);
                serviceInstance.service.setRequestBody(
                    serviceInstance.service.getRequestBody().replace('<branchCode>', branchCode)
                );

                HttpResponse response;

                // Send real or mock request
                if (serviceInstance.service.getIsActive()) {
                    response = serviceInstance.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setStatusCode(200);
                    response.setBody(serviceInstance.service.getmockRespnse());
                }

                // Parse the response
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                    // Add responseCode
                    resultData.add(String.valueOf(rootMap.get('responseCode')));

                    // Extract business date from payload
                    if (rootMap.containsKey('payload')) {
                        Map<String, Object> payloadMap = (Map<String, Object>) rootMap.get('payload');
                        resultData.add(String.valueOf(payloadMap.get('currentBusinessDate')));
                    }
                }
            }
        } catch (Exception ex) {
            Logger.error('Login Fee Business Date Fetch Error: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }

        return resultData;
    }
}