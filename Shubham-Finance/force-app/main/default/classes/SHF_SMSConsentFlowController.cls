/**
* @File Name : SHF_SMSConsentFlowController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 31, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 31, 2025 |   | Initial Version
**/

public with sharing class SHF_SMSConsentFlowController {

    @AuraEnabled
    public static String sendConsentSMS(Id applicantId) {
        if(applicantId == null) {
            return 'Record Id missing';
        }

        Loan_Applicant__c app = [
            SELECT Id, Mobile_Number__c 
            FROM Loan_Applicant__c 
            WHERE Id = :applicantId 
            LIMIT 1
        ];

        if(String.isBlank(app.Mobile_Number__c)) {
            return 'Mobile Number not found';
        }

        // Prepare message
        String smsText = 'Dear Customer, we have received your consent. Thank you.';

        Message_Service__e msgEvt = new Message_Service__e(
            Receiver__c = app.Mobile_Number__c,
            Message_Template__c = smsText
        );

        Database.SaveResult sr = EventBus.publish(msgEvt);

        if(sr.isSuccess()) {
            return 'SUCCESS';
        } else {
            return 'FAILED';
        }
    }

}