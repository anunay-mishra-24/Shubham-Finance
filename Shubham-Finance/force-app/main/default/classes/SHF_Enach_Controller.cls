public with sharing class SHF_Enach_Controller {
    
    @AuraEnabled(cacheable=true)
    public static List<E_Nach__c> getEnachRecords(Id applicationId) {
        return [ SELECT Id, Name, Status__c FROM E_Nach__c WHERE Loan_Application__c = :applicationId ORDER BY CreatedDate DESC];
    }

    @AuraEnabled
    public static E_Nach__c createOrRetryEnach(Id applicationId) {

        if (applicationId == null) {
            throw new AuraHandledException('Application Id is required');
        }

        List<E_Nach__c> existingList = [
            SELECT Id, Enach_Process_Count__c, Status__c
            FROM E_Nach__c
            WHERE Loan_Application__c = :applicationId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        E_Nach__c enach;

        if (!existingList.isEmpty()) {
            enach = existingList[0];

            if (enach.Enach_Process_Count__c >= 3) {
                throw new AuraHandledException(
                    'E-Nach has already been triggered 3 times. Please go to Document tab.'
                );
            }

            enach.Enach_Process_Count__c += 1;
            enach.Last_Triggered_On__c = System.now();
            enach.Status__c = 'Pending';

            update enach;

        } else {
            system.debug('enach===>Inserting');
            enach = new E_Nach__c(
                Loan_Application__c = applicationId,
                Status__c = 'Pending',
                Enach_Process_Count__c = 1,
                Last_Triggered_On__c = System.now()
            );

            insert enach;
        }

        return enach;
    }
    
    @AuraEnabled
    public static void sendEnachLinkToCustomer(String applicationId) {
        List<Loan_Applicant__c> primaryApplicants = [ SELECT Id, Name, Mobile_Number__c FROM Loan_Applicant__c WHERE Application__c = :applicationId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        String applicantName = primaryApplicants[0].Name;
        String mobileNumber = primaryApplicants[0].Mobile_Number__c;
        Map<String, String> templateData = SHF_CommonUtil.getNotificationTemplate('Public_Site_Upload_Document_SMS');
            if (templateData == null) {
              throw new AuraHandledException('Notification template not found');
            }
            String smsTemplate = SHF_CommonUtil.formatSMSTemplate(templateData.get('SMS_Notification'));
            String urlLabelValue = System.Label.E_Nach_Form_Link;
            String url = urlLabelValue + applicationId;
            
            String finalMessage = smsTemplate.replace('<var1>', applicantName)
                                             .replace('<var2>', url);
            Message_Service__e evt = new Message_Service__e();
            evt.Receiver__c = mobileNumber;
            evt.Message_Template__c = finalMessage;
            EventBus.publish(evt);
    }
}