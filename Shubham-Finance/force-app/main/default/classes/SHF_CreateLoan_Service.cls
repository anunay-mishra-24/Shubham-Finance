/**
* @File Name          : SHF_CreateLoan_Service.cls
* @Description        : API to create Loan
* @Author             : David Saini
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       17-07-2025      David Saini       Initial Version
*/
public with sharing class SHF_CreateLoan_Service {
    @AuraEnabled
    public static String createLoan(Id applicationId) {
        Savepoint sp;
        String message = '';
        try {
            Callout_Framework__mdt metadata = SHF_CommonUtil.getCalloutMetadata('Create_Loan_API').get('Create_Loan_API');
            String accesstoken = SHF_LMSCommonUtil.generateAccessToken();
            if(String.isNotBlank(accessToken)){
                String requestBody = metadata.Body__c;
                SHF_HTTPCalloutService callout = new SHF_HTTPCalloutService('Create_Loan_API');
                callout.setRequestMethod(metadata.HTTP_Method__c);
                callout.setEndpointURL(metadata.Endpoint__c);
                callout.setRequestBody(requestBody);
                callout.setHeaderParameter('access_token',accesstoken);
                callout.setHeaderParameter('bridgeChannel','LMS');
                callout.setHeaderParameter('transmissionPrimitive','SYNC');
                callout.setHeaderParameter('Content-Type', 'application/json');

                
                HttpResponse response;
                if (metadata.Active__c) {
                    response = callout.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setBody(callout.getmockRespnse());
                    response.setStatusCode(200);
                }
                
                String responseBody = response.getBody();
                
                if (response.getStatusCode() == 200 && String.isNotBlank(responseBody)) {
                    Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    System.debug('responseBody: ' + res);
                }
                
                String reqBodyLog = callout.getRequestBody();
                if (reqBodyLog != null && reqBodyLog.length() > 5000) {
                    reqBodyLog = reqBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Request Body: ' + reqBodyLog);
                Logger.info('Response Status Code: ' + response.getStatusCode());
                Logger.info('Response Status: ' + response.getStatus());
                system.debug('Response Status: ' + response.getStatus());
                
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    message = 'Success';
                }

                String respBodyLog = response.getBody();
                if (respBodyLog != null && respBodyLog.length() > 5000) {
                    respBodyLog = respBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Response Body: ' + respBodyLog);
                system.debug('Response Body: ' + respBodyLog);
            }
            else{
                Logger.error('Access token is blank');
                return 'Access token is blank';
            }
        } catch (Exception e) {
            if (sp != null) {
                Database.rollback(sp);
            }
            System.debug('Error in Create_Loan_API: ' + e.getMessage());
            Logger.error('Error: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
        System.debug('message : '+message);
        return message;
    }

    private static String generateLoanBookingRequest(Id applicationId) {
        String requestJson = '';

        requestJson += '{';

        // ================= requestHeader =================
        requestJson += '"requestHeader":{';
        requestJson += '"userDetail":{';
        requestJson += '"userCode":"casadmin",';
        requestJson += '"branchId":901';
        requestJson += '},';
        requestJson += '"tenantId":505';
        requestJson += '},';

        // ================= loanBookingRequest =================
        requestJson += '"loanBookingRequest":{';
        requestJson += '"loanDetail":{';

        requestJson += '"unitOfTenure":"3",';
        requestJson += '"tag":"LOAN",';
        requestJson += '"schemeCode":"SCHEM627",';
        requestJson += '"requestChannelCode":"BULK",';

        // -------- repaymentScheduleSpecificationDetail --------
        requestJson += '"repaymentScheduleSpecificationDetail":{';
        requestJson += '"tenure":180,';
        requestJson += '"repaymentStartDate":"07/01/2023",';
        requestJson += '"repaymentPolicyCode":"HL_RP_2",';
        requestJson += '"rateTypeCode":1,';
        requestJson += '"numberOfAdvanceInstallments":0,';
        requestJson += '"interestStartDate":"18/12/2022",';
        requestJson += '"interestRate":16.0,';
        requestJson += '"interestFreeDays":0,';
        requestJson += '"installmentTypeCode":"11",';
        requestJson += '"installmentAmount":null,';
        requestJson += '"gradedBasedOnCode":null,';
        requestJson += '"dueDay":"4",';
        requestJson += '"brokenPeriodDays":0,';
        requestJson += '"anchorTypeCode":"SHDFCHL2",';
        requestJson += '"anchorRate":0.0';
        requestJson += '},';

        requestJson += '"productCode":"HL025",';
        requestJson += '"netMarkup":0.0,';
        requestJson += '"multipleDisbursalFlag":"M",';
        requestJson += '"moratoriumTreatmentTypeCode":"",';
        requestJson += '"moratoriumPeriod":"",';
        requestJson += '"ltv":20,';
        requestJson += '"loanRefId":"",';
        requestJson += '"loanPurpose":"TRANSFER_EXISTING_HL",';

        // -------- loanDisbursalDetails --------
        requestJson += '"loanDisbursalDetails":[';
        requestJson += '{';
        requestJson += '"tag":"DISB",';
        requestJson += '"disbursalReferenceId":"44544",';
        requestJson += '"referenceLoanAccountNumber":"",';
        requestJson += '"principalRecoveryFlag":0,';
        requestJson += '"loanRefId":"",';
        requestJson += '"disbursalTypeCode":"Normal",';
        requestJson += '"disbursalTransactionDate":"18/05/2023",';
        requestJson += '"disbursalRemarks":"DM-0000224862",';
        requestJson += '"disbursalNo":1,';
        requestJson += '"disbursalDate":"18/11/2023",';

        requestJson += '"disbursalBreakUpDetails":[';
        requestJson += '{';
        requestJson += '"tag":"DISBBU",';
        requestJson += '"loanRefId":"",';
        requestJson += '"disbursalPaymentDetails":[';

        Disbursement__c disbursement = [SELECT Id,Name/*,Application__c*/ FROM Disbursement__c /*WHERE Application__c =: applicationId*/];
        List<Payee_Details__c> payee = [SELECT Id,Name,Disbursement__c,SubPaymentMode__c,TypeOfPaymentMode__c,Payment_Amount__c,Instrument_Number__r.Name,InstrumentDate__c,Customer_Bank__r.Branch_code__c,Account_Number__c,BeneficiaryName__c FROM Payee_Details__c WHERE Disbursement__c =: disbursement.Id];
        for(Payee_Details__c payeeDetail : payee){
            requestJson += '{';
            requestJson += '"tag":"DISBPM",';
            requestJson += '"subPaymentModeCode":null,';  // field availbel on Salesforce is SubPaymentMode__c
            requestJson += '"sourcePaymentReferenceNumber":0,';  // no field found
            requestJson += '"printingBranchCode":"GUJ",';   //Printing_Branch__c instead of code field has branch name like Delhi
            requestJson += '"payoutbankId":"5001916",';  // no such field found
            requestJson += '"paymentModeCode":"'+payeeDetail.TypeOfPaymentMode__c+'",';
            requestJson += '"paymentAmount":'+payeeDetail.Payment_Amount__c+',';
            requestJson += '"instrumentNumber":'+payeeDetail.Instrument_Number__r.Name+',';
            requestJson += '"instrumentDate":"'+payeeDetail.InstrumentDate__c+'",';
            requestJson += '"bankIdentificationType":null,'; //no such field found
            requestJson += '"bankIdentificationCode":null,';  // no such field found
            requestJson += '"bankBranchCode":'+payeeDetail.Customer_Bank__r.Branch_code__c+',';    
            requestJson += '"accountTypeCode":null,';
            requestJson += '"accountNumber":'+payeeDetail.Account_Number__c+',';
            requestJson += '"accountByName":"'+payeeDetail.BeneficiaryName__c+' A/C NO '+payeeDetail.Account_Number__c+'",';
            requestJson += '}';
        }

        requestJson += '],';

        requestJson += '"disbursalChargeAmount":1500.0,';
        requestJson += '"disbursalAmount":';
        requestJson += '}';
        requestJson += '],';

        requestJson += '"disbursalAuthorName":null,';
        requestJson += '"disbursalAmount":';
        requestJson += '}';
        requestJson += '],';

        requestJson += '"loanAssetCost":7555500,';
        requestJson += '"loanAmountWithoutVAP":1568400,';
        requestJson += '"loanAccountNumber":null,';
        requestJson += '"linkingDetail":null,';

        // -------- gstDetail --------
        requestJson += '"gstDetail":[{';
        requestJson += '"loanRefId":"",';
        requestJson += '"gSTStateCode":"",';
        requestJson += '"gSTINNo":"",';
        requestJson += '"gSTINCustomerNo":"",';
        requestJson += '"gSTINAddress":"",';
        requestJson += '"branchStateCode":"",';
        requestJson += '"bpTypeId":"",';
        requestJson += '"bpId":""';
        requestJson += '}],';

        // -------- disbursalChargeDetails --------
        List<Fees__c> disbursalCharges = [SELECT Id,Amount__c,Application__c,Cancellation_Reason__c,Charge_Master__c,Charge_Master__r.Charge_Sub_Type__c,Fee_Type__c,Receipt_Id__c,Related_To__c,Status__c,Tax__c FROM Fees__c WHERE Application__c =: applicationId];
        requestJson += '"disbursalChargeDetails":[';
        for(Fees__c fee : disbursalCharges) {
            requestJson += '{';
            requestJson += '"transactionChargeDate":"18/11/2023",';
            requestJson += '"originalChargeAmount":'+fee.Amount__c+',';
            requestJson += '"imdDetails":[],';
            requestJson += '"dueDate":"18/11/2023",';
            requestJson += '"chargeId":"'+fee.Name+'",';
            requestJson += '"chargeAmount":'+fee.Amount__c+',';
            requestJson += '"bpTypeCode":null,';
            requestJson += '"bpCode":"2890",';
            if(fee.Charge_Master__r.Charge_Sub_Type__c == 'Collectible'){
                requestJson += '"adjustChargeAtDisbursement":"N"';
            }
            else {
                requestJson += '"adjustChargeAtDisbursement":"Y"';
            }
            requestJson += '}';

        }
        requestJson += '],';
        requestJson += '"customerNo":"",';
        requestJson += '"currencyCode":"INR",';
        requestJson += '"branchCode":"GUJ",';
        requestJson += '"applicationTypeCode":"NewApplication",';
        requestJson += '"applicationFormNumber":"",';
        requestJson += '"applicationFileNumber":"",';
        requestJson += '"applicationCreationDate":"04/08/2023",';
        requestJson += '"agreementDate":"04/09/2023"';

        requestJson += '},'; // loanDetail end

        // -------- guarantor --------
        requestJson += '"gurantorCoapplicantDetails":[{';
        requestJson += '"relationshipType":"1",';
        requestJson += '"partyRelationship":"Son",';
        requestJson += '"customerNumber":"GLBCUST00005001007",';
        requestJson += '"applicationFileNumber":""';
        requestJson += '}]';

        requestJson += '}'; // loanBookingRequest
        requestJson += '}'; // root

        System.debug('Loan Booking Request JSON => ' + requestJson);
        return requestJson;
    }


}