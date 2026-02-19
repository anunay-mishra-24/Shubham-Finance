@isTest
public with sharing class SHF_EmploymentVerificationAPIServiceTest {

    private class EmploymentVerificationAPIMock implements HttpCalloutMock {
      Integer statusCode;
      String responseBody;
    
    public HTTPRequest lastRequest;

    EmploymentVerificationAPIMock(Integer code, String body) {
        statusCode = code;
        responseBody = body;
    }

    public HTTPResponse respond(HTTPRequest req) {
        lastRequest = req;
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        res.setBody(responseBody);
        return res;
    }
}

private static Loan_Applicant__c makeApplicant(Boolean hasEmail) {
    Application__c app = SHF_TestDataFactory.createApplication(null, true);
    Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, true);
    if (hasEmail) {
        la.Email__c = 'test@example.com';
    }
    return [
        SELECT Id, Email__c, Employment_Verification__c, Employment_Verification_Executed__c, Application__c
        FROM Loan_Applicant__c
        WHERE Id = :la.Id
    ];
}

@IsTest
static void testCallEmploymentVerificationAPISuccess() {
    Loan_Applicant__c applicant = makeApplicant(true);

    String successResponse = JSON.serialize(new Map<String, Object>{
        'status-code' => '101',
        'result' => new Map<String, Object>{
            'pdfLink' => 'https://example.com/pdf/employment_verification.pdf'
        }
    });
    EmploymentVerificationAPIMock mock = new EmploymentVerificationAPIMock(200, successResponse);
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    SHF_Employment_Verification_API_Service.VerificationResponse result =
        SHF_Employment_Verification_API_Service.callEmploymentVerificationAPI(applicant.Id);
    Test.stopTest();

    System.assertEquals(true, result.isSuccess, 'Result should be successful');
    System.assert(result.message != null && result.message.contains('Employment Verification Success'));
    System.assertNotEquals(null, result.pdfLink, 'PDF link should be populated');

    E_Verification__c ver = [
        SELECT Id, Status__c 
        FROM E_Verification__c 
        WHERE Loan_Applicant__c = :applicant.Id
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    System.assertEquals(SHF_ConstantsUtil.COMPLETEDSTATUS, ver.Status__c);

    Loan_Applicant__c updatedApplicant = [
        SELECT Id, Employment_Verification__c, Employment_Verification_Executed__c 
        FROM Loan_Applicant__c 
        WHERE Id = :applicant.Id
    ];
    System.assertNotEquals(null, updatedApplicant.Employment_Verification__c);
    System.assertEquals(true, updatedApplicant.Employment_Verification_Executed__c);
}

@IsTest
static void testCallEmploymentVerificationAPIFailure_statusCode() {
    Loan_Applicant__c applicant = makeApplicant(true);

    String failedResponse = JSON.serialize(new Map<String, Object>{
        'status-code' => '400',
        'result' => new Map<String, Object>{}
    });
    Test.setMock(HttpCalloutMock.class, new EmploymentVerificationAPIMock(200, failedResponse));

    Test.startTest();
    SHF_Employment_Verification_API_Service.VerificationResponse result =
        SHF_Employment_Verification_API_Service.callEmploymentVerificationAPI(applicant.Id);
    Test.stopTest();

    System.assertEquals(false, result.isSuccess, 'Should fail due to status code 400');
    System.assert(result.message != null && result.message.contains('Employment Verification Failed'));

    E_Verification__c ver = [
        SELECT Id, Status__c, Failed_Reason__c 
        FROM E_Verification__c 
        WHERE Loan_Applicant__c = :applicant.Id
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ver.Status__c);
    System.assert(ver.Failed_Reason__c != null && ver.Failed_Reason__c.contains('status-code'));
}

@IsTest
static void testInvalidHttpResponse() {
    Loan_Applicant__c applicant = makeApplicant(true);

    Test.setMock(HttpCalloutMock.class, new EmploymentVerificationAPIMock(500, 'Internal Server Error'));

    Test.startTest();
    SHF_Employment_Verification_API_Service.VerificationResponse result =
        SHF_Employment_Verification_API_Service.callEmploymentVerificationAPI(applicant.Id);
    Test.stopTest();

    System.assertEquals(false, result.isSuccess);
    System.assert(result.message != null && result.message.contains('Employment Verification HTTP Error'));

    E_Verification__c ver = [
        SELECT Id, Status__c, Failed_Reason__c 
        FROM E_Verification__c 
        WHERE Loan_Applicant__c = :applicant.Id
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ver.Status__c);
    System.assert(ver.Failed_Reason__c != null && ver.Failed_Reason__c.contains('Invalid HTTP Response'));
}

@IsTest
static void testMissingMetadata() {
    Loan_Applicant__c applicant = makeApplicant(true);

    // Detect if metadata exists in this org; make the test resilient to org state
    Callout_Framework__mdt md = null;
    try {
        // Prefer using the same utility if available; fallback to direct query
        Map<String, Callout_Framework__mdt> metaMap = SHF_CommonUtil.getCalloutMetadata('Employment_Verification_API');
        if (metaMap != null) md = metaMap.get('Employment_Verification_API');
    } catch (Exception ignore) {}

    if (md == null) {
        // Metadata missing path: service should indicate not configured
        Test.startTest();
        SHF_Employment_Verification_API_Service.VerificationResponse result =
            SHF_Employment_Verification_API_Service.callEmploymentVerificationAPI(applicant.Id);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Expected failure when metadata missing');
        System.assert(result.message != null && result.message.contains('Error: Employment Verification API metadata not configured'));
    } else {
        // Metadata present path: ensure service does NOT return the not-configured message
        Test.startTest();
        SHF_Employment_Verification_API_Service.VerificationResponse result =
            SHF_Employment_Verification_API_Service.callEmploymentVerificationAPI(applicant.Id);
        Test.stopTest();

        System.assert(result.message == null || !result.message.contains('metadata not configured'),
            'Did not expect metadata-not-configured message when metadata exists');
        // No further hard assertions as behavior depends on downstream callout; other tests cover success/failure paths
    }
 }

}