public with sharing class SHFIncomeProgramControllerUnderwriter {
    
    
    @AuraEnabled(cacheable=true)
    public static String getIncomeProgram(Id applicationId) {
        List<Income_And_Financial__c> records = [
            SELECT Applicable_Calculator__c
            FROM Income_And_Financial__c
            WHERE Loan_Applicant__r.Application__c = :applicationId
            AND Applicable_Calculator__c != null
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0].Applicable_Calculator__c;
    }
    
}