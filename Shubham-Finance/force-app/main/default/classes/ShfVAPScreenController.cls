public class ShfVAPScreenController {

    // Utility wrapper for applicant check
    @AuraEnabled
    public static String getPrimaryApplicantName(Id applicationId) {
        Application__c app = [
            SELECT Id,
                   (SELECT Id, Name, Applicant_Type__c, Insurance_Verification__c
                    FROM Loan_Applicants__r
                    WHERE Applicant_Type__c = 'Primary Applicant'
                    LIMIT 1)
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        if (app.Loan_Applicants__r == null || app.Loan_Applicants__r.isEmpty()) {
            return 'No Primary Applicant found';
        }

        if (String.isBlank(app.Loan_Applicants__r[0].Insurance_Verification__c)) {
            return 'INSURANCE_REQUIRED';
        }

        return app.Loan_Applicants__r[0].Name;
    }

    @AuraEnabled
    public static Application__c getApplicationDetails(String recordId){
        Application__c app = [
            SELECT Id, OwnerId,
                   (SELECT Id, Name, Applicant_Type__c, Insurance_Verification__c, Customer_Type__c,
                    Insurance_Verification__r.Premium_Amount__c, Insurance_Verification__r.Sum_Insured__c,
                    Insurance_Verification__r.Insurance_Provider__c, Insurance_Verification__r.Nominee_Name__c,
                    Insurance_Verification__r.Nominee_Relationship__c, Insurance_Verification__r.Nominee_Date_of_Birth__c,
                    Insurance_Verification__r.Nominee_Address__c, Insurance_Verification__r.Percentage_of_Entitlement__c,
                    Insurance_Verification__r.Nominee_Gender__c
                    FROM Loan_Applicants__r
                    WHERE Applicant_Type__c = 'Primary Applicant'
                    LIMIT 1),
                    (SELECT Id, Application__c, VAP_Product__c, Applicant_Name__c, VAP_Category__c,
                    VAP_Type__c, VAP_Treatment__c, VAP_Policy_Amount__c, VAP_Amount__c,
                    Bought_From__c, Disburse_To__c, Policy_Number__c, Gender__c,
                    Insurance_Term_in_Years__c, Insurance_Term_in_Months__c, Start_Date__c, Maturity_Date__c,
                    Coverage_Type__c, Coverage_Amount__c, Premium_Amount__c, Insured__c,
                    Nominee_Name__c, Nominee_Relationship__c, Date_of_Birth__c, Nominee_address__c,
                    Percentage_of_Entitlement__c FROM VAP__r)
            FROM Application__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return app;
    }

    @AuraEnabled(cacheable=true)
    public static List<E_Verification_Line_Item__c> getPrimaryApplicantNominees(Id applicationId) {

        // Get Primary Applicant's Insurance Verification
        Loan_Applicant__c primaryApplicant = [
            SELECT Id, Insurance_Verification__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            AND Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];

        Id nomineeRTId = Schema.SObjectType.E_Verification_Line_Item__c
        .getRecordTypeInfosByDeveloperName()
        .get('Insurance_Nominee')
        .getRecordTypeId();

        if (primaryApplicant.Insurance_Verification__c == null) {
            return new List<E_Verification_Line_Item__c>();
        }

        return [
            SELECT Id,
                Sequence__c,
                Nominee_Name__c,
                Nominee_Relationship__c,
                Nominee_Date_of_Birth__c,
                Nominee_Gender__c,
                Is_Minor__c,
                Appointee_Name__c,
                Appointee_Relationship__c,
                Appointee_DOB__c,
                Percentage_of_Entitlement__c,
                Nominee_Address__c
            FROM E_Verification_Line_Item__c
            WHERE E_Verification__c = :primaryApplicant.Insurance_Verification__c
            AND RecordTypeId = :nomineeRTId
            ORDER BY Sequence__c ASC
        ];
    }


    /*
    @AuraEnabled(cacheable=true)
    public static Decimal getPremiumAmount(Id applicationId) {
    E_Verification__c ev = [
        SELECT Premium_Amount__c,Sum_Insured__c 
        FROM E_Verification__c
        WHERE Loan_Application__c = :applicationId
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    return ev.Premium_Amount__c;
}

    */

    public class PremiumResult {
        @AuraEnabled public Decimal premiumAmount;
        @AuraEnabled public Decimal sumInsured;
    }

    @AuraEnabled(cacheable=true)
    public static PremiumResult getPremiumAmount(Id applicationId) {
        E_Verification__c ev = [
            SELECT Premium_Amount__c, Sum_Insured__c
            FROM E_Verification__c
            WHERE Loan_Application__c = :applicationId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        PremiumResult result = new PremiumResult();
        result.premiumAmount = ev.Premium_Amount__c;
        result.sumInsured    = ev.Sum_Insured__c;
        return result;
    }


    @AuraEnabled
    public static VAP__c saveVAPRecord(VAP__c vapRecord){
        try{
            UPSERT vapRecord;
        }catch(Exception e){
            throw newMessageException(e.getMessage());
        }
        return vapRecord;
    }

    @AuraEnabled
    public static List<PicklistOption> getApplicantOptions(String recordId) {

        List<PicklistOption> options = new List<PicklistOption>();

        for (Loan_Applicant__c record : [SELECT Id, Name FROM Loan_Applicant__c WHERE Application__c =: recordId ORDER BY Applicant_Type__c ASC ]) {
            options.add(new PicklistOption(record.Name, record.Id));
        }

        return options;
    }

    public class PicklistOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    private static AuraHandledException newMessageException(String msg){
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }

    /*@AuraEnabled
    public static Id saveVAPRecord(VAP__c vapRec) {
    // 1. Insurance Verification
    List<E_Verification__c> insVerList = [
        SELECT Id, Premium_Amount__c, Sum_Insured__c, Insured__c, Loan_Application__c, Loan_Tenure_In_Years__c
        FROM E_Verification__c
        WHERE Loan_Application__c = :vapRec.Application__c
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    if (insVerList.isEmpty()) {
        throw new AuraHandledException('No Insurance Verification found for this Application.');
    }
    E_Verification__c insVer = insVerList[0];

    // 2. Existing VAP check
    List<VAP__c> existingVapList = [
        SELECT Id FROM VAP__c WHERE Application__c = :vapRec.Application__c LIMIT 1
    ];

    VAP__c targetVap;
    if (!existingVapList.isEmpty()) {
        targetVap = existingVapList[0];
    } else {
        targetVap = new VAP__c();
        targetVap.Application__c = vapRec.Application__c;
        targetVap.Applicant_Name__c = vapRec.Applicant_Name__c;
        String applicant = String.isBlank(vapRec.Applicant_Name__c) ? 'Unknown' : vapRec.Applicant_Name__c;
        targetVap.Name = 'VAP-' + applicant + '-' + Date.today().format();
    }

    // 3. Copy values from LWC vapRec
    targetVap.VAP_Product__c        = vapRec.VAP_Product__c;
    targetVap.VAP_Category__c       = vapRec.VAP_Category__c;
    targetVap.VAP_Type__c           = vapRec.VAP_Type__c;
    targetVap.VAP_Treatment__c      = vapRec.VAP_Treatment__c;
    targetVap.VAP_Policy_Amount__c  = vapRec.VAP_Policy_Amount__c;
    targetVap.VAP_Amount__c         = vapRec.VAP_Amount__c;
    targetVap.Bought_From__c        = vapRec.Bought_From__c;
    targetVap.Disburse_To__c        = vapRec.Disburse_To__c;
    targetVap.Policy_Number__c      = vapRec.Policy_Number__c;
    targetVap.Insurance_Term_in_Years__c = vapRec.Insurance_Term_in_Years__c;
    targetVap.Insurance_Term_in_Months__c= vapRec.Insurance_Term_in_Months__c;
    targetVap.Start_Date__c         = vapRec.Start_Date__c;
    targetVap.Maturity_Date__c      = vapRec.Maturity_Date__c;
    targetVap.Coverage_Type__c      = vapRec.Coverage_Type__c; // must be valid picklist value
    targetVap.Date_of_Birth__c      = vapRec.Date_of_Birth__c;
    targetVap.Nominee_address__c    = vapRec.Nominee_address__c;
    targetVap.Nominee_Name__c       = vapRec.Nominee_Name__c;
    targetVap.Nominee_Relationship__c = vapRec.Nominee_Relationship__c;
    targetVap.Gender__c             = vapRec.Gender__c;  
    targetVap.Insured__c            = vapRec.Insured__c;  
    targetVap.Percentage_of_Entitlement__c   = vapRec.Percentage_of_Entitlement__c;

    // 4. Stamp Insurance Verification values (if business requires overriding)
    //targetVap.Premium_Amount__c = insVer.Premium_Amount__c;
    targetVap.Coverage_Amount__c = insVer.Sum_Insured__c;
    //targetVap.Insurance_Term_in_Years__c = insVer.Loan_Tenure_In_Years__c;

    // 5. Save
    try {
        if (targetVap.Id != null) {
            update targetVap;
        } else {
            insert targetVap;
        }
    } catch (DmlException e) {
        throw new AuraHandledException('Failed to save VAP record: ' + e.getMessage());
    }

    return targetVap.Id;
}*/
}