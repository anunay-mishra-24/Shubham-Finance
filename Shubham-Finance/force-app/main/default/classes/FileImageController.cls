public with sharing class FileImageController {
    public String fileUrl { get; set; }

    public FileImageController() {
        Id contentDocId = '069C1000005quzVIAQ';

        ContentVersion cv = [
            SELECT Id
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocId
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];

        fileUrl = '/sfc/servlet.shepherd/version/download/' + cv.Id;
    }
}