/**
* @File Name          : SHF_LOSCalloutEventTrigger
* @Description        : 
* @Author             : Akshi Sharma
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         16-09-2025              Akshi Sharma
*/
trigger SHF_LOSCalloutEventTrigger on LOS_Callout_Event__e (after insert) {
    SHF_AbstractTriggerContext.run('LOS_Callout_Event__e',
        Trigger.operationType,
        Trigger.new,
        Trigger.old,
        Trigger.newMap,
        Trigger.oldMap
    );
}