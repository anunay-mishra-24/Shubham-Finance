/**
* @File Name          : SHF_GSTVerification_Service_Test.cls
* @Description        : Test class to cover SHF_GSTVerification_Service.
* @Author             : Kunal Soni
* 
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         19-08-2025   Kunal Soni   Initial Version
*/
@IsTest
public class SHF_GSTVerification_Service_Test {
   
    // ---------------- MOCKS ----------------
    private class MockGSTSuccessResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{ "result": { "gstnDetailed": { "gstinStatus": "Active" } } }');
            return res;
        }
    }
    
    private class MockGSTErrorResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{ "error": { "message": "Invalid GSTIN" } }');
            return res;
        }
    }
    
    @IsTest
    static void testValidateGSTDetails_Success() {
        // Use factory to insert Application + Loan Applicant
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '22AAAAA0000A1Z5', true);

        Test.setMock(HttpCalloutMock.class, new MockGSTSuccessResponse());
        
        Test.startTest();
        String msg = SHF_GSTVerification_Service.validateGSTDetails(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, msg, 'Message should not be null');
        
        // Verify E_Verification record created
        E_Verification__c ev = [
            SELECT Id, Description__c, Status__c 
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id 
            LIMIT 1
        ];
        System.assertEquals('Active', ev.Description__c, 'Expected gstinStatus to be stored');
        System.assertEquals(SHF_ConstantsUtil.COMPLETEDSTATUS, ev.Status__c, 'Status should be completed');
    }
    
    @IsTest
    static void testValidateGSTDetails_Error() {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '22AAAAA0000A1Z5', true);

        Test.setMock(HttpCalloutMock.class, new MockGSTErrorResponse());
        
        Test.startTest();
        String msg = SHF_GSTVerification_Service.validateGSTDetails(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, msg, 'Error message should not be null');
        
        // Verify E_Verification record created with Failed status
        E_Verification__c ev = [
            SELECT Id, Error_Message__c, Status__c 
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id 
            LIMIT 1
        ];
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c, 'Should be failed when error in API');
        System.assertEquals('Invalid GSTIN', ev.Error_Message__c, 'Error message should come from API');
    }
    
    @IsTest
    static void testValidateGSTDetails_NoApplicant() {
        Test.setMock(HttpCalloutMock.class, new MockGSTSuccessResponse());
        
        Test.startTest();
        String msg = SHF_GSTVerification_Service.validateGSTDetails('001000000000000AAA'); // non-existent applicant Id
        Test.stopTest();
        
        System.assertEquals(null, msg, 'Should return null if applicant not found');
    }
}