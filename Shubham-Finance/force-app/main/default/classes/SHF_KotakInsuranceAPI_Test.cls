@IsTest
private class SHF_KotakInsuranceAPI_Test {

    private static final String AUTH_MOCK_JSON = '{"TokenDetails":{"TokenId":"MOCK_TOKEN"}}';

    private static final String PREMIUM_SUCCESS_JSON =
    '{' +
      '"Response":{' +
        '"ResponseInfo":{' +
          '"CreationDate":"2025-09-19",' +
          '"TransactionId":"CN-12345"' +
        '},' +
        '"ResponsePayload":{' +
          '"Transactions":[{' +
            '"TransactionData":{' +
              '"IsSuccess":true,' +
              '"PremiumInfoDetails":{' +
                '"TotalPremium": 1234.56,' +
                '"JobId":"POL-98765",' +
                '"CoverEndDate":"31/12/2026"' +
              '}' +
            '}' +
          '}]' +
        '}' +
      '}' +
    '}';

    private static final String PREMIUM_BUSINESS_ERROR_JSON =
    '{' +
      '"Response":{' +
        '"ResponseInfo":{' +
          '"CreationDate":"2025-09-19",' +
          '"TransactionId":"CN-ERROR"' +
        '},' +
        '"ResponsePayload":{' +
          '"Transactions":[{' +
            '"TransactionData":{' +
              '"IsSuccess":false,' +
              '"ResponseMessage:":"Invalid proposal data"' +
            '}' +
          '}]' +
        '}' +
      '}' +
    '}';

    private class SimpleHttpMock implements HttpCalloutMock {
        Integer code;
        String body;
        Map<String,String> headers;
        public SimpleHttpMock(Integer code, String body) {
            this.code = code; this.body = body; this.headers = new Map<String,String>();
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            res.setHeader('Content-Type','application/json');
            return res;
        }
    }

    @TestSetup
    static void setupData() {

        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);

        Loan_Applicant__c applicant = new Loan_Applicant__c(
            Application__c = app.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Date_of_Birth__c = Date.newInstance(1990, 5, 15),
            Gender__c = 'Male'
        );
        insert applicant;

