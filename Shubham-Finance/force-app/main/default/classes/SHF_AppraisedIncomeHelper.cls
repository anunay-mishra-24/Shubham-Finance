/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_AppraisedIncomeHelper
 * Author          : <Karan>
 * Created Date    : Jan 6, 2026
 * Last Modified By: <Karan>
 * Last Modified On: Jan 6, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 6, 2026  │ <Karan>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public with sharing class SHF_AppraisedIncomeHelper {

    public static void updateAppraisedIncome(Set<Id> loanApplicantIds) {
        if (loanApplicantIds == null || loanApplicantIds.isEmpty()) return;

        List<Loan_Applicant__c> applicantsToUpdate = new List<Loan_Applicant__c>();

        Map<Id, Income_And_Financial__c> applicantToFinancialMap = new Map<Id, Income_And_Financial__c>();
        for (Income_And_Financial__c i : [
            SELECT Loan_Applicant__c, Applicable_Calculator__c, Assessed_Monthly_Income__c 
            FROM Income_And_Financial__c 
            WHERE Loan_Applicant__c IN :loanApplicantIds
            ORDER BY LastModifiedDate DESC 
        ]) {
            if (!applicantToFinancialMap.containsKey(i.Loan_Applicant__c)) {
                applicantToFinancialMap.put(i.Loan_Applicant__c, i);
            }
        }

        List<ID> myList = new List<ID>(loanApplicantIds);

        Map<Id, Decimal> incomeDetailsMap = getAggregateSum(myList.get(0), 'Income_Details');

        Map<Id, Decimal> otherIncomeMap = getAggregateSum(myList.get(0), 'Other_Income_Details');

        for (Id applicantId : loanApplicantIds) {
            Decimal finalAppraisedIncome = 0;
            
            Income_And_Financial__c financialRec = applicantToFinancialMap.get(applicantId);
            String program = (financialRec != null) ? financialRec.Applicable_Calculator__c : 'Common Income Program'; // Default
            
            Decimal otherIncome = otherIncomeMap.containsKey(applicantId) ? otherIncomeMap.get(applicantId) : 0;
            Decimal incomeDetails = incomeDetailsMap.containsKey(applicantId) ? incomeDetailsMap.get(applicantId) : 0;
            Decimal calculatorIncome = (financialRec != null && financialRec.Assessed_Monthly_Income__c != null) ? financialRec.Assessed_Monthly_Income__c : 0;

            System.debug('otherIncome '+ otherIncome);
            System.debug('incomeDetails '+ incomeDetails);
            System.debug('calculatorIncome '+ calculatorIncome);
            System.debug('program '+ program);

            // --- SITUATION LOGIC ---
            if (program == 'Eligibility Calculator' || program == 'Common Income Program' || program == 'Final_Eligibility_Calculator') {
                finalAppraisedIncome = incomeDetails + otherIncome;
            } else {
                finalAppraisedIncome = calculatorIncome + otherIncome;
            }

            applicantsToUpdate.add(new Loan_Applicant__c(
                Id = applicantId,
                Appraised_Income__c = finalAppraisedIncome,
                Total_Income__c = finalAppraisedIncome
            ));
        }

        if (!applicantsToUpdate.isEmpty()) {
            update applicantsToUpdate;
        }
    }

    private static Map<Id, Decimal> getAggregateSum(ID applicantId, String recordTypeDevName) {
        Map<Id, Decimal> resultMap = new Map<Id, Decimal>();

        List<Income_details__c> incomeList = [SELECT Loan_Applicant__c, Total_Income_Monthly__c 
            FROM Income_Details__c 
            WHERE Loan_Applicant__c = :applicantId 
            AND RecordType.DeveloperName = :recordTypeDevName limit 1 ];

        if(incomeList != null && incomeList.size() > 0){
            resultMap.put(applicantId, incomeList[0].Total_Income_Monthly__c);
        }else{
            resultMap.put(applicantId, 0);
        }
        
        /** for (AggregateResult ar : [
            SELECT Loan_Applicant__c, SUM(Total_Income_Monthly__c) total
            FROM Income_Details__c 
            WHERE Loan_Applicant__c IN :applicantIds 
            AND RecordType.DeveloperName = :recordTypeDevName
            GROUP BY Loan_Applicant__c
        ]) {
            resultMap.put((Id)ar.get('Loan_Applicant__c'), (Decimal)ar.get('total'));
        } **/
        return resultMap;
    }
}