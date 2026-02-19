/**
* @File Name          : SHF_WhatsApp_Service.cls
* @Description        : API to send WhatsApp message to the customer
* @Author             : Riteek 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         07-07-2025               Riteek                 Added Flow invocation with placeholders
*/
public with sharing class SHF_WhatsApp_Service {
    private SHF_HTTPCalloutService service;

    public static void sendNotification(String mobileNumber, String templateName, List<String> placeholders) {
        // Mobile number of the recipient (10-digit number).This is used as the destination number for sending the message.
       // The name of the WhatsApp message template configured in your messaging provider.This must match exactly with the template defined in your provider’s dashboard.
       //A list of values to dynamically replace placeholders in the message template. These are inserted into the message body.
        try {
            if (String.isBlank(mobileNumber) || !mobileNumber.isNumeric() || mobileNumber.length() != 10) {
                Logger.error('Invalid or missing mobile number: ' + mobileNumber);
                return;
            }

            if (String.isBlank(templateName)) {
                Logger.error('Template name is required.' + templateName);
                return;
            }
            
            SHF_WhatsApp_Service whatsAppService = new SHF_WhatsApp_Service();
            whatsAppService.service = new SHF_HTTPCalloutService('WhatsApp_API');
            
            String jsonBody = whatsAppService.service.getRequestBody();
            String formattedNumber = '"91' + mobileNumber + '"';
            jsonBody = jsonBody.replace('"<ReceiverMobileNumber>"', formattedNumber);
            jsonBody = jsonBody.replace('"templateName": "<Template>"', '"templateName": "' + templateName + '"');

            // Format placeholder array
            if (placeholders != null && !placeholders.isEmpty()) {
                List<String> quotedValues = new List<String>();
                for (String val : placeholders) {
                    quotedValues.add('"' + val + '"');
                }
                String placeholderArrayJson = '[' + String.join(quotedValues, ',') + ']';
                jsonBody = jsonBody.replace('<PLACEHOLDER_ARRAY>', placeholderArrayJson);
            } else {
                jsonBody = jsonBody.replace('<PLACEHOLDER_ARRAY>', '[]');
            }
            whatsAppService.service.setRequestBody(jsonBody);

            HttpResponse response = whatsAppService.service.sendRequest();
            Logger.info('WhatsApp API Request - Body: ' + whatsAppService.service.getRequestBody());
            Logger.info('WhatsApp API Response - Status Code: ' + response.getStatusCode());
            Logger.info('WhatsApp API Response - Status: ' + response.getStatus());
            Logger.info('WhatsApp API Response - Body: ' + response.getBody());

        } catch (Exception e) {
            Logger.error('WhatsApp API Error: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }

    @InvocableMethod(label='Send WhatsApp Message' description='Triggers WhatsApp message using mobile number, template, and placeholders')
    public static void sendWhatsAppFromFlow(List<WhatsAppInput> inputList) {
        if (!inputList.isEmpty()) {
            WhatsAppInput input = inputList[0];
            sendNotification(input.mobileNumber, input.templateName, input.placeholders);
        }
    }

    public class WhatsAppInput {
        @InvocableVariable(label='Mobile Number' required=true)
        public String mobileNumber;

        @InvocableVariable(label='Template Name' required=true)
        public String templateName;

        @InvocableVariable(label='Placeholders' )
        public List<String> placeholders;
    }
}