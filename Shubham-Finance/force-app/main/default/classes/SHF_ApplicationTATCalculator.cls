public with sharing class SHF_ApplicationTATCalculator {

    @InvocableMethod(
        label='Calculate Application Escalations'
        description='Calculates L2, L3, L4 escalation dates for Application__c'
    )
    public static void calculateEscalations(List<Application__c> applications) {

        if (applications == null || applications.isEmpty()) {
            return;
        }

        try {
            fflib_SObjectUnitOfWork uow =
                new fflib_SObjectUnitOfWork(new List<SObjectType>{ Application__c.SObjectType });

            // Business Hours Map 
            Map<String, Id> bhMap = new Map<String, Id>();
            for (BusinessHours bh : [
                SELECT Id, Name
                FROM BusinessHours
                WHERE IsActive = true
            ]) {
                bhMap.put(bh.Name.toLowerCase(), bh.Id);
            }
          System.debug('Business Hrs'+ bhMap);
           
            for (Application__c app : applications) {

                if (app.Id == null || app.LastModifiedDate == null) {
                    continue;
                }

               
                String bhName = 'SHDFC Noida Business Hours';
                String bhKey  = bhName.toLowerCase();

                if (!bhMap.containsKey(bhKey)) {
                    continue;
                }

                Id bhId = bhMap.get(bhKey);
                DateTime startDate = app.LastModifiedDate;

               
                app.L2_Escalation__c = BusinessHours.addGmt(
                    bhId,
                    startDate,
                    Integer.valueOf(Label.Application_L2_Escalation_Milliseconds)
                );

                app.L3_Escalation__c = BusinessHours.addGmt(
                    bhId,
                    startDate,
                    Integer.valueOf(Label.Application_L3_Escalation_Milliseconds)
                );

                app.L4_Escalation__c = BusinessHours.addGmt(
                    bhId,
                    startDate,
                    Integer.valueOf(Label.Application_L4_Escalation_Milliseconds)
                );
               System.debug('Application Record'+app.Id);
                uow.registerDirty(app);
            }

            uow.commitWork();

        } catch (Exception e) {
            Logger.error('Error in Application Escalation Calculation: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }
}