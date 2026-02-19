global with sharing class SHF_DeleteOldContentVersionsBatch implements Schedulable,Database.Batchable<SObject> {
    
    // public Integer retentionDays;
    // global SHF_DeleteOldContentVersionsBatch() {
        //     retentionDays = Integer.valueOf(Label.Maximum_Doc_Storage_Days);
    // }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Integer retentionDays = Integer.valueOf(Label.Maximum_Doc_Storage_Days);
        DateTime cutoffDate = System.now().addDays(-retentionDays);
        
        return Database.getQueryLocator([
            SELECT Id
            FROM ContentDocument
            WHERE LatestPublishedVersion.CreatedDate < :cutoffDate
        ]);
    }
    global void execute(Database.BatchableContext bc,List<ContentDocument> scope) {
        if(scope != null){
            Database.delete(scope,false);
        }
    }
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new SHF_DeleteOldContentVersionsBatch(), 200);
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('Old ContentVersion cleanup batch completed');
    }
}