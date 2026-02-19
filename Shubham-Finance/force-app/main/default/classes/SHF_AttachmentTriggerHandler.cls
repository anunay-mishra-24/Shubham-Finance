/**
* @description       : When an attachment is uploaded related to a Document__c record,the document’s Status__c field is updated to "Uploaded".
* @author            : Riteek Tiwari
* @Created Date      : 08-12-2025
* @Created by        : Riteek Tiwari
**/
public class SHF_AttachmentTriggerHandler {

    public static void updateCreatedDocumentStatus(List<Attachment> newList){
        Logger.info('Entered updateCreatedDocumentStatus');
        Set<Id> documentIds = new Set<Id>();
        List<SObject> updateSObjectList = new List<SObject>();

        try {
            Logger.info('Total Attachments Received: ' + newList.size());

            for (Attachment att : newList) {
                Logger.info('Processing Attachment Id: ' + att.Id);

                if (att.ParentId != null && att.ParentId.getSObjectType() == Document__c.SObjectType) {
                    Logger.info('Valid Document Parent Found: ' + att.ParentId);
                    documentIds.add(att.ParentId);
                } else {
                    Logger.info('Skipping Attachment - Parent Not Document__c: ' + att.Id);
                }
            }

            Logger.info('Collected Document Ids: ' + documentIds);

            if (documentIds.isEmpty()) {
                Logger.info('No Document__c records found to update. Exiting.');
                return;
            }

            // Fetch Documents & Update Status__c
            for (Document__c doc : [SELECT Id, Status__c FROM Document__c WHERE Id IN :documentIds]) {
                Logger.info('Updating Document__c Id: ' + doc.Id);

                Document__c dcObj = doc;
                dcObj.Status__c = 'Uploaded';
                updateSObjectList.add(dcObj);
            }

            Logger.info('Total Documents to Update: ' + updateSObjectList.size());
            Logger.info('Records Prepared for Update: ' + updateSObjectList);

            if (!updateSObjectList.isEmpty()) {
                update updateSObjectList; 
                Logger.info('Document status updated successfully.');
            }

        } catch (Exception e) {
            Logger.error('Exception in updateCreatedDocumentStatus: ' + e.getMessage());
        } finally {
            Logger.saveLog(); 
        }
    }
}