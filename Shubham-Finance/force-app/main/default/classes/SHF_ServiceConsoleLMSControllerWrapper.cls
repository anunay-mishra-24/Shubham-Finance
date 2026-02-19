/**
* @File Name          : SHF_ServiceConsoleLMSControllerWrapper.cls
* @Description        : 
* @Author             : Kunal Soni
* 
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         23-07-2025   Kunal Soni   Initial Version
*/
public class SHF_ServiceConsoleLMSControllerWrapper {

     @AuraEnabled(cacheable=false)
    public static SHF_ServiceConsoleLMSControllerWrapper getLMSWrapperData(String loanApplicationName) {

        SHF_ServiceConsoleLMSControllerWrapper wrapper = SHF_GetLoanDetailsLMSService.getLoanDetails(loanApplicationName);
        
        wrapper = SHF_GetExposureLMSService.getExposure(loanApplicationName, wrapper);
        wrapper = SHF_OverDueLMSService.getOverDueDetails(loanApplicationName, wrapper);
        wrapper = SHF_SearchCustomerLMSService.fetchCustomer(wrapper.customerId, wrapper);
        return wrapper;
    }
    
    // Applicant Details
    @AuraEnabled public String customerId;
    @AuraEnabled public String customerName;
    @AuraEnabled public String coApplicantName;
    @AuraEnabled public Date dob;
    @AuraEnabled public String gender;
    @AuraEnabled public String pan;
    @AuraEnabled public String aadhar;

    // Loan Details
    @AuraEnabled public String applicationNumber;
    @AuraEnabled public Decimal financedAmount;
    @AuraEnabled public Decimal futurePrincipal;
    @AuraEnabled public Decimal principalOutstanding;
    @AuraEnabled public Decimal totalOverdue;
    @AuraEnabled public String loanStatus;
    @AuraEnabled public String contractType;
    @AuraEnabled public String businessSegment;
    @AuraEnabled public String loanBranchCode;
    @AuraEnabled public String loanBranchName;
    @AuraEnabled public Date maturityDate;
    @AuraEnabled public Date nextInstallmentDate;
    @AuraEnabled public Date agreementDate;
    @AuraEnabled public Decimal sanctionedAmount;
    @AuraEnabled public Decimal disbursedAmount;
    @AuraEnabled public String disbursalStatus;
    @AuraEnabled public String originalTenure;
    @AuraEnabled public String currentTenure;
    @AuraEnabled public String Product;
    @AuraEnabled public String balanceTenure;
    @AuraEnabled public String numberOfInstallments;
    @AuraEnabled public String anchorType;
    @AuraEnabled public String anchorRate;
    @AuraEnabled public String anchorMarkUp;
    @AuraEnabled public String ltvRatio;

    // Repayment Info
    @AuraEnabled public String rateType;
    @AuraEnabled public String effectiveInterestRate;
    @AuraEnabled public String dueDay;
    @AuraEnabled public String repaymentFrequency;

    // Address Info
    @AuraEnabled public String addressType;
    @AuraEnabled public String addressLine1;
    @AuraEnabled public String addressLine2;
    @AuraEnabled public String addressLine3;
    @AuraEnabled public String country;
    @AuraEnabled public String pincode;

    // Overdue Info
    @AuraEnabled public String chargeCodeDescription;
    @AuraEnabled public Decimal totalOutstandingReceivableAmount;
    @AuraEnabled public Decimal totalOutstandingPayableAmount;
    @AuraEnabled public Decimal netOverDueAmount;

}