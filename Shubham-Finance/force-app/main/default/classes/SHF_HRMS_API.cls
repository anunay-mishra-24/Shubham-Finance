/*
* @File Name          : SHF_HRMS_API.cls
* @Author             : Ranjeet Pandit
* @Last Modified Date : 06 Feb 2026
* @Description        : fetching Active and Inactive data from HRMS API's.
*/
public class SHF_HRMS_API { 
    
    @AuraEnabled
    public static String getActiveEmployeeData() {
        String message = 'Failed';
        
        try {
            Map<String, Callout_Framework__mdt> metaMap = SHF_CommonUtil.getCalloutMetadata('HRMS_Active_Employee_Data');
            
            Callout_Framework__mdt metadata = metaMap.get('HRMS_Active_Employee_Data');
            
            if (metadata == null || !metadata.Active__c) {
                Logger.error('Callout metadata not found or inactive');
                return message;
            }
            SHF_HTTPCalloutService callout = new SHF_HTTPCalloutService('HRMS_Active_Employee_Data');
            
            callout.setRequestMethod(metadata.HTTP_Method__c);
            callout.setEndpointURL(metadata.Endpoint__c);
            callout.setRequestBody(metadata.Body__c);
            
            HttpResponse response = callout.sendRequest();
            
            Logger.info('Response Status Code: ' + response.getStatusCode());
            Logger.info('Response Status: ' + response.getStatus());
            Logger.info('Response Endpoint: ' + metadata.Endpoint__c);
            Logger.info('Response Method: ' + metadata.HTTP_Method__c);
            
            String responseBody = response.getBody();
            
            if (responseBody != null && responseBody.length() > 5000) {
                responseBody = responseBody.substring(0, 5000) + '... [TRUNCATED]';
            }
            
            Logger.info('Response Body: ' + responseBody);
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                
                Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('HRMS Response Map => ' + res);
                message = 'Success';
                
            } else {
                Logger.error(
                    'HRMS API failed. StatusCode=' + response.getStatusCode()
                );
            }
            
        } catch (Exception e) {
            Logger.error('Error in HRMS_Active_Employee_Data: ' + e.getMessage());
            System.debug('Exception StackTrace: ' + e.getStackTraceString());
        } finally {
            Logger.saveLog();
        }
        
