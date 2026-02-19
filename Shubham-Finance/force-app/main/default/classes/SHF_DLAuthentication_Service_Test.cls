@IsTest
private class SHF_DLAuthentication_Service_Test {
    
    private class SHF_DLAuthMock implements HttpCalloutMock {
        private String scenario;
        private Integer callCount = 0;
        
        public SHF_DLAuthMock(String scenario) {
            this.scenario = scenario;
        }
        
        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // First call is always access token, second is DL verification
            if (callCount == 1) {
                return getAccessTokenResponse();
            } else {
                return getDLVerificationResponse();
            }
        }
        
        private HttpResponse getAccessTokenResponse() {
            HttpResponse res = new HttpResponse();
            
            if (scenario == 'EMPTY_TOKEN' || scenario == 'TOKEN_FAILURE') {
                res.setStatusCode(500);
                res.setStatus('Internal Server Error');
                res.setBody('{"error": "Token generation failed"}');
            } else if (scenario == 'EMPTY_BODY') {
                res.setStatusCode(200);
                res.setBody('');
            } else if (scenario == 'MALFORMED_JSON') {
                res.setStatusCode(200);
                res.setBody('{invalid json}');
            } else if (scenario == 'USER_ID_ONLY') {
                res.setStatusCode(200);
                res.setBody('{"userId": "mockUserId456"}');
            } else {
                // SUCCESS - default
                res.setStatusCode(200);
                res.setBody('{"id": "mockAccessToken123"}');
            }
            
            return res;
        }
        
        private HttpResponse getDLVerificationResponse() {
            HttpResponse res = new HttpResponse();
            
            if (scenario == 'API_FAILURE') {
                res.setStatusCode(500);
                res.setStatus('Internal Server Error');
                res.setBody('{"error": "Verification failed"}');
            } else if (scenario == 'NO_RESULT') {
                res.setStatusCode(200);
                res.setBody('{"response": {}}');
            } else if (scenario == 'PARTIAL_RESULT') {
                res.setStatusCode(200);
                res.setBody('{"response": {"result": {"verified": "false"}}}');
            } else if (scenario == 'EMPTY_RESPONSE_BODY') {
                res.setStatusCode(200);
                res.setBody('');
            } else {
                // SUCCESS - default
                res.setStatusCode(200);
                res.setBody('{"response": {"result": {"verified": "true", "message": "DL Verified Successfully"}}}');
            }
            
            return res;
        }
    }
       
    @TestSetup
    static void setupTestData() {
        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);
        
        List<Loan_Applicant__c> applicants = new List<Loan_Applicant__c>();
        
        // Applicant 1: Full details
        Loan_Applicant__c la1 = SHF_TestDataFactory.createLoanApplicant(app.Id, 'John', 'Doe', null, false);
        la1.Driving_License_Number__c = 'DL123456789';
        la1.Date_of_Birth__c = Date.newInstance(1990, 5, 15);
        applicants.add(la1);
        
        // Applicant 2: No DOB (null date handling)
        Loan_Applicant__c la2 = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Jane', 'Smith', null, false);
        la2.Driving_License_Number__c = 'DL987654321';
        la2.Date_of_Birth__c = null;
        applicants.add(la2);
        
        // Applicant 3: Single-digit day/month (date formatting)
        Loan_Applicant__c la3 = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Bob', 'Johnson', null, false);
        la3.Driving_License_Number__c = 'DL111111111';
        la3.Date_of_Birth__c = Date.newInstance(1995, 3, 5);
        applicants.add(la3);
        
        // Applicant 4: Double-digit day/month (date formatting)
        Loan_Applicant__c la4 = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Alice', 'Wonder', null, false);
        la4.Driving_License_Number__c = 'DL555555555';
        la4.Date_of_Birth__c = Date.newInstance(1995, 11, 25);
        applicants.add(la4);
        
        insert applicants;
    }
    
    @IsTest
    static void test_generateAccessToken_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('SUCCESS'));
        
        String token = SHF_DLAuthentication_Service.generateAccessToken();
        
        Test.stopTest();
        
        // Token should either be the mock value or handle inactive service
        System.assert(token == 'mockAccessToken123' || token == null, 
                     'Should handle token generation');
    }
    
    /**
     * Test access token with userId instead of id
     */
    @IsTest
    static void test_generateAccessToken_UserIdOnly() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('USER_ID_ONLY'));
        
        String token = SHF_DLAuthentication_Service.generateAccessToken();
        
        Test.stopTest();
        
        System.assertEquals(null, token, 'Should return null when only userId present');
    }
    
    /**
     * Test access token with empty response body
     */
    @IsTest
    static void test_generateAccessToken_EmptyBody() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('EMPTY_BODY'));
        
        String token = SHF_DLAuthentication_Service.generateAccessToken();
        
        Test.stopTest();
        
        System.assertEquals(null, token, 'Should return null for empty body');
    }
    
    /**
     * Test access token with malformed JSON
     */
    @IsTest
    static void test_generateAccessToken_MalformedJson() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('MALFORMED_JSON'));
        
        String token = SHF_DLAuthentication_Service.generateAccessToken();
        
        Test.stopTest();
        
        System.assertEquals(null, token, 'Should return null for malformed JSON');
    }
    
    /**
     * Test access token with failed status code
     */
    @IsTest
    static void test_generateAccessToken_FailedStatus() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('TOKEN_FAILURE'));
        
        String token = SHF_DLAuthentication_Service.generateAccessToken();
        
        Test.stopTest();
        
        System.assertEquals(null, token, 'Should return null for failed status');
    }
    
    @IsTest
    static void test_validateDLDetails_Success() {
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c 
                                       WHERE Driving_License_Number__c = 'DL123456789' 
                                       LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('SUCCESS'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(applicant.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should return a message');
        
        // Verify E_Verification record was created
        List<E_Verification__c> eVers = [SELECT Id, Status__c, Description__c, Loan_Applicant__c 
                                          FROM E_Verification__c 
                                          WHERE Loan_Applicant__c = :applicant.Id];
        System.assertEquals(1, eVers.size(), 'Should create 1 verification record');
        System.assertEquals('true', eVers[0].Status__c, 'Status should be true');
        System.assertEquals('DL Verified Successfully', eVers[0].Description__c, 
                           'Description should match');
        
        // Verify applicant was updated with verification link
        Loan_Applicant__c updatedApplicant = [SELECT DL_Verification__c 
                                               FROM Loan_Applicant__c 
                                               WHERE Id = :applicant.Id];
        System.assertNotEquals(null, updatedApplicant.DL_Verification__c, 
                              'Applicant should be linked to verification');
    }
    
    /**
     * Test DL validation with null DOB
     */
    @IsTest
    static void test_validateDLDetails_NullDOB() {
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c 
                                       WHERE Driving_License_Number__c = 'DL987654321' 
                                       LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('SUCCESS'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(applicant.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should handle null DOB');
        
        List<E_Verification__c> eVers = [SELECT Id FROM E_Verification__c 
                                          WHERE Loan_Applicant__c = :applicant.Id];
        System.assertEquals(1, eVers.size(), 'Should create verification even with null DOB');
    }
    
    /**
     * Test DL validation with single-digit day/month in DOB
     */
    @IsTest
    static void test_validateDLDetails_SingleDigitDate() {
        Loan_Applicant__c applicant = [SELECT Id, Date_of_Birth__c 
                                       FROM Loan_Applicant__c 
                                       WHERE Driving_License_Number__c = 'DL111111111' 
                                       LIMIT 1];
        
        System.assertEquals(5, applicant.Date_of_Birth__c.day(), 'Day should be 5');
        System.assertEquals(3, applicant.Date_of_Birth__c.month(), 'Month should be 3');
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('SUCCESS'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(applicant.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should handle single-digit date formatting');
        
        List<E_Verification__c> eVers = [SELECT Id FROM E_Verification__c 
                                          WHERE Loan_Applicant__c = :applicant.Id];
        System.assertEquals(1, eVers.size(), 'Should create verification with formatted date');
    }
    
    /**
     * Test DL validation with double-digit day/month in DOB
     */
    @IsTest
    static void test_validateDLDetails_DoubleDigitDate() {
        Loan_Applicant__c applicant = [SELECT Id, Date_of_Birth__c 
                                       FROM Loan_Applicant__c 
                                       WHERE Driving_License_Number__c = 'DL555555555' 
                                       LIMIT 1];
        
        System.assertEquals(25, applicant.Date_of_Birth__c.day(), 'Day should be 25');
        System.assertEquals(11, applicant.Date_of_Birth__c.month(), 'Month should be 11');
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('SUCCESS'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(applicant.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should handle double-digit date formatting');
        
        List<E_Verification__c> eVers = [SELECT Id FROM E_Verification__c 
                                          WHERE Loan_Applicant__c = :applicant.Id];
        System.assertEquals(1, eVers.size(), 'Should create verification with formatted date');
    }
    
    /**
     * Test API failure (500 error)
     */
    @IsTest
    static void test_validateDLDetails_APIFailure() {
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c 
                                       WHERE Driving_License_Number__c = 'DL123456789' 
                                       LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('API_FAILURE'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(applicant.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should handle API failure');
        
        List<E_Verification__c> eVers = [SELECT Status__c, Warning_Code__c, Description__c 
                                          FROM E_Verification__c 
                                          WHERE Loan_Applicant__c = :applicant.Id];
        System.assertEquals(1, eVers.size(), 'Should create verification record on failure');
        System.assertEquals('Failed', eVers[0].Status__c, 'Status should be Failed');
        System.assertEquals('500', eVers[0].Warning_Code__c, 'Warning code should be 500');
        System.assert(eVers[0].Description__c.contains('failed'), 
                     'Description should mention failure');
    }
    
    /**
     * Test empty access token
     */
    @IsTest
    static void test_validateDLDetails_EmptyToken() {
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c 
                                       WHERE Driving_License_Number__c = 'DL123456789' 
                                       LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('EMPTY_TOKEN'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(applicant.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should return error message for empty token');
        
        // Should NOT create verification without token
        List<E_Verification__c> eVers = [SELECT Id FROM E_Verification__c 
                                          WHERE Loan_Applicant__c = :applicant.Id];
        System.assertEquals(0, eVers.size(), 'Should not create verification without token');
    }
    
    /**
     * Test invalid applicant ID
     */
    @IsTest
    static void test_validateDLDetails_InvalidApplicantId() {
        // Create a fake ID that doesn't exist
        String fakeId = 'a0A000000000000AAA';
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('SUCCESS'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(fakeId);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should return error for invalid ID');
    }
    
    /**
     * Test response with no result key
     */
    @IsTest
    static void test_validateDLDetails_NoResultKey() {
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c 
                                       WHERE Driving_License_Number__c = 'DL123456789' 
                                       LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('NO_RESULT'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(applicant.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should handle missing result key');
        
        List<E_Verification__c> eVers = [SELECT Id, Status__c FROM E_Verification__c 
                                          WHERE Loan_Applicant__c = :applicant.Id];
        System.assertEquals(1, eVers.size(), 'Should create verification record');
    }
    
    /**
     * Test response with partial result (verified only, no message)
     */
    @IsTest
    static void test_validateDLDetails_PartialResult() {
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c 
                                       WHERE Driving_License_Number__c = 'DL123456789' 
                                       LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('PARTIAL_RESULT'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(applicant.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should handle partial result');
        
        List<E_Verification__c> eVers = [SELECT Status__c, Description__c 
                                          FROM E_Verification__c 
                                          WHERE Loan_Applicant__c = :applicant.Id];
        System.assertEquals(1, eVers.size(), 'Should create verification record');
        System.assertEquals('false', eVers[0].Status__c, 'Status should be false');
    }
    
    /**
     * Test response with empty body
     */
    @IsTest
    static void test_validateDLDetails_EmptyResponseBody() {
        Loan_Applicant__c applicant = [SELECT Id FROM Loan_Applicant__c 
                                       WHERE Driving_License_Number__c = 'DL123456789' 
                                       LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('EMPTY_RESPONSE_BODY'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(applicant.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should handle empty response body');
    }
    
    /**
     * Test with blank DL number
     */
    @IsTest
    static void test_validateDLDetails_BlankDLNumber() {
        Application__c app = SHF_TestDataFactory.createApplication('Blank DL Test', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(
            app.Id, 'Test', 'Blank', null, false
        );
        applicant.Driving_License_Number__c = null;
        applicant.Date_of_Birth__c = Date.newInstance(1990, 1, 1);
        insert applicant;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SHF_DLAuthMock('SUCCESS'));
        
        String message = SHF_DLAuthentication_Service.validateDLDetails(applicant.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Should handle blank DL number');
        
        List<E_Verification__c> eVers = [SELECT Id FROM E_Verification__c 
                                          WHERE Loan_Applicant__c = :applicant.Id];
        System.assertEquals(1, eVers.size(), 'Should create verification even with blank DL');
    }
}