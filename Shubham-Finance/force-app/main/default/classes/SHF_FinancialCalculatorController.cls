/**
* @File Name          : SHF_FinancialCalculatorController.cls
* @Description        : 
* @Author             : Akshi Sharma 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         14-11-2025               Akshi Sharma           
*/
public with sharing class SHF_FinancialCalculatorController {

    @AuraEnabled(cacheable=true)
    public static List<LoanApplicantWrapper> getLoanApplicants(Id applicationId) {
        List<LoanApplicantWrapper> listWrap = new List<LoanApplicantWrapper>();

        for (Loan_Applicant__c la : [
            SELECT Id, Name, Customer_Profile__c, Customer_Type__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId AND IsFinancial_Applicant__c = 'Yes' AND IsDeleted__c = false
            ORDER BY CreatedDate
        ]) {
            LoanApplicantWrapper w = new LoanApplicantWrapper();
            w.id = la.Id;
            w.name = la.Name;
            w.customerProfile = la.Customer_Profile__c;
            w.customerType = la.Customer_Type__c;
            listWrap.add(w);
        }
        return listWrap;
    }

    /** Added by Karan **/

    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> getTabVisibilityFlags(String loanApplicantId) {
        Map<String, Boolean> flags = new Map<String, Boolean>{
            'showExpenseTab' => false
        };
        
        List<Loan_Applicant__c> applicants = [
            SELECT Customer_Type__c, IsFinancial_Applicant__c 
            FROM Loan_Applicant__c 
            WHERE Id = :loanApplicantId 
            LIMIT 1
        ];

        if (!applicants.isEmpty()) {
            Loan_Applicant__c app = applicants[0];
            if (app.Customer_Type__c == 'Individual' && app.IsFinancial_Applicant__c == 'Yes') {
                flags.put('showExpenseTab', true);
            }
        }
        return flags;
    }

    // METHOD TO GET SAVED PROGRAM
    @AuraEnabled
    public static String getSavedIncomeProgram(String loanApplicantId) {
        List<Income_And_Financial__c> records = [
            SELECT Applicable_Calculator__c 
            FROM Income_And_Financial__c 
            WHERE Loan_Applicant__c = :loanApplicantId 
            LIMIT 1
        ];
        if (!records.isEmpty()) {
            return records[0].Applicable_Calculator__c;
        }
        return null;
    }

    @AuraEnabled
    public static Map<String, String> getSavedFinancialRecord(String recordId) {
        List<Income_And_Financial__c> existingRecords = [
            SELECT Loan_Applicant__c, Applicable_Calculator__c 
            FROM Income_And_Financial__c 
            WHERE Loan_Applicant__c IN (
                SELECT Id FROM Loan_Applicant__c WHERE Application__c = :recordId
            )
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        if (!existingRecords.isEmpty()) {
            return new Map<String, String>{
                'borrowerId' => existingRecords[0].Loan_Applicant__c,
                'incomeProgram' => existingRecords[0].Applicable_Calculator__c
            };
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static ApplicantReadOnlyWrapper getApplicantReadOnlyData(Id applicantId) {

        Loan_Applicant__c applicant = [
            SELECT Id, Name, Entity_Name__c, Applicant_Type__c, RecordType_Name__c,
                   Constitution__c, IsFinancial_Applicant__c, Customer_Type__c,
                   Date_of_Birth__c, Date_Of_Incorporation1__c,
                   Customer_Profile__c, Risk_Category__c,Application__r.Name,
                   Final_Risk_Score__c
            FROM Loan_Applicant__c
            WHERE Id = :applicantId
            LIMIT 1
        ];

        List<Employment__c> empList = [
            SELECT Industry__c, Sub_Industry__c
            FROM Employment__c
            WHERE Loan_Applicant__c = :applicantId
            LIMIT 1
        ];

        Employment__c emp;
        if (!empList.isEmpty()) {
            emp = empList[0];
        } else {
            emp = null;
        }
        
        ApplicantReadOnlyWrapper applicantWrapper = new ApplicantReadOnlyWrapper();
        applicantWrapper.applicationId   = applicant.Application__r.Name;
        applicantWrapper.applicantType   = applicant.Applicant_Type__c;
        applicantWrapper.constitution    = applicant.Constitution__c;
        applicantWrapper.isFinancial     = applicant.IsFinancial_Applicant__c;
        applicantWrapper.customerProfile = applicant.Customer_Profile__c;
        applicantWrapper.customerType = applicant.Customer_Type__c;
        applicantWrapper.riskCategory    = applicant.Risk_Category__c;
        applicantWrapper.riskScore       = applicant.Final_Risk_Score__c;
        applicantWrapper.industry        = emp != null ? emp.Industry__c : null;
        applicantWrapper.subIndustry     = emp != null ? emp.Sub_Industry__c : null;

        // Conditional display logic
        if (applicant.RecordType_Name__c == 'Individual') {
            applicantWrapper.displayName = applicant.Name;
            applicantWrapper.dobOrDoi    = applicant.Date_of_Birth__c;
        } else {
            applicantWrapper.displayName = applicant.Entity_Name__c;
            applicantWrapper.dobOrDoi    = applicant.Date_Of_Incorporation1__c;
        }


        return applicantWrapper;
    }


    public class LoanApplicantWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String customerProfile;
        @AuraEnabled public String customerType;
    }

    public class ApplicantReadOnlyWrapper {
        @AuraEnabled public String applicationId;
        @AuraEnabled public String displayName;
        @AuraEnabled public String applicantType;
        @AuraEnabled public String constitution;
        @AuraEnabled public String isFinancial;
        @AuraEnabled public Date dobOrDoi;
        @AuraEnabled public String customerProfile;
        @AuraEnabled public String customerType;
        @AuraEnabled public String riskCategory;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public String industry;
        @AuraEnabled public String subIndustry;
    }
}