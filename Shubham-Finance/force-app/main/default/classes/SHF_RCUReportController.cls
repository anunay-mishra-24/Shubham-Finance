/**
* @File Name : SHF_RCUReportController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 23, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 23, 2025 |   | Initial Version
**/

public with sharing class SHF_RCUReportController {
    
    public Verification_Activity__c verificationRec { get; set; }
    
    
    // Header
    public String reportDate { get; set; }
    
    // Basic Details
    public String rcuAgencyName { get; set; }
    public String region { get; set; }
    public String state { get; set; }
    public String branch { get; set; }
    public String applicationNumber { get; set; }
    public String type { get; set; }
    public Decimal loanAmount { get; set; }
    public String product { get; set; }
    public String program { get; set; }
    public String rcuEmployeeName { get; set; }
    public String sourcingOfficerName { get; set; }
    public String sourcingOfficerCode { get; set; }
    public Boolean isInternalUser { get; set; }
    public String displayName { get; set; }
    public String displayCode { get; set; }
    public String displayTimestamp { get; set; }
    public Integer verifiedDocCount { get; set; }
    public Map<String, Integer> rcuStatusCountMap { get; set; }
    public Integer totalDocCount { get; set; }
    public String rcuStatusSummary { get; set; }
    public List<ContentDocument> verificationImages { get; set; }
    
    
    // Applicant Details
    public String primaryApplicant { get; set; }
    public List<String> coApplicants { get; set; }
    public List<Document_Activity__c> documentActivities { get; set; }
    
    
    // Dates
    public Date pickupDate { get; set; }
    public Date reportedDate { get; set; }
    public Decimal tat { get; set; }
    
    // Status
    public String overallStatus { get; set; }
    public String overallRemarks { get; set; }
    
    public SHF_RCUReportController(ApexPages.StandardController stdCtrl) {
        
        verificationRec = (Verification_Activity__c) stdCtrl.getRecord();
        Id recordId = stdCtrl.getId();
        coApplicants = new List<String>();
        verifiedDocCount = 0;
        
        
        reportDate = DateTime.now().format('dd-MM-yyyy');
        verificationRec = [ SELECT Id,Verification__c, Verification__r.Owner.Name,Region__c,State__c, Verification__r.Application__r.Branch__r.Name,Verification__r.Application__r.Name,Type__c,
                           Loan_Amount__c,Verification__r.Application__r.Product__r.Name,Verification__r.Application__r.Product__r.Product_Name__c,Decision__c,Overall_Remarks__c,
                           Sourcing_Officer_Employee_ID__c,Sourcing_Officer_Name__c,Pickup_Date__c,Reported_Date__c,TAT__c,Vendor_Type__c, Owner.Name FROM Verification_Activity__c WHERE Id = :recordId LIMIT 1];
        
        
        Id verificationId = verificationRec.Verification__c;
        Id applicationId = verificationRec.Verification__r != null && verificationRec.Verification__r.Application__r != null ? verificationRec.Verification__r.Application__r.Id : null;
        if (applicationId != null) {
            
            List<Loan_Applicant__c> applicants = [SELECT Applicant_Type__c, Account_Name__c FROM Loan_Applicant__c WHERE Application__c = :applicationId AND IsDeleted__c = FALSE ORDER BY CreatedDate];
            
            for (Loan_Applicant__c la : applicants) {
                
                if (la.Applicant_Type__c != null &&
                    la.Applicant_Type__c.contains('Primary Applicant')) {
                        
                        primaryApplicant = la.Account_Name__c;
                        
                    } else {
                        coApplicants.add(la.Account_Name__c);
                    }
            }
        }       
        
        isInternalUser = (verificationRec.Vendor_Type__c == 'Internal');
        
        if (verificationId != null) {
            documentActivities = [SELECT Id, Verification__r.Type__c, Document__r.Name, Document__r.Pick_up_Criteria__c, Document__r.RCU_Verification_Status__c,Document__r.Acknowledge_Status__c FROM Document_Activity__c WHERE Verification__c = :verificationId ORDER BY CreatedDate];
        }
        
        for (Document_Activity__c docAct : documentActivities) {
            if (docAct.Document__r != null &&
                docAct.Document__r.Acknowledge_Status__c == 'Verified') {
                    verifiedDocCount++;
                }
        }
        
        
        displayTimestamp = DateTime.now().format('dd/MM/yyyy HH:mm');
        
        if (isInternalUser) {
            displayName = rcuEmployeeName;
            displayCode = sourcingOfficerCode;
        } else {
            displayName = rcuAgencyName;
            displayCode = sourcingOfficerCode;
        }
        
        rcuStatusCountMap = new Map<String, Integer>();
        totalDocCount = 0;
        
        if (documentActivities != null) {
            
            totalDocCount = documentActivities.size();
            
            for (Document_Activity__c docAct : documentActivities) {
                
                if (docAct.Document__r == null ||
                    docAct.Document__r.RCU_Verification_Status__c == null) {
                        continue;
                    }
                
                String status = docAct.Document__r.RCU_Verification_Status__c.trim();
                
                if (!rcuStatusCountMap.containsKey(status)) {
                    rcuStatusCountMap.put(status, 1);
                } else {
                    rcuStatusCountMap.put(status, rcuStatusCountMap.get(status) + 1);
                }
            }
        }
        
        List<String> parts = new List<String>();
        
        for (String key : rcuStatusCountMap.keySet()) {
            parts.add(key + ' - ' + rcuStatusCountMap.get(key));
        }
        
        rcuStatusSummary = String.join(parts, ', ') + ', Total - ' + totalDocCount;
        
        
        verificationImages = new List<ContentDocument>();
        
        if (verificationRec != null) {
            List<ContentDocumentLink> docLinks = [
                SELECT ContentDocumentId, ContentDocument.FileType FROM ContentDocumentLink WHERE LinkedEntityId = :verificationRec.Id AND ContentDocument.FileType IN ('PNG','JPG','JPEG') ];
            
            if (!docLinks.isEmpty()) {
                Set<Id> docIds = new Set<Id>();
                for (ContentDocumentLink link : docLinks) {
                    docIds.add(link.ContentDocumentId);
                }
                
                verificationImages = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id IN :docIds ORDER BY CreatedDate];
            }
        }
        
        
        
        
        rcuAgencyName = verificationRec.Verification__r != null && verificationRec.Verification__r.Owner != null ? verificationRec.Owner.Name : '';
        region = verificationRec.Region__c != null ? verificationRec.Region__c : '';
        state = verificationRec.State__c != null ? verificationRec.State__c : '';
        branch = verificationRec.Verification__r != null && verificationRec.Verification__r.Application__r != null && verificationRec.Verification__r.Application__r.Branch__r != null ? verificationRec.Verification__r.Application__r.Branch__r.Name : '';
        applicationNumber = verificationRec.Verification__r != null && verificationRec.Verification__r.Application__r != null ? verificationRec.Verification__r.Application__r.Name : '';
        type = verificationRec.Type__c != null ? verificationRec.Type__c : '';
        loanAmount = verificationRec.Loan_Amount__c;
        product = verificationRec.Verification__r != null && verificationRec.Verification__r.Application__r != null && verificationRec.Verification__r.Application__r.Product__r != null ? verificationRec.Verification__r.Application__r.Product__r.Name : '';
        program = verificationRec.Verification__r != null && verificationRec.Verification__r.Application__r != null && verificationRec.Verification__r.Application__r.Product__r != null ? verificationRec.Verification__r.Application__r.Product__r.Product_Name__c : '';
        rcuEmployeeName = verificationRec.Verification__r != null && verificationRec.Verification__r.Owner != null ? verificationRec.Owner.Name : '';
        sourcingOfficerName = verificationRec.Sourcing_Officer_Name__c != null ? verificationRec.Sourcing_Officer_Name__c : '';
        sourcingOfficerCode = verificationRec.Sourcing_Officer_Employee_ID__c != null ? verificationRec.Sourcing_Officer_Employee_ID__c : '';
        
        pickupDate = verificationRec.Pickup_Date__c ;
        reportedDate = verificationRec.Reported_Date__c;
        tat = verificationRec.TAT__c;        
        overallStatus = verificationRec.Decision__c != null ? verificationRec.Decision__c : '';
        overallRemarks = verificationRec.Overall_Remarks__c != null ? verificationRec.Overall_Remarks__c : '';
    }
}