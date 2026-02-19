public without sharing class SHF_TATCalculator {

    @InvocableMethod(label='Calculate TAT Targets' description='Calculates TAT Target Dates for given Application records')
    public static void calculateTargets(List<Id> appIds) {
        if (appIds.isEmpty()) return;

        List<Application__c> apps = [SELECT Id, RecordType.DeveloperName, Stage_Entry_Time__c FROM Application__c WHERE Id IN :appIds];
        
        Map<String, TAT_Configuration__mdt> configMap = new Map<String, TAT_Configuration__mdt>();
        for(TAT_Configuration__mdt md : [SELECT DeveloperName, L2_Threshold_Hours__c, L3_Threshold_Hours__c, L4_Threshold_Hours__c FROM TAT_Configuration__mdt]) {
            configMap.put(md.DeveloperName, md);
        }

        BusinessHours defaultBH = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        Id bhId = defaultBH.Id;

        List<Application__c> updates = new List<Application__c>();

        for (Application__c app : apps) {
            Datetime startDate = (app.Stage_Entry_Time__c != null) ? app.Stage_Entry_Time__c : System.now();

            if (configMap.containsKey(app.RecordType.DeveloperName)) {
                TAT_Configuration__mdt config = configMap.get(app.RecordType.DeveloperName);

                Long l2Millis = (Long)(config.L2_Threshold_Hours__c * 60 * 60 * 1000);
                Long l3Millis = (Long)(config.L3_Threshold_Hours__c * 60 * 60 * 1000);
                Long l4Millis = (Long)(config.L4_Threshold_Hours__c * 60 * 60 * 1000);

                app.L2_Target_Date__c = BusinessHours.addGmt(bhId, startDate, l2Millis);
                app.L3_Target_Date__c = BusinessHours.addGmt(bhId, startDate, l3Millis);
                app.L4_Target_Date__c = BusinessHours.addGmt(bhId, startDate, l4Millis);
                
                updates.add(app);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
}