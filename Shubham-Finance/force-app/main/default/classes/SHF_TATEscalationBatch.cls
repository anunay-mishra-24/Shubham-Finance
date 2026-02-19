public class SHF_TATEscalationBatch implements Database.Batchable<sObject>, Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SHF_TATEscalationBatch(), 50);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, OwnerId, Owner.Name, RecordType.DeveloperName, Application_Stage__c,
                   L2_Target_Date__c, L3_Target_Date__c, L4_Target_Date__c,
                   L2_Escalation_Time__c, L3_Escalation_Time__c, 
                   L4_Escalation_Time__c, Last_Repeating_Alert_Time__c
            FROM Application__c 
            WHERE RecordType.DeveloperName != 'Closed'
            AND (L2_Target_Date__c != null OR L4_Escalation_Time__c != null)
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Application__c> scope) {
        Datetime nowTime = System.now();
        List<Application__c> updates = new List<Application__c>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        Map<String, Notification_Template__mdt> templateMap = Notification_Template__mdt.getAll();
        Notification_Template__mdt template = templateMap.get('Application_Escalation_Notification');

        Set<Id> ownerIds = new Set<Id>();
        for(Application__c app : scope) ownerIds.add(app.OwnerId);
        
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Name, Email, ManagerId, 
                   Manager.Id, Manager.Name, Manager.Email, 
                   Manager.ManagerId, Manager.Manager.Name, Manager.Manager.Email, 
                   Manager.Manager.ManagerId, Manager.Manager.Manager.Name, Manager.Manager.Manager.Email
            FROM User WHERE Id IN :ownerIds
        ]);
        
        Map<String, Decimal> repeatingConfig = new Map<String, Decimal>();
        for(TAT_Configuration__mdt md : [SELECT DeveloperName, Repeating_Interval_Hours__c FROM TAT_Configuration__mdt]) {
            repeatingConfig.put(md.DeveloperName, md.Repeating_Interval_Hours__c);
        }
        
        BusinessHours defaultBH = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        for(Application__c app : scope) {
            User l1 = userMap.get(app.OwnerId);
            if(l1 == null) continue;
            Boolean isUpdated = false;

            if (app.L2_Target_Date__c <= nowTime && app.L2_Escalation_Time__c == null) {
                if (l1.ManagerId != null) {
                    sendEscalation(app, l1.Manager.Id, l1.Manager.Email, l1.Manager.Name, template, emails, 'L2');
                    app.L2_Escalation_Time__c = nowTime;
                    isUpdated = true;
                }
            }

            if (app.L3_Target_Date__c <= nowTime && app.L3_Escalation_Time__c == null) {
                if (l1.Manager.ManagerId != null) {
                    sendEscalation(app, l1.Manager.ManagerId, l1.Manager.Manager.Email, l1.Manager.Manager.Name, template, emails, 'L3');
                    app.L3_Escalation_Time__c = nowTime;
                    isUpdated = true;
                }
            }

            if (app.L4_Target_Date__c <= nowTime && app.L4_Escalation_Time__c == null) {
                if (l1.Manager.Manager.ManagerId != null) {
                    sendEscalation(app, l1.Manager.Manager.ManagerId, l1.Manager.Manager.Manager.Email, l1.Manager.Manager.Manager.Name, template, emails, 'L4');
                    app.L4_Escalation_Time__c = nowTime;
                    app.Last_Repeating_Alert_Time__c = nowTime; 
                    isUpdated = true;
                }
            }

            if (app.L4_Escalation_Time__c != null && repeatingConfig.containsKey(app.RecordType.DeveloperName)) {
                Decimal interval = repeatingConfig.get(app.RecordType.DeveloperName);
                if(interval != null && interval > 0) {
                    Long diffMillis = BusinessHours.diff(defaultBH.Id, app.Last_Repeating_Alert_Time__c, nowTime);
                    Double diffHours = diffMillis / (1000.0 * 60 * 60);

                    if (diffHours >= interval) {
                        if (l1.Manager.ManagerId != null) { 
                            sendEscalation(app, l1.Manager.ManagerId, l1.Manager.Manager.Email, l1.Manager.Manager.Name, template, emails, 'Repeating');
                            app.Last_Repeating_Alert_Time__c = nowTime;
                            isUpdated = true;
                        }
                    }
                }
            }

            if(isUpdated) updates.add(app);
        }

        if(!emails.isEmpty()) Messaging.sendEmail(emails, false);
        if(!updates.isEmpty()) update updates;
    }

    public void finish(Database.BatchableContext bc) {}

    private void sendEscalation(Application__c app, Id targetUserId, String targetEmail, String targetName, Notification_Template__mdt template, List<Messaging.SingleEmailMessage> emails, String level) {
        
        if (template == null) return;

        String appStage = (app.Application_Stage__c != null) ? app.Application_Stage__c : '';
        String ownerName = (app.Owner.Name != null) ? app.Owner.Name : '';

        if (String.isNotBlank(template.Bell_Notification__c)) {
            String bellBody = template.Bell_Notification__c
                .replace('<recipientName>', targetName)
                .replace('<ApplicationName>', app.Name)
                .replace('<OwnerName>', ownerName)
                .replace('<ApplicantionStage>', appStage);

            SHF_CommonUtil.notifyUsersByNotification(
                new Set<String>{ targetUserId },
                app.Id,
                'Application Escalation Reminder (' + level + ')', 
                bellBody,
                System.Label.Send_Notification_To_User 
            );
        }

        if (String.isNotBlank(targetEmail) && String.isNotBlank(template.Email_Template__c)) {
            String emailBody = template.Email_Template__c
                .replace('<recipientName>', targetName)
                .replace('<ApplicationName>', app.Name)
                .replace('<OwnerName>', ownerName)
                .replace('<ApplicantionStage>', appStage);

            emails.addAll(SHF_CommonUtil.notifyUsersByEmailHTMLApplication(
                new List<String>{ targetEmail },
                emailBody,
                'Application Escalation - ' + level,
                'Shubham Housing Finance' // Display Name
            ));
        }
    }
}