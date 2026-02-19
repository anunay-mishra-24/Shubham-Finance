/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_VerificationActivityReportSvc
 * Author          : Pankaj Anand
 * Created Date    : Jan 9, 2026
 * Last Modified By: Anunay Kumar
 * Last Modified On: Jan 10, 2026
 * Description     : This class implements for......
 *  
 * Change History  :fixed all the occures in client demo
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 9, 2026  │ Pankaj Anand   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public without sharing class SHF_VerificationActivityReportSvc {

    public class VAData {
        @AuraEnabled public Id id;

       
        @AuraEnabled public String typeValue;
        @AuraEnabled public Date pickupDate;
        @AuraEnabled public Date reportedDate;
        @AuraEnabled public String documentName;
        @AuraEnabled public String pickupCriteriaValue;
        @AuraEnabled public String rcuActivityStatusValue;
        @AuraEnabled public Decimal totalDocsSampled;
        @AuraEnabled public String overallStatusValue;
        @AuraEnabled public String overallRemarksValue;
        @AuraEnabled public Boolean isRcuEditable;

        
        @AuraEnabled public String rcuAgencyName;
        @AuraEnabled public String applicationNo;
        @AuraEnabled public String branchName;
        @AuraEnabled public String state;
        @AuraEnabled public String region;
        @AuraEnabled public String productName;
        @AuraEnabled public String programName;
        @AuraEnabled public String sourcingChannel;
        @AuraEnabled public String sourcingOfficerName;
        @AuraEnabled public String sourcingOfficerEmpId;
        @AuraEnabled public Decimal loanAmount;
        @AuraEnabled public Decimal tat;
        @AuraEnabled public Id applicationId;
    }

    public class VASaveInput {
        @AuraEnabled public Id id;

        @AuraEnabled public String typeValue;
        @AuraEnabled public Date pickupDate;
        @AuraEnabled public Date reportedDate;
        @AuraEnabled public String documentName;
        @AuraEnabled public String pickupCriteriaValue;
        @AuraEnabled public String rcuActivityStatusValue;
        @AuraEnabled public Decimal totalDocsSampled;
        @AuraEnabled public String overallStatusValue;
        @AuraEnabled public String overallRemarksValue;
    }

    
    private static Boolean isExternalUser() {

        User u = [SELECT UserType FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return u.UserType != null && u.UserType != 'Standard';
    }

   
    @AuraEnabled(cacheable=true)
    public static VAData getData(Id recordId) {
        if (recordId == null) throw new AuraHandledException('RecordId is required.');

        if (!Schema.sObjectType.Verification_Activity__c.isAccessible()) {
            throw new AuraHandledException('No access to Verification Activity.');
        }

        Verification_Activity__c va = [
            SELECT Id, OwnerId,
                   Type__c, Pickup_Date__c, Reported_Date__c,
                   Documents_Name__c, Pickup_up_Criteria__c, RCU_Activity_Status__c,
                   Total_Docs_Sampled__c, Overall_Status__c, Overall_Remarks__c,
                   If_RCU_Editable__c,
                   State__c, Region__c, Sourcing_Channel__c, Sourcing_Officer_Name__c,
                   Sourcing_Officer_Employee_ID__c, Loan_Amount__c, TAT__c,

                   Verification__r.Owner.Name,
                   Verification__r.Application__c,
                   Verification__r.Application__r.Name,
                   Verification__r.Application__r.Branch__r.Name,
                   Verification__r.Application__r.Product__r.Name,
                   Verification__r.Application__r.Product__r.Product_Name__c
            FROM Verification_Activity__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        VAData dto = new VAData();
        dto.id = va.Id;

        dto.typeValue = va.Type__c;
        dto.pickupDate = va.Pickup_Date__c;
        dto.reportedDate = va.Reported_Date__c;
        dto.documentName = va.Documents_Name__c;
        dto.pickupCriteriaValue = va.Pickup_up_Criteria__c;
        dto.rcuActivityStatusValue = va.RCU_Activity_Status__c;
        dto.totalDocsSampled = va.Total_Docs_Sampled__c;
        dto.overallStatusValue = va.Overall_Status__c;
        dto.overallRemarksValue = va.Overall_Remarks__c;
        dto.isRcuEditable = va.If_RCU_Editable__c;

        dto.state = va.State__c;
        dto.region = va.Region__c;
        dto.sourcingChannel = va.Sourcing_Channel__c;
        dto.sourcingOfficerName = va.Sourcing_Officer_Name__c;
        dto.sourcingOfficerEmpId = va.Sourcing_Officer_Employee_ID__c;
        dto.loanAmount = va.Loan_Amount__c;
        dto.tat = va.TAT__c;

        dto.rcuAgencyName = va.Verification__r != null ? va.Verification__r.Owner.Name : null;
        dto.applicationId = va.Verification__r != null ? va.Verification__r.Application__c : null;

        dto.applicationNo = va.Verification__r?.Application__r?.Name;
        dto.branchName = va.Verification__r?.Application__r?.Branch__r?.Name;
        dto.productName = va.Verification__r?.Application__r?.Product__r?.Name;
        dto.programName = va.Verification__r?.Application__r?.Product__r?.Product_Name__c;

        return dto;
    }

    @AuraEnabled
    public static void saveData(String payload) {
       System.debug('payload raw => ' + payload);

    if (String.isBlank(payload)) {
        throw new AuraHandledException('Invalid input.');
    }

    VASaveInput input = (VASaveInput) JSON.deserialize(payload, VASaveInput.class);
    System.debug('input JSON => ' + JSON.serializePretty(input));

    if (input == null || input.id == null) {
        throw new AuraHandledException('Invalid input.');
    }

    if (!Schema.sObjectType.Verification_Activity__c.isUpdateable()) {
        throw new AuraHandledException('No update access.');
    }

    Verification_Activity__c existing = [
        SELECT Id, OwnerId, If_RCU_Editable__c
        FROM Verification_Activity__c
        WHERE Id = :input.id
        LIMIT 1
    ];

    Verification_Activity__c upd = new Verification_Activity__c(
        Id = input.id,
        Type__c = input.typeValue,
        Pickup_Date__c = input.pickupDate,
        Reported_Date__c = input.reportedDate,
        Documents_Name__c = input.documentName,
        Pickup_up_Criteria__c = input.pickupCriteriaValue,
        Total_Docs_Sampled__c = input.totalDocsSampled,
        Overall_Status__c = input.overallStatusValue,
        Overall_Remarks__c = input.overallRemarksValue
    );

    if (existing.If_RCU_Editable__c == true) {
        upd.RCU_Activity_Status__c = input.rcuActivityStatusValue;
    }

    update upd;

    }
     public class ApplicantResponse {
        @AuraEnabled public String primaryApplicant;
        @AuraEnabled public List<String> coApplicants;

        public ApplicantResponse() {
            coApplicants = new List<String>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static ApplicantResponse fetchApplicants(Id applicationId) {

        Logger.info('fetchApplicants called with Application Id: ' + applicationId);

        ApplicantResponse response = new ApplicantResponse();

        if (applicationId == null) {
            Logger.info('Application Id is null');
            return response;
        }

        List<Loan_Applicant__c> applicants = [SELECT Name, Applicant_Type__c, Account_Name__c, IsDeleted__c FROM Loan_Applicant__c WHERE Application__c = :applicationId AND IsDeleted__c = FALSE];

        Logger.info('Total Loan Applicants found: ' + applicants.size());

        for (Loan_Applicant__c loanApplicant : applicants) {
            if (loanApplicant.Applicant_Type__c != null &&
                loanApplicant.Applicant_Type__c.contains('Primary Applicant')) {

                response.primaryApplicant = loanApplicant.Account_Name__c;
                Logger.info('Primary Applicant found: ' + response.primaryApplicant);
            } else {
                response.coApplicants.add(loanApplicant.Account_Name__c);
                Logger.info('Co-Applicant added: ' + loanApplicant.Account_Name__c);
            }
        }

        return response;
    }
}