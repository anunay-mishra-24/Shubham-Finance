@isTest
private class SHF_Message_Service_Future_Test {

    // Mock class for WhatsApp and SMS callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @isTest
    static void testSendWhatsApp() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        // Call future method
        SHF_Message_Service_Future.sendWhatsApp(
            '9876543210',
            'TEMPLATE_WHATSAPP',
            '{"name":"Harshita"}'
        );
        Test.stopTest(); // Ensures future method executes
    }

    @isTest
    static void testSendSMS() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        // Call future method
        SHF_Message_Service_Future.sendSMS(
            '9876543210',
            'This is a test SMS'
        );
        Test.stopTest(); // Ensures future method executes
    }
}