/**
* @File Name          : SHF_OverDueLMSService_Test.cls
* @Description        : Test class to cover SHF_OverDueLMSService.
* @Author             : Kunal Soni
* 
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         19-08-2025   Kunal Soni   Initial Version
*/
@isTest
public class SHF_OverDueLMSService_Test {
    
    // Mock class to simulate successful HTTP response
    private class SMSHttpMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":{"loanId":5052442,"loanAcccountNo":"0NND2210000005052442","totalOutstandingReceivableAmount":39639,"totalOutstandingPayableAmount":0,"netOverDueAmount":39639,"overDueDetails":[{"chargeCodeDescription":"Late Payment Charge"}]}}');
            res.setStatusCode(200);
            return res;
        } 
    }

    // Mock class to simulate invalid response (forces exception)
    private class SMSHttpMockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('INVALID_JSON');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @IsTest
    static void testGetOverDue_Success() {
        Test.setMock(HttpCalloutMock.class, new SMSHttpMockSuccess());
        SHF_ServiceConsoleLMSControllerWrapper wrapper = new SHF_ServiceConsoleLMSControllerWrapper();
        
        Test.startTest();
        SHF_ServiceConsoleLMSControllerWrapper result =
            SHF_OverDueLMSService.getOverDueDetails('ACC123', wrapper);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertEquals('Late Payment Charge', result.chargeCodeDescription, 'Charge code description should be set');
    }
    
    @IsTest
    static void testGetOverDue_CatchBlock() {
        Test.setMock(HttpCalloutMock.class, new SMSHttpMockError());
        SHF_ServiceConsoleLMSControllerWrapper wrapper = new SHF_ServiceConsoleLMSControllerWrapper();
        
        Test.startTest();
        SHF_ServiceConsoleLMSControllerWrapper result =
            SHF_OverDueLMSService.getOverDueDetails('ACC999', wrapper);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Wrapper should still be returned even when exception occurs');
    }
}