public without sharing class SHF_SpecialConditionStageInvocable {

    @InvocableMethod(
        label='Create Special Conditions on Stage Change'
        description='Creates Special Condition documents based on application stage'
    )
    public static void createSpecialConditions(List<SHF_StageBasedInput> inputs) {

        System.debug('Invocable called. Inputs size => ' + inputs.size());

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

        SHF_SpecialConditionStageInvocable.createConditions(applicationIds, stage);
    }
    
    public static void createConditions(Set<Id> applicationIds, String stage) {

        System.debug('Entered createConditions()');
        System.debug('applicationIds => ' + applicationIds);
        System.debug('stage => ' + stage);

        if (String.isBlank(stage) || applicationIds.isEmpty()) {
            System.debug(' Exiting: stage is blank OR applicationIds empty');
            return;
        }

        List<Sanction_Condition_Master__c> masters = [
            SELECT Id,
                   Query_Sub_Cat__c, Condition_Category__c,
                   Type__c
            FROM Sanction_Condition_Master__c
            WHERE Type__c = 'Pre-Disbursement Document'
        ];

        System.debug('Sanction_Condition_Master__c records found => ' + masters.size());

        if (masters.isEmpty()) {
            System.debug('No master records found for stage => ' + stage);
            return;
        }

        List<Document__c> conditionDocs = new List<Document__c>();

        for (Id appId : applicationIds) {
            for (Sanction_Condition_Master__c scm : masters) {
                String formattedCategory = scm.Condition_Category__c;
                if (formattedCategory != null) {
                    formattedCategory = formattedCategory
                        .replaceAll('\\s*/\\s*', '_')
                        .replaceAll('\\s*-\\s*', '_')
                        .trim();
                }
                conditionDocs.add(new Document__c(
                    Application__c = appId,
                    Type__c = 'Special Condition',
                    Document_Category__c = 'Loan Specific Documents',
                    Sanction_Condition_Master__c = scm.Id,
                    Type_Of_Condition__c = scm.Type__c,
                    File_Name__c = formattedCategory,
                    Condition_Description__c = scm.Query_Sub_Cat__c,
                    Status__c = 'Not Uploaded'
                ));
            }
        }

        System.debug('Document__c records to insert => ' + conditionDocs.size());

        if (!conditionDocs.isEmpty()) {
            insert conditionDocs;
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