public without sharing class SHF_FinancialSheetController {

    // Added by karan 

    public class FinancialRowWrapper {
        @AuraEnabled public Integer rowIndex { get; set; }
        @AuraEnabled public Integer order { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }

    // Get assets on the base of loan applicant 
    @AuraEnabled
    public static List<Assets__c> getAssets(String loanApplicantId) {
        return [
            SELECT Id, Name, Asset_Type__c, Category__c, Asset_Type_Description__c, Asset_Value__c 
            FROM Assets__c 
            WHERE Loan_Applicant__c = :loanApplicantId
        ];
    }

    // Save assets, upsert and delete rows
    @AuraEnabled
    public static void saveAssets(List<Assets__c> assetsToSave, List<String> assetIdsToDelete, String loanApplicantId) {
        try {
            // Delete removed rows
            if (assetIdsToDelete != null && !assetIdsToDelete.isEmpty()) {
                delete [SELECT Id FROM Assets__c WHERE Id IN :assetIdsToDelete];
            }

            // Link new records
            for (Assets__c a : assetsToSave) {
                if (String.isBlank(a.Loan_Applicant__c)) {
                    a.Loan_Applicant__c = loanApplicantId;
                }
            }

            upsert assetsToSave;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving assets: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<FinancialRowWrapper> getFinancialData(String loanApplicantId, String incomeProgram) {
        List<FinancialRowWrapper> wrapperList = new List<FinancialRowWrapper>();
        
        List<Income_And_Financial_QA__c> qaList = [
            SELECT Value__c 
            FROM Income_And_Financial_QA__c 
            WHERE Income_And_Financial__r.Loan_Applicant__c = :loanApplicantId 
            AND Income_And_Financial__r.Applicable_Calculator__c = :incomeProgram
        ];

        for (Income_And_Financial_QA__c qa : qaList) {
            if (String.isNotBlank(qa.Value__c)) {
                try {
                    // FIX: Unescape the HTML characters (converting &quot; back to ")
                    String jsonString = qa.Value__c.unescapeHtml4();
                    
                    // Deserialize directly into the Wrapper class
                    FinancialRowWrapper wrapper = (FinancialRowWrapper) JSON.deserialize(jsonString, FinancialRowWrapper.class);
                    wrapperList.add(wrapper);
                } catch (Exception e) {
                    System.debug('Error parsing row: ' + e.getMessage());
                }
            }
        }
        return wrapperList;
    }

    @AuraEnabled(cacheable=true)
    public static List<SHF_Financial_Sheet__mdt> getFinancialSheet(String incomeProgram) {
        return [
            SELECT DeveloperName,
                   Label__c,
                   Order__c,
                   Data_type__c,
                   Is_Disabled__c,
                   Is_Show_On_UI__c,
                   Is_Required__c,
                   Max_length__c,
                   Max_Value__c,
                   Min_value__c,
                   Formula__c
            FROM SHF_Financial_Sheet__mdt
            WHERE Income_Program__c = :incomeProgram
            ORDER BY Order__c ASC
        ];
    }

    @AuraEnabled
    public static void saveFinancialData(
        Id loanApplicantId,
        String applicableCalculator,
        List<FinancialRowWrapper> rows,
        Decimal netIncome) {

            if(netIncome != null) {
            netIncome = netIncome.setScale(2);
            }

        if (loanApplicantId == null || String.isBlank(applicableCalculator)) {
            throw new AuraHandledException('Missing required data');
        }
        Income_And_Financial__c parent;

        List<Income_And_Financial__c> existing = [
                SELECT Id
                FROM Income_And_Financial__c
                WHERE Loan_Applicant__c = :loanApplicantId
                AND Applicable_Calculator__c = :applicableCalculator
                LIMIT 1
        ];

        if (!existing.isEmpty()) {
            parent = existing[0];

            parent.Assessed_Monthly_Income__c = netIncome; 
            update parent;
            // delete old child records to prevent getting duplicate data
             delete [SELECT Id FROM Income_And_Financial_QA__c WHERE Income_And_Financial__c = :parent.Id];
        } else {
            parent = new Income_And_Financial__c(
                    Loan_Applicant__c = loanApplicantId,
                    Applicable_Calculator__c = applicableCalculator, 
                    Assessed_Monthly_Income__c = netIncome
                );
            insert parent;
        }
        List<Income_And_Financial_QA__c> qaList = new List<Income_And_Financial_QA__c>();

        for (FinancialRowWrapper row : rows) {
            Map<String, Object> valueJson = new Map<String, Object>{
                'rowIndex' => row.rowIndex,
                'order' => row.order,
                'label' => row.label,
                'value' => row.value
            };

            qaList.add(new Income_And_Financial_QA__c(
                Income_And_Financial__c = parent.Id,
                Order__c = row.order,
                Label__c = row.label,
                Value__c = JSON.serialize(valueJson)
            ));
        }

        if (!qaList.isEmpty()) {
            insert qaList;
        }
        
        SHF_AppraisedIncomeHelper.updateAppraisedIncome(new Set<Id>{loanApplicantId});

        // Clear the sendback flag since Financial Calculator has been re-initiated
        Loan_Applicant__c la = new Loan_Applicant__c(
            Id = loanApplicantId,
            Financial_Calculator_Changed_After_SB__c = false
        );
        update la;
    }

}