global class SHF_DiscoverEmailServiceHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        System.debug('===== EMAIL SERVICE STARTED =====');

        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            
            if (email.subject == null || 
                !email.subject.contains('Discover Process Completed')) {

                System.debug('subject does not match criteria');
                result.success = true;
                return result;
            }

            String requestId;
            String extractedLink;

            System.debug('Email Subject: ' + email.subject);

            // Extract Request ID from subject
            Pattern reqPattern = Pattern.compile('[a-f0-9\\-]{36}');
            Matcher reqMatcher = reqPattern.matcher(email.subject);

            if (reqMatcher.find()) {
                requestId = reqMatcher.group();
                System.debug('Request ID Found: ' + requestId);
            }

            // Extract link from PDF attachment
            if (email.binaryAttachments != null) {

                for (Messaging.InboundEmail.BinaryAttachment att : email.binaryAttachments) {

                    System.debug('Processing attachment: ' + att.fileName);

                    String content = att.body.toString();

                    Pattern urlPattern = Pattern.compile('https://[^\\s"]+');
                    Matcher urlMatcher = urlPattern.matcher(content);

                    if (urlMatcher.find()) {
                        extractedLink = urlMatcher.group();
                        System.debug('Extracted Link: ' + extractedLink);
                        break;
                    }
                }
            }

            // Update existing E_Verification record
            if (requestId != null && extractedLink != null) {

                System.debug('Searching E_Verification record...');

                List<E_Verification__c> records = [
                    SELECT Id, Attachment_URL__c
                    FROM E_Verification__c
                    WHERE Request_Id__c = :requestId
                    LIMIT 1
                ];

                if (!records.isEmpty()) {

                    E_Verification__c ev = records[0];
                    ev.Attachment_URL__c = extractedLink;

                    update ev;

                    System.debug('E_Verification updated: ' + ev.Id);

                } else {
                    System.debug('No E_Verification found for Request ID');
                }
            }

            result.success = true;

        } catch (Exception e) {

            System.debug('ERROR: ' + e.getMessage());
            System.debug(e.getStackTraceString());

            result.success = false;
        }

        System.debug('===== EMAIL SERVICE FINISHED =====');

        return result;
    }
}