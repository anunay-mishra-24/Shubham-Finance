/**
* @File Name          : SHF_LegalOpinionController.cls
* @Description        : For Legal Opinion Document generation   VFPage : SHF_Legal_Opinion_Report
* @Author             : Ashutosh Dubey
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       19/01/2026      Ashutosh Dubey       Initial Version
*/

public class SHF_LegalOpinionController {
    
    public LegalOpinionWrapper legalOpinion {get; set;}
    
    public SHF_LegalOpinionController(){
        legalOpinion = new LegalOpinionWrapper();
        Id applicationId = ApexPages.currentPage().getParameters().get('id');
        applicationId = 'a03C100000Kb822IAB';
        legalOpinion.ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP'); 
        
        if(applicationId != null){
            Application__c application = [Select Id, Name, Branch__r.Name, Application_Status__c, Loan_Product__c From Application__c Where Id =: applicationId];
            legalOpinion.application = application;
            List<Loan_Applicant__c> applicants = [SELECT Id, Name, Applicant_Type__c From Loan_Applicant__c WHERE Application__c =: applicationId];
            List<String> coBorrowers = new List<String>();
            if(!applicants.isEmpty()){
                for(Loan_Applicant__c applicant : applicants){
                    if(applicant.Applicant_Type__c == 'Primary Applicant'){
                        legalOpinion.primaryApplicant = applicant;
                    }else{
                        coBorrowers.add(applicant.Name);
                    }
                }
            }
            legalOpinion.coBorrowers = coBorrowers.isEmpty() ? 'NONE' :  String.join(coBorrowers, ', ');

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
            legalOpinion.collateralOwners = OwnerNames;
            
        }
        System.debug('legalOpinion --> '+ JSON.serializePretty(legalOpinion));
    }
    
    public class LegalOpinionWrapper {
        public Application__c application {get; set;}
        public Loan_Applicant__c primaryApplicant {get; set;}
        public String coBorrowers {get; set;}
        public String ipAddress {get; set;}
        public String collateralOwners {get; set;}
        public String submittedDate {get; set;}
    }
}