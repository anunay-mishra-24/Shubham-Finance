@IsTest
private class SHF_GSTVerification_ServiceTest {

    // Simple HTTP mock to simulate the GST API behavior used by SHF_HTTPCalloutService
    private class MockGST implements HttpCalloutMock {
        Integer code;
        String body;
        MockGST(Integer c, String b) { code = c; body = b; }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            if (code == 200) res.setStatus('OK');
            res.setBody(body);
            return res;
        }
    }

    // Helpers
    private static Loan_Applicant__c makeApplicant(Boolean doInsert, String gstNumber) {
        Application__c app = SHF_TestDataFactory.createApplication(null, true);
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, false);
        la.GST_Number__c = String.isBlank(gstNumber) ? '27AAACB2230M1ZL' : gstNumber;
        if (doInsert) insert la;
        return la;
    }

    private static String successWithGstinStatus(String statusVal) {
        return JSON.serialize(new Map<String, Object>{
            'result' => new Map<String, Object>{
                'gstnDetailed' => new Map<String, Object>{
                    'gstinStatus' => statusVal
                }
            }
        });
    }

    private static String successWithoutGstinStatusWithError(String errMsg) {
        // Successful 200 but result doesn't include gstinStatus and includes error wrapper
        return JSON.serialize(new Map<String, Object>{
            'error' => new Map<String, Object>{
                'message' => errMsg
            }
        });
    }

    private static String successWithoutGstinStatusNoErrorWrapper() {
        // Successful 200 but result doesn't include gstnDetailed
        return JSON.serialize(new Map<String, Object>{
            'result' => new Map<String, Object>{}
        });
    }

    @IsTest
    static void testSuccess200_WithGstinStatus_MapsDescriptionAndCommits() {
        Loan_Applicant__c la = makeApplicant(true, '27AAACB2230M1ZL');

        // Mock 200 with gstnDetailed.gstinStatus
        Test.setMock(HttpCalloutMock.class, new MockGST(200, successWithGstinStatus('Active')));

        Test.startTest();
        String msg = SHF_GSTVerification_Service.validateGSTDetails(la.Id);
        Test.stopTest();

        // Message comes from MessageConfigMap.get('GST_API_Success').Message__c in implementation
        System.assertNotEquals(null, msg, 'Should return success message');

        // Verification record created and linked to applicant
        Loan_Applicant__c after = [
            SELECT Id, GST_Verification__c FROM Loan_Applicant__c WHERE Id = :la.Id
        ];
        System.assertNotEquals(null, after.GST_Verification__c, 'GST verification must be linked to applicant');

        E_Verification__c ev = [
            SELECT Id, Description__c, Status__c
            FROM E_Verification__c WHERE Id = :after.GST_Verification__c
        ];
        System.assertEquals('Active', ev.Description__c, 'gstinStatus should be mapped to Description__c');
        System.assertEquals(SHF_ConstantsUtil.COMPLETEDSTATUS, ev.Status__c, 'Verification is created with Completed status');
    }

    @IsTest
    static void testSuccess200_NoGstinStatus_UsesErrorWrapperAndFailed() {
        Loan_Applicant__c la = makeApplicant(true, '27AAACB2230M1ZL');

        // 200 but without gstnDetailed.gstinStatus; include error wrapper to map Error_Message__c
        Test.setMock(HttpCalloutMock.class, new MockGST(200, successWithoutGstinStatusWithError('Some GST error')));

        Test.startTest();
        String msg = SHF_GSTVerification_Service.validateGSTDetails(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, msg, 'Should still return message (success branch sets success message after processing)');

        Loan_Applicant__c after = [SELECT Id, GST_Verification__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertNotEquals(null, after.GST_Verification__c);

        E_Verification__c ev = [
            SELECT Id, Error_Message__c, Status__c
            FROM E_Verification__c WHERE Id = :after.GST_Verification__c
        ];
        System.assertEquals('Some GST error', ev.Error_Message__c, 'Error wrapper message should map to Error_Message__c');
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c, 'Status should be set to Failed when gstinStatus missing');
    }

    @IsTest
    static void testSuccess200_ResultMissingGstnDetailed_SetsFailed() {
        Loan_Applicant__c la = makeApplicant(true, '27AAACB2230M1ZL');

        // 200 with result but missing gstnDetailed, also no error wrapper
        Test.setMock(HttpCalloutMock.class, new MockGST(200, successWithoutGstinStatusNoErrorWrapper()));

        Test.startTest();
        String msg = SHF_GSTVerification_Service.validateGSTDetails(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, msg, 'Message set even if failed path inside 200 branch');

        Loan_Applicant__c after = [SELECT Id, GST_Verification__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertNotEquals(null, after.GST_Verification__c);

        E_Verification__c ev = [
            SELECT Id, Status__c
            FROM E_Verification__c WHERE Id = :after.GST_Verification__c
        ];
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c, 'Missing gstnDetailed should set Failed');
    }

    @IsTest
    static void testNon200_TopLevel_SetsFailedAndReturnsErrorMessage() {
        Loan_Applicant__c la = makeApplicant(true, '27AAACB2230M1ZL');

        // Non-200
        Test.setMock(HttpCalloutMock.class, new MockGST(500, '{"error":{"message":"Server down"}}'));

        Test.startTest();
        String msg = SHF_GSTVerification_Service.validateGSTDetails(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, msg, 'Error message from metadata should be returned for non-200');

        Loan_Applicant__c after = [SELECT Id, GST_Verification__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertNotEquals(null, after.GST_Verification__c);

        E_Verification__c ev = [SELECT Id, Status__c FROM E_Verification__c WHERE Id = :after.GST_Verification__c];
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c);
    }

    @IsTest
    static void testApplicantNotFoundReturnsNull() {
        // Pass a random Id that won't be found
        Id bogusId = '001000000000001AAA'; // 15/18 char fake Id but sufficient for test branch
        Test.startTest();
        String msg = SHF_GSTVerification_Service.validateGSTDetails(bogusId);
        Test.stopTest();
        System.assertEquals(null, msg, 'Should return null if applicant not found');
    }

    @IsTest
    static void testExceptionRollbackHandled() {
        Loan_Applicant__c la = makeApplicant(true, '27AAACB2230M1ZL');

        // Return invalid JSON to trigger exception and test catch/rollback path
        String invalid = '{result:{gstnDetailed:{gstinStatus:Active}}}'; // invalid JSON (keys not quoted)
        Test.setMock(HttpCalloutMock.class, new MockGST(200, invalid));

        Test.startTest();
        String msg;
        try {
            msg = SHF_GSTVerification_Service.validateGSTDetails(la.Id);
        } catch (Exception e) {
            System.assert(false, 'validateGSTDetails should handle exceptions and not throw');
        }
        Test.stopTest();
    }
}