        System.debug('Final Message => ' + message);
        return message;
    }
    
    
    
    @AuraEnabled
    public static String getInactiveEmployeeData() {
        String message = '';
        try {
            Map<String, Callout_Framework__mdt> metaMap = SHF_CommonUtil.getCalloutMetadata('HRMS_Inactive_Employee_Data');       
            Callout_Framework__mdt metadata = metaMap.get('HRMS_Inactive_Employee_Data');  
            if(metadata == null || !metadata.Active__c){
                Logger.error('Callout metadata not found or inactive');
                return message;
            }
            SHF_HTTPCalloutService callout = new SHF_HTTPCalloutService('HRMS_Inactive_Employee_Data');          
            callout.setRequestMethod(metadata.HTTP_Method__c);
            callout.setEndpointURL(metadata.Endpoint__c);
            callout.setRequestBody(metadata.Body__c);
            
            HttpResponse response = callout.sendRequest();
            
            Logger.info('Response Status Code: ' + response.getStatusCode());
            Logger.info('Response Status: ' + response.getStatus());
            Logger.info('Response Endpoint: ' + metadata.Endpoint__c);
            Logger.info('Response Method: ' + metadata.HTTP_Method__c);
            
            String responseBody = response.getBody();
            
            if(responseBody != null && responseBody.length() > 5000){
                responseBody = responseBody.substring(0, 5000) + '... [TRUNCATED]';
            }
            
            Logger.info('Response Body: ' + responseBody);
            
            if(response.getStatusCode() == 200 && String.isNotBlank(response.getBody())){
                
                Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('HRMS Response Map => ' + res);
                message = 'Success';
                
            } 
            else {
                Logger.error(
                    'HRMS API failed. StatusCode=' + response.getStatusCode()
                );
            }
            
        }
        catch (Exception e) {
            Logger.error('Error in HRMS_InActive_Employee_Data: ' + e.getMessage());
            System.debug('Exception StackTrace: ' + e.getStackTraceString());
        } 
        finally {
            Logger.saveLog();
        }
        System.debug('Final Message => ' + message);
        return message;
    }

    // NEW METHOD: For Batch class to fetch active employee data
    public static List<Object> getActiveEmployeeList() {
        List<Object> employeeList = new List<Object>();
        
        try {
            Map<String, Callout_Framework__mdt> metaMap = SHF_CommonUtil.getCalloutMetadata('HRMS_Active_Employee_Data');
            Callout_Framework__mdt metadata = metaMap.get('HRMS_Active_Employee_Data');
            
            if (metadata == null || !metadata.Active__c) {
                Logger.error('Callout metadata not found or inactive for Active Employee Data');
                return employeeList;
            }
            
            SHF_HTTPCalloutService callout = new SHF_HTTPCalloutService('HRMS_Active_Employee_Data');
            callout.setRequestMethod(metadata.HTTP_Method__c);
            callout.setEndpointURL(metadata.Endpoint__c);
            callout.setRequestBody(metadata.Body__c);
            
            HttpResponse response = callout.sendRequest();
            
            Logger.info('Active Employee API Response Status Code: ' + response.getStatusCode());
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                // Extract the employee list from 'employee_data' key based on actual API structure
                if (res.containsKey('employee_data')) {
                    employeeList = (List<Object>) res.get('employee_data');
                    Logger.info('Active employees fetched: ' + employeeList.size());
                } else {
                    Logger.warn('employee_data key not found in API response');
                    Logger.warn('Available keys: ' + String.join(new List<String>(res.keySet()), ', '));
                }
            } else {
                Logger.error('Active Employee API failed. StatusCode=' + response.getStatusCode());
            }
            
        } catch (Exception e) {
            Logger.error('Error in getActiveEmployeeList: ' + e.getMessage());
            System.debug('Exception StackTrace: ' + e.getStackTraceString());
        }
        
        return employeeList;
    }
    
    // NEW METHOD: For Batch class to fetch inactive employee data
    public static List<Object> getInactiveEmployeeList() {
        List<Object> employeeList = new List<Object>();
        
        try {
            Map<String, Callout_Framework__mdt> metaMap = SHF_CommonUtil.getCalloutMetadata('HRMS_Inactive_Employee_Data');
            Callout_Framework__mdt metadata = metaMap.get('HRMS_Inactive_Employee_Data');
            
            if (metadata == null || !metadata.Active__c) {
                Logger.error('Callout metadata not found or inactive for Inactive Employee Data');
                return employeeList;
            }
            
            SHF_HTTPCalloutService callout = new SHF_HTTPCalloutService('HRMS_Inactive_Employee_Data');
            callout.setRequestMethod(metadata.HTTP_Method__c);
            callout.setEndpointURL(metadata.Endpoint__c);
            callout.setRequestBody(metadata.Body__c);
            
            HttpResponse response = callout.sendRequest();
            
            Logger.info('Inactive Employee API Response Status Code: ' + response.getStatusCode());
            
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                // Extract the employee list from 'employee_data' key based on actual API structure
                if (res.containsKey('employee_data')) {
                    employeeList = (List<Object>) res.get('employee_data');
                    Logger.info('Inactive employees fetched: ' + employeeList.size());
                } else {
                    Logger.warn('employee_data key not found in API response');
                    Logger.warn('Available keys: ' + String.join(new List<String>(res.keySet()), ', '));
                }
            } else {
                Logger.error('Inactive Employee API failed. StatusCode=' + response.getStatusCode());
            }
            
        } catch (Exception e) {
            Logger.error('Error in getInactiveEmployeeList: ' + e.getMessage());
            System.debug('Exception StackTrace: ' + e.getStackTraceString());
        }
        
        return employeeList;
    }
}