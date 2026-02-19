/**
* @File Name          : SHF_ElectricityBill_Service.cls
* @Description        : Service class to verify ElectricityBill details and create E-Verification record.
* @Author             : Riteek Tiwari
* 
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         29-07-2025        Riteek Tiwari    Initial Version
*/
public with sharing class SHF_ElectricityBill_Service {
    public SHF_HTTPCalloutService service;
    public static String electricityBill(String customerId, String consumerId, String serviceProvider, String mobileNumber,String serviceProviderName) {
        System.debug('serviceProviderserviceProvider - '+serviceProvider);
        System.debug('serviceProviderName - '+serviceProviderName);
        Savepoint sp;
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('Electricity_Bill_API');
        
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Loan_Applicant__c.SObjectType });
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ customerId });
            
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + customerId);
                return null;
            }            
            Loan_Applicant__c applicant = loanAppList[0];
            
            String addressDistrict = '';
            List<Address__c> currentAddresses = new SHF_AddressesSelector().selectAddressByApplicantIds(new Set<Id>{ customerId });
            if (!currentAddresses.isEmpty()) {
                Address__c currentAddress = currentAddresses[0];
                if (String.isNotBlank(currentAddress.District__c)) {
                    addressDistrict = currentAddress.District__c;
                    System.debug('addressDistrict: ' + addressDistrict);
                }
            }
            
            SHF_ElectricityBill_Service electricityBillService = new SHF_ElectricityBill_Service();
            electricityBillService.service = new SHF_HTTPCalloutService('Electricity_Bill_API');
            String requestBody = electricityBillService.service.getRequestBody();
            
            requestBody = requestBody
                .replace('<ConsumerId>', String.isNotBlank(consumerId) ? consumerId : '')
                .replace('<ServiceProvider>', String.isNotBlank(serviceProvider) ? serviceProvider : '')
                // .replace('<District>', String.isNotBlank(addressDistrict) ? addressDistrict : '')
                .replace('<District>', String.isNotBlank(addressDistrict) ? '' : '')
                .replace('<MobileNumber>', String.isNotBlank(mobileNumber) ? mobileNumber : '');
            
            electricityBillService.service.setRequestBody(requestBody);
            System.debug('Request Body: ##' + electricityBillService.service.getRequestBody());
            
            HttpResponse response;
            if (electricityBillService.service.getIsActive()) {
                response = electricityBillService.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(electricityBillService.service.getmockRespnse());
            }          
                       
            String responseBody = response.getBody();
            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(customerId, SHF_ConstantsUtil.ELECTRCITY_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS);
            
            if (response.getStatusCode() == 200 && String.isNotBlank(responseBody)) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                
                if (responseMap.containsKey('result') && responseMap.get('result') != null) {
                    Map<String, Object> resultMap = (Map<String, Object>) responseMap.get('result');
                    
                    if (resultMap != null && !resultMap.isEmpty()) {
                        if (resultMap.containsKey('bill_no') && resultMap.get('bill_no') != null) eVerification.Bill_Number__c = String.valueOf(resultMap.get('bill_no'));
                        if (resultMap.containsKey('bill_amount')) eVerification.Bill_Amount__c = String.valueOf(resultMap.get('bill_amount'));
                        if (resultMap.containsKey('amount_payable')) eVerification.Amount_Payable__c = String.valueOf(resultMap.get('amount_payable'));
                        if (resultMap.containsKey('total_amount')) eVerification.Total_Amount__c = String.valueOf(resultMap.get('total_amount'));
                        if (resultMap.containsKey('consumer_number')) eVerification.Consumer_Number__c = String.valueOf(resultMap.get('consumer_number'));
                        if (resultMap.containsKey('mobile_number')) eVerification.Mobile__c = String.valueOf(resultMap.get('mobile_number'));
                        if (resultMap.containsKey('address')) eVerification.Full_Address__c = String.valueOf(resultMap.get('address'));
                        if (resultMap.containsKey('consumer_name')) eVerification.Consumer_Name__c = String.valueOf(resultMap.get('consumer_name'));
                        if (resultMap.containsKey('email_address')) eVerification.Email__c = String.valueOf(resultMap.get('email_address'));
                        if (resultMap.containsKey('bill_date')) eVerification.Bill_Date__c = String.valueOf(resultMap.get('bill_date'));
                        if (resultMap.containsKey('bill_issue_date')) eVerification.Bill_Issue_Date__c = String.valueOf(resultMap.get('bill_issue_date'));
                        if (resultMap.containsKey('bill_due_date')) eVerification.Bill_Due_Date__c = String.valueOf(resultMap.get('bill_due_date'));
                        eVerification.Electricity_Service_Provider__c = serviceProviderName;
                        message = MessageConfigMap.get('ElectricityBill_API_Success').Message__c;
                    } else {
                        eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                        Logger.error('Missing or null "result" node in response');
                        eVerification.Failed_Reason__c = 'Missing or null "result" node in response';
                        message = MessageConfigMap.get('ElectricityBill_API_Error').Message__c;
                    }
                }
            } else {
                eVerification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                Logger.error('Non-StatusCode-200 response or empty body received');
                eVerification.Failed_Reason__c = 'Non-StatusCode-200 response or empty body received';
                message = MessageConfigMap.get('ElectricityBill_API_Error').Message__c;
            }
            
            uow.registerNew(eVerification);
            uow.commitWork();
            loanAppList[0].Electricity_Verification__c = eVerification.Id;
            applicantUow.registerDirty(loanAppList);
            applicantUow.commitWork();
            Logger.info('Request Body: ' + electricityBillService.service.getRequestBody());
            System.debug('Request Body2: ' + electricityBillService.service.getRequestBody());
            Logger.info('Status Code: ' + response.getStatusCode());
            Logger.info('Status: ' + response.getStatus());
            Logger.info('Body: ' + response.getBody());
            
        } catch (Exception e) {
            if (sp != null) Database.rollback(sp);
            Logger.error('Error in Electricity Bill Service: ' + e.getMessage());
            System.debug('Error in Electricity Bill Service: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
        return message;
    }
    
}