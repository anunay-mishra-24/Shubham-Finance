/**
* Class Name      : SHF_GenerateKFSDocumentController
* Description     : Loads KFS VF Page Preview and auto creates Document__c record
*/

public with sharing class SHF_GenerateKFSDocumentController {

    /**
     * Returns VF Page Name based on Applicant Language
     */
    @AuraEnabled(cacheable=true)
    public static String getVFPageName(Id applicationId, String language) {

        Map<String, String> vfPages = new Map<String, String>{
            'English'   => 'SHF_KFS_English',
            'Hindi'     => 'SHF_KFS_Hindi',
            'Gujarati'  => 'SHF_KFS_Gujarati',
            'Marathi'   => 'SHF_KFS_Marathi',
            'Punjabi'   => 'SHF_KFS_Punjabi',
            'Tamil'     => 'SHF_KFS_Tamil',
            'Telugu'    => 'SHF_KFS_Telgu'
        };

        return vfPages.containsKey(language)
            ? vfPages.get(language)
            : 'SHF_KFS_English';
    }

    /**
     * Returns Primary Applicant Language
     */
    @AuraEnabled(cacheable=true)
    public static String getPrimaryApplicantLanguage(Id applicationId) {

        if(applicationId == null){
            return 'English';
        }

        List<Loan_Applicant__c> applicants = [
            SELECT Preferred_Language__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            AND Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];

        if (applicants.isEmpty() || applicants[0].Preferred_Language__c == null) {
            return 'English';
        }

        return applicants[0].Preferred_Language__c;
    }

    /**
     * Auto Create Document__c record when popup is opened
     */
    @AuraEnabled
    public static Id createKfsDocumentRecord(Id applicationId) {

        if(applicationId == null){
            throw new AuraHandledException('Application Id is missing');
        }

        String fileName = 'Key Fact Statement';

        // Check if already exists
        List<Document__c> docs = [
            SELECT Id
            FROM Document__c
            WHERE Application__c = :applicationId
            AND File_Name__c = :fileName
            LIMIT 1
        ];

        if (!docs.isEmpty()) {
            return docs[0].Id;
        }

        // Create new Document__c record
        Document__c doc = new Document__c(
            File_Name__c = fileName,
            Stage__c = 'QDE',
            Mandatory_Document__c = true,
            Document_Category__c = 'Others',
            Application__c = applicationId,
            Status__c = 'Not Uploaded',
            Document_Source__c = 'Manual',
            Document_Received_Date__c = Date.today()
        );

        insert doc;

        return doc.Id;
    }
}