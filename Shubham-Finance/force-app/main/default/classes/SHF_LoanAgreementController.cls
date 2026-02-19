/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_LoanAgreementController
 * Author          : Pankaj Anand
 * Created Date    : Jan 30, 2026
 * Last Modified By: <YourName>
 * Description     : For Loan Agreement Document generation     VFPage : SHF_Combined_Loan_Agreement
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 30, 2026  │ Pankaj Anand   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class SHF_LoanAgreementController {

    public LoanAgreementWrapper loanAgreement {get; set;}
    public String sanctionLoanAmountInWords {get; set;}
    public String salutationHtml { get; set; }

    public SHF_LoanAgreementController() {
        loanAgreement = new LoanAgreementWrapper();
        Id applicationId = ApexPages.currentPage().getParameters().get('id');
        
        applicationId = 'a03C100000JkkN3IAJ'; 

        if(applicationId != null) {
            Application__c application = [SELECT Id, Name, Sanction_Amount__c, Negotiation_Rate_of_Interest_ROI__c,
                                          Branch__r.Name, Sanction_Date__c, Revised_Rate__c
                                          FROM Application__c WHERE Id = :applicationId];

            sanctionLoanAmountInWords = CurrencyInWordsUtil.formatINR(application.Sanction_Amount__c);
            Date d = application.Sanction_Date__c;
            loanAgreement.sanctionDate = d != null ? d.format() : '';
            loanAgreement.sanctionDateInWords = d != null ? String.valueOf(d.day()) + ' day of ' + String.valueOf(d.month()) + ' Two thousand and ' + String.valueOf(d.year()).subString(2,4) : '';
            loanAgreement.application = application;

            List<Loan_Applicant__c> applicants = [SELECT Id, Name, Applicant_Type__c, Salutation__c, Customer_Type__c,
                                                  Address__r.Address_Line_1__c, Address__r.Address_Line_2__c, 
                                                  Address__r.Address_Line_3__c, Address__r.Pincode__r.City_Master__r.Name, 
                                                  Address__r.Pincode__r.Name
                                                  FROM Loan_Applicant__c WHERE Application__c = :applicationId];

            loanAgreement.secondaryApplicants = new List<ApplicantWrapper>();
            for(Loan_Applicant__c app : applicants) {
                ApplicantWrapper wrap = new ApplicantWrapper();
                wrap.record = app;
                wrap.radioHtml = generateSalutationHtml(app.Salutation__c);

                if(app.Applicant_Type__c == 'Primary Applicant') {
                    loanAgreement.primaryApplicant = app;
                    loanAgreement.primaryApplicantName = wrap;
                } else {
                    loanAgreement.secondaryApplicants.add(wrap);
                }
            }

            String addressType = loanAgreement.primaryApplicant.Customer_Type__c == 'Individual' ? 'Current Address' : 'Office Address';
            List<Address__c> primaryAddr = [SELECT Id, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, 
                                            Pincode__r.City_Master__r.Name, Pincode__r.Name
                                            FROM Address__c 
                                            WHERE Loan_Applicant__c = :loanAgreement.primaryApplicant.Id 
                                            AND Mailing_Address__c = :addressType LIMIT 1];
            loanAgreement.address = primaryAddr.isEmpty() ? null : primaryAddr[0];

            List<Collateral__c> colls = [SELECT Id, House_FlatNumber__c, Built_Up_Area__c, Full_Address__c 
                                        FROM Collateral__c WHERE Application__c = :applicationId];
            List<String> addressParts = new List<String>();
            for(Collateral__c c : colls) {
                String entry = 'Collateral Address : ' + (c.House_FlatNumber__c ?? '') + 
                               ' , admeasuring ' + (c.Built_Up_Area__c != null ? String.valueOf(c.Built_Up_Area__c) : '') + 
                               ' of built up area, situated at ' + (c.Full_Address__c ?? '');
                addressParts.add(entry);
            }
            loanAgreement.collateralAddresses = addressParts.isEmpty() ? '' : 
                (addressParts.size() == 1 ? 'the property ' : 'the properties ') + String.join(addressParts, ', ');
            
            loanAgreement.witnessList = new List<String>();
        }
    }

    private String generateSalutationHtml(String selected) {
        String html = '';
        for(String opt : new List<String>{'Mr', 'Mrs', 'Ms'}) {
            String symbol = (opt == selected) ? '&#9673;' : '&#9675;';
            html += '<span style="font-family: Arial Unicode MS; white-space:nowrap;">' + symbol + ' ' + opt + '&nbsp;&nbsp;</span>';
        }
        return html;
    }

    public class LoanAgreementWrapper {
        public Application__c application {get; set;}
        public Loan_Applicant__c primaryApplicant {get; set;}
        public ApplicantWrapper primaryApplicantName {get; set;}
        public List<ApplicantWrapper> secondaryApplicants {get; set;}
        public Address__c address {get; set;}
        public String sanctionDate {get; set;}
        public String sanctionDateInWords {get; set;}
        public String collateralAddresses {get; set;}
        public List<String> witnessList {get; set;}
    }

    public class ApplicantWrapper {
        public Loan_Applicant__c record {get; set;}
        public String radioHtml {get; set;}
    }
}