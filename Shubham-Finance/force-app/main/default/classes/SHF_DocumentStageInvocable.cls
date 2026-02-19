public without sharing class SHF_DocumentStageInvocable {

    @InvocableMethod(
        label='Create Documents on Stage Change'
        description='Creates Document records based on application stage'
    )
    public static void createDocuments(List<SHF_StageBasedInput> inputs) {

        System.debug('[Invocable] createDocuments called');
        System.debug('Inputs size => ' + inputs.size());

        Set<Id> applicationIds = new Set<Id>();
        String stage;

        for (SHF_StageBasedInput input : inputs) {
            System.debug('Input applicationId => ' + input.applicationId);
            System.debug('Input stage => ' + input.stage);

            applicationIds.add(input.applicationId);
            stage = input.stage;
        }

        System.debug('Final applicationIds => ' + applicationIds);
        System.debug('Final stage => ' + stage);

        SHF_DocumentStageInvocable.createDocuments(applicationIds, stage);
    }

    public static void createDocuments(Set<Id> applicationIds, String stage) {

        System.debug(' Entered createDocuments()');
        System.debug('applicationIds => ' + applicationIds);
        System.debug('stage => ' + stage);

        if (String.isBlank(stage) || applicationIds.isEmpty()) {
            System.debug('Exiting: stage is blank OR applicationIds empty');
            return;
        }

        List<Document_Checklist__c> checklistRecords = [
            SELECT Id,
                   Document_Category__c,
                   Document_Type__c,
                   Name,
                   Document_Stage__c,
                   Mandatory_Optional__c
            FROM Document_Checklist__c
            WHERE Document_Stage__c = :stage
              AND Mandatory_Optional__c = 'Mandatory'
        ];

        System.debug('Document_Checklist__c records found => ' + checklistRecords.size());

        if (checklistRecords.isEmpty()) {
            System.debug('No checklist records found for stage => ' + stage);
            return;
        }

        List<Document__c> documentsToInsert = new List<Document__c>();

        for (Id appId : applicationIds) {
            for (Document_Checklist__c chk : checklistRecords) {
                documentsToInsert.add(new Document__c(
                    Application__c = appId,
                    Document_Category__c = chk.Document_Category__c,
                    Document_Type__c = chk.Document_Type__c,
                    File_Name__c = chk.Name,
                    Mandatory_Document__c = true,
                    Stage__c = stage,
                    Status__c = 'Not Uploaded'
                ));
            }
        }

        System.debug('Document__c records to insert => ' + documentsToInsert.size());

        if (!documentsToInsert.isEmpty()) {
            insert documentsToInsert;
            System.debug('Document__c records inserted successfully');
        } else {
            System.debug('No Document__c records created');
        }
    }

    public class SHF_StageBasedInput {

        @InvocableVariable(required=true)
        public Id applicationId;

        @InvocableVariable(required=true)
        public String stage;
    }
}