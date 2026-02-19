/**
* @File Name          : SHF_ApfReportController.cls
* @Description        : For APF Report Document generation     VFPage : SHF_APF_Report
* @Author             : Ashutosh Dubey
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       20/01/2026      Ashutosh Dubey       Initial Version
*/

public class SHF_ApfReportController {
    public String verActivityId { get; set; }
    public ApfReportWrapper apfReport {get; set;}
    
    public SHF_ApfReportController(){
        verActivityId = ApexPages.currentPage().getParameters().get('verActivityId');
        System.debug('verActivityId --> '+ verActivityId);
        apfReport = new ApfReportWrapper();
        Id applicationId = ApexPages.currentPage().getParameters().get('id');
        applicationId = 'a03C100000H8AZvIAN';
        if(applicationId != null){
            Application__c application = [SELECT Id, Name FROM Application__c WHERE Id =: applicationId];
            apfReport.application = application;
        }
        System.debug(apfReport.application);
    }
    
    public class ApfReportWrapper {
        public Application__c application {get; set;}
    }
}