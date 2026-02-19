/**
* @File Name     : SHF_LeadCrifScoreBatch.cls
* @Description   : Batch Apex to send Lead report (Lead Id, Name, CRIF Score) when CRIF score is null and created today.
* @Author        : Riteek Tiwari
* ============================================================================== 
* Ver   Date          Author        Modification
* 1.0   04-09-2025    Riteek        Initial batch version
*/
global class SHF_LeadCrifScoreBatch implements Database.Batchable<SObject>, Schedulable {

    // Start method: query Leads where CRIF Score is null and Created Today
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([ SELECT Id, Name, Crif_Score__c, CreatedDate FROM Lead__c WHERE Crif_Score__c = NULL AND CreatedDate = TODAY]);
    }

    // Execute method: process each batch of leads
    global void execute(Database.BatchableContext BC, List<Lead__c> scope) {
        List<String> toRecipients = new List<String>();

        try {
            if (!scope.isEmpty()) {
                String header = 'Id, Name, CRIF Score, CreatedDate\n';
                String csvContent = header;

                for (Lead__c lead : scope) {
                    csvContent += '"' + lead.Id + '","' + lead.Name + '","' + '' + '","' + lead.CreatedDate.format() + '"\n';
                }
                Logger.info('CSV content prepared with ' + scope.size() + ' records.');

                String toStr = System.Label.Lead_Crif_Report_To_Emails;
                Logger.info('toStr@ ' + toStr);
                if (!String.isBlank(toStr)) {
                    toRecipients = toStr.split(',');

                // Create email
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toRecipients);
                
                email.setSubject('Lead CRIF Score Report - ' + Date.today().format());
                email.setHtmlBody(
                    'Hello,<br/><br/>Please find attached Lead report for records created today with missing CRIF Score.<br/><br/>Thank You.<br/>Team Shubham Finance'
                );

                // From address from Org-Wide Email
                OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];
                if (owea != null) {
                    email.setOrgWideEmailAddressId(owea.Id);
                }

                // Create attachment
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Lead_Crif_Score_Report.csv');
                attachment.setBody(Blob.valueOf(csvContent));
                attachment.setContentType('text/csv');
                email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });

                // Send email
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
                Logger.info('Lead CRIF Score Report email sent successfully to: ' + String.join(toRecipients, ', '));
            }
            } else {
                Logger.info('No Lead__c records found with CRIF Score null and created today.');
            }
        } catch (Exception ex) {
            Logger.error('Error in execute method of batch: ' + ex.getLineNumber() + ' Error: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }
    }

    // Finish method: log completion
    global void finish(Database.BatchableContext BC) {
        system.debug('SHF_LeadCrifScoreBatch completed.');
    }

    // Optional: Schedulable interface to run daily
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SHF_LeadCrifScoreBatch(), 200);
    }
}