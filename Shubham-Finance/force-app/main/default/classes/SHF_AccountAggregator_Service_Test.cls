@IsTest
public class SHF_AccountAggregator_Service_Test {

    private static Loan_Applicant__c makeApplicant(Boolean hasPan, Boolean hasMobileNo, Boolean doInsert) {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, false);
        if (hasPan && hasMobileNo) {
            la.Pan_Number__c = 'ABCDE1234F';
            la.Mobile_Number__c = '9999999999';
        }
        if (doInsert) insert la;
        return la;
    }

    @IsTest
    static void test_generateAccessToken_success() {

        Test.setMock(HttpCalloutMock.class,
            new TokenMock(200, '{"token":"tok123","sessionId":"ses456"}')
        );

        Test.startTest();
        Map<String,String> tokenMap = SHF_AccountAggregator_Service.generateAccessToken();
        Test.stopTest();

        System.assertEquals('tok123', tokenMap.get('token'));
        System.assertEquals('ses456', tokenMap.get('sessionId'));
    }

    @IsTest
    static void test_generateAccessToken_errorResponse() {

        Test.setMock(HttpCalloutMock.class,new TokenMock(500, 'Internal Error'));

        Test.startTest();
        Map<String,String> tokenMap = SHF_AccountAggregator_Service.generateAccessToken();
        Test.stopTest();

        System.assertEquals(true, tokenMap.isEmpty(), 'Token map must be empty on error');
    }

    @IsTest
    static void test_generateAccessToken_invalidJson() {

        Test.setMock(HttpCalloutMock.class,new TokenMock(200, '{badJson'));

        Test.startTest();
        Map<String,String> tokenMap = SHF_AccountAggregator_Service.generateAccessToken();
        Test.stopTest();

        System.assertEquals(true, tokenMap.isEmpty(), 'Token map must be empty on invalid JSON');
    }

    @IsTest
    static void test_getInitiateAccountAggregator_success() {

        Test.setMock(
            HttpCalloutMock.class,
            new CompositeMock(
                200,
                '{"token":"tok123","sessionId":"ses456"}',
                200,
                '{"txnid":"tx1","clienttxnid":"ctx1","sessionId":"ses456","redirectionurl":"https://example.com/redirect==","consentHandle":"abc,def,30D"}'
            )
        );
        
        Loan_Applicant__c la = makeApplicant(true, true, true);
       
        Test.startTest();
        String msg = SHF_AccountAggregator_Service.getInitiateAccountAggregator(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, msg, 'Response must not be null');
        System.assertNotEquals('', msg, 'Response must not be blank');
    }

    @IsTest
    static void test_getInitiateAccountAggregator_missingApplicant() {

        Test.setMock(
            HttpCalloutMock.class,
            new TokenMock(200, '{"token":"tok123","sessionId":"ses456"}')
        );

        Test.startTest();
        String msg = SHF_AccountAggregator_Service.getInitiateAccountAggregator('001000000000000AAA');
        Test.stopTest();

        System.assertNotEquals(null, msg);
    }

    @IsTest
    static void test_getManualFetchAccountDetails_success() {

        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c la = makeApplicant(true,true,true);
        la.Account_Aggregator_CAM__c = app.Id;
        update la;

        Test.setMock(
            HttpCalloutMock.class,
            new CompositeMock(
                200,
                '{"token":"tok123","sessionId":"ses456"}',
                200,
                '{"statusMessage":"OK","reference_id":"ref-1"}'
            )
        );

        Test.startTest();
        String msg = SHF_AccountAggregator_Service.getManualFetchAccountDetails(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, msg);
        System.assert(msg.contains('OK') || msg.contains('ref-'), 'Expected a success response');
    }

    @IsTest
    static void test_getManualFetchAccountDetails_missingLink() {

        Loan_Applicant__c la = makeApplicant(true,true,true);

        Test.setMock(
            HttpCalloutMock.class,
            new TokenMock(200, '{"token":"tok123","sessionId":"ses456"}')
        );

        Test.startTest();
        String msg = SHF_AccountAggregator_Service.getManualFetchAccountDetails(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, msg, 'Must return message');
    }

    // ===== MOCK CLASSES =====

    private class TokenMock implements HttpCalloutMock {
        Integer status;
        String body;

        TokenMock(Integer s, String b) {
            status = s;
            body = b;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(status);
            r.setBody(body);
            return r;
        }
    }

    private class CompositeMock implements HttpCalloutMock {
        Integer status1;
        String body1;
        Integer status2;
        String body2;
        Integer counter = 0;

        CompositeMock(Integer s1, String b1, Integer s2, String b2) {
            status1 = s1;
            body1 = b1;
            status2 = s2;
            body2 = b2;
        }

        public HttpResponse respond(HttpRequest req) {

            HttpResponse r = new HttpResponse();

            if (counter == 0) {
                r.setStatusCode(status1);
                r.setBody(body1);
            } else {
                r.setStatusCode(status2);
                r.setBody(body2);
            }

            counter++;
            return r;
        }
    }
}