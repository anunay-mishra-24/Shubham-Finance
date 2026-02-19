/**
* @File Name : SHF_EligibilityController.cls
* @Description :
* @Author : Karan Keswani 
* @Last Modified By :
* @Last Modified On : December 29, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 29, 2025 |   | Initial Version
**/

public with sharing class SHF_EligibilityController {

    @AuraEnabled
    public static Application__c getApplicationData(String applicationId) {
        return [
            SELECT Id, 
                   Applied_Loan_Amount__c, 
                   EMI__c, 
                   Rate_of_Interest__c, 
                   Revised_Rate__c, 
                   Tenure__c, 
                   Sanction_Amount__c, 
                   Recommended_Loan_Amount__c,
                   Joint_Exposure__c
            FROM Application__c 
            WHERE Id = :applicationId
        ];
    }

    @AuraEnabled
    public static List<Obligation__c> getObligationsData(String applicationId) {
        return [
            SELECT Id, 
                   Outstanding_Amount__c, 
                   Consider_To_be_Deleted__c, 
                   Considered_for_FOIR__c, 
                   Institution__c, 
                   EMI__c 
            FROM Obligation__c 
            WHERE Application__c = :applicationId AND Loan_Applicant__r.IsFinancial_Applicant__c = 'Yes'
        ];
    }

    public class EligibilityCalculationData {
        @AuraEnabled public Decimal totalAppraisedIncome;
        @AuraEnabled public Decimal totalExpenses;
        @AuraEnabled public String errorMessage;

        public EligibilityCalculationData() {
            this.totalAppraisedIncome = 0;
            this.totalExpenses = 0;
            this.errorMessage = null;
        }
    }

    @AuraEnabled
    public static EligibilityCalculationData getEligibilityData(String applicationId) {
        EligibilityCalculationData data = new EligibilityCalculationData();
        try {
            List<Loan_Applicant__c> financialApplicants = [
                SELECT Id, Appraised_Income__c, IsFinancial_Applicant__c, Expense__c
                FROM Loan_Applicant__c
                WHERE Application__c = :applicationId AND IsFinancial_Applicant__c = 'Yes'
            ];

            if (financialApplicants.isEmpty()) {
                data.errorMessage = 'No financial applicants found.';
                return data;
            }

            Map<Id, Personal_Discussion__c> pdMap = new Map<Id, Personal_Discussion__c>();
            Set<Id> financialApplicantIds = new Map<Id, SObject>(financialApplicants).keySet();

            for (Personal_Discussion__c pd : [
                SELECT Loan_Applicant__c, Total__c
                FROM Personal_Discussion__c
                WHERE Application__c = :applicationId
                AND RecordType.DeveloperName = 'Credit_PD'
                AND Loan_Applicant__c IN :financialApplicantIds
            ]) {
                pdMap.put(pd.Loan_Applicant__c, pd);
            }

            Decimal runningTotalExpenses = 0;
            Decimal runningTotalIncome = 0;

            for (Loan_Applicant__c app : financialApplicants) {
                runningTotalIncome += (app.Appraised_Income__c != null ? app.Appraised_Income__c : 0);

                Decimal applicantExpense = (app.Expense__c != null ? app.Expense__c : 0);
                Decimal pdExpense = 0;

                if (pdMap.containsKey(app.Id)) {
                    pdExpense = (pdMap.get(app.Id).Total__c != null ? pdMap.get(app.Id).Total__c : 0);
                }

                runningTotalExpenses += Math.max(applicantExpense, pdExpense);
            }
            System.debug('TOTAL INCOME: ' + runningTotalIncome);
            System.debug('TOTAL EXPENSES: ' + runningTotalExpenses);
            data.totalAppraisedIncome = runningTotalIncome;
            data.totalExpenses = runningTotalExpenses;
            data.errorMessage = 'Calculation Succeeded'; 

        } catch (Exception e) {
            data.errorMessage = 'FINAL LOGIC FAILED: ' + e.getMessage() + ' ---- STACK TRACE: ' + e.getStackTraceString();
        }
        return data;
    }

    @AuraEnabled(cacheable=true)
    public static Application__c getApplicationPolicyDetails(String applicationId) {
        return [
            SELECT Id, 
                Product__r.Policy_FOIR__c, 
                Product__r.LTV__c 
            FROM Application__c 
            WHERE Id = :applicationId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Collateral_Application__c> getCollaterals(String applicationId) {
        return [
            SELECT Id,
                Collateral__r.Property_Cost__c,  
                Collateral__r.Property_cost_INR__c,
                Collateral__r.Accepted_Value_Valuation_Value_INR__c, 
                Collateral__r.Market_Value_INR__c 
            FROM Collateral_Application__c 
            WHERE Application__c = :applicationId
        ];
    }

    @AuraEnabled
    public static Decimal getMonthlyEMI(Integer tenure, Decimal roi, Decimal loanAmount) {
        if (loanAmount == null || roi == null || tenure == null || tenure == 0) {
            return 0;
        }
        Decimal emi = SHF_Application_RepaymentSchedule.getPMT(roi, tenure, loanAmount);
        return Math.round(emi);
    }

    @AuraEnabled
    public static Boolean validateFinancialApplicants(Id applicationId) {
        List<Loan_Applicant__c> financialApplicants = [
            SELECT Id, Name, Customer_Profile__c
            FROM Loan_Applicant__c 
            WHERE Application__c = :applicationId 
            AND IsFinancial_Applicant__c = 'Yes'
        ];

        if (financialApplicants.isEmpty()) {
            return true; 
        }

        Set<String> incomeDetailsProfiles = new Set<String>{'Formal Salaried', 'Informal Salaried- Bank Credit', 'Informal Salaried- Cash'};
        Set<Id> incomeDetailsProfileIds = new Set<Id>();
        Set<Id> incomeFinancialProfileIds = new Set<Id>();
        Map<Id, Loan_Applicant__c> applicantMap = new Map<Id, Loan_Applicant__c>();

        for(Loan_Applicant__c app : financialApplicants){
            applicantMap.put(app.Id, app);
            if(incomeDetailsProfiles.contains(app.Customer_Profile__c)){
                incomeDetailsProfileIds.add(app.Id);
            } else {
                incomeFinancialProfileIds.add(app.Id);
            }
        }

        Set<Id> applicantIdsWithIncomeDetails = new Set<Id>();
        if(!incomeDetailsProfileIds.isEmpty()){
            for(Income_Details__c inc : [
                SELECT Loan_Applicant__c 
                FROM Income_Details__c 
                WHERE Loan_Applicant__c IN :incomeDetailsProfileIds
            ]){
                applicantIdsWithIncomeDetails.add(inc.Loan_Applicant__c);
            }
        }

        Set<Id> applicantIdsWithIncomeFinancial = new Set<Id>();
        if(!incomeFinancialProfileIds.isEmpty()){
            for(Income_And_Financial__c inc : [
                SELECT Loan_Applicant__c 
                FROM Income_And_Financial__c 
                WHERE Loan_Applicant__c IN :incomeFinancialProfileIds
            ]){
                applicantIdsWithIncomeFinancial.add(inc.Loan_Applicant__c);
            }
        }

        List<String> missingApplicants = new List<String>();
        for(Id applicantId : incomeDetailsProfileIds){
            if(!applicantIdsWithIncomeDetails.contains(applicantId)){
                missingApplicants.add(applicantMap.get(applicantId).Name);
            }
        }

        for(Id applicantId : incomeFinancialProfileIds){
            if(!applicantIdsWithIncomeFinancial.contains(applicantId)){
                missingApplicants.add(applicantMap.get(applicantId).Name);
            }
        }

        if(!missingApplicants.isEmpty()){
            String missingNames = String.join(missingApplicants, ', ');
            throw new AuraHandledException('Income assessment is not for the below applicants: ' + missingNames);
        }

        return true; 
    }
}