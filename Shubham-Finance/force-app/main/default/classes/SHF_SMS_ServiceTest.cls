@IsTest
private class SHF_SMS_ServiceTest {

    // Mock class to simulate successful HTTP response
    private class SMSHttpMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock class to simulate failed HTTP response
    private class SMSHttpMockFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"error"}');
            res.setStatusCode(400);
            return res;
        }
    }

    @IsTest
    static void testSendNotificationToUser_Success() {
        Test.setMock(HttpCalloutMock.class, new SMSHttpMockSuccess());
        Test.startTest();
        SHF_SMS_Service.sendNotificationToUser('9999999999', 'Test SMS Body');
        Test.stopTest();
    }

    @IsTest
    static void testSendNotificationToUser_Failure() {
        Test.setMock(HttpCalloutMock.class, new SMSHttpMockFailure());
        Test.startTest();
        SHF_SMS_Service.sendNotificationToUser('9999999999', 'Test SMS Body');
        Test.stopTest();
    }

    @IsTest
    static void testSendNotificationToUser_BlankNumber() {
        Test.startTest();
        SHF_SMS_Service.sendNotificationToUser('', 'Test SMS Body');
        Test.stopTest();
    }

    @IsTest
    static void testSendNotificationToUser_BlankBody() {
        Test.startTest();
        SHF_SMS_Service.sendNotificationToUser('9999999999', '');
        Test.stopTest();
    }

    @IsTest
    static void testSendSMSFromFlow() {
        Test.setMock(HttpCalloutMock.class, new SMSHttpMockSuccess());
        SHF_SMS_Service.FlowSMSInput input = new SHF_SMS_Service.FlowSMSInput();
        input.mobileNumber = '9999999999';
        input.smsBody = 'From Flow';
        List<SHF_SMS_Service.FlowSMSInput> inputList = new List<SHF_SMS_Service.FlowSMSInput>{ input };
        Test.startTest();
        SHF_SMS_Service.sendSMSFromFlow(inputList);
        Test.stopTest();
    }

    @IsTest
    static void testSendSMSFromFlow_EmptyList() {
        Test.startTest();
        SHF_SMS_Service.sendSMSFromFlow(new List<SHF_SMS_Service.FlowSMSInput>());
        Test.stopTest();
    }
}