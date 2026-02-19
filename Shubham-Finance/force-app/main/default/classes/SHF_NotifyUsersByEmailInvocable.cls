public with sharing class SHF_NotifyUsersByEmailInvocable {

    /**
     * @Description : Invocable method to prepare and send email notifications without setTargetObjectId.
     * @Author      : Kunal Soni
     * @Date        : 09/07/2025
     */
    @InvocableMethod(label='Notify Users by Email' description='Prepares and sends email notifications to users using an Email Template.')
    public static void notifyUsersByEmailInvocable(List<EmailRequest> requests) {
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();

        for (EmailRequest req : requests) {
            if (req.recipients == null || req.recipients.isEmpty() || String.isBlank(req.emailTemplateId))
                continue;

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            
            // Render template without target object
            Messaging.SingleEmailMessage renderResult = Messaging.renderStoredEmailTemplate(
                req.emailTemplateId,
                null,
                req.whatId
            );

            message.setToAddresses(req.recipients);
            message.setSubject(renderResult.getSubject());
            
            // Set HTML or PlainText Body
            if (renderResult.getHtmlBody() == null)
                message.setPlainTextBody(renderResult.getPlainTextBody());
            else
                message.setHtmlBody(renderResult.getHtmlBody());
            
            // Set Org-Wide Email Address
            OrgWideEmailAddress orgWide = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
            message.setOrgWideEmailAddressId(orgWide.Id);
            message.setSaveAsActivity(true);
          //  message.setLogEmailOnSend(true);
            allEmails.add(message);
        }

        if (!allEmails.isEmpty()) {
            Messaging.sendEmail(allEmails);
        }
    }

    /**
     * @Description : Wrapper class for Invocable method input parameters.
     */
    public class EmailRequest {
        @InvocableVariable(label='Recipients' description='List of email addresses to send the email to.')
        public List<String> recipients;

        @InvocableVariable(label='Email Template Id' description='Id of the email template to be used.')
        public String emailTemplateId;

        @InvocableVariable(label='What Id' description='Id of the related record for merge fields.')
        public String whatId;
    }
}