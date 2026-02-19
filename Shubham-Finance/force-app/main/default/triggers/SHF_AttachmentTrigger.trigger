/**
* @description       : Attechment Trigger.
* @author            : Riteek Tiwari
* @Created Date      : 08-12-2025
* @Created by        : Riteek Tiwari
**/
trigger SHF_AttachmentTrigger on Attachment (after insert) {
    Logger.info('AttachmentTrigger fired. Trigger size: ' + Trigger.new.size());
    try {
        if (Trigger.isAfter && Trigger.isInsert) {
            Logger.info('Calling AttachmentTriggerHandler.updateCreatedDocumentStatus()');
            SHF_AttachmentTriggerHandler.updateCreatedDocumentStatus(Trigger.New);
        }
    } catch (Exception e) {
        Logger.error('Error in AttachmentTrigger: ' + e.getMessage());
    } finally {
        Logger.saveLog();
    }
}