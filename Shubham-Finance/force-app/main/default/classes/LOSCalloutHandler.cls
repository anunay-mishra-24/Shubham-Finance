/**
* @File Name          : LOSCalloutHandler.apex
* @Author             : Akshi Sharma
* @Created On         : 17.09.2025
* @Description        : Handler Class for calling APIs through LOS Callout Event PE.
*================================================================================================
* Ver         Date                     Author                 Modification        Description
*================================================================================================
* 1.0      17.09.2025              Akshi Sharma        Initial Version
**/

public without sharing class LOSCalloutHandler {
    
    @future(callout=true)
    public static void invokeLOSAPIs(String calloutData) {
        try {
            // Deserialize the string into LOS_Callout_Event__e records
            List<LOS_Callout_Event__e> calloutEventList = 
                (List<LOS_Callout_Event__e>) JSON.deserialize(calloutData, List<LOS_Callout_Event__e>.class);
            
            // Collect FI_Callout events
            List<LOS_Callout_Event__e> fiCalloutList = new List<LOS_Callout_Event__e>();
            List<LOS_Callout_Event__e> mnrlCalloutList = new List<LOS_Callout_Event__e>();
            
            for (LOS_Callout_Event__e calloutEvent : calloutEventList) {
                if (calloutEvent.Event_Type__c == 'FI_Callout') {
                    fiCalloutList.add(calloutEvent);
                }else if (calloutEvent.Event_Type__c == 'Mobile_Verification'){
                    mnrlCalloutList.add(calloutEvent);
                }
            }
            
            // FI Callout processing
            if (!fiCalloutList.isEmpty()) {
                for (LOS_Callout_Event__e eventObj : fiCalloutList) {
                    Logger.info('Processing FI Callout event for recordId: ' + eventObj.RecordId__c);
                    // Example callout 
                    // LOSCalloutWapper losCalloutWrap = PNB_LOS_Uconnect_FI.makeCalloutForFINew(
                    //     eventObj.RecordId__c, eventObj.Additional_Attributes__c
                    // );
                }
            }
            
            // MNRL Callout processing
            if (!mnrlCalloutList.isEmpty()) {
                Logger.info('mnrlCalloutList : ' + mnrlCalloutList);
                Logger.info('mnrlCalloutList size : ' + mnrlCalloutList.size());
                fflib_SObjectUnitOfWork everificationUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{E_Verification__c.SObjectType});
                for (LOS_Callout_Event__e eventObj : mnrlCalloutList) {
                    E_Verification__c everificationRecord = SHF_Mobile_MNRL_Service.processMobileVerification(eventObj.Additional_Attributes__c, eventObj.RecordId__c);                   
                    if (everificationRecord != null) {
                        everificationUow.registerDirty(everificationRecord);
                    }
                    Logger.info('Processing MNRL Callout events for recordId: ' + eventObj.RecordId__c + ' | Mobile: ' + eventObj.Additional_Attributes__c);
                }
                everificationUow.commitWork();
            }
            
            
        } catch (Exception ex) {
            // Log error to debug and Nebula Logger
            System.debug('### Exception: ' + ex.getMessage() + ' -- ' + ex.getLineNumber());
            System.debug('### Stacktrace: ' + ex.getStackTraceString());
            
            Logger.error('LOSCalloutHandler failed with exception: ' + ex.getMessage());
            Logger.error('Stack Trace: ' + ex.getStackTraceString());
        } finally {
            Logger.saveLog(); 
        }
    }
    
    public class LOSCalloutWapper {
        public String status { get; set; }
        public String responseBody { get; set; }
    }
}