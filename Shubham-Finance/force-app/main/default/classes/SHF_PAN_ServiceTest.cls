@IsTest
private class SHF_PAN_ServiceTest {

    // Simple mock to simulate SHF_HTTPCalloutService behavior if actual wrapper isn't invoked in test context.
    private class FakeHttpCalloutMock implements HttpCalloutMock {
        Integer statusCode;
        String body;
        FakeHttpCalloutMock(Integer code, String b) {
            statusCode = code; body = b;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            if (statusCode == 200) res.setStatus('OK');
            res.setBody(body);
            return res;
        }
    }

    // Utility to insert minimal data required for SHF_PAN_Service.validatePANNumber
    private static Loan_Applicant__c makeApplicant(Boolean hasPan, Boolean doInsert) {
        Application__c app = SHF_TestDataFactory.createApplication(null, true);
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, false);
        if (hasPan) {
            la.Pan_Number__c = 'ABCDE1234F';
        }
        if (doInsert) insert la;
        return la;
    }

    // Common PAN API success response payload
    private static String successResponse(String messageVal) {
        return JSON.serialize(new Map<String, Object>{
            'message' => messageVal,
            'statusCode' => 200,
            'result' => new Map<String, Object>{
                'name' => 'TEST APPLICANT',
                'firstName' => 'TEST',
                'middleName' => 'MID',
                'lastName' => 'APPLICANT',
                'fatherName' => 'FATHER TEST',
                'dateOfBirth' => '01-01-1990',
                'typeOfHolder' => 'INDIVIDUAL',
                'gender' => 'MALE',
                'isIndividual' => true,
                'category' => 'Some Category',
                'maskedAadhaarNumber' => 'XXXX-XXXX-1234',
                'emailId' => 'test@example.com',
                'mobileNumber' => '9999999999',
                'aadhaarLinked' => true
            }
        });
    }

    // Error style response where result exists but code != 200 or message indicates failure
    private static String failureResultBody() {
        return JSON.serialize(new Map<String, Object>{
            'message' => 'Invalid PAN',
            'statusCode' => 400,
            'result' => new Map<String, Object>{
                'message' => 'Invalid PAN entered',
                'statusCode' => 400
            }
        });
    }

    // Response missing 'result' key entirely
    private static String noResultBody() {
        return JSON.serialize(new Map<String, Object>{
            'message' => 'Some server error',
            'statusCode' => 500
        });
    }

    @IsTest
    static void testBlankPanReturnsMessage() {
        // Applicant without PAN
        Loan_Applicant__c la = makeApplicant(false, true);

        Test.startTest();
        // Since code short-circuits before callout when PAN is blank, no mock needed.
        String message = SHF_PAN_Service.validatePANNumber(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, message, 'Message should be returned when PAN is blank');
        // It should not have created verification or updated flags
        Loan_Applicant__c laAfter = [SELECT Id, Pan_Verification__c, Is_Pan_Verified__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertEquals(null, laAfter.Pan_Verification__c, 'No verification should be linked when PAN blank');
        System.assertEquals(false, laAfter.Is_Pan_Verified__c, 'Is_Pan_Verified__c should remain false');
    }

    @IsTest
    static void testPanFoundSuccess200() {
        // Applicant with PAN
        Loan_Applicant__c la = makeApplicant(true, true);

        // Mock a full success 200 with "PAN Number FOUND"
        String body = successResponse('PAN Number FOUND');
        Test.setMock(HttpCalloutMock.class, new FakeHttpCalloutMock(200, body));

        Test.startTest();
        String message = SHF_PAN_Service.validatePANNumber(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, message, 'Message should be set from API response');
        // Verify E_Verification__c inserted and applicant updated
        Loan_Applicant__c laAfter = [SELECT Id, Pan_Verification__c, Is_Pan_Verified__c, Date_of_Birth__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertNotEquals(null, laAfter.Pan_Verification__c, 'Verification should be created and linked');
        System.assertEquals(true, laAfter.Is_Pan_Verified__c, 'Should be true when message indicates PAN found');
        System.assertEquals(Date.newInstance(1990, 1, 1), laAfter.Date_of_Birth__c, 'DOB should be parsed and set from response');

        E_Verification__c ev = [
            SELECT Id, PAN_Full_Name__c, PAN_First_Name__c, PAN_Middle_Name__c, PAN_Last_Name__c,
                   PAN_Father_Name__c, Date_of_Birth__c, Type_Of_Holder__c, Gender__c, Is_Individual__c,
                   Category__c, Masked_Aadhar_No__c, Email__c, Mobile__c, Aadhar_linked__c, Error_Message__c, Warning_Code__c
            FROM E_Verification__c WHERE Id = :laAfter.Pan_Verification__c
        ];
        System.assertEquals('TEST APPLICANT', ev.PAN_Full_Name__c);
        System.assertEquals('TEST', ev.PAN_First_Name__c);
        System.assertEquals('MID', ev.PAN_Middle_Name__c);
        System.assertEquals('APPLICANT', ev.PAN_Last_Name__c);
        System.assertEquals('FATHER TEST', ev.PAN_Father_Name__c);
        System.assertEquals(Date.newInstance(1990, 1, 1), ev.Date_of_Birth__c);
        System.assertEquals('INDIVIDUAL', ev.Type_Of_Holder__c);
        System.assertEquals('MALE', ev.Gender__c);
        System.assertEquals(true, ev.Is_Individual__c);
        System.assertEquals('Some Category', ev.Category__c);
        System.assertEquals('XXXX-XXXX-1234', ev.Masked_Aadhar_No__c);
        System.assertEquals('test@example.com', ev.Email__c);
        System.assertEquals('9999999999', ev.Mobile__c);
        System.assertEquals(true, ev.Aadhar_linked__c);
        System.assertEquals('PAN Number FOUND', ev.Error_Message__c, 'The code maps message into Error_Message__c');
        System.assertEquals('200', ev.Warning_Code__c, 'statusCode stored as string');
    }

    @IsTest
    static void testPanResultPresentButFailureBranch() {
        // Applicant with PAN
        Loan_Applicant__c la = makeApplicant(true, true);

        // Mock a response with result present but code != 200
        String body = failureResultBody();
        Test.setMock(HttpCalloutMock.class, new FakeHttpCalloutMock(200, body));

        Test.startTest();
        String message = SHF_PAN_Service.validatePANNumber(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, message, 'Failure message from metadata should be returned');
        Loan_Applicant__c laAfter = [SELECT Id, Pan_Verification__c, Is_Pan_Verified__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertNotEquals(null, laAfter.Pan_Verification__c, 'Verification should be created even on failure branch');
        System.assertEquals(false, laAfter.Is_Pan_Verified__c, 'Should not be verified on failure branch');

        E_Verification__c ev = [
            SELECT Id, Failed_Reason__c, Error_Message__c, Warning_Code__c, Status__c
            FROM E_Verification__c WHERE Id = :laAfter.Pan_Verification__c
        ];
        System.assertEquals('Invalid PAN entered', ev.Failed_Reason__c);
        System.assertEquals('Invalid PAN entered', ev.Error_Message__c);
        System.assertEquals('400', ev.Warning_Code__c);
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c);
    }

    @IsTest
    static void testPanNoResultBranch() {
        // Applicant with PAN
        Loan_Applicant__c la = makeApplicant(true, true);

        // Mock with no 'result' key at all
        String body = noResultBody();
        Test.setMock(HttpCalloutMock.class, new FakeHttpCalloutMock(200, body));

        Test.startTest();
        String message = SHF_PAN_Service.validatePANNumber(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, message, 'Generic error message should be returned');
        Loan_Applicant__c laAfter = [SELECT Id, Pan_Verification__c, Is_Pan_Verified__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertNotEquals(null, laAfter.Pan_Verification__c, 'Verification should be created in no-result branch');
        System.assertEquals(false, laAfter.Is_Pan_Verified__c, 'Should not be verified');

        E_Verification__c ev = [
            SELECT Id, Failed_Reason__c, Status__c
            FROM E_Verification__c WHERE Id = :laAfter.Pan_Verification__c
        ];
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c);
        System.assertNotEquals(null, ev.Failed_Reason__c, 'Failed reason populated from PAN_API_Issue/Error metadata');
    }

    @IsTest
    static void testHttpNon200TopLevel() {
        // Applicant with PAN
        Loan_Applicant__c la = makeApplicant(true, true);

        // Simulate top-level non-200 HTTP status (service returns 500)
        // Our Fake mock returns statusCode as given with that body.
        String body = JSON.serialize(new Map<String, Object>{
            'message' => 'Upstream error',
            'statusCode' => 500
        });
        Test.setMock(HttpCalloutMock.class, new FakeHttpCalloutMock(500, body));

        Test.startTest();
        String message = SHF_PAN_Service.validatePANNumber(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, message, 'PAN_API_Issue message should be returned');
        Loan_Applicant__c laAfter = [SELECT Id, Pan_Verification__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertNotEquals(null, laAfter.Pan_Verification__c, 'Verification should still be created');

        E_Verification__c ev = [SELECT Id, Status__c FROM E_Verification__c WHERE Id = :laAfter.Pan_Verification__c];
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c);
    }

    @IsTest
    static void testExceptionRollbackHandled() {
        // This test exercises the catch block and rollback path by causing an exception after savepoint.
        Loan_Applicant__c la = makeApplicant(true, true);

        // Create a body that will cause an exception: make dateOfBirth malformed to hit else branch logging, still should not throw.
        // To force an exception, we can craft a large body and then in verification insertion we will cause a DML error by exceeding field length.
        // Instead, simpler approach: return a body that is not valid JSON to cause JSON.deserializeUntyped to throw.
        String invalidJson = '{message:"PAN Number FOUND", statusCode:200, result:{}}'; // invalid because keys not quoted properly.

        Test.setMock(HttpCalloutMock.class, new FakeHttpCalloutMock(200, invalidJson));

        Test.startTest();
        // Should handle exception and not throw out of method
        String message = SHF_PAN_Service.validatePANNumber(la.Id);
        Test.stopTest();

        // Even on exception, method returns a string (may be empty), but must not throw.
        System.assertNotEquals(null, message, 'Method should safely return a message even on exception');
    }
}