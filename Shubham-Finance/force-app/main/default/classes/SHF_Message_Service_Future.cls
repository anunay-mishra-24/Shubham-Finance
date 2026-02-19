/**
 * @File Name          : SHF_Message_Service_Future.cls
 * @Description        : 
 * @Author             : Akshi Sharma
 * ==============================================================================
 * Ver         Date         Author       Modification
 * ==============================================================================
 * 1.0         21-08-2025   Akshi Sharma  Initial Version
 */
public class SHF_Message_Service_Future {
    @future(callout=true)
    public static void sendWhatsApp(String mobile, String template, String placeholderStr) {
        List<String> placeholders = SHF_LMSCommonUtil.getPlaceholdersList(placeholderStr);
        SHF_WhatsApp_Service.sendNotification(mobile, template, placeholders);
    }
    
    @future(callout=true)
    public static void sendSMS(String mobile, String body) {
        SHF_SMS_Service.sendNotificationToUser(mobile, body);
    }
}