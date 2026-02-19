/**
* @File Name          : SHF_PricePegging_Service.cls
* @Description        : Service class to call PRICE_PEGGING_API and Uses standard SHF HTTP framework.
* @Author             : 
* 
* ==============================================================================
* Ver         Date              Author           Modification
* ==============================================================================
* 1.0         06-02-2026                Initial Version
*/
public with sharing class SHF_PricePegging_Service {
    
    //HTTP callout service wrapper
    public SHF_HTTPCalloutService service;
    
    /* Method to fetch price pegging details based on location, rate per sqft and application number */
    Public static Map<String,Object> getPricePeggingData(String location, String ratePerSqft, String applicationNo){
        
        //Savepoint for rollback in case of failure
        Savepoint sp;
        //Result map
        Map<String,Object> result = new Map<String,Object>();
        
        try{
            
            //Fetch message config from metadata
            Map<String,Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('PRICE_PEGGING_API');
            
            //Initialize Price Pegging HTTP Service
            SHF_PricePegging_Service priceService = new SHF_PricePegging_Service();
            priceService.service = new SHF_HTTPCalloutService('PRICE_PEGGING_API');
            
            //Prepare request body from metadata
            String requestbody = priceService.service.getRequestBody();
            if(String.isBlank(requestbody)){
                requestbody = '';
            }
            
            //Replace placeholders with actual values
            requestbody = requestbody.replace('<location>',location);
            requestbody = requestbody.replace('<ratePerSqft>',ratePerSqft);
            requestbody = requestbody.replace('<applicationNo>',applicationNo);
            
            //Set final request body
            priceService.service.setRequestBody(requestbody);
            
            //Execute API Callout/Mock Response
            HttpResponse response;
            
            if (priceService.service.getIsActive()) {
                //Actual callout
                response = priceService.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                //Mock response handling
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(priceService.service.getmockRespnse());
            }
            
            //Logging request and response
            Logger.info('Price Pegging Request :: ' + requestBody);
            Logger.info('Price Pegging Response :: ' + response.getBody());
            
            //Response Handling
            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())){
                
                //Deserialize response
                Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                
                //Validate response structure
                if(responseMap != null && responseMap.containsKey('data')) {
                    List<Object> dataList = (List<Object>) responseMap.get('data');
                    if(!dataList.isEmpty()) {
                        //Extract first rate object
                        Map<String, Object> rateMap = (Map<String, Object>) dataList[0];
                        //Prepare success response
                        result.put('location', responseMap.get('location'));
                        result.put('minimumRate', rateMap.get('minimumRate'));
                        result.put('maximumRate', rateMap.get('maximumRate'));
                        result.put('averageRate', rateMap.get('averageRate'));
                        result.put('color', rateMap.get('color'));
                        result.put('status', 'Success');
                        
                    }
                }else {
                    
                    //API response missing expected data
                    result.put('status', 'Error');
                    result.put('message',messageConfigMap.get('Price_Pegging_API_Error').Message__c
                    );
                }
            }else {
                
                //Non-success HTTP status
                result.put('status', 'Error');
                result.put('message',
                messageConfigMap.get('Price_Pegging_API_Error').Message__c);
            }
        }catch (Exception ex) {
            
            //Rollback in case of failure
            if(sp != null){
                Database.rollback(sp); 
            }
            //Log error
            Logger.error('Price Pegging API Error :: ' + ex.getMessage());
            
            //Return error response
            result.put('status', 'Error');
            result.put('message', ex.getMessage());
            
        } finally {
            Logger.saveLog();
        }
        
        return result;
    }
    
    
}