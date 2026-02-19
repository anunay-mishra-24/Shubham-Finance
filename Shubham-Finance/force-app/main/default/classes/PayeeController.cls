public with sharing class PayeeController {

    public class PayeeWrapper {
        @AuraEnabled public String applicantType {get;set;}
        @AuraEnabled public String applicantName {get;set;}
        @AuraEnabled public Decimal disbursalAmount {get;set;}
        @AuraEnabled public String adjustmentAmount {get;set;}
        @AuraEnabled public Decimal paymentAmount {get;set;}
        @AuraEnabled public String subPaymentMode {get;set;}
        @AuraEnabled public Date effectivePaymentDate {get;set;}
        @AuraEnabled public String typeOfPaymentMode {get;set;}
        @AuraEnabled public String inFavourOf {get;set;}
        @AuraEnabled public String instrumentNumber {get;set;}
        @AuraEnabled public Date instrumentDate {get;set;}
        @AuraEnabled public String printingBranch {get;set;}
        @AuraEnabled public String bankValidationStatus {get;set;}
        @AuraEnabled public String ifscCode {get;set;}
        @AuraEnabled public String customerBank {get;set;}
        @AuraEnabled public String accountNumber {get;set;}
        @AuraEnabled public String payeeName {get;set;}

        // EFT
        @AuraEnabled public String beneficiaryName {get;set;}
        @AuraEnabled public String beneficiaryAccountType {get;set;}
        @AuraEnabled public String beneficiaryAccountNumber {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static PayeeWrapper getDataToLoad(Id disbursementId, Id applicationId){
        if(disbursementId == null || applicationId == null) return new PayeeWrapper();

        List<Application__c> appliation = [
            SELECT Id, Branch__r.Name
            FROM Application__c
            WHERE Id =:applicationId
            LIMIT 1
        ];

        List<Disbursement__c> disbList = new SHF_disbursementSelector().selectByRecordId(new Set<Id>{disbursementId});

        PayeeWrapper pr  = new PayeeWrapper();
        if(!disbList.isEmpty()){
            pr.disbursalAmount = disbList[0].Disbursal_Amount__c;
            pr.adjustmentAmount = String.valueOf(disbList[0].Adjustment_Amount__c);
            pr.paymentAmount  = disbList[0].Disbursal_Amount__c - disbList[0].Adjustment_Amount__c;
            pr.effectivePaymentDate = disbList[0].Disbursal_Date__c;
            pr.instrumentDate = disbList[0].Disbursal_Date__c;
        }
        pr.printingBranch = (appliation.isEmpty() ? null : appliation[0].Branch__r.Name);
        return pr;
    }

    // ===== GET BANK DETAILS =====
    @AuraEnabled(cacheable=true)
    public static Bank_master__c getBankDetails(Id bankId){
        if(bankId == null) return new Bank_master__c();
        return [
            SELECT Id, IFSC_code__c, Name, Branch_name__c, Account_Number__c
            FROM Bank_master__c
            WHERE Id = :bankId AND RecordType.Name = 'Bank Master'
            LIMIT 1
        ];
    }

    // ===== GET APPLICANTS =====
    @AuraEnabled(cacheable=true)
    public static List<Loan_Applicant__c> getApplicants(String applicantType, String applicationId){
        if(String.isBlank(applicantType) || String.isBlank(applicationId)) return new List<Loan_Applicant__c>();

        List<Loan_Applicant__c> primaryApplicant = new List<Loan_Applicant__c>();
        List<Loan_Applicant__c> coApplicants = new List<Loan_Applicant__c>();

        for(Loan_Applicant__c applicant : new SHF_LoanApplicantsSelector().getApplicantsByApplication(applicationId)){
            if(applicant.Applicant_Type__c == SHF_ConstantsUtil.APPPLICANT){
                primaryApplicant.add(applicant);
            } else if(applicant.Applicant_Type__c == SHF_ConstantsUtil.CO_APPLICANT){
                coApplicants.add(applicant);
            }
        }

        if(applicantType == 'Primary Applicant') return primaryApplicant;
        if(applicantType == 'Co applicant') return coApplicants;

        return new List<Loan_Applicant__c>();
    }

    @AuraEnabled
    public static List<Payee_Details__c> getPayeeList(Id disbursementId){
        if(disbursementId == null) return new List<Payee_Details__c>();
        return new SHF_payeeDetailsSelector().selectByIdsDisbId(new Set<Id>{disbursementId});
    }

    // ===== CREATE PAYEE =====
    @AuraEnabled
    public static void createPayee(PayeeWrapper wrap, Id applicationId, String disbursementId){
        try {
            Payee_Details__c p = new Payee_Details__c();
            p.Disbursement__c = disbursementId;
            p.Is_Deleted__c = false;

            if(String.isNotBlank(wrap.applicantType)) p.BusinessPartnerTypeApplicantType__c = wrap.applicantType;
            if(String.isNotBlank(wrap.applicantName)) p.BusinessPartnerNameApplicantName__c = wrap.applicantName;

            if(wrap.disbursalAmount != null) p.DisbursalAmount__c = wrap.disbursalAmount;
            if(String.isNotBlank(wrap.adjustmentAmount)) p.AdjustmentAmount__c = wrap.adjustmentAmount;
            if(wrap.paymentAmount != null) p.Payment_Amount__c = wrap.paymentAmount;

            if(String.isNotBlank(wrap.subPaymentMode)) p.SubPaymentMode__c = wrap.subPaymentMode;
            if(wrap.effectivePaymentDate != null) p.EffectivePaymentDate__c = wrap.effectivePaymentDate;
            if(String.isNotBlank(wrap.typeOfPaymentMode)) p.TypeOfPaymentMode__c = wrap.typeOfPaymentMode;
            if(String.isNotBlank(wrap.inFavourOf)) p.InFavourOf__c = wrap.inFavourOf;

            if(String.isNotBlank(wrap.payeeName)) p.Payee_Name__c = wrap.payeeName;
            if(String.isNotBlank(wrap.customerBank)) p.Customer_Bank__c = wrap.customerBank;
            if(String.isNotBlank(wrap.accountNumber)) p.Account_Number__c = wrap.accountNumber;
            if(String.isNotBlank(wrap.printingBranch)) p.Printing_Branch__c = wrap.printingBranch;
            if(String.isNotBlank(wrap.bankValidationStatus)) p.BankValidationStatus__c = wrap.bankValidationStatus;
            if(String.isNotBlank(wrap.ifscCode)) p.IFSC_Code__c = wrap.ifscCode;

            if(String.isNotBlank(wrap.instrumentNumber)) p.Instrument_Number__c = wrap.instrumentNumber;
            if(wrap.instrumentDate != null) p.InstrumentDate__c = wrap.instrumentDate;

            if(String.isNotBlank(wrap.beneficiaryName)) p.BeneficiaryName__c = wrap.beneficiaryName;
            if(String.isNotBlank(wrap.beneficiaryAccountType)) p.BeneficiaryAccountType__c = wrap.beneficiaryAccountType;
            if(String.isNotBlank(wrap.beneficiaryAccountNumber)) p.BeneficiaryAccountNumber__c = Decimal.valueOf(wrap.beneficiaryAccountNumber);

            insert p;
        } catch(Exception e){
            throw new AuraHandledException('Create Payee failed: ' + e.getMessage());
        }
    }

    // ===== UPDATE PAYEE =====
    @AuraEnabled
    public static void updatePayee(PayeeWrapper wrap, Id payeeId){
        try {
            if(payeeId == null) return;

            Payee_Details__c p = [
                SELECT Id
                FROM Payee_Details__c
                WHERE Id = :payeeId
                LIMIT 1
            ];

            if(String.isNotBlank(wrap.applicantType)) p.BusinessPartnerTypeApplicantType__c = wrap.applicantType;
            if(String.isNotBlank(wrap.applicantName)) p.BusinessPartnerNameApplicantName__c = wrap.applicantName;

            if(wrap.disbursalAmount != null) p.DisbursalAmount__c = wrap.disbursalAmount;
            if(String.isNotBlank(wrap.adjustmentAmount)) p.AdjustmentAmount__c = wrap.adjustmentAmount;
            if(wrap.paymentAmount != null) p.Payment_Amount__c = wrap.paymentAmount;

            if(String.isNotBlank(wrap.subPaymentMode)) p.SubPaymentMode__c = wrap.subPaymentMode;
            if(wrap.effectivePaymentDate != null) p.EffectivePaymentDate__c = wrap.effectivePaymentDate;
            if(String.isNotBlank(wrap.typeOfPaymentMode)) p.TypeOfPaymentMode__c = wrap.typeOfPaymentMode;
            if(String.isNotBlank(wrap.inFavourOf)) p.InFavourOf__c = wrap.inFavourOf;

            if(String.isNotBlank(wrap.payeeName)) p.Payee_Name__c = wrap.payeeName;
            if(String.isNotBlank(wrap.customerBank)) p.Customer_Bank__c = wrap.customerBank;
            if(String.isNotBlank(wrap.accountNumber)) p.Account_Number__c = wrap.accountNumber;
            if(String.isNotBlank(wrap.printingBranch)) p.Printing_Branch__c = wrap.printingBranch;
            if(String.isNotBlank(wrap.bankValidationStatus)) p.BankValidationStatus__c = wrap.bankValidationStatus;
            if(String.isNotBlank(wrap.ifscCode)) p.IFSC_Code__c = wrap.ifscCode;

            if(String.isNotBlank(wrap.instrumentNumber)) p.Instrument_Number__c = wrap.instrumentNumber;
            if(wrap.instrumentDate != null) p.InstrumentDate__c = wrap.instrumentDate;

            if(String.isNotBlank(wrap.beneficiaryName)) p.BeneficiaryName__c = wrap.beneficiaryName;
            if(String.isNotBlank(wrap.beneficiaryAccountType)) p.BeneficiaryAccountType__c = wrap.beneficiaryAccountType;
            if(String.isNotBlank(wrap.beneficiaryAccountNumber)) p.BeneficiaryAccountNumber__c = Decimal.valueOf(wrap.beneficiaryAccountNumber);

            update p;
        } catch(Exception e){
            throw new AuraHandledException('Update Payee failed: ' + e.getMessage());
        }
    }

    // ===== SOFT DELETE =====
    @AuraEnabled
    public static void softDeletePayee(Id payeeId){
        try {
            if(payeeId == null) return;

            Payee_Details__c p = [
                SELECT Id, Is_Deleted__c
                FROM Payee_Details__c
                WHERE Id = :payeeId
                LIMIT 1
            ];
            p.Is_Deleted__c = true;
            update p;

        } catch(Exception e){
            throw new AuraHandledException('Delete Payee failed: ' + e.getMessage());
        }
    }
}