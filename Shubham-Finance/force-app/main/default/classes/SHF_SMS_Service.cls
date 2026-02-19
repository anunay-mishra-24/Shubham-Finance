/**
* @File Name          : SHF_SendSMS_Service.cls
* @Description        : API to send user creation SMS to the customer.
* @Author             : Riteek 
* @Test Class         : 
*==============================================================================
* Ver         Date         Author     Modification
*==============================================================================
* 1.0         03-06-2025   Riteek     Initial Version
*/
public with sharing class SHF_SMS_Service {
    public static void sendNotificationToUser(String mobileNumber, String smsBody) {    
        System.debug('mobileNumber-->'+mobileNumber);
         System.debug('smsBody-->'+smsBody);
        // The mobile number where the SMS will be sent. This is required by the SMS API to identify the recipient.
        // The actual message content that will be sent in the SMS. This text appears in the recipient's inbox.
        try {
            if (String.isBlank(mobileNumber)) {
                Logger.error('Invalid or missing mobile number: ' + mobileNumber);
                return;
            }
            if (String.isNotBlank(smsBody)) {
                SHF_HTTPCalloutService service = new SHF_HTTPCalloutService('SMS_User_Creation_API');
                service.setURLParameter('to', mobileNumber);
                
                service.setURLParameter('message', SHF_CommonUtil.formatSMSTemplate(smsBody));
                HttpResponse response = service.sendRequest();
                
                if (response.getStatusCode() == 200) {
                    Logger.info('SMS sent successfully.');
                    Logger.info('Mobile Number: ' + mobileNumber);
                    Logger.info('SMS Body: ' + smsBody);
                    Logger.info('Status Code: ' + response.getstatusCode());
                    Logger.info('Response Body: ' + response.getBody());
                } else {
                    Logger.error('Failed to send SMS.');
                    Logger.error('Mobile Number: ' + mobileNumber);
                    Logger.error('SMS Body: ' + smsBody);
                    Logger.error('Status code: ' + response.getstatusCode());
                    Logger.error('Response Body: ' +  response.getBody());
                } 
                
            }            
            
        } catch (Exception e) {
            Logger.error('error ' + e.getMessage() + e.getlinenumber());
        } finally {
            Logger.saveLog();
        }
    }
    
    @InvocableMethod(label='Send SMS Nofication' description='Sends an SMS using mobile number and message from Flow')
    public static void sendSMSFromFlow(List<FlowSMSInput> inputList) {
        if (!inputList.isEmpty()) {
            FlowSMSInput input = inputList[0];
            sendNotificationToUser(input.mobileNumber, input.smsBody);
        }
    }
    public class FlowSMSInput {
        @InvocableVariable(label='Mobile Number' required=true)
        public String mobileNumber;
        
        @InvocableVariable(label='SMS Body' required=true)
        public String smsBody;
    }
}