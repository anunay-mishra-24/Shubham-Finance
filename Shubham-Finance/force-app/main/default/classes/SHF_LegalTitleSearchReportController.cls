/**
* @File Name          : SHF_LegalTitleSearchReportController.cls
* @Description        : For Legal Title Search Report Document generation       VFPage : SHF_Legal_Title_Search_Report
* @Author             : Ashutosh Dubey
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       16/01/2026      Ashutosh Dubey       Initial Version
*/

public class SHF_LegalTitleSearchReportController {
    
    public LegalTitleSearchReportWrapper legalTitleSearchReport {get; set;}

    public SHF_LegalTitleSearchReportController(){
        legalTitleSearchReport = new LegalTitleSearchReportWrapper();
        Id applicationId = ApexPages.currentPage().getParameters().get('id');
		applicationId = 'a03C100000H8AZvIAN';        
        if(applicationId != null){
            Application__c application = [SELECT Id, Name, Sanction_Amount__c, Product__r.Name,Sanction_Date__c FROM Application__c WHERE Id =: applicationId];
            legalTitleSearchReport.application = application;
            //legalTitleSearchReport.recieptDate =getFormattedDate(application.Sanction_Date__c);
            
            List<Collateral__c> collaterals = [SELECT Id, Name, Full_Address__c, Application__c, Property_Owner__c FROM Collateral__c WHERE Application__c =: applicationId];
            legalTitleSearchReport.collaterals = collaterals;
            
            List<Loan_Applicant__c> applicants = [SELECT Id, Name, Applicant_Type__c From Loan_Applicant__c WHERE Application__c =: applicationId];
            List<String> coApplicantList = new List<String>();
            if(!applicants.isEmpty()){
                for(Loan_Applicant__c applicant : applicants){
                     if (applicant.Applicant_Type__c == 'Primary Applicant') {
                        legalTitleSearchReport.primaryApplicant = applicant;
                    } else if (applicant.Applicant_Type__c == 'Co-Applicant') {
                        coApplicantList.add(applicant.Name);
                    } else if (applicant.Applicant_Type__c == 'Guarantor') {
                        coApplicantList.add(applicant.Name);
                    }
                }
            }
            legalTitleSearchReport.coApplicants  = coApplicantList.isEmpty() ? 'NONE' :  String.join(coApplicantList, ', ');
            
            List<Collateral_Application__c> collateralApplications = [SELECT Id, Collateral__c FROM Collateral_Application__c WHERE Application__c =: applicationId];
            Set<String> collateralIds = new Set<String>();
            if(!collateralApplications.isEmpty()){
                for(Collateral_Application__c colApp : collateralApplications){
                    collateralIds.add(colApp.Collateral__c);
                }
            }
            
            Set<String> ownerNamesSet = new Set<String>();
            List<Collateral_Seller_Owner__c> owners = [SELECT Id, ownerName__c FROM Collateral_Seller_Owner__c WHERE RecordType.Name = 'Owner' AND Collateral__c IN: collateralIds];
            if(!owners.isEmpty()){
                for(Collateral_Seller_Owner__c owner : owners){
                    ownerNamesSet.add(owner.ownerName__c);
                }
            }
            
            String OwnerNames = ownerNamesSet.isEmpty() ? '' : String.join(new List<String>(ownerNamesSet), ', ');
            legalTitleSearchReport.collateralOwners = OwnerNames;
        }
        System.debug('legalTitleSearchReport --> '+ JSON.serializePretty(legalTitleSearchReport));
    }
    
    public static String getFormattedDate(Date dateValue){
        DateTime dt = DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day());
        return dt.format('MMM d, yyyy');
    }
    
    public class LegalTitleSearchReportWrapper {
        public Application__c application {get; set;}
        public List<Collateral__c> collaterals{get; set;}
        public Loan_Applicant__c primaryApplicant {get; set;}
        public String coApplicants {get; set;}
        //public String gurantors {get; set;}
        public String recieptDate {get; set;}
        public String reportSubmittedDate {get; set;}
        public String collateralOwners {get; set;}
        public String ipAddress {get; set;}
        public LegalTitleSearchReportWrapper(){
            this.ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        }
    }
}