        E_Verification__c ev = new E_Verification__c(
            Status__c = 'INITIATED'
        );
        insert ev;
    }

    @IsTest
    static void test_buildDynamicRequest_replacements() {
        // Arrange
        Application__c app = [SELECT Id, Applied_Loan_Amount__c, Tenure__c FROM Application__c LIMIT 1];
        // Populate fields used by method
        app.Applied_Loan_Amount__c = 250000;
        app.Tenure__c = 24;
        update app;

        Loan_Applicant__c la = [SELECT Id, Date_of_Birth__c, Gender__c FROM Loan_Applicant__c LIMIT 1];

        // We cannot instantiate Callout_Framework__mdt; pass null so method uses default '{}'
        String dateOfCommencement = '01/01/2026';

        // Act
        String body = SHF_KotakInsuranceAPI.buildDynamicRequest(null, app, la, null, dateOfCommencement);

        // Assert - since template is '{}', ensure we still get a non-null string and no exception
        System.assertNotEquals(null, body, 'Dynamic request should return a string');
        System.assert(!String.isBlank(body), 'Dynamic request should not be blank');
    }

    @IsTest
    static void test_updateEVerification_mapping_success() {
        // Arrange
        E_Verification__c ev = [SELECT Id FROM E_Verification__c LIMIT 1];

        // Act
        Test.startTest();
        SHF_KotakInsuranceAPI.updateEVerification(PREMIUM_SUCCESS_JSON, ev.Id);
        Test.stopTest();

        // Assert mapping fields
        E_Verification__c after = [
            SELECT Id, Cover_Note_Creation_Date__c, Start_Date__c, Cover_Note_Number__c,
                   Premium_Amount__c, Policy_Number__c, End_Date__c, Type_Of_Insurance__c, Status__c
            FROM E_Verification__c WHERE Id = :ev.Id
        ];
        System.assertEquals(Date.valueOf('2025-09-19'), after.Cover_Note_Creation_Date__c);
        System.assertEquals(Date.valueOf('2025-09-19'), after.Start_Date__c);
        System.assertEquals('CN-12345', after.Cover_Note_Number__c);
        System.assertEquals(1234.56, after.Premium_Amount__c);
        System.assertEquals('POL-98765', after.Policy_Number__c);
        System.assertEquals(Date.newInstance(2026,12,31), after.End_Date__c);
        System.assertEquals('Life Insurance', after.Type_Of_Insurance__c);
        System.assertEquals('COMPLETED', after.Status__c);
    }

    @IsTest
    static void test_calculatePremium_active_success_and_business_error() {
        // Arrange
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Loan_Applicant__c la = [SELECT Id FROM Loan_Applicant__c LIMIT 1];
        E_Verification__c ev = [SELECT Id FROM E_Verification__c LIMIT 1];

        // Insurance data map
        Map<String,Object> insuranceData = new Map<String,Object>{
            'Date_Of_Cover_Of_Commencement__c' => '01/01/2026'
        };

        // 1) Success case
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SimpleHttpMock(200, PREMIUM_SUCCESS_JSON));
        String success = SHF_KotakInsuranceAPI.calculatePremium('TOK', ev.Id, app, la, insuranceData);
        Test.stopTest();
        System.assert(!String.isBlank(success) && success.contains('ResponsePayload'), 'Should return success JSON');

        // 2) Business error case (status code 200 but IsSuccess=false)
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SimpleHttpMock(200, PREMIUM_BUSINESS_ERROR_JSON));
        String biz = SHF_KotakInsuranceAPI.calculatePremium('TOK', ev.Id, app, la, insuranceData);
        Test.stopTest();
        System.assert(biz.startsWith('ERROR::'), 'Business error should be prefixed');
        System.assert(biz.contains('Invalid proposal data'), 'Error message should surface');
    }

    @IsTest
    static void test_calculatePremium_missing_token_returns_null() {
        // Arrange
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Loan_Applicant__c la = [SELECT Id FROM Loan_Applicant__c LIMIT 1];
        E_Verification__c ev = [SELECT Id FROM E_Verification__c LIMIT 1];
        Map<String,Object> insuranceData = new Map<String,Object>();

        // Act
        Test.startTest();
        // When token is blank, method returns null
        String res = SHF_KotakInsuranceAPI.calculatePremium('', ev.Id, app, la, insuranceData);
        Test.stopTest();

        // Assert
        System.assertEquals(null, res, 'Blank token should return null per implementation');
    }

    @IsTest
    static void test_callKotakService_end_to_end_active() {
        // Arrange
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Loan_Applicant__c la = [SELECT Id FROM Loan_Applicant__c LIMIT 1];
        E_Verification__c ev = [SELECT Id FROM E_Verification__c LIMIT 1];

        // Step 1: Token
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SimpleHttpMock(200, AUTH_MOCK_JSON));
        String tok = SHF_KotakInsuranceAPI.generateAccessToken();
        Test.stopTest();
        System.assertEquals('MOCK_TOKEN', tok, 'Token should be parsed from TokenDetails.TokenId');

        // Step 2: Premium
        Map<String,Object> insuranceData = new Map<String,Object>{
            'Date_Of_Cover_Of_Commencement__c' => '01/01/2026'
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SimpleHttpMock(200, PREMIUM_SUCCESS_JSON));
        String finalRes = SHF_KotakInsuranceAPI.calculatePremium(tok, ev.Id, app, la, insuranceData);
        Test.stopTest();
        System.assert(finalRes.contains('ResponsePayload'), 'Final premium call should return success JSON');

        // Optional: run callKotakService end-to-end by mocking token again then premium again
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SimpleHttpMock(200, AUTH_MOCK_JSON));
        // Next call within callKotakService will also do an HTTP, so set again
        Test.setMock(HttpCalloutMock.class, new SimpleHttpMock(200, PREMIUM_SUCCESS_JSON));
        String eo = SHF_KotakInsuranceAPI.callKotakService(ev.Id, app, la, insuranceData);
        Test.stopTest();
        System.assert(eo.contains('ResponsePayload'), 'End-to-end service call should succeed');
    }

    @IsTest
    static void test_generateAccessToken_active_error_handling() {
        // Simulate non-200
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SimpleHttpMock(500, '{"error":"server"}'));
        String tok = SHF_KotakInsuranceAPI.generateAccessToken();
        Test.stopTest();
        // On non-200, method returns null (since tokenId never set)
        System.assertEquals(null, tok, 'Non-200 should result in null token per implementation');
    }
}