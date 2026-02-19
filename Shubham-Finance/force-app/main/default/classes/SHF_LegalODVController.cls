/**
* @File Name          : SHF_LegalODVController.cls
* @Description        : For Legal ODV Document generation   VFPage : SHF_Legal_ODV_Report
* @Author             : Ashutosh Dubey
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       19/01/2026      Ashutosh Dubey       Initial Version
*/

public class SHF_LegalODVController {
    
    public LegalODVWrapper legalODV {get; set;}
    
    public SHF_LegalODVController(){
        legalODV = new LegalODVWrapper();
        Id applicationId = ApexPages.currentPage().getParameters().get('id');
        applicationId = 'a03C100000H8AZvIAN';
        legalODV.ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP'); 
        
        if(applicationId != null){
            Application__c application = [Select Id, Name, Branch__r.Name, Application_Status__c From Application__c Where Id =: applicationId];
            legalODV.application = application;
            List<Loan_Applicant__c> applicants = [SELECT Id, Name, Applicant_Type__c From Loan_Applicant__c WHERE Application__c =: applicationId];
           // List<String> applicantNameList = new List<String>();
            if(!applicants.isEmpty()){
                for(Loan_Applicant__c applicant : applicants){
                     if (applicant.Applicant_Type__c == 'Primary Applicant') {
                        legalODV.primaryApplicant = applicant;
                    }
                }
            }
           // legalODV.applicantNames = applicantNameList.isEmpty() ? 'NONE' :  String.join(applicantNameList, ', ');
        }
        System.debug('legalODV --> '+ JSON.serializePretty(legalODV));
    }
    
        public static String getFormattedDate(Date dateValue){
        DateTime dt = DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day());
        return dt.format('MMM d, yyyy');
    }
    
    public class LegalODVWrapper {
        public Application__c application {get; set;}
        public Loan_Applicant__c primaryApplicant {get; set;}
        public String applicantNames {get; set;}
        public String ipAddress {get; set;}
    }
}