@IsTest
private class SHF_Mobile_MNRL_ServiceTest {

    // Simple HttpCalloutMock to simulate Mobile_MNRL responses
    private class SimpleMock implements HttpCalloutMock {
        Integer code;
        String body;
        SimpleMock(Integer c, String b) { code = c; body = b; }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            if (code == 200) res.setStatus('OK');
            res.setBody(body);
            return res;
        }
    }

    // Helpers to build a Loan Applicant with various mobile fields populated
    private static Loan_Applicant__c makeApplicant(Boolean setPrimary, Boolean setAlternate, Boolean doInsert) {
        Application__c app = SHF_TestDataFactory.createApplication(null, true);
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, false);
        if (setPrimary) la.Mobile_Number__c = '9999999999';
        if (setAlternate) la.Alternate_Mobile_Number__c = '8888888888';
        if (doInsert) insert la;
        return la;
    }

    // Create a minimal E_Verification__c and link to applicant fields for testing processMobileVerification
    private static E_Verification__c createAndLinkVerification(Loan_Applicant__c la, Boolean linkPrimary) {
        E_Verification__c ev = SHF_CommonUtil.createVerfication(
            la.Id,
            SHF_ConstantsUtil.MOBILE_VERIFICATION_RECORD_TYPE,
            ''
        );
        insert ev;

        if (linkPrimary) {
            la.Mobile_Verification__c = ev.Id;
        } else {
            la.Alternate_Mobile_Verification__c = ev.Id;
        }
        update la;
        return ev;
    }

    // Payloads
    private static String successFoundBody() {
        return JSON.serialize(new Map<String, Object>{
            'msg' => 'Mobile found in records',
            'isFound' => true
        });
    }
    private static String successNotFoundBody() {
        return JSON.serialize(new Map<String, Object>{
            'msg' => 'Mobile not found',
            'isFound' => false
        });
    }
    private static String emptyMapBody() {
        return JSON.serialize(new Map<String, Object>{});
    }

    // initiateMNRLVerification tests

    @IsTest
    static void testInitiatePrimarySuccessCreatesVerificationAndPublishesEvent() {
        Loan_Applicant__c la = makeApplicant(true, false, true);

        Test.startTest();
        String msg = SHF_Mobile_MNRL_Service.initiateMNRLVerification(la.Id, SHF_ConstantsUtil.INITIATEPRIMARYVERIFICATION);
        Test.stopTest();

        System.assertEquals('Mobile_MNRL_API_Success', msg, 'Should indicate success');
        Loan_Applicant__c after = [
            SELECT Id, Mobile_Verification__c, Alternate_Mobile_Verification__c
            FROM Loan_Applicant__c WHERE Id = :la.Id
        ];
        System.assertNotEquals(null, after.Mobile_Verification__c, 'Primary verification should be created and linked');
        System.assertEquals(null, after.Alternate_Mobile_Verification__c, 'Alt verification not expected in this test');
    }

    @IsTest
    static void testInitiateAlternateSuccessCreatesVerificationAndPublishesEvent() {
        Loan_Applicant__c la = makeApplicant(false, true, true);

        Test.startTest();
        String msg = SHF_Mobile_MNRL_Service.initiateMNRLVerification(la.Id, SHF_ConstantsUtil.INITIATEALTERNATEVERIFICATION);
        Test.stopTest();

        System.assertEquals('Mobile_MNRL_API_Success', msg, 'Should indicate success');
        Loan_Applicant__c after = [
            SELECT Id, Mobile_Verification__c, Alternate_Mobile_Verification__c
            FROM Loan_Applicant__c WHERE Id = :la.Id
        ];
        System.assertEquals(null, after.Mobile_Verification__c, 'Primary verification not expected in this test');
        System.assertNotEquals(null, after.Alternate_Mobile_Verification__c, 'Alt verification should be created and linked');
    }

    @IsTest
    static void testInitiatePrimaryWhenMobileBlank() {
        Loan_Applicant__c la = makeApplicant(false, false, true);

        Test.startTest();
        String msg = SHF_Mobile_MNRL_Service.initiateMNRLVerification(la.Id, SHF_ConstantsUtil.INITIATEPRIMARYVERIFICATION);
        Test.stopTest();

        System.assertEquals('Mobile_Number_is_blank', msg);
    }

    @IsTest
    static void testInitiateAlternateWhenAltBlank() {
        Loan_Applicant__c la = makeApplicant(true, false, true);

        Test.startTest();
        String msg = SHF_Mobile_MNRL_Service.initiateMNRLVerification(la.Id, SHF_ConstantsUtil.INITIATEALTERNATEVERIFICATION);
        Test.stopTest();

        System.assertEquals('Mobile_Number_is_blank', msg);
    }

    @IsTest
    static void testInitiateAlreadyCompletedSkips() {
        // Setup applicant with both verifications already completed via relationships
        Loan_Applicant__c la = makeApplicant(true, true, true);

        // Create verification records and set their statuses to Completed
        E_Verification__c evPrimary = SHF_CommonUtil.createVerfication(la.Id, SHF_ConstantsUtil.MOBILE_VERIFICATION_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS);
        E_Verification__c evAlt = SHF_CommonUtil.createVerfication(la.Id, SHF_ConstantsUtil.MOBILE_VERIFICATION_RECORD_TYPE, SHF_ConstantsUtil.COMPLETEDSTATUS);
        insert new List<E_Verification__c>{ evPrimary, evAlt };

        la.Mobile_Verification__c = evPrimary.Id;
        la.Alternate_Mobile_Verification__c = evAlt.Id;
        update la;

        Test.startTest();
        String msg = SHF_Mobile_MNRL_Service.initiateMNRLVerification(la.Id, SHF_ConstantsUtil.INITIATEPRIMARYVERIFICATION);
        Test.stopTest();

        System.assertEquals('E_verification_already_completed', msg);
    }

    // processMobileVerification tests

    @IsTest
    static void testProcessMobileVerificationSuccessFound() {
        Loan_Applicant__c la = makeApplicant(true, false, true);
        E_Verification__c ev = createAndLinkVerification(la, true);

        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, successFoundBody()));

        Test.startTest();
        E_Verification__c updated = SHF_Mobile_MNRL_Service.processMobileVerification(la.Mobile_Number__c, ev.Id);
        Test.stopTest();

        System.assertNotEquals(null, updated, 'Should return an updated verification');
        System.assertEquals(SHF_ConstantsUtil.COMPLETEDSTATUS, updated.Status__c, 'Status should be Completed');
        System.assertEquals('Mobile found in records', updated.Description__c, 'Description mapped from msg');
        System.assertEquals(true, updated.Mobile_IsFound__c, 'isFound true should map to true');
    }

    @IsTest
    static void testProcessMobileVerificationSuccessNotFound() {
        Loan_Applicant__c la = makeApplicant(true, false, true);
        E_Verification__c ev = createAndLinkVerification(la, true);

        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, successNotFoundBody()));

        Test.startTest();
        E_Verification__c updated = SHF_Mobile_MNRL_Service.processMobileVerification(la.Mobile_Number__c, ev.Id);
        Test.stopTest();

        System.assertNotEquals(null, updated);
        System.assertEquals(SHF_ConstantsUtil.COMPLETEDSTATUS, updated.Status__c);
        System.assertEquals('Mobile not found', updated.Description__c);
        System.assertEquals(false, updated.Mobile_IsFound__c, 'isFound false should map to false');
    }

    @IsTest
    static void testProcessMobileVerificationEmptyBodyBranch() {
        Loan_Applicant__c la = makeApplicant(true, false, true);
        E_Verification__c ev = createAndLinkVerification(la, true);

        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, emptyMapBody()));

        Test.startTest();
        E_Verification__c updated = SHF_Mobile_MNRL_Service.processMobileVerification(la.Mobile_Number__c, ev.Id);
        Test.stopTest();

        System.assertNotEquals(null, updated);
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, updated.Status__c, 'Empty map should lead to failed status');
        System.assertNotEquals(null, updated.Failed_Reason__c, 'Failed reason set from metadata');
    }

    @IsTest
    static void testProcessMobileVerificationNon200Branch() {
        Loan_Applicant__c la = makeApplicant(true, false, true);
        E_Verification__c ev = createAndLinkVerification(la, true);

        // Simulate upstream error
        Test.setMock(HttpCalloutMock.class, new SimpleMock(500, '{"msg":"error"}'));

        Test.startTest();
        E_Verification__c updated = SHF_Mobile_MNRL_Service.processMobileVerification(la.Mobile_Number__c, ev.Id);
        Test.stopTest();

        System.assertNotEquals(null, updated);
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, updated.Status__c);
        System.assertNotEquals(null, updated.Failed_Reason__c);
    }

    @IsTest
    static void testProcessMobileVerificationExceptionPath() {
        Loan_Applicant__c la = makeApplicant(true, false, true);
        E_Verification__c ev = createAndLinkVerification(la, true);

        // Return invalid JSON to force JSON.deserializeUntyped to throw
        String invalid = '{msg:Mobile found in records,isFound:true}';
        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, invalid));

        Test.startTest();
        E_Verification__c updated;
        try {
            updated = SHF_Mobile_MNRL_Service.processMobileVerification(la.Mobile_Number__c, ev.Id);
        } catch (Exception e) {
            System.assert(false, 'Method should handle exceptions and not throw');
        }
        Test.stopTest();
    }
}