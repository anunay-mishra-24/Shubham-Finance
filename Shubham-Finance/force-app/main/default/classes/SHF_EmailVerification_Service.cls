/**
* @File Name          : SHF_EmailVerification_Service.cls
* @Description        : Service class to verify Email details and create E-Verification records.
* @Author             : Riteek Tiwari
* 
*==============================================================================
* Ver         Date              Author              Modification
*==============================================================================
* 1.0         31-10-2025        Riteek Tiwari       Initial Version
*/
public class SHF_EmailVerification_Service {
    
    public static String initiateEmailVerification(Id applicantId) {
        Savepoint sp;
        String message = '';
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('EMAIL_VERIFICATION');
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{E_Verification__c.SObjectType});
            fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Loan_Applicant__c.SObjectType});
            
            List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{applicantId});
            Map<String, Notification_Template__mdt> templateMap = Notification_Template__mdt.getAll();
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            if (loanAppList.isEmpty()) {
                Logger.error('Loan Applicant not found for Id: ' + applicantId);
                message = MessageConfigMap.get('Email_Verification_Applicant_Error').Message__c;
                return message;
            }
            
            
            Loan_Applicant__c applicant = loanAppList[0];
            
            if (String.isBlank(applicant.Email__c)) {
                Logger.error('Email not found for Id: ' + applicantId);
                message = MessageConfigMap.get('Email_Verification_Email_Error').Message__c;
                return message;
            }
            
            E_Verification__c eVerification = SHF_CommonUtil.createVerfication(applicantId, SHF_ConstantsUtil.EMAIL_VERIFICATION_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS);
            eVerification.Status__c = 'In Progress';
            eVerification.Sent_To__c = '';
            uow.registerNew(eVerification);
            uow.commitWork();
            
            applicant.Email_Verification__c = eVerification.Id;
            applicantUow.registerDirty(applicant);
            applicantUow.commitWork();
            
            if (templateMap != null && templateMap.containsKey(SHF_ConstantsUtil.EMAIL_VERIFICATION_TEMPLATE)) {
                //String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
                //String eVerificationLink = baseUrl + '/lightning/r/E_Verification__c/' + eVerification.Id + '/view';
              //  String baseUrl = URL.getOrgDomainUrl().toExternalForm();
               // String eVerificationLink = baseUrl + '/apex/EmailVerificationPage?id=' + eVerification.Id;
                
                String siteBaseUrl = 'https://shubham--dev.sandbox.my.salesforce-sites.com';
                String eVerificationLink = siteBaseUrl + '/EmailVerificationPage?id=' + eVerification.Id;
                
                
                // Send escalation email
                logger.info( 'Template : '+templateMap.get(SHF_ConstantsUtil.EMAIL_VERIFICATION_TEMPLATE).Email_Template__c);
                String recipientName = applicant.Customer_Type__c == 'Individual' ? applicant.First_Name__c : applicant.Entity_Name__c; // Added by vikas on  18/11/25 for parul 
                emails.addAll(SHF_CommonUtil.notifyUsersByEmailHTML(new List<String>{ applicant.Email__c },
                                                                templateMap.get(SHF_ConstantsUtil.EMAIL_VERIFICATION_TEMPLATE).Email_Template__c
                                                                .replace('<recipientName>', recipientName)
                                                                .replace(
                                                                    '<EVerificationLink>',
                                                                    '<a href="' + eVerificationLink + '" style="font-weight:bold; color:#1a73e8; text-decoration:none;">Click here to verify your email</a>'
                                                                ),
                                                                'Email Verification To' + ' - ' + recipientName,
                                                                SHF_ConstantsUtil.CASE_DISPLAY_NAME
                                                               ));               
            }
            Logger.info('emails.size(): ' + emails.size());
            
            // Send email notifications
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
                Logger.info('Sent escalation Lead emails'+ new Map<String,Object>{ 'Count' => emails.size() });
            }
            message = MessageConfigMap.get('Email_Verification_Success').Message__c;
            Logger.info('Email Verification initiated for: ' + applicant.Email__c);
            // Logger.info('Verification URL: ' + verificationUrl);
            
        } catch (Exception ex) {
            if (sp != null) Database.rollback(sp);
            Logger.error('Email Verification Error: ' + ex.getMessage());
            message = 'Email verification failed: ' + ex.getMessage();
        } finally {
            Logger.saveLog();
        }
        return message;
    }
    
}