/**
 * @File Name          : MessageServiceTriggerHandler.cls
 * @Description        : 
 * @Author             : Akshi Sharma
 * ==============================================================================
 * Ver         Date         Author       Modification
 * ==============================================================================
 * 1.0         21-08-2025   Akshi Sharma  Initial Version
 */
global class MessageServiceTriggerHandler extends SHF_AbstractTriggerContext {

    global override void afterInsert(
        List<sObject> newList,
        List<sObject> oldList,
        Map<Id, sObject> newMap,
        Map<Id, sObject> oldMap
    ) {
        List<Message_Service__e> newEvents = (List<Message_Service__e>) newList;

        for (Message_Service__e evt : newEvents) {
            if (String.isNotBlank(evt.Message_Template__c) && String.isNotBlank(evt.Receiver__c)) {
                if (String.isNotBlank(evt.WhatsApp_Placeholders__c)) {
                    // WhatsApp
                    SHF_Message_Service_Future.sendWhatsApp(
                        evt.Receiver__c,
                        evt.Message_Template__c,
                        evt.WhatsApp_Placeholders__c
                    );
                } else {
                    // SMS
                    SHF_Message_Service_Future.sendSMS(
                        evt.Receiver__c,
                        evt.Message_Template__c
                    );
                }
            }
        }
    }
}