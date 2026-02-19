@IsTest
public class SHF_VoterIdVerification_Service_Test {
    
    // ---------------- MOCKS ----------------
    
    // Mock for Access Token Generation - Success
    private class MockAccessTokenSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"id":"test-access-token-123","userId":"user123"}');
            return res;
        }
    }
    
    // Mock for Voter ID Verification - Success with valid result
    private class MockVoterIdSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"response":{"result":{"verification":"verified","message":"Voter ID verified successfully"}}}');
            return res;
        }
    }
    
    // Mock for Voter ID Verification - Failed with error in result
    private class MockVoterIdFailedResult implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"response":{"error":"Invalid Voter ID"}}');
            return res;
        }
    }
    
    // Mock for Non-200 Status Code
    private class MockVoterIdNon200 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }
    
    // Mock for Access Token Generation - Returns blank
    private class MockAccessTokenBlank implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }
    
    // Multi-Mock to handle both Access Token and Voter ID calls
    private class MultiMockSuccess implements HttpCalloutMock {
        private Integer callCount = 0;
        
        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            
            // First call is for Access Token
            if (callCount == 1) {
                res.setBody('{"id":"test-access-token-123","userId":"user123"}');
            } 
            // Second call is for Voter ID Verification
            else {
                res.setBody('{"response":{"result":{"verification":"verified","message":"Voter ID verified successfully"}}}');
            }
            return res;
        }
    }
    
    private class MultiMockFailedResult implements HttpCalloutMock {
        private Integer callCount = 0;
        
        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            
            if (callCount == 1) {
                res.setBody('{"id":"test-access-token-123","userId":"user123"}');
            } else {
                res.setBody('{"response":{"error":"Invalid Voter ID"}}');
            }
            return res;
        }
    }
    
    private class MultiMockNon200 implements HttpCalloutMock {
        private Integer callCount = 0;
        
        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            
            if (callCount == 1) {
                res.setStatusCode(200);
                res.setBody('{"id":"test-access-token-123","userId":"user123"}');
            } else {
                res.setStatusCode(500);
                res.setBody('{"error":"Internal Server Error"}');
            }
            return res;
        }
    }
    
    private class MultiMockAccessTokenBlank implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }
    
    // ---------------- TEST METHODS ----------------
    
    @IsTest
    static void testVoterIdVerification_Success_WithAddress() {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '27AAACB2230M1ZL', true);
        applicant.Voter_Id_Number__c = 'ABC1234567';
        update applicant;
        
        Address__c address = SHF_TestDataFactory.createAddress(applicant.Id, 'Test Address Line 1', 'Test Address', 'Delhi', 'Delhi', true);
        
        Test.setMock(HttpCalloutMock.class, new MultiMockSuccess());
        
        Test.startTest();
        String msg = SHF_VoterIdVerification_Service.voterIdVerification(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, msg, 'Message should not be null');
        
        E_Verification__c ev = [
            SELECT Id, Verification__c, Description__c, Status__c, Loan_Applicant__c
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id 
            LIMIT 1
        ];
        System.assertEquals('verified', ev.Verification__c, 'Verification field should be set');
        System.assertEquals('Voter ID verified successfully', ev.Description__c, 'Description should match');
        System.assertEquals(SHF_ConstantsUtil.COMPLETEDSTATUS, ev.Status__c, 'Status should be completed');
        
        Loan_Applicant__c updatedApplicant = [SELECT Id, VoterId_Verification__c FROM Loan_Applicant__c WHERE Id = :applicant.Id];
        System.assertEquals(ev.Id, updatedApplicant.VoterId_Verification__c, 'Loan Applicant should be linked to E_Verification');
    }
    
    @IsTest
    static void testVoterIdVerification_Success_WithoutAddress() {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '27AAACB2230M1ZL', true);
        applicant.Voter_Id_Number__c = 'ABC1234567';
        update applicant;
        
        Test.setMock(HttpCalloutMock.class, new MultiMockSuccess());
        
        Test.startTest();
        String msg = SHF_VoterIdVerification_Service.voterIdVerification(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, msg, 'Message should not be null');
        
        E_Verification__c ev = [
            SELECT Id, Verification__c, Description__c, Status__c 
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id 
            LIMIT 1
        ];
        System.assertEquals('verified', ev.Verification__c, 'Verification should be set even without address');
        System.assertEquals(SHF_ConstantsUtil.COMPLETEDSTATUS, ev.Status__c, 'Status should be completed');
    }
    
    @IsTest
    static void testVoterIdVerification_FailedResult() {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '27AAACB2230M1ZL', true);
        applicant.Voter_Id_Number__c = 'ABC1234567';
        update applicant;
        
        Test.setMock(HttpCalloutMock.class, new MultiMockFailedResult());
        
        Test.startTest();
        String msg = SHF_VoterIdVerification_Service.voterIdVerification(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, msg, 'Error message should not be null');
        
        E_Verification__c ev = [
            SELECT Id, Status__c 
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id 
            LIMIT 1
        ];
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c, 'Status should be failed when error in result');
    }
    
    @IsTest
    static void testVoterIdVerification_Non200Status() {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '27AAACB2230M1ZL', true);
        applicant.Voter_Id_Number__c = 'ABC1234567';
        update applicant;
        
        Test.setMock(HttpCalloutMock.class, new MultiMockNon200());
        
        Test.startTest();
        String msg = SHF_VoterIdVerification_Service.voterIdVerification(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, msg, 'Error message should not be null');
        
        E_Verification__c ev = [
            SELECT Id, Status__c 
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id 
            LIMIT 1
        ];
        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c, 'Status should be failed for non-200 status code');
    }
    
    @IsTest
    static void testVoterIdVerification_BlankAccessToken() {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '27AAACB2230M1ZL', true);
        applicant.Voter_Id_Number__c = 'ABC1234567';
        update applicant;
        
        Test.setMock(HttpCalloutMock.class, new MultiMockAccessTokenBlank());
        
        Test.startTest();
        String msg = SHF_VoterIdVerification_Service.voterIdVerification(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, msg, 'Error message should be returned when access token is blank');
        
        List<E_Verification__c> evList = [
            SELECT Id 
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id
        ];
        System.assertEquals(0, evList.size(), 'No E_Verification record should be created when access token is blank');
    }
    
    @IsTest
    static void testVoterIdVerification_ApplicantNotFound() {
        Test.setMock(HttpCalloutMock.class, new MultiMockSuccess());
        
        Test.startTest();
        String msg = SHF_VoterIdVerification_Service.voterIdVerification('a0B000000000000AAA');
        Test.stopTest();
        
        System.assertEquals(null, msg, 'Should return null when applicant not found');
    }
    
    @IsTest
    static void testVoterIdVerification_WithBlankVoterIdNumber() {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '27AAACB2230M1ZL', true);
        
        Test.setMock(HttpCalloutMock.class, new MultiMockSuccess());
        
        Test.startTest();
        String msg = SHF_VoterIdVerification_Service.voterIdVerification(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, msg, 'Message should not be null even with blank Voter ID');
        
        E_Verification__c ev = [
            SELECT Id, Status__c 
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id 
            LIMIT 1
        ];
        System.assertNotEquals(null, ev, 'E_Verification record should be created');
    }
    
    @IsTest
    static void testVoterIdVerification_WithBlankAddressState() {
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '27AAACB2230M1ZL', true);
        applicant.Voter_Id_Number__c = 'ABC1234567';
        update applicant;
        
        Address__c address = SHF_TestDataFactory.createAddress(applicant.Id, 'Test Address Line 1', 'Test Address', 'Delhi', null, true);
        
        Test.setMock(HttpCalloutMock.class, new MultiMockSuccess());
        
        Test.startTest();
        String msg = SHF_VoterIdVerification_Service.voterIdVerification(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, msg, 'Message should not be null');
        
        E_Verification__c ev = [
            SELECT Id, Status__c 
            FROM E_Verification__c 
            WHERE Loan_Applicant__c = :applicant.Id 
            LIMIT 1
        ];
        System.assertEquals(SHF_ConstantsUtil.COMPLETEDSTATUS, ev.Status__c, 'Should complete successfully even with blank state');
    }
}