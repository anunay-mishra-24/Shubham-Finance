@IsTest
public class shf_getLoanService_Test {

    private static Loan_Applicant__c createApplicant(Boolean withLoanAgreement) {
        Application__c app = new Application__c(
            Name = 'Test App',
            Loan_Agreement_No__c = withLoanAgreement ? 'LN-12345' : null
        );
        insert app;

        Loan_Applicant__c applicant = new Loan_Applicant__c(
            Name = 'Primary Applicant',
            Applicant_Type__c = 'Primary Applicant',
            Application__c = app.Id
        );
        insert applicant;

        return applicant;
    }

    private class Mock_Selector implements HttpCalloutMock {
        HttpResponse responseToReturn;
        Mock_Selector(HttpResponse resp) { responseToReturn = resp; }
        public HTTPResponse respond(HTTPRequest req) {
            return responseToReturn != null ? responseToReturn : new HttpResponse();
        }
    }

    @IsTest
    static void test_generateAccessToken() {

        Test.startTest();
        String token = shf_getLoanService.generateAccessToken();
        Test.stopTest();

        System.assertNotEquals(null, token, 'Token should be returned in test mode.');
    }

    @IsTest
    static void test_getLoanDetails_success() {

        Loan_Applicant__c applicant = createApplicant(true);

        // Prepare mock HTTP response for token and loan detail API through SHF_HTTPCalloutService's inactive path
        HttpResponse resp = new HttpResponse();
        // success payload expected by service: { "success": { "principalOutstanding": 123.45 } }
        resp.setStatusCode(200);
        resp.setBody('{"success":{"principalOutstanding":123.45}}');

        // Set a generic HttpCalloutMock so if any callout happens in active mode, it won't fail
        Test.setMock(HttpCalloutMock.class, new Mock_Selector(resp));

        Test.startTest();
        String result = shf_getLoanService.getLoanDetails(applicant.Application__c);
        Test.stopTest();

        System.assertEquals('Joint_Exposure_Success_Msg', result);
    
        Loan_Applicant__c updated = [
            SELECT Joint_Exposure__c FROM Loan_Applicant__c WHERE Id = :applicant.Id
        ];
        System.assertNotEquals(null, updated.Joint_Exposure__c);
    }

    @IsTest
    static void test_getLoanDetails_noApplicant() {

        // No applicant in DB for this random app Id; also ensure callouts don't fail
        Test.setMock(HttpCalloutMock.class, new Mock_Selector(null));

        Test.startTest();
        String result = shf_getLoanService.getLoanDetails('000000000000000');
        Test.stopTest();

        System.assertEquals('Joint_Exposure_Error_Msg', result);
    }

    @IsTest
    static void test_getLoanDetails_noLoanAgreement() {

        Loan_Applicant__c applicant = createApplicant(false);

        Test.setMock(HttpCalloutMock.class, new Mock_Selector(null));

        Test.startTest();
        String result = shf_getLoanService.getLoanDetails(applicant.Application__c);
        Test.stopTest();

        System.assertEquals('Loan_Agreement_not_available', result);
    }

    @IsTest
    static void test_getLoanDetails_tokenFail() {

        // Simulate token failure path: service returns null token unless Test.isRunningTest forces default
        // We provide a callout mock so no real callout occurs
        Test.setMock(HttpCalloutMock.class, new Mock_Selector(null));

        Test.startTest();
        String result = shf_getLoanService.getLoanDetails('ANYID');
        Test.stopTest();

        System.assertEquals('Token_not_generated', result);
    }
}