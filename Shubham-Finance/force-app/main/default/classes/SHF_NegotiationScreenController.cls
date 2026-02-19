/**
 * @File Name          : SHF_NegotiationScreenController.cls
 * @Description        : Show the required fields into Data table for Under Writer decision Screen.
 * @Author             : Anunay Kumar
 * @Created Date        : 2026-01-19
 * @Last Modified Date  : 2026-01-19
 *
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0         2026-01-19           Anunay Kumar         Initial Version
 * 1.1         2026-01-19           Author Name         Change details
 */



public without sharing class SHF_NegotiationScreenController {


    public class InsuranceRowDTO {
        @AuraEnabled public Id loanApplicantId;
        @AuraEnabled public String applicantName;
        @AuraEnabled public Id insuranceVerificationId; 

        @AuraEnabled public String insuranceProvider;


        @AuraEnabled public Decimal actualInsuredAmount;       
        @AuraEnabled public Decimal actualInsurancePremium;    
        @AuraEnabled public Decimal actualInsuranceTenure;     


        @AuraEnabled public Decimal requestedInsuredAmount;     
        @AuraEnabled public Decimal requestedInsurancePremium;  
        @AuraEnabled public Decimal requestedInsuranceTenure;   

         @AuraEnabled public Decimal originalInsuredAmount;
        @AuraEnabled public Decimal originalInsurancePremium;
        @AuraEnabled public Decimal originalInsuranceTenure;
    }

    public class ScreenDTO {

        @AuraEnabled public Decimal actualSanctionAmount; 
        @AuraEnabled public Decimal actualTenure;         
        @AuraEnabled public Decimal actualRoi;
        @AuraEnabled public Decimal actualProcessingFee;
        @AuraEnabled public Decimal actualProcessingFeePercent;          
        @AuraEnabled public Boolean canEdit;

        @AuraEnabled public Decimal requestedSanctionAmount; 
        @AuraEnabled public Decimal requestedTenure;        
        @AuraEnabled public Decimal requestedRoi; 
        @AuraEnabled public Decimal requestedProcessingFee;
        @AuraEnabled public Decimal requestedProcessingFeePercent;

        @AuraEnabled public Decimal originalSanctionAmount;
        @AuraEnabled public Decimal originalTenure;
        @AuraEnabled public Decimal originalRoi;
        @AuraEnabled public Decimal originalProcessingFee;
        @AuraEnabled public Decimal originalProcessingFeePercent;
         
        @AuraEnabled public String cboApprovalStatus;
        @AuraEnabled public String reSanctionStatus;
        @AuraEnabled public String applicationStage;


        @AuraEnabled public List<InsuranceRowDTO> insuranceRows;
          @AuraEnabled public List<CollateralRowDTO> collateralRows;
        @AuraEnabled public Boolean hasAnyRequestedValue;
    }
    public class CollateralRowDTO {
    @AuraEnabled public Id collateralId;
    @AuraEnabled public String collateralName;
    @AuraEnabled public Decimal marketValue;
    @AuraEnabled public Decimal ltv;
    @AuraEnabled public String propertyAddress;
    @AuraEnabled public Decimal agreementValue;
}


    public class InsuranceSaveItem {
        @AuraEnabled public Id insuranceVerificationId;
        @AuraEnabled public Map<String, String> requestedUpdates; 
        @AuraEnabled public Map<String, String> reasonUpdates;    
    }

    public class SavePayload {
        @AuraEnabled public Id applicationId;
        @AuraEnabled public Map<String, String> applicationRequestedUpdates; 
        @AuraEnabled public Map<String, String> applicationReasonUpdates;   
        @AuraEnabled public List<InsuranceSaveItem> insuranceUpdates;
    }


    @AuraEnabled
    public static ScreenDTO loadScreen(Id applicationId) {
        System.System.debug('--- loadScreen called for applicationId: ' + applicationId);
        if (applicationId == null) return null;

        ScreenDTO dto = new ScreenDTO();
        dto.insuranceRows = new List<InsuranceRowDTO>();
        dto.collateralRows = new List<CollateralRowDTO>();
        Application__c app = [
            SELECT Id,
            Sanction_Amount__c, Tenure__c, Revised_Rate__c,Application_Stage__c,
            Processing_Fee__c, Processing_Fee_Percent__c,
            Negotiate_Sanctioned_Loan_Amount__c, Negotiate_Tenure__c,
            Negotiation_Rate_of_Interest_ROI__c,
            Negotiation_Processing_Fee__c, Negotiation_Processing_Fee_Percent__c,
            Original_Sanction_Loan_Amount__c, Original_Tenure__c, Original_ROI__c,
            Original_Processing_Fee__c, Original_Processing_Fee_Percent__c,
            Re_Sanction_Status__c, CBO_Approval_Status__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        dto.actualSanctionAmount = app.Sanction_Amount__c;
        dto.actualTenure         = app.Tenure__c;
        dto.actualRoi            = app.Revised_Rate__c;
        dto.actualProcessingFee = app.Processing_Fee__c;
        dto.actualProcessingFeePercent = app.Processing_Fee_Percent__c;

        dto.requestedSanctionAmount = app.Negotiate_Sanctioned_Loan_Amount__c;
        dto.requestedTenure         = app.Negotiate_Tenure__c;
        dto.requestedRoi            = app.Negotiation_Rate_of_Interest_ROI__c;
        dto.requestedProcessingFee = app.Negotiation_Processing_Fee__c;
        dto.requestedProcessingFeePercent = app.Negotiation_Processing_Fee_Percent__c;

        dto.originalSanctionAmount = app.Original_Sanction_Loan_Amount__c;
        dto.originalTenure         = app.Original_Tenure__c;
        dto.originalRoi            = app.Original_ROI__c;
        dto.originalProcessingFee = app.Original_Processing_Fee__c;
        dto.originalProcessingFeePercent = app.Original_Processing_Fee_Percent__c;

        dto.cboApprovalStatus = app.CBO_Approval_Status__c;
        dto.reSanctionStatus  = app.Re_Sanction_Status__c;
        dto.applicationStage = app.Application_Stage__c;
         List<Collateral_Application__c> colls = [
        SELECT Id, Collateral__r.Name, Market_Value__c, LTV__c, Collateral_Address__c,Agreement_Value_INR__c
        FROM Collateral_Application__c
        WHERE Application__c = :applicationId and Collateral__r.Property_Identification__c = 'Yes' and isActive__c=True
        ORDER BY CreatedDate ASC
    ];
     for (Collateral_Application__c c : colls) {
        CollateralRowDTO cr = new CollateralRowDTO();
        cr.collateralId = c.Id;
        cr.collateralName = c.collateral__r.Name; 
        cr.marketValue = c.Market_Value__c;
        cr.ltv = c.LTV__c;
        cr.propertyAddress = c.Collateral_Address__c;
        cr.agreementValue = c.Agreement_Value_INR__c;
        dto.collateralRows.add(cr);
    }

        List<Loan_Applicant__c> applicants = [
            SELECT Id, Name, Insurance_Verification__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId AND IsDeleted__c = False 
            AND Customer_Type__c ='Individual'
            ORDER BY CreatedDate ASC
        ];

        Set<Id> insIds = new Set<Id>();
        for (Loan_Applicant__c la : applicants) {
            if (la.Insurance_Verification__c != null) insIds.add(la.Insurance_Verification__c);
        }

        Map<Id, E_Verification__c> insById = new Map<Id, E_Verification__c>();
        if (!insIds.isEmpty()) {
            insById = new Map<Id, E_Verification__c>([
                SELECT Id,
                       Insurance_Provider__c,
                       Insured_Amount__c,
                       Premium_Amount__c,
                       Loan_Tenure_In_Years__c,
                       Outstanding_Loan_Tenure__c,
                       Negotiation_Insured_Amount__c,
                       Negotiation_Insurance_Premium__c,
                       Negotiation_Insurance_Tenure__c,
                       Original_Insured_Amount__c,
                       Original_Insurance_Premium__c,
                       Original_Insurance_Tenure__c
                FROM E_Verification__c
                WHERE Id IN :insIds
            ]);
        }

        for (Loan_Applicant__c la : applicants) {
            InsuranceRowDTO row = new InsuranceRowDTO();
            row.loanApplicantId = la.Id;
            row.applicantName = la.Name;
            row.insuranceVerificationId = la.Insurance_Verification__c;

            if (la.Insurance_Verification__c != null && insById.containsKey(la.Insurance_Verification__c)) {
                E_Verification__c ins = insById.get(la.Insurance_Verification__c);

                row.insuranceProvider = ins.Insurance_Provider__c;

                row.actualInsuredAmount = ins.Insured_Amount__c;
                row.actualInsurancePremium = ins.Premium_Amount__c;
                row.originalInsuredAmount       = ins.Original_Insured_Amount__c;
                row.originalInsurancePremium    = ins.Original_Insurance_Premium__c;
                row.originalInsuranceTenure     = ins.Original_Insurance_Tenure__c;
                if (ins.Insurance_Provider__c == 'Kotak Life Insurance') {
                    row.actualInsuranceTenure = ins.Loan_Tenure_In_Years__c;
                } else if (ins.Insurance_Provider__c == 'ICICI Life Insurance') {
                    row.actualInsuranceTenure = ins.Outstanding_Loan_Tenure__c;
                } else {
                    row.actualInsuranceTenure = null;
                }

                row.requestedInsuredAmount = ins.Negotiation_Insured_Amount__c;
                row.requestedInsurancePremium = ins.Negotiation_Insurance_Premium__c;
                row.requestedInsuranceTenure = ins.Negotiation_Insurance_Tenure__c;
            }

            dto.insuranceRows.add(row);
        }

        dto.hasAnyRequestedValue = hasAnyRequested(dto);
        dto.canEdit = canCurrentUserEdit();
        return dto;
    }

    private static Boolean canCurrentUserEdit() {
    User usecrObj = [
        SELECT Id, Profile.Name, UserRole.Name, Profile.PermissionsModifyAllData
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];



    if (usecrObj.Profile.Name == 'System Administrator') return true;

   
    String roleName = (usecrObj.UserRole != null) ? usecrObj.UserRole.Name : '';
    if (!String.isBlank(roleName) && roleName.toLowerCase().contains('branch manager')) return true;

    return false;
}

private static void enforceCanEdit() {
    if (!canCurrentUserEdit()) {
        throw new AuraHandledException('You do not have permission to edit. Only Branch Manager role or Admin can edit.');
    }
}

    @AuraEnabled
    public static String saveNegotiationDraft(String payloadSave) {
       
        try {
            enforceCanEdit();
             SavePayload payload = (SavePayload) JSON.deserialize(payloadSave, SavePayload.class);
            if (payload == null || payload.applicationId == null) return 'error> Application Id is missing.';
            

            if (payload.applicationRequestedUpdates != null || payload.applicationReasonUpdates != null) {
                Application__c appUpd = new Application__c(Id = payload.applicationId);

                if (payload.applicationRequestedUpdates != null) {
                    for (String api : payload.applicationRequestedUpdates.keySet()) {
                        String v = payload.applicationRequestedUpdates.get(api);
                        setDecimalField(appUpd, api, v, true);

                        if (api == 'Negotiation_Rate_of_Interest_ROI__c') validatePercent(v, 'Negotiation ROI');
                    }
                }
                if (payload.applicationReasonUpdates != null) {
                    for (String api : payload.applicationReasonUpdates.keySet()) {
                        appUpd.put(api, payload.applicationReasonUpdates.get(api));
                    }
                }

                update appUpd;
            }


            if (payload.insuranceUpdates != null && !payload.insuranceUpdates.isEmpty()) {
               Map<Id, E_Verification__c> updMap = new Map<Id, E_Verification__c>();

                for (InsuranceSaveItem item : payload.insuranceUpdates) {
                    if (item == null || item.insuranceVerificationId == null) continue;
                    Id insId = item.insuranceVerificationId;

                    E_Verification__c insUpd = updMap.get(insId);
                    if (insUpd == null) {
                        insUpd = new E_Verification__c(Id = insId);
                        updMap.put(insId, insUpd);
                    }
                    if (item.requestedUpdates != null) {
                        for (String api : item.requestedUpdates.keySet()) {
                            String v = item.requestedUpdates.get(api);
                            setDecimalField(insUpd, api, v, true);
                        }
                    }
                    if (item.reasonUpdates != null) {
                        for (String api : item.reasonUpdates.keySet()) {
                            insUpd.put(api, item.reasonUpdates.get(api));
                        }
                 }

                    
                }

                if (!updMap.isEmpty()) {
                    update updMap.values();
                }
            }

            return 'Success';
        } catch (Exception ex) {
            return 'error> ' + ex.getMessage() + ' Line:- ' + ex.getLineNumber();
        }
    }


    @AuraEnabled
    public static void resetRequestedValues(Id applicationId) {
        if (applicationId == null) return;
        enforceCanEdit();
        update new Application__c(
            Id = applicationId,
            Negotiate_Sanctioned_Loan_Amount__c = null,
            Negotiate_Tenure__c = null,
            Negotiation_Rate_of_Interest_ROI__c = null,
            Negotiation_Processing_Fee__c = null,
            Negotiation_Processing_Fee_Percent__c = null
        );

        List<Loan_Applicant__c> applicants = [
            SELECT Id, Insurance_Verification__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
              AND Insurance_Verification__c != null
        ];

        Set<Id> insIds = new Set<Id>();
        for (Loan_Applicant__c la : applicants) insIds.add(la.Insurance_Verification__c);

        if (!insIds.isEmpty()) {
            List<E_Verification__c> insUpd = new List<E_Verification__c>();
            for (Id insId : insIds) {
                insUpd.add(new E_Verification__c(
                    Id = insId,
                    Negotiation_Insured_Amount__c = null,
                    Negotiation_Insurance_Premium__c = null,
                    Negotiation_Insurance_Tenure__c = null
                ));
            }
            update insUpd;
        }
    }


    private static Boolean hasAnyRequested(ScreenDTO dto) {
        if (dto == null) return false;
        if (dto.requestedSanctionAmount != null) return true;
        if (dto.requestedTenure != null) return true;
        if (dto.requestedRoi != null) return true;
        if (dto.requestedProcessingFee != null) return true;
        if (dto.requestedProcessingFeePercent != null) return true;

        if (dto.insuranceRows != null) {
            for (InsuranceRowDTO r : dto.insuranceRows) {
                if (r == null) continue;
                if (r.requestedInsuredAmount != null) return true;
                if (r.requestedInsurancePremium != null) return true;
                if (r.requestedInsuranceTenure != null) return true;
            }
        }
        return false;
    }

    private static void validatePercent(String v, String label) {
        if (String.isBlank(v)) return;
        Decimal d = Decimal.valueOf(v);
        if (d <= 0) throw new AuraHandledException(label + ' must be greater than 0.');
        if (d > 100) throw new AuraHandledException(label + ' must be less than or equal to 100.');
    }

    private static void setDecimalField(SObject sobj, String apiName, String v, Boolean disallowZeroOrNegative) {
        if (String.isBlank(apiName)) return;

        if (String.isBlank(v)) {
            sobj.put(apiName, null);
            return;
        }

        Decimal d = Decimal.valueOf(v);
        if (disallowZeroOrNegative && d <= 0) {
            throw new AuraHandledException(apiName + ' must be greater than 0.');
        }
        sobj.put(apiName, d);
    }
}