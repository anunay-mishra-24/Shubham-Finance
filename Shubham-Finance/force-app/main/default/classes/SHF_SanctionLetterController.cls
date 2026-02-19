/**
* @File Name          : SHF_SanctionLetterController.cls
* @Description        : For Sanction Letter Document generation     VFPage : SHF_Sanction_Letter
* @Author             : Ashutosh Dubey
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       15/01/2026      Ashutosh Dubey       Initial Version
*/


public class SHF_SanctionLetterController {
    
    public SanctionLetterWrapper sanctionLetter {get; set;}
    
    public SHF_SanctionLetterController(){
        sanctionLetter = new SanctionLetterWrapper();
        Id applicationId = ApexPages.currentPage().getParameters().get('id');
        // applicationId = 'a03C100000Kb822IAB'; //HL
        applicationId = 'a03C100000JkkN3IAJ'; //LAP
        if(applicationId != null){
            Application__c application = [SELECT Id, Name, Sanction_Amount__c,Loan_Product__c, Application_Auto_Number__c,Tenure__c, Rate_of_Interest__c, EMI__c, Loan_Disbursement_Date__c, Purpose_of_Loan__c, Branch__r.Name, Branch__r.State__c, Branch__r.City__r.City_Code__c, Sub_Product__c, Charges_Visible__c, Product__r.Product_Type__c, Sanction_Date__c FROM Application__c WHERE Id =: applicationId];
            sanctionLetter.application = application;
            sanctionLetter.loanAmount = application.Sanction_Amount__c != null ? CurrencyInWordsUtil.formatINR(application.Sanction_Amount__c) : '';
            Date d = application.Sanction_Date__c;
            sanctionLetter.sanctionDate = d != null ? String.valueOf(d.day()).leftPad(2, '0') + '/' + String.valueOf(d.month()).leftPad(2, '0') + '/' + String.valueOf(d.year()) : '';
            sanctionLetter.isHL = application.Loan_Product__c == 'Home Loan';
            sanctionLetter.emi = application.EMI__c != null ? CurrencyInWordsUtil.formatINR(application.EMI__c) : '';
            
            List<Loan_Applicant__c> applicants = [SELECT Id, Salutation__c, Name, Applicant_Type__c, Risk_Category__c, Address__r.Address_Line_1__c, Address__r.Address_Line_2__c, Address__r.Address_Line_3__c, Address__r.Pincode__r.Name,  Address__r.Pincode__r.City_Master__r.Name, Insurance_Verification__r.Premium_Amount__c From Loan_Applicant__c WHERE Application__c =: applicationId];
            List<String> borrowerList = new List<String>();
            List<String> guarantorList = new List<String>();
            if (!applicants.isEmpty()) {
                for (Loan_Applicant__c applicant : applicants) {
                    if (applicant.Applicant_Type__c == 'Primary Applicant') {
                        sanctionLetter.primaryApplicant = applicant;
                        borrowerList.add(applicant.Name);
                    } else if (applicant.Applicant_Type__c == 'Co-Applicant') {
                        borrowerList.add(applicant.Name);
                    } else if (applicant.Applicant_Type__c == 'Guarantor') {
                        guarantorList.add(applicant.Name);
                    }
                }
            }
            sanctionLetter.borrowers  = borrowerList.isEmpty() ? 'NONE' :  String.join(borrowerList, ', ');
            sanctionLetter.gurantors  = guarantorList.isEmpty() ? 'NONE' : String.join(guarantorList, ', ');
            
            List<Collateral__c> collaterals = [SELECT Id, Name, Full_Address__c, Application__c, Property_Owner__c FROM Collateral__c WHERE Application__c =: applicationId];
            sanctionLetter.collaterals = collaterals;
            
            List<Charge_Master__c> chargeList = [SELECT Id, Amount_Based__c, Lower_Range__c, Upper_Range__c, GST_Percentage__c, Charge_Sub_Type__c, Product_Type__c, Type_Of_Charge__c, Login_Fee__c FROM Charge_Master__c WHERE Product_Type__c =: application.Product__r.Product_Type__c AND Lower_Range__c <= :application.Sanction_Amount__c AND Upper_Range__c>= :application.Sanction_Amount__c];
            if(!chargeList.isEmpty()){
                for(Charge_Master__c charge : chargeList){
                    if(charge.Type_of_Charge__c == 'Cersai'){
                        sanctionLetter.cersaiCharge = CurrencyInWordsUtil.formatINR(Decimal.valueOf(charge.Amount_Based__c));
                    }else if(charge.Type_of_Charge__c == 'Charges'){
                        sanctionLetter.administrativeAndOperationalCharge = CurrencyInWordsUtil.formatINR(charge.Login_Fee__c);
                    }
                }
            }
            
            List<Bank_Details__c> bankDetails = [SELECT Id, Name, Due_Day__c, Interest_Rate_Type__c, Installment_Type__c FROM Bank_Details__c WHERE Application__c = :applicationId AND RecordType.DeveloperName = 'Repayment' LIMIT 1];
            if(!bankDetails.isEmpty()){
                sanctionLetter.bankDetail = bankDetails[0];
                sanctionLetter.dueDate = String.isNotBlank(bankDetails[0].Due_Day__c) ? + bankDetails[0].Due_Day__c + 'th Every Month' : '';
            }
            
            List<Anchor_Master__c> masters = [SELECT Id, Anchor_Type__c, Anchor_Rate__c FROM Anchor_Master__c WHERE Is_Active__c = true];
            if(!masters.isEmpty()){
                Decimal plrPercent = (masters[0].Anchor_Type__c == 'PLR' &&  masters[0].Anchor_Rate__c != null) ? masters[0].Anchor_Rate__c : 0;
                sanctionLetter.plr = plrPercent + '% p.a.';
                Decimal spreadRate = application.Rate_of_Interest__c != null ? plrPercent - application.Rate_of_Interest__c : 0;
                sanctionLetter.applicableInterestRate = String.valueOf(plrPercent - spreadRate) + '% per annum';
            }
        }
        System.debug('sanctionLetter --> '+ JSON.serializePretty(sanctionLetter));
    }
    
    public class SanctionLetterWrapper {
        public Application__c application {get; set;}
        public Boolean isHL {get; set;}
        public Loan_Applicant__c primaryApplicant {get; set;}
        public List<Bank_Details__c> bankDetails {get; set;}        
        public List<Collateral__c> collaterals {get; set;}
        public Bank_Details__c bankDetail {get; set;}
        public String borrowers {get; set;}
        public String gurantors {get; set;}
        public String cersaiCharge {get; set;}
        public String administrativeAndOperationalCharge {get; set;}
        public String plr {get; set;}
        public Decimal spreadRate {get; set;}
        public String applicableInterestRate {get; set;}
        public String sanctionDate {get; set;}
        public String emi {get;set;}
        public String dueDate {get; set;}
        public String loanAmount {get; set;}
    }
    
}