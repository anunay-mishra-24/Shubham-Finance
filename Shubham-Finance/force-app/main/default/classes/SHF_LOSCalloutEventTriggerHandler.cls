/**
* @File Name          : SHF_LOSCalloutEventTriggerHandler.cls
* @Description        : Handler Class of LOS Callout Event Platform Event Trigger
* @Author             : Akshi Sharma
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         16-09-2025              Akshi Sharma
*/
public without sharing class SHF_LOSCalloutEventTriggerHandler extends SHF_AbstractTriggerContext {
    public override void afterInsert(List<sObject> newList, List<sObject> oldList, Map<Id, sObject> newMap, Map<Id, sObject> oldMap) {
        //override for after insert logic
        LOSCalloutHandler.invokeLOSAPIs(JSON.serialize(newList));
    }
    
    public override void beforeInsert(List<sObject> newList, List<sObject> oldList, Map<Id, sObject> newMap, Map<Id, sObject> oldMap){
		//override for before insert logic 
	}
    
    public override void beforeUpdate(List<sObject> newList, List<sObject> oldList, Map<Id, sObject> newMap, Map<Id, sObject> oldMap){
    	//override for before update logic
    }
    
    //public override void afterUpdate(List<sObject> newList, List<sObject> oldList, Map<Id, sObject> newMap, Map<Id, sObject> oldMap){
        //override for after update logic 
    //}
}