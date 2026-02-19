public with sharing class SHF_CAMService {

    @AuraEnabled
    public static String generateCAM(Id applicationId) {
        PageReference camPage = Page.SHF_CAMGenerationReport;
        camPage.getParameters().put('id', applicationId);

        Blob pdfBlob = camPage.getContentAsPDF();

        ContentVersion cv = new ContentVersion(
            Title = 'CAM_Report_' + applicationId + '_' + Datetime.now().getTime(),
            PathOnClient = 'CAM_Report.pdf',
            VersionData = pdfBlob
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        return cv.ContentDocumentId; 
    }
}