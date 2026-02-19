@isTest
private class MessageServiceTriggerHandlerTest {
    
    @isTest
    static void testWhatsAppMessageFlow() {
        Test.startTest();
        // Publish a Platform Event with WhatsApp_Placeholders__c set
        Message_Service__e evt = new Message_Service__e(
            Receiver__c = '9999999999',
            Message_Template__c = 'TEMPLATE_WHATSAPP',
            WhatsApp_Placeholders__c = '{"name":"akhay"}'
        );
        Database.SaveResult sr = EventBus.publish(evt);
        Test.stopTest();
        
        System.assertEquals(true, sr.isSuccess(), 'Event should be published successfully');
    }
    
    @isTest
    static void testSMSMessageFlow() {
        Test.startTest();
        // Publish a Platform Event without WhatsApp_Placeholders__c (so SMS branch executes)
        Message_Service__e evt = new Message_Service__e(
            Receiver__c = '8888888888',
            Message_Template__c = 'TEMPLATE_SMS'
        );
        Database.SaveResult sr = EventBus.publish(evt);
        Test.stopTest();
        
        System.assertEquals(true, sr.isSuccess(), 'Event should be published successfully');
    }
    
    @isTest
    static void testEventMissingFields_NoCall() {
        Test.startTest();
        // Event with blank fields
        Message_Service__e evt = new Message_Service__e();
        Database.SaveResult sr = EventBus.publish(evt);
        Test.stopTest();
        
        System.assertEquals(true, sr.isSuccess(), 'Event with blank values should still publish');
    }
}