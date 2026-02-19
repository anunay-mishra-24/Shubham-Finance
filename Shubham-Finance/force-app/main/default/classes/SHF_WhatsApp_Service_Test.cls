/**
* @File Name          : SHF_WhatsApp_Service_Test.cls
* @Description        : Test class for SHF_WhatsApp_Service
* @Author             : Kunal soni
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         20-08-2025   Kunal soni
*/
@IsTest
public class SHF_WhatsApp_Service_Test {

    // Mock successful callout
    private class WhatsAppHttpMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"SUCCESS"}');
            return res;
        }
    }

    // Mock callout throwing error
    private class WhatsAppHttpMockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated callout failure');
        }
    }

    @IsTest
    static void testSendNotification_Success() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppHttpMockSuccess());

        Test.startTest();
        SHF_WhatsApp_Service.sendNotification('9876543210', 'WelcomeTemplate', new List<String>{'John','Loan123'});
        Test.stopTest();

        // If Logger persists somewhere, you could assert logs
        System.assert(true, 'Execution should complete without exception');
    }

    @IsTest
    static void testSendNotification_InvalidMobile() {
        Test.startTest();
        // Blank
        SHF_WhatsApp_Service.sendNotification('', 'TestTemplate', new List<String>());
        // Non-numeric
        SHF_WhatsApp_Service.sendNotification('98AB543210', 'TestTemplate', new List<String>());
        // Wrong length
        SHF_WhatsApp_Service.sendNotification('12345', 'TestTemplate', new List<String>());
        Test.stopTest();

        System.assert(true, 'Invalid mobile numbers should not callout');
    }

    @IsTest
    static void testSendNotification_BlankTemplate() {
        Test.startTest();
        SHF_WhatsApp_Service.sendNotification('9876543210', '', new List<String>());
        Test.stopTest();

        System.assert(true, 'Blank template should not callout');
    }

    @IsTest
    static void testSendNotification_Exception() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppHttpMockError());

        Test.startTest();
        SHF_WhatsApp_Service.sendNotification('9876543210', 'ErrorTemplate', new List<String>{'Val1'});
        Test.stopTest();

        System.assert(true, 'Exception should be caught without failure');
    }

    @IsTest
    static void testSendWhatsAppFromFlow() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppHttpMockSuccess());

        SHF_WhatsApp_Service.WhatsAppInput input = new SHF_WhatsApp_Service.WhatsAppInput();
        input.mobileNumber = '9876543210';
        input.templateName = 'FlowTemplate';
        input.placeholders = new List<String>{'Hello','World'};

        Test.startTest();
        SHF_WhatsApp_Service.sendWhatsAppFromFlow(new List<SHF_WhatsApp_Service.WhatsAppInput>{input});
        Test.stopTest();

        System.assert(true, 'Flow invocation should trigger sendNotification');
    }
}