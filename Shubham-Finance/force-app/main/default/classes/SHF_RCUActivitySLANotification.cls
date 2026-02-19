/**
* @File Name : SHF_RCUActivitySLANotification.cls
* @Description :  this class is used for sending Bell Notifications to RCU Managers and Vendors.
* @Author :  Anand
* @Last Modified On : Dec 22, 2025
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | Dec 22, 2025 | Anand  | Initial Version
**/

global without sharing class SHF_RCUActivitySLANotification implements Schedulable, Database.Batchable<SObject> {
    
    /*
    * Fetches all RCU verification activities that are not completed
    * and have crossed the defined SLA timeline (created on or before yesterday)
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {        
        return Database.getQueryLocator([
            SELECT 
            Id, Name, OwnerId, Owner.Name, CreatedDate, Vendor_Status__c, Vendor_Type__c,
            Verification__r.OwnerId, Verification__r.Owner.Name, Due_Date__c, Verification__r.Type__c
            FROM Verification_Activity__c
            WHERE Vendor_Status__c != 'Completed'
            AND Due_Date__c < : System.today()
        ]);
    }
    
    // Processes the RCU activity record and sends bell notifications
    // to the assigned vendor and the respective RCU manager
    global void execute(Database.BatchableContext bc, List<Verification_Activity__c> activities) {

        System.debug('activities ==> '+ activities);
        Verification_Activity__c activityRecord = activities.get(0);
        System.debug('activityRecord ==> '+ activityRecord);
        Id vendorId  = activityRecord.OwnerId;
        Id managerId = activityRecord.Verification__r.OwnerId;
        Boolean isExternal = activityRecord.Vendor_Type__c == 'External';
        DateTime dueDate = activityRecord.Due_Date__c;
        String verificationType = activityRecord.Verification__r.Type__c;
        
        String notificationMessageToManager = 'The assigned '+ verificationType +' RCU activity (' + activityRecord.Name +
            ') has not been completed within the defined TAT. Assigned To: [' +
            activityRecord.Owner.Name + '], Due Date : [' + dueDate + '].';
        String notificationMessageToVendor = 'Please complete the activity(' + activityRecord.Name +
            ') assigned to you.';
        if(!isExternal && vendorId == managerId) return;
        SHF_CommonUtil.notifyUsersByNotification(new Set<String>{managerId}, activityRecord.Id, 'RCU Activity Pending', notificationMessageToManager, 'Manager_Notification');
        SHF_CommonUtil.notifyUsersByNotification(new Set<String>{vendorId}, activityRecord.Id, 'RCU Activity Pending', notificationMessageToVendor, 'Vendor_Notification'); 
    }
    
    // Schedules and triggers the RCU SLA notification batch job
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new SHF_RCUActivitySLANotification(), 1);
    }
    
    // Executes after all batch records are processed
    global void finish(Database.BatchableContext bc) {
        System.debug('RCU SLA Notification Batch Finished');
    }    
}