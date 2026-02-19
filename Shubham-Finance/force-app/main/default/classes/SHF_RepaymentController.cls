/**
 * @File Name          : SHF_RepaymentController.cls
 * @Description        : 
 * @Author             : Akshi Sharma
 * ==============================================================================
 * Ver         Date         Author       Modification
 * ==============================================================================
 * 1.0         27-08-2025   Akshi Sharma  Initial Version
 */
public with sharing class SHF_RepaymentController {

    @AuraEnabled(cacheable=true)
    public static Bank_Details__c getBankDetails(Id applicationId) {
        // Try to fetch existing record
        List<Bank_Details__c> bankDetailList = [
            SELECT Id, Name, Application__c, Application_Amount__c, Disbursal_Type__c, Number_of_Disbursals__c,
                   Tenure__c, Tenure_In__c, Due_Day__c, Interest_Start_Date__c, First_Installment_Date__c,
                   Recovery_Type__c, Recovery_Sub_Type__c, Repayment_Type__c, Repayment_Frequency__c,
                   Interest_Charge_Method__c, Interest_Rate_Type__c, Interest_Charge_Type__c,
                   Moratorium_Handling__c, Moratorium_Type__c, Moratorium__c, Moratorium_Days__c,Broken_Period_Adjustment__c,
                   Number_of_Advanced_Installments__c, Total_Number_of_Installments__c, Anchor_Type__c, Anchor_Rate__c,
                   Interest_Charged__c,Rate__c, Application__r.Tenure__c, Application__r.Rate_of_Interest__c, Revised_Policy_Rate__c,
                   Application__r.Applied_Loan_Amount__c, Package_Discount__c, Product_Discount__c
            FROM Bank_Details__c
            WHERE Application__c = :applicationId
            AND RecordType.DeveloperName = 'Repayment'
            LIMIT 1
        ];

        if (!bankDetailList.isEmpty()) {
            return bankDetailList[0];
        } else {
            // Return a new unsaved instance for UI
            Bank_Details__c newRecord = new Bank_Details__c(
                Application__c = applicationId
            );
            return newRecord;
        }
    }

    /*@AuraEnabled
    public static String getPrimaryApplicantName(Id applicationId) {
        List<Loan_Applicant__c> primaryApplicants = [
            SELECT Id, Name, Applicant_Type__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            AND Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        return !primaryApplicants.isEmpty() ? primaryApplicants[0].Name : null;
    }*/

    @AuraEnabled
    public static Loan_Applicant__c getPrimaryApplicantName(Id applicationId) {
        List<Loan_Applicant__c> primaryApplicants = [
            SELECT Id, Name, Applicant_Type__c, Application__r.Product__r.Product_Type__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            AND Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        return (!primaryApplicants.isEmpty()) ? primaryApplicants[0] : new Loan_Applicant__c();
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getROIFromRateMaster(Id applicationId) {
        // Fetch application product & branch
        Application__c app = [
            SELECT Id, Branch__c, Product__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        // Fetch highest income applicant with CIBIL & CRIF data
        Loan_Applicant__c richestApplicant = [
            SELECT Id, Name, Total_Income__c,Customer_Profile__c,
                CIBIL_Verification__r.Score__c,
                CRIF_Verification__r.Score__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            ORDER BY Total_Income__c DESC NULLS LAST
            LIMIT 1
        ];

        if (richestApplicant == null) return null;

        // Determine score
        Decimal cibilScore;
        Decimal crifScore;

        if (richestApplicant.CIBIL_Verification__r != null && richestApplicant.CIBIL_Verification__r.Score__c != null) {
            cibilScore = Decimal.valueOf(richestApplicant.CIBIL_Verification__r.Score__c);
        }

        if (richestApplicant.CRIF_Verification__r != null && richestApplicant.CRIF_Verification__r.Score__c != null) {
            crifScore = Decimal.valueOf(richestApplicant.CRIF_Verification__r.Score__c);
        }

        Decimal finalScore;
        if (cibilScore != null && crifScore != null) {
            finalScore = (cibilScore > crifScore) ? cibilScore : crifScore;
        } else if (crifScore != null) {
            finalScore = crifScore;
        } else {
            finalScore = cibilScore;
        }

        // Determine Score Category
        String scoreBand = 'NTC / Not Scored';
        if (finalScore != null) {
            if (finalScore >= 300 && finalScore <= 697) {
                scoreBand = '300-697';
            } else if (finalScore >= 698 && finalScore <= 797) {
                scoreBand = '698-797';
            } else if (finalScore >= 798) {
                scoreBand = '>=798';
            }
        }
        System.debug('>>>scoreband'+scoreBand);

        // Query Rate Master
        List<Rate_Master__c> rmList = [
            SELECT Id, ROI__c
            FROM Rate_Master__c
            WHERE Bureau_Score__c = :scoreBand
            AND Product_Branch_Mapping__r.Branch_Master__c = :app.Branch__c
            AND Product_Branch_Mapping__r.Product_Master__c = :app.Product__c
            AND Customer_Profile__c = :richestApplicant.Customer_Profile__c
            LIMIT 1
        ];

        return rmList.isEmpty() ? null : rmList[0].ROI__c;
    }


    @AuraEnabled
    public static Anchor_Master__c getActiveAnchorMaster() {
        List<Anchor_Master__c> masters = [
            SELECT Id, Anchor_Type__c, Anchor_Rate__c
            FROM Anchor_Master__c
            WHERE Is_Active__c = true
            LIMIT 1
        ];

        return masters.isEmpty() ? null : masters[0];
    }


    @AuraEnabled
    public static Bank_Details__c saveRepaymentDetails(Id recordId,Id applicationId,Map<String, Object> repaymentData) {
        System.debug('*** '+ repaymentData);
        Bank_Details__c bd;
        Decimal revisedRate;

        try {
            // Fetch existing record if recordId is provided
            if (recordId != null) {
                bd = [
                    SELECT Id, Application__c, RecordTypeId
                    FROM Bank_Details__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
            } 
            // Otherwise check if an existing repayment record exists for the application
            else {
                List<Bank_Details__c> existingByApp = [
                    SELECT Id, Application__c, RecordTypeId,RecordType.DeveloperName
                    FROM Bank_Details__c
                    WHERE Application__c = :applicationId
                    AND RecordType.DeveloperName = 'Repayment'
                    LIMIT 1
                ];
                bd = existingByApp.isEmpty()
                    ? new Bank_Details__c(Application__c = applicationId)
                    : existingByApp[0];
            }

            // Always ensure required fields
            bd.Application__c = applicationId;

            if (bd.RecordTypeId == null) {
                bd.RecordTypeId = [
                    SELECT Id
                    FROM RecordType
                    WHERE SObjectType = 'Bank_Details__c'
                    AND DeveloperName = 'Repayment'
                    LIMIT 1
                ].Id;
            }

            //  Apply  data 
            // Get all Bank_Details__c field types
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Bank_Details__c.fields.getMap();
        System.debug('repaymentData '+ repaymentData);

        for (String key : repaymentData.keySet()) {
            if (!fieldMap.containsKey(key)) {
                System.debug('**Skipped invalid field: ' + key);
                continue;
            }
            System.debug('**field: ' + key);
            if(key == 'Anchor_Type__c' || key == 'Anchor_Rate__c'){
                continue;
            }

            Object value = repaymentData.get(key);
            Schema.DisplayType dt = fieldMap.get(key).getDescribe().getType();

            try {
                System.debug('**Test' + dt);
                if (value != null) {
                    if (dt == Schema.DisplayType.Date) {
                        // Convert string to Date
                        bd.put(key, Date.valueOf(String.valueOf(value)));
                    } else if (dt == Schema.DisplayType.DateTime) {
                        // Convert string to Datetime
                        bd.put(key, Datetime.valueOf(String.valueOf(value)));
                    } else if (dt == Schema.DisplayType.Integer) {
                        bd.put(key, Integer.valueOf(String.valueOf(value)));
                    } else if (dt == Schema.DisplayType.Double || dt == Schema.DisplayType.PERCENT) {
                        bd.put(key, Double.valueOf(String.valueOf(value)));
                        if(key == 'Revised_Policy_Rate__c'){
                            revisedRate = Double.valueOf(String.valueOf(value));
                        }
                    } else if (dt == Schema.DisplayType.ID) {
                        System.debug('**Value  '+ value);
                        //bd.put(key, String.valueOf(value));
                    }else {
                        bd.put(key, value);
                    }
                }
            } catch (Exception e) {
                System.debug('Failed to assign field: ' + key + ' value: ' + value + ' due to ' + e.getMessage());
            }
        }
            Anchor_Master__c am = getActiveAnchorMaster();
            if (am != null) {
                bd.Anchor_Master__c = am.Id;
            }
            System.debug('revisedRate '+ revisedRate);

            //  Explicit DML
            if (bd.Id == null) {
                insert bd;
            } else {
                update bd;
            }

            if(revisedRate != null){
                Application__c app = new Application__c(Id = applicationId, Revised_Rate__c = revisedRate);
                UPDATE app;
            }

            return bd;
        } catch (Exception e) {
            System.debug(' Error in saveRepaymentDetails: ' + e.getMessage());
            throw new AuraHandledException('Error saving repayment details: ' + e.getMessage());
        }
    }
}