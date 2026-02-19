public with sharing class SHF_CaseUpdateController {
    
    @AuraEnabled
    public static void updateCaseWithApplication(
        Id caseId,
        Id applicationId,
        String customerName,
        String customerEmail,
        String contactNumber,
        String dummyApplication,
        Boolean searchCriteriaNotAvailable,
        Id branch
    ) {
        Case c = new Case(Id = caseId);
        
        System.debug('searchCriteriaNotAvailable=' + searchCriteriaNotAvailable);
        System.debug('applicationId=' + applicationId);
        
        /* -------- ALWAYS UPDATE CUSTOMER FIELDS IF PROVIDED -------- */
        
            c.Customer_Name__c = customerName;
            c.Customer_Email__c = customerEmail;
            c.Contact_No_1__c = contactNumber;
       
        if (applicationId != null) {
            c.Application__c = applicationId;
            c.Search_Criteria_Not_Available__c = false;
        }
        
        /* -------- MANUAL FLOW -------- */
        if (searchCriteriaNotAvailable == true) {
            c.Search_Criteria_Not_Available__c = true;
            c.Dummy_Application_Tagging__c = dummyApplication;
            
            if (branch != null) {
                c.Branch__c = branch;
            }
        }
        
        system.debug('Case to Update- '+c);
        update c;
    }
    
    
}