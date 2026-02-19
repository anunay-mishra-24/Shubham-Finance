/**
 * @File Name          : SHF_UWApplicantFinancialTableController.cls
 * @Description        : Show the required fields into Data table for Under Writer decision Screen.
 * @Author             : Anunay Kumar
 * @Created Date        : 2026-01-07
 * @Last Modified Date  : 2026-01-07
 *
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0         2026-01-07           Anunay Kumar         Initial Version
 */




public with sharing class SHF_UWApplicantFinancialTableController {

    public class ApplicantRow {
        @AuraEnabled public Id applicantId;
        @AuraEnabled public String applicantName;
        @AuraEnabled public Decimal appraisedIncome;
        @AuraEnabled public String incomeProgram;
        @AuraEnabled public String customerProfile;
    }

    // As per requirement: Salaried applicants always get this program
    private static final String COMMON_INCOME_PROGRAM = 'Common Income Program';

    @AuraEnabled(cacheable=true)
    public static List<ApplicantRow> getApplicantFinancialRows(Id applicationId) {
        if (applicationId == null) return new List<ApplicantRow>();

        // 1) Loan Applicants under Application 
        List<Loan_Applicant__c> applicants = [
            SELECT Id, Name, Account_Name__c, Appraised_Income__c, Customer_Profile__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            ORDER BY CreatedDate ASC
        ];
        if (applicants.isEmpty()) return new List<ApplicantRow>();

        Set<Id> applicantIds = new Set<Id>();
        for (Loan_Applicant__c la : applicants) applicantIds.add(la.Id);

        // 2) For NON-salaried applicants: Income Program from Income_And_Financial__c records
        Map<Id, String> programByApplicant = new Map<Id, String>();
        for (Income_And_Financial__c iaf : [
            SELECT Loan_Applicant__c, Applicable_Calculator__c, CreatedDate
            FROM Income_And_Financial__c
            WHERE Loan_Applicant__c IN :applicantIds
            AND Applicable_Calculator__c != null
            ORDER BY CreatedDate DESC
        ]) {
            if (!programByApplicant.containsKey(iaf.Loan_Applicant__c)) {
                programByApplicant.put(iaf.Loan_Applicant__c, iaf.Applicable_Calculator__c);
            }
        }

        // 3) Build result rows
        List<ApplicantRow> rows = new List<ApplicantRow>();
        for (Loan_Applicant__c la : applicants) {
            ApplicantRow r = new ApplicantRow();
            r.applicantId = la.Id;
            r.applicantName = String.isBlank(la.Account_Name__c) ? la.Name : la.Account_Name__c;
            r.appraisedIncome = la.Appraised_Income__c;
            r.customerProfile = la.Customer_Profile__c;

            Boolean isSalaried = !String.isBlank(la.Customer_Profile__c)
                && la.Customer_Profile__c.toLowerCase().contains('salaried');

            if (isSalaried) {
                r.incomeProgram = COMMON_INCOME_PROGRAM;
            } else {
                r.incomeProgram = programByApplicant.get(la.Id); // null if not found
            }

            rows.add(r);
        }

        return rows;
    }
}