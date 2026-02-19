/**
* @File Name          : SHF_NonAPFReportController.cls
* @Description        : For Non APF Report Document generation     VFPage : SHF_Non_APF_Report
* @Author             : Ashutosh Dubey
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       19/01/2026      Ashutosh Dubey       Initial Version
*/


public class SHF_NonAPFReportController {
    
    public NonApfReportWrapper nonApfReport {get; set;}
    
    public SHF_NonAPFReportController(){
        nonApfReport = new NonApfReportWrapper();
        Id applicationId = ApexPages.currentPage().getParameters().get('id');
        applicationId = 'a03C100000H8AZvIAN';
        if(applicationId != null){
            Application__c application = [SELECT Id, Name, Branch__r.Name, Loan_Product__c FROM Application__c WHERE Id =: applicationId];
            nonApfReport.application = application;
            List<Loan_Applicant__c> applicants = [SELECT Id, Salutation__c, Name, Applicant_Type__c From Loan_Applicant__c WHERE Application__c =: applicationId];
            if (!applicants.isEmpty()) {
                for (Loan_Applicant__c applicant : applicants) {
                    if (applicant.Applicant_Type__c == 'Primary Applicant') {
                        nonApfReport.primaryApplicant = applicant;
                    }
                }
            }
        }
    }
    
    public class NonApfReportWrapper {
        public Application__c application {get; set;}
        public Loan_Applicant__c primaryApplicant {get; set;}
    }
}