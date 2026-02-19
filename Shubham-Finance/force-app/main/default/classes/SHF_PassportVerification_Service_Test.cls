@isTest
public with sharing class SHF_PassportVerification_Service_Test {

    private class mockPassportSuccessResponse implements HttpCalloutMock{
            public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{ "response": { "result": {"verified": "Verified", "message": "Passport verified successfully"} } }');
            return res;
        }
    }

    private class mockPassportErrorResponse implements HttpCalloutMock{
            public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error": {"message": "Invalid passport details"}}');
            return res;
        }
    }

     private static Loan_Applicant__c makeApplicant(Boolean hasPassport, Boolean doInsert) {
        Application__c app = SHF_TestDataFactory.createApplication(null, true);
        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', null, false);
        if (hasPassport) {
            la.Passport_File_Number__c = 'A1234567';
        }
        la.Date_of_Birth__c = Date.newInstance(1995, 6, 15);
        if (doInsert) insert la;
        return la;
    }

    @isTest
    static void testValidatePassportDetails_Success(){
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = makeApplicant(true, true);
 
        Test.setMock(HttpCalloutMock.class, new mockPassportSuccessResponse());
        Test.startTest();
        String message = SHF_PassportVerification_Service.validatePassportDetails(applicant.Id);
        Test.stopTest();

        System.assertNotEquals(null, message, 'Message should not be null');
         
        E_Verification__c ev = [
            SELECT Id, Description__c, Status__c 
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id 
            LIMIT 1
        ];

        System.assertEquals('Verified', ev.Status__c, 'Passport should be marked verified');
        
   }

   @isTest
   static void testValidatePassportDetails_Error(){
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = makeApplicant(false, true);

        Test.setMock(HttpCalloutMock.class, new mockPassportErrorResponse());
        
        Test.startTest();
        String message = SHF_PassportVerification_Service.validatePassportDetails(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, message, 'Error message should not be null');
        
        // Verify E_Verification record created with Failed status
        E_Verification__c ev = [
            SELECT Id, Error_Message__c, Status__c 
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id 
            LIMIT 1
        ];

        System.assertEquals('Failed', ev.Status__c, 'Status should indicate failure');
        System.assert(ev.Error_Message__c.contains('Invalid passport details'), 'Error message should match mock response');
    }

    @isTest
    static void testValidatePassportDetails_NoApplicant() {
        Test.startTest();
        String message = SHF_PassportVerification_Service.validatePassportDetails(null);
        Test.stopTest();

        System.assertEquals(null, message, 'Should return null for missing applicant');
    }
}