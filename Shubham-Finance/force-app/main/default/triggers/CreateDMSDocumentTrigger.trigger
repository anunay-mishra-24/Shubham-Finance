/**
* @File Name          : CreateDMSDocumentTrigger.cls
* @Description        : 
* @Author             : Akshi Sharma
* @Test Class         : 
*==============================================================================
* Ver         Date         Author     Modification
*==============================================================================
* 1.0         03-06-2025   Akshi     Initial Version
*/
trigger CreateDMSDocumentTrigger on Create_DMS_Document__e (after insert) {
    SHF_AbstractTriggerContext.run('Create_DMS_Document__e',
        Trigger.operationType,
        Trigger.new,
        Trigger.old,
        Trigger.newMap,
        Trigger.oldMap
    );
}