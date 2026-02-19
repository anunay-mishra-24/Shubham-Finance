public class SHF_BureauAnalysisReportController {
    
    public BureauAnalysisReportWrapper bureauReport {get; set;}
    
    public SHF_BureauAnalysisReportController(){
        bureauReport = new BureauAnalysisReportWrapper();
        Id applicationId = ApexPages.currentPage().getParameters().get('id');
        applicationId = 'a03C100000H8AZvIAN';
        if(applicationId != null){
            Application__c application = [SELECT Id, Name FROM Application__c WHERE Id =: applicationId];
            bureauReport.application = application;
            List<Loan_Applicant__c> applicants = [SELECT Id, Name, Applicant_Type__c From Loan_Applicant__c WHERE Application__c =: applicationId];
            if (!applicants.isEmpty()) {
                for (Loan_Applicant__c applicant : applicants) {
                    if (applicant.Applicant_Type__c == 'Primary Applicant') {
                        bureauReport.primaryApplicant = applicant;
                    }
                }
            }
        }
    }
    
    public class BureauAnalysisReportWrapper {
        public Application__c application {get; set;}
        public Loan_Applicant__c primaryApplicant {get; set;}
    }
}