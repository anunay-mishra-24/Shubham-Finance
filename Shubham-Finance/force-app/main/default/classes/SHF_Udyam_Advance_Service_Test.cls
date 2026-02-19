@IsTest
private class SHF_Udyam_Advance_Service_Test {

    private class ServiceMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        ServiceMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            return res;
        }
    }

    private static String successMapJson() {
        return
            '{"result":{' +
                '"dateOfCommencement":"2021-01-02",' +
                '"dateOfIncorporation":"2020-05-06",' +
                '"dateOfRegistration":"2019-03-04",' +
                '"enterpriseTypeDetails":[' +
                    '{ "type":"MICRO","classificationDate":"2022-07-01"}' +
                ']' +
            '}}';
    }

    private static String emptyResultJson() {
        return '{"result":{}}';
    }

    @IsTest
    static void testService_Success_MapResult() {

        Application__c app =
            SHF_TestDataFactory.createApplication('Test Application', true);

        Loan_Applicant__c la =
            SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, true);

        Test.setMock(HttpCalloutMock.class, new ServiceMock(200, successMapJson()));

        Test.startTest();
        String response = SHF_Udyam_Advance_Service.fetchUdyamAdvDetails(la.Id, 'Udyam');
        Test.stopTest();

        System.assertNotEquals(null, response);

        List<E_Verification__c> evList = [
        SELECT Date_of_Commencement__c, Enterprise_Type__c
        FROM E_Verification__c
        WHERE Loan_Applicant__c = :la.Id
        LIMIT 1
        ];

       System.assert(!evList.isEmpty(), 'Expected an E_Verification__c record to be created');

       E_Verification__c ev = evList[0];

       System.assertEquals('2021-01-02', ev.Date_of_Commencement__c);
       System.assertEquals('MICRO', ev.Enterprise_Type__c);

    }

    @IsTest
    static void testService_EmptyResult() {

        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);

        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, true);

        Test.setMock(HttpCalloutMock.class, new ServiceMock(200, emptyResultJson()));

        Test.startTest();
        String response = SHF_Udyam_Advance_Service.fetchUdyamAdvDetails(la.Id, 'UAMEMPTY');
        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @IsTest
    static void testService_NotVerified() {

        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);

        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, false);

        Test.startTest();
        String response = SHF_Udyam_Advance_Service.fetchUdyamAdvDetails(la.Id, 'UAMNV');
        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @IsTest
    static void testService_InvalidApplicant() {

        Test.startTest();
        String result = SHF_Udyam_Advance_Service.fetchUdyamAdvDetails(UserInfo.getUserId(), 'UAMERR');
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @IsTest
    static void testService_ExceptionHandling() {

        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);

        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, true);

        Test.setMock(HttpCalloutMock.class, new ServiceMock(200, '{invalid'));

        Test.startTest();
        String response = SHF_Udyam_Advance_Service.fetchUdyamAdvDetails(la.Id, 'UAMEX');
        Test.stopTest();

        System.assertNotEquals(null, response);
    }
}