/**
 * @File Name          : MessageServiceTrigger
 * @Description        : 
 * @Author             : Akshi Sharma
 * ==============================================================================
 * Ver         Date         Author       Modification
 * ==============================================================================
 * 1.0         21-08-2025   Akshi Sharma  Initial Version
 */
trigger MessageServiceTrigger on Message_Service__e (after insert) {  
    SHF_AbstractTriggerContext.run('Message_Service__e',
        Trigger.operationType,
        Trigger.new,
        Trigger.old,
        Trigger.newMap,
        Trigger.oldMap
    );

}