/**
* @File Name          : SHF_SearchCustomerLMSService.cls
* @Description        : To fetch customer based on file name and extract specific fields.
* @Author             : Kunal Soni
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         18-07-2025   Kunal Soni   Initial Version
*/

public class SHF_SearchCustomerLMSService {
    SHF_HTTPCalloutService service;
    
    public static SHF_ServiceConsoleLMSControllerWrapper fetchCustomer(String fileName, SHF_ServiceConsoleLMSControllerWrapper wrappers) {
        SHF_ServiceConsoleLMSControllerWrapper wrapper = wrappers;
        try {
            String accessToken = SHF_LMSCommonUtil.generateAccessToken();
            
            if(Test.isRunningTest() && accessToken == null){
                accessToken = '6b9711a1-9f5f-42cf-9116-eded1f63649f';
            }
            if (String.isNotBlank(accessToken)) {
                SHF_SearchCustomerLMSService svc = new SHF_SearchCustomerLMSService();
                svc.service = new SHF_HTTPCalloutService('Search_Customer');
                svc.service.setHeaderParameter('Content-Type', 'application/json');
                svc.service.setHeaderParameter('access_token', accessToken);
                svc.service.setRequestBody(svc.service.getRequestBody().replace('<FileName>', fileName));
                
                HttpResponse response;
                if (svc.service.getIsActive()) {
                    response = svc.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setBody(svc.service.getmockRespnse());
                    response.setStatusCode(200);
                }
                
                
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if (parsed.containsKey('searchResult')) {
                        List<Object> results = (List<Object>) parsed.get('searchResult');
                        for (Object o : results) {
                            Map<String, Object> cust = (Map<String, Object>) ((Map<String, Object>) o).get('customerRecord');
                            
                            
                            Map<String, Object> person = (Map<String, Object>) cust.get('personInfo');
                            wrapper.coApplicantName = String.valueOf(person.get('fullName'));
                            wrapper.dob = SHF_LMSCommonUtil.parseDateFormate(String.valueOf(person.get('dateOfBirth')));
                            wrapper.gender = String.valueOf(person.get('genderCode'));
                            
                            List<Object> contactInfoList = (List<Object>) cust.get('contactInfo');
                            for (Object contact : contactInfoList) {
                                Map<String, Object> contactMap = (Map<String, Object>) contact;
                                List<Object> addressList = (List<Object>) contactMap.get('addressInfo');
                                
                                for (Object addr : addressList) {
                                    Map<String, Object> address = (Map<String, Object>) addr;
                                    Map<String, Object> pojo = (Map<String, Object>) address.get('addressInfoPojo');
                                    wrapper.addressType = String.valueOf(pojo.get('addressTypeCode'));
                                    wrapper.addressLine1 = String.valueOf(pojo.get('addressLine1'));
                                    wrapper.addressLine2 = String.valueOf(pojo.get('addressLine2'));
                                    wrapper.addressLine3 = String.valueOf(pojo.get('addressLine3'));
                                    wrapper.country = String.valueOf(pojo.get('country'));
                                    wrapper.pincode = String.valueOf(pojo.get('zipcode'));
                                }
                            }
                            
                            List<Object> idList = (List<Object>) cust.get('identificationInfo');
                            for (Object id : idList) {
                                Map<String, Object> idMap = (Map<String, Object>) id;
                                String type = String.valueOf(idMap.get('identificationTypeCode'));
                                if (type == 'PAN') wrapper.pan = String.valueOf(idMap.get('identificationNumber'));
                                if (type == 'AAdhar_No') wrapper.aadhar = String.valueOf(idMap.get('identificationNumber'));
                            }
                            
                            System.debug('wrapperList Loan Detail-->'+wrapper);
                        }
                    }
                }
                String reqBodyLog = svc.service.getRequestBody();
                if (reqBodyLog != null && reqBodyLog.length() > 5000) {
                    reqBodyLog = reqBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Request Body ' + reqBodyLog);
                
                Logger.info('status code ' + response.getStatusCode());
                Logger.info('status ' + response.getStatus());
                
                String respBodyLog = response.getBody();
                if (respBodyLog != null && respBodyLog.length() > 5000) {
                    respBodyLog = respBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Response Body ' + respBodyLog);
            }
        } catch (Exception e) {
            Logger.error('Error: ' + e.getMessage()+ ' '+ e.getLineNumber());
        } finally {
            Logger.saveLog();
        }
        return wrapper;
    }
}