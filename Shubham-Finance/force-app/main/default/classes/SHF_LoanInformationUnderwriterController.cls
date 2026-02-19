public without sharing class SHF_LoanInformationUnderwriterController {

    public class SummaryRow {
        @AuraEnabled public Id id;
        @AuraEnabled public Decimal sanctionAmount;
        @AuraEnabled public Decimal roi;
        @AuraEnabled public Decimal tenure;
        @AuraEnabled public Decimal loanAmount;
        @AuraEnabled public String loanPurpose;
        @AuraEnabled public Decimal insuranceTotal;
        @AuraEnabled public Decimal sanctionIncludingInsurance;
    }

    @AuraEnabled(cacheable=true)
    public static List<SummaryRow> getSummary(Id applicationId) {
        if (applicationId == null) return new List<SummaryRow>();

        Application__c app = [
            SELECT Sanction_Amount__c, Rate_of_Interest__c, Tenure__c,
                   Applied_Loan_Amount__c, Purpose_of_Loan__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        Decimal insTotal = 0;
        AggregateResult ar = [
            SELECT SUM(Insurance_Verification__r.Premium_Amount__c) totalPrem
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId 
              AND Insurance_Verification__c != null
        ];
        if (ar != null && ar.get('totalPrem') != null) {
            insTotal = (Decimal) ar.get('totalPrem');
        }

        Decimal sanction = app.Sanction_Amount__c == null ? 0 : app.Sanction_Amount__c;

        SummaryRow row = new SummaryRow();
        row.id = applicationId;
        row.sanctionAmount = app.Sanction_Amount__c;
        row.roi = app.Rate_of_Interest__c;
        row.tenure = app.Tenure__c;
        row.loanAmount = app.Applied_Loan_Amount__c;
        row.loanPurpose = app.Purpose_of_Loan__c;
        row.insuranceTotal = insTotal;
        row.sanctionIncludingInsurance = sanction + insTotal;

        return new List<SummaryRow>{ row };
    }
}