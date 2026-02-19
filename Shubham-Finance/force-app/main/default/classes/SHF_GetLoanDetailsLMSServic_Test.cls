/**
* @File Name          : SHF_GetLoanDetailsLMSServic_Test.cls
* @Description        : test class to cover SHF_GetLoanDetailsLMSServic.
* @Author             : Kunal Soni
* 
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         18-08-2025   Kunal Soni   Initial Version
*/

@Istest
public class SHF_GetLoanDetailsLMSServic_Test {
    
    // Mock class to simulate successful HTTP response
    private class SMSHttpMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":{"requestHeader":null,"loanId":5052442,"loanAccountNumber":"0NND2210000005052442","businessSegment":"Retail","dealReferenceNumber":null,"facilityReferenceNumber":null,"requestChannel":null,"productDescription":"Self Construction","loanBranchCode":"NND","loanBranchName":"NANDED","financedAmount":288509,"tenure":240,"currencyIsoCode":"INR","disbursalDate":"12/10/2022","agreementDate":"22/09/2022","productTypeDescription":"Home Loan","businessDate":"19/08/2025","disbursalStatus":"Partial Disbursed","matured":false,"nextDueInstallmentAmount":4232,"nextDueDate":"04/09/2025","balanceTenure":219,"numberOfInstallmentUnpaid":8,"numberOfInstallmentsPaid":26,"amountOverdue":39639,"contractType":"Loan","contractSubType":null,"curtailmentType":null,"overDraftFlag":"No","overDraftType":null,"recoveryType":"Installment / Rental","recoverySubType":"Non-Revolving","offeringType":null,"residualValue":0,"daysPastDue":227,"loanRepaymentDetailMO":{"effectiveRateOfInterest":17,"interestChargeMode":"Floating","repaymentFrequency":"Monthly","repaymentDueDay":"4","installmentAmount":4232,"repaymentModeDetails":[{"repaymentMode":"National Automated Clearing House","accountDetails":[{"accountType":"Saving Account","accountNumber":"80076781411","accountName":"NIJAM SHABIR SAYYAD","contributionBasis":"Balance Installment","contributionPercentage":100,"mandateRefereceNumber":"0NND2210000005052442","instrumentPurpose":"Installment","expiryDate":null,"ifscCode":"MAHG0004102","bankIdentificationCode":"431570598"}]}]},"customerDetailMO":{"customerNumber":"GLBCUST00005341198","fullName":"NIJAM SHABIR SAYYAD","mobileNumber":"8975101016","dateOfBirth":"24/05/1995","primaryEmailId":null,"corporateDateOfInception":null,"indvCorpFlag":"individual","identificationDetails":[{"identificationType":"PAN","identificationNumber":"KDIPS1330E","identificationRefNumber":null},{"identificationType":"Aadhar No.","identificationNumber":"000000000351","identificationRefNumber":null}],"panNumber":null,"vehicleRegistrationNumber":null,"requestHeader":null},"anchorRate":16.5,"netMarkup":0.5,"applicationFormNumber":"NND666748","applicationFileNumber":"APPL05224668","ltv":31,"lastDisbursalDate":"04/11/2023","disbursedAmount":288509,"finalSanctionedAmount":536426,"installmentSubventionAmount":null,"maturityDate":"04/11/2043","sourceApplicationId":5245668,"status":"Active","groupId":null,"limitReferenceNo":null,"depositLinkedAccount":null,"principalOutstanding":286458,"futurePrincipal":284996,"anchorCode":"SHDFCHLOTHER","anchorDescription":"SHDFC_HL_Other","moratoriumInterest":0,"moratoriumInterestReceived":0,"tenureUnit":"Months","noOfTransactionToDisplay":0,"nextNInstallments":null,"lastNPaymentsByCustomer":null,"lastNBounces":null,"propertyAddress":null,"nextEmiDueDate":"04/09/2025"}}');
            res.setStatusCode(200);
            return res;
        } 
    }
    
     @IsTest
        static void testGetLoanDetail_Success() {
            Test.setMock(HttpCalloutMock.class, new SMSHttpMockSuccess());
            Test.startTest();
            SHF_GetLoanDetailsLMSService.getLoanDetails('0NND2210000005052442');
            Test.stopTest();
        }
}