/**
* @File Name          : SHF_GetExposureLMSService_Test.cls
* @Description        : Test class to cover SHF_GetExposureLMSService.
* @Author             : Kunal Soni
* 
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         19-08-2025   Kunal Soni   Initial Version
*/

@IsTest
public class SHF_GetExposureLMSService_Test {
    // Mock class to simulate successful HTTP response
    private class SMSHttpMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Customer Exposure Details":[{"customerNumber":"GLBCUST00005341198","customerName":"NIJAM SHABIR SAYYAD","loanDetails":[{"tenantId":505,"loanId":5052442,"accountNumber":"0NND2210000005052442","applicationId":"5245668","fileNo":"APPL05224668","status":"A","financedAmount":536426,"disbursedAmount":288509,"tenure":240,"balancetenure":219,"installmentAmount":4232,"numberOfInstallments":253,"numberOfInstallmentsPaid":26,"amountOverdue":39639,"futurePrincipalAmount":284996,"otherPayables":0,"delinquencyString":"XXXXXXXX00000000000000000000000000001234567","numberOfChequesBounced":4,"assetClassificationStage":"SSTD","writeOffAmount":0,"currencyName":"INR","currencyISOCode":"INR","effectiveInterestRate":17,"productName":"Self Construction","dealDetailMO":{"dealReferenceNo":null,"facilityReferenceNo":null,"facilityType":null,"facilityGroup":null,"facilitySubGroup":null},"productCode":"HL005","scheme":"Others Prop-Cash Salaried-HL005","schemeCode":"SCHEM898","loanBranchCode":"NND","loanBranchName":"NANDED","loanRateType":"Floating","collateralNumbers":["GLBCOLL00000111267"],"repaymentFrequency":"Monthly","installmentPlan":"Equated Installments / Rentals","disbursalStatus":"Partial Disbursed","totalLoanOutstanding":324635,"source":"CAS","customerRelationship":"PRIMARY","daysPastDue":227,"tenureUnit":"Months","contractType":"Loan","contractSubType":null,"curtailmentType":null,"overDraftFlag":"No","overDraftType":null,"recoveryType":"Installment / Rental","recoverySubType":"Non-Revolving","offeringType":null,"residualValue":0,"loanMarkingDetails":[{"code":"REPO","description":"Repossessed","value":"N"},{"code":"LA-00009","description":"State Bank Of India","value":"Y"}],"daysPastDueOtherCharge":0,"goldRevaluationDetails":{"marginPercentage":null,"marginShortfallOnPos":null,"marginShortfallOnPosAndInterest":null,"marginShortfallOnTotalOutstanding":null},"currentMonthLatePaymentInterest":393,"currentMonthLatePaymentFee":0}]},{"customerNumber":"GLBCUST00005341199","customerName":"SAYYAD RUKSANA  SAYYADNIJAM","loanDetails":[{"tenantId":505,"loanId":5052442,"accountNumber":"0NND2210000005052442","applicationId":"5245668","fileNo":"APPL05224668","status":"A","financedAmount":536426,"disbursedAmount":288509,"tenure":240,"balancetenure":219,"installmentAmount":4232,"numberOfInstallments":253,"numberOfInstallmentsPaid":26,"amountOverdue":39639,"futurePrincipalAmount":284996,"otherPayables":0,"delinquencyString":"XXXXXXXX00000000000000000000000000001234567","numberOfChequesBounced":4,"assetClassificationStage":"SSTD","writeOffAmount":0,"currencyName":"INR","currencyISOCode":"INR","effectiveInterestRate":17,"productName":"Self Construction","dealDetailMO":{"dealReferenceNo":null,"facilityReferenceNo":null,"facilityType":null,"facilityGroup":null,"facilitySubGroup":null},"productCode":"HL005","scheme":"Others Prop-Cash Salaried-HL005","schemeCode":"SCHEM898","loanBranchCode":"NND","loanBranchName":"NANDED","loanRateType":"Floating","collateralNumbers":["GLBCOLL00000111267"],"repaymentFrequency":"Monthly","installmentPlan":"Equated Installments / Rentals","disbursalStatus":"Partial Disbursed","totalLoanOutstanding":324635,"source":"CAS","customerRelationship":"Co-applicant","daysPastDue":227,"tenureUnit":"Months","contractType":"Loan","contractSubType":null,"curtailmentType":null,"overDraftFlag":"No","overDraftType":null,"recoveryType":"Installment / Rental","recoverySubType":"Non-Revolving","offeringType":null,"residualValue":0,"loanMarkingDetails":[{"code":"REPO","description":"Repossessed","value":"N"},{"code":"LA-00009","description":"State Bank Of India","value":"Y"}],"daysPastDueOtherCharge":0,"goldRevaluationDetails":{"marginPercentage":null,"marginShortfallOnPos":null,"marginShortfallOnPosAndInterest":null,"marginShortfallOnTotalOutstanding":null},"currentMonthLatePaymentInterest":393,"currentMonthLatePaymentFee":0}]}]}');
            res.setStatusCode(200);
            return res;
        } 
    }
    
    @IsTest
    static void testGetLoanDetail_Success() {
        Test.setMock(HttpCalloutMock.class, new SMSHttpMockSuccess());
        // Prepare an empty wrapper
        SHF_ServiceConsoleLMSControllerWrapper wrapper = new SHF_ServiceConsoleLMSControllerWrapper();

        Test.startTest();
        SHF_ServiceConsoleLMSControllerWrapper result =
            SHF_GetExposureLMSService.getExposure('ACC123', wrapper);
        Test.stopTest();
    }
    
}