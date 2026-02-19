/*
* @File Name       : SHF_InsuranceAPIService.cls
* @Author          : Preeti
* @Created Date    : Sept 19, 2025
* @Description     : This class handles integration with Insurance APIs (Kotak and ICICI) for 
*                    Loan Applicants. It fetches relevant Loan Applicant and Application records,
*                    validates mandatory fields, determines the appropriate insurer, 
*                    performs HTTP callouts, and returns the API response.
* @Last Modified By: Preeti
* @Last Modified On: Sept 19, 2025
* @Modification Log:
*==============================================================================
* Ver | Date       | Author | Modification
*==============================================================================
* 1.0 | 19-sept-25  | Preeti | Initial Version
*/

public with sharing class SHF_InsuranceAPIService {
    
    @AuraEnabled
    public static String callInsuranceAPI(Id applicantId) {
        Map<String,Object> result = new Map<String,Object>();
        
        try {
            // Fetch Loan Applicant
            Loan_Applicant__c loanApplicant = (new SHF_LoanApplicantsSelector()).selectInsuranceApplicant(applicantId);
            if (loanApplicant == null) {
                result.put('status', 'error');
                result.put('message', 'Loan Applicant not found');
                System.debug('Loan Applicant not found for Id: ' + applicantId);
                return JSON.serialize(result);
            }
            
            // Fetch Application
            Application__c application = (new SHF_ApplicationSelector()).selectApplicationForInsurance(loanApplicant.Application__c);
            if (application == null) {
                result.put('status', 'error');
                result.put('message', 'Application not found');
                System.debug('Application not found for Applicant Id: ' + applicantId);
                return JSON.serialize(result);
            }
            
            // Check missing fields
            Boolean isKotak = shouldCallKotak(application);
            List<String> missingFields = getMissingMandatoryFields(loanApplicant, application, isKotak);
            if (!missingFields.isEmpty()) {
                result.put('status', 'error');
                result.put('missingFields', missingFields);
                System.debug('Missing fields for Applicant Id ' + applicantId + ': ' + missingFields);
                return JSON.serialize(result);
            }
            
            // Decide which API to call
            if (isKotak) {
                //String response = SHF_KotakInsuranceAPI.callKotakService(loanApplicant.Insurance_Verification__c, application, loanApplicant, insuranceData);
                result.put('status', 'kotakInputRequired');
                result.put('response', 'Kotak input required');
                result.put('applicantId', applicantId);
                System.debug('Kotak API called successfully for Applicant Id: ' + applicantId);
            } else {
                result.put('status', 'hold');
                result.put('message', 'ICICI input required');
                result.put('applicantId', applicantId);
                System.debug('ICICI API requires input for Applicant Id: ' + applicantId);
            }
            
            return JSON.serialize(result);
            
        } catch (Exception e) {
            result.put('status', 'error');
            result.put('message', e.getMessage());
            System.debug('Error in callInsuranceAPI: ' + e.getMessage());
            return JSON.serialize(result);
        }
    }
    
    // Helper method to check for missing mandatory fields
    public static List<String> getMissingMandatoryFields(Loan_Applicant__c loanApplicant, Application__c application, Boolean isKotak) {
        List<String> missing = new List<String>();
        
        // Common fields
        if (String.isBlank(loanApplicant.Gender__c)) missing.add('Gender');
        if (loanApplicant.Date_of_Birth__c == null) missing.add('Date of Birth');
        if (application.Applied_Loan_Amount__c == null) missing.add('Applied Loan Amount');
        if (application.Tenure__c == null) missing.add('Tenure');
        
        // ICICI-specific fields
        if (!isKotak) {
            if (String.isBlank(loanApplicant.First_Name__c)) missing.add('First Name');
            if (String.isBlank(loanApplicant.Last_Name__c)) missing.add('Last Name');
        }
        
        // Kotak-specific fields
        if (isKotak) {
            if (application.Loan_Disbursement_Date__c == null) missing.add('Loan Disbursement Date');
            if (application.Product__r == null || String.isBlank(application.Product__r.Product_Type__c)) missing.add('Product Type');
            if (application.Branch__r == null || application.Branch__r.City__r == null ||
                application.Branch__r.City__r.State_Master__r == null ||
                String.isBlank(application.Branch__r.City__r.State_Master__r.State_Code__c)) missing.add('State Code');
        }
        
        return missing;
    }
@AuraEnabled
public static String callICICIInsuranceAPI(Id eVerificationId, Id applicantId, String insuranceJson) {
    Map<String, Object> insuranceData = (Map<String, Object>) JSON.deserializeUntyped(insuranceJson);
    Map<String,Object> result = new Map<String,Object>();
    try {
        // Fetch Loan Applicant
        Loan_Applicant__c loanApplicant = (new SHF_LoanApplicantsSelector()).selectInsuranceApplicant(applicantId);
        if (loanApplicant == null) {
            result.put('status','error');
            result.put('message','Loan Applicant not found');
            System.debug('Loan Applicant not found for Id: ' + applicantId);
            return JSON.serialize(result);
        }

        // Fetch Application
        Application__c application = (new SHF_ApplicationSelector()).selectApplicationForInsurance(loanApplicant.Application__c);
        if (application == null) {
            result.put('status','error');
            result.put('message','Application not found');
            System.debug('Application not found for Applicant Id: ' + applicantId);
            return JSON.serialize(result);
        }

        // Validate Insurance_Verification__c
        if (eVerificationId == null) {
            result.put('status','error');
            result.put('message','Insurance Verification Id is missing');
            System.debug('Insurance_Verification__c missing for Applicant Id: ' + applicantId);
            return JSON.serialize(result);
        }

        // Call ICICI service
        String response = SHF_ICICIInsuranceAPI.callICICIService(
            eVerificationId,
            application,
            loanApplicant,
            insuranceData
        );
        result.put('status','success');
        result.put('response', response);
        System.debug('ICICI API called successfully for Applicant Id: ' + applicantId);
        return JSON.serialize(result);

    } catch (Exception e) {
        result.put('status','error');
        result.put('message', e.getMessage());
        System.debug('Error in callICICIInsuranceAPI: ' + e.getMessage());
        return JSON.serialize(result);
    }
}


    @AuraEnabled
    public static String callKotakInsuranceAPI(Id eVerificationId, Id applicantId, String insuranceJson) {
        Map<String, Object> insuranceData = (Map<String, Object>) JSON.deserializeUntyped(insuranceJson);
        Map<String,Object> result = new Map<String,Object>();
        try {
            // Fetch Loan Applicant
            Loan_Applicant__c loanApplicant = (new SHF_LoanApplicantsSelector()).selectInsuranceApplicant(applicantId);
            if (loanApplicant == null) {
                result.put('status','error');
                result.put('message','Loan Applicant not found');
                System.debug('Loan Applicant not found for Id: ' + applicantId);
                return JSON.serialize(result);
            }

            // Fetch Application
            Application__c application = (new SHF_ApplicationSelector()).selectApplicationForInsurance(loanApplicant.Application__c);
            if (application == null) {
                result.put('status','error');
                result.put('message','Application not found');
                System.debug('Application not found for Applicant Id: ' + applicantId);
                return JSON.serialize(result);
            }

            // Validate Insurance_Verification__c
            if (eVerificationId == null) {
                result.put('status','error');
                result.put('message','Insurance Verification Id is missing');
                System.debug('Insurance_Verification__c missing for Applicant Id: ' + applicantId);
                return JSON.serialize(result);
            }

            // Call ICICI service
            String response = SHF_KotakInsuranceAPI.callKotakService(
                eVerificationId,
                application,
                loanApplicant,
                insuranceData
            );
            result.put('status','success');
            result.put('response', response);
            System.debug('ICICI API called successfully for Applicant Id: ' + applicantId);
            return JSON.serialize(result);

        } catch (Exception e) {
            result.put('status','error');
            result.put('message', e.getMessage());
            System.debug('Error in callKotakInsuranceAPI: ' + e.getMessage());
            return JSON.serialize(result);
        }
    }

    // Helper method to decide Kotak or ICICI
    private static Boolean shouldCallKotak(Application__c application) {
        if (application == null || application.Branch__r == null || application.Branch__r.City__r == null || application.Branch__r.City__r.State_Master__r == null) {
            return false;
        }
        String zone = application.Branch__r.City__r.State_Master__r.Zone__c;
        String region = application.Branch__r.City__r.State_Master__r.Region__c;
        
        return (zone != null && zone.equalsIgnoreCase('South')) || (region != null && region.toLowerCase().contains('south'));
    }

    /*@AuraEnabled(cacheable=true)
    public static Application__c getApplicationDetails(Id applicationId) {
        if (applicationId == null) return null;

        SHF_ApplicationSelector selector = new SHF_ApplicationSelector();
        return selector.selectApplicationForInsuranceModal(applicationId);
    }*/

    @AuraEnabled(cacheable=true)
    public static Loan_Applicant__c getApplicantDetails(Id applicantId) {
        if (applicantId == null) return null;

        SHF_LoanApplicantsSelector selector = new SHF_LoanApplicantsSelector();
        return selector.selectApplicantForInsuranceModal(applicantId);
    }


@AuraEnabled(cacheable=true)
public static List<Loan_Applicant__c> getChildApplicants(Id applicationId, Id excludeApplicantId) {
    if (applicationId == null) return new List<Loan_Applicant__c>();

    return [
        SELECT Id, Name, Gender__c, Date_of_Birth__c, Applicant_Age__c, Insurance_Verification__c
        FROM Loan_Applicant__c
        WHERE Application__c = :applicationId
        AND Id != :excludeApplicantId
        AND IsDeleted__c = false
    ];
}




    @AuraEnabled(cacheable=true)
    public static E_Verification__c getEVerificationById(Id eVerificationId) {
       if (eVerificationId == null) {
        throw new AuraHandledException('E-Verification Id is missing.');
       }
       List<E_Verification__c> records =  [SELECT Id, Funded__c, Life_Insured__c, Loan_Type__c, Outstanding_Loan_Amount__c, 
                                            Outstanding_Loan_Tenure__c, LDD__c,  Cover__c, Benefit_Option__c,  Joint_Life_Option__c, 
                                            Date_Of_Birth_of_Older_Borrower__c, Date_Of_Birth_of_Younger_Borrower__c, 
                                            Date_Of_Cover_Of_Commencement__c, Sanctioned_Loan_Amount__c, Flat_Tenure_In_Years__c, 
                                            Reducing_Tenure_In_Years__c, Loan_Tenure_In_Years__c, Does_Premium_Have_To_Be_Funding__c, 
                                            Age_Of_Younger_Borrower__c, UnderWriting_Status_Of_Younger_Borrower__c, 
                                            Younger_Borrower_s_Premium__c, Sum_Assured_Death__c, Sum_Assured_ADB__c,
                                            Sum_Assured_ACI__c, Coverage_Term_Death__c, Coverage_Term_ACI__c,
                                            Coverage_Term_ADB__c, Plan_Code__c
                                            FROM E_Verification__c WHERE Id = :eVerificationId LIMIT 1 ];
       if (eVerificationId == null) {
        throw new AuraHandledException('E-Verification Id is missing.');
    }
    return records[0];

    }

    @AuraEnabled
    public static Id updateEVerification(E_Verification__c inputRecord,Id applicantId,Id oldEVId,List<E_Verification_Line_Item__c> nominees) {
        if (inputRecord == null) {
            throw new AuraHandledException('Invalid E-Verification data.');
        }
        
        Loan_Applicant__c loanApplicant = [
            SELECT Id, Application__c, Application__r.Applied_Loan_Amount__c 
            FROM Loan_Applicant__c WHERE Id = : applicantId LIMIT 1];
            
        RecordType insuranceRT = [
            SELECT Id FROM RecordType
            WHERE DeveloperName = 'Insurance'
            AND SObjectType = 'E_Verification__c'
            LIMIT 1
        ];

        inputRecord.LDD__c = Date.today().addDays(120);
        inputRecord.RecordTypeId = insuranceRT.Id;
        inputRecord.Loan_Applicant__c = applicantId;
        inputRecord.Status__c = 'Initiated';
        inputRecord.Type_Of_Insurance__c = 'Life Insurance';
        inputRecord.Insured_Amount__c = loanApplicant.Application__r.Applied_Loan_Amount__c;

        try {
            insert inputRecord;

            /* ---------------- Applicant Linking ---------------- */
            List<Loan_Applicant__c> applicantsToUpdate = new List<Loan_Applicant__c>{
                new Loan_Applicant__c(
                    Id = applicantId,
                    Insurance_Verification__c = inputRecord.Id
                )
            };

            if (inputRecord.Loan_Applicant_2__c != null) {
                applicantsToUpdate.add(
                    new Loan_Applicant__c(
                        Id = inputRecord.Loan_Applicant_2__c,
                        Insurance_Verification__c = inputRecord.Id
                    )
                );
            }

            if (oldEVId != null) {
                E_Verification__c oldEV = [
                    SELECT Loan_Applicant_2__c
                    FROM E_Verification__c
                    WHERE Id = :oldEVId
                    LIMIT 1
                ];

                if (oldEV.Loan_Applicant_2__c != null &&
                    oldEV.Loan_Applicant_2__c != inputRecord.Loan_Applicant_2__c) {

                    applicantsToUpdate.add(
                        new Loan_Applicant__c(
                            Id = oldEV.Loan_Applicant_2__c,
                            Insurance_Verification__c = null
                        )
                    );
                }
            }

            update applicantsToUpdate;

            /* ---------------- NOMINEE HANDLING ---------------- */

            RecordType nomineeRT = [
                SELECT Id FROM RecordType
                WHERE DeveloperName = 'Insurance_Nominee'
                AND SObjectType = 'E_Verification_Line_Item__c'
                LIMIT 1
            ];

            // Existing nominees
            Map<Id, E_Verification_Line_Item__c> existingNominees = new Map<Id, E_Verification_Line_Item__c>(
                [
                    SELECT Id
                    FROM E_Verification_Line_Item__c
                    WHERE E_Verification__c = :inputRecord.Id
                ]
            );

            List<E_Verification_Line_Item__c> nomineesToUpsert = new List<E_Verification_Line_Item__c>();
            Set<Id> incomingIds = new Set<Id>();

            Integer seq = 1;

            for (E_Verification_Line_Item__c n : nominees) {
                n.E_Verification__c = inputRecord.Id;
                n.RecordTypeId = nomineeRT.Id;
                n.Sequence__c = seq++;
                nomineesToUpsert.add(n);

                if (n.Id != null) {
                    incomingIds.add(n.Id);
                }
            }

            // Delete removed nominees
            List<E_Verification_Line_Item__c> toDelete = new List<E_Verification_Line_Item__c>();
            for (Id existingId : existingNominees.keySet()) {
                if (!incomingIds.contains(existingId)) {
                    toDelete.add(existingNominees.get(existingId));
                }
            }

            if (!toDelete.isEmpty()) delete toDelete;
            if (!nomineesToUpsert.isEmpty()) upsert nomineesToUpsert;

        } catch (Exception ex) {
            throw new AuraHandledException(
                'Failed to update Insurance Verification: ' + ex.getMessage()
            );
        }

        return inputRecord.Id;
    }


    @AuraEnabled(cacheable=true)
    public static List<InsurancePlanWrapper> getKotakPlans() {
        List<InsurancePlanWrapper> result = new List<InsurancePlanWrapper>();

        for (Insurance_Master__mdt m :
            [SELECT Plan_Code__c, Minimum_Sum_Assured__c, Maximum_Sum_Assured__c,
                    Minimum_Tenure__c, Maximum_Tenure__c,
                    Minimum_Age__c, Maximum_Age__c, Cease_Age__c
            FROM Insurance_Master__mdt
            WHERE Insurance_Type__c = 'Kotak Life Insurance']) {

            InsurancePlanWrapper w = new InsurancePlanWrapper();
            w.planCode = m.Plan_Code__c;
            w.minSum = m.Minimum_Sum_Assured__c;
            w.maxSum = m.Maximum_Sum_Assured__c;
            w.minTenure = Integer.valueOf(m.Minimum_Tenure__c);
            w.maxTenure = Integer.valueOf(m.Maximum_Tenure__c);
            w.minAge = Integer.valueOf(m.Minimum_Age__c);
            w.maxAge = Integer.valueOf(m.Maximum_Age__c);
            w.ceaseAge = Integer.valueOf(m.Cease_Age__c);
            result.add(w);
        }
        return result;
    }

    @AuraEnabled
    public static List<E_Verification_Line_Item__c> getInsuranceNominees(Id eVerificationId) {
        return [
            SELECT Id, Sequence__c,
                Nominee_Name__c, Nominee_Relationship__c,
                Nominee_Date_of_Birth__c, Nominee_Gender__c,
                Is_Minor__c,
                Appointee_Name__c, Appointee_Relationship__c, Appointee_DOB__c,
                Percentage_of_Entitlement__c,
                Nominee_Address__c
            FROM E_Verification_Line_Item__c
            WHERE E_Verification__c = :eVerificationId
            AND RecordType.DeveloperName = 'Insurance_Nominee'
            ORDER BY Sequence__c
        ];
    }


    public class InsurancePlanWrapper {
        @AuraEnabled public String planCode;
        @AuraEnabled public Decimal minSum;
        @AuraEnabled public Decimal maxSum;
        @AuraEnabled public Integer minTenure;
        @AuraEnabled public Integer maxTenure;
        @AuraEnabled public Integer minAge;
        @AuraEnabled public Integer maxAge;
        @AuraEnabled public Integer ceaseAge;
    }

}