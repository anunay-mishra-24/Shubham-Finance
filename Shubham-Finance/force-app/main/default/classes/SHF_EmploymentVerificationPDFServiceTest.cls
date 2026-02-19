@IsTest
private class SHF_EmploymentVerificationPDFServiceTest {

    private class MockPDFResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('GET', req.getMethod(), 'Expected GET method');
            
            Blob pdfBlob = Blob.valueOf('Dummy PDF content');
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/pdf');
            res.setBodyAsBlob(pdfBlob);
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockFailedResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('Not Found');
            return res;
        }
    }

    @IsTest
    static void testProcessPDF_Success() {
      
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '22AAAAA0000A1Z5', true);

        Test.setMock(HttpCalloutMock.class, new MockPDFResponse());
        Test.startTest();
        Map<String, Object> result = SHF_Employment_Verification_PDF_Service.processEmploymentVerificationPDF(
            applicant.Id,
            'https://example.com/test.pdf'
        );
        Test.stopTest();

        System.assert(result.containsKey('isSuccess') && result.containsKey('message'), 'Result must contain isSuccess and message');
        System.assert((Boolean)result.get('isSuccess'), 'Expected success = true');
        System.assertEquals('PDF downloaded successfully.', (String)result.get('message'), 'Success message mismatch');

        System.assertNotEquals(null, result.get('documentId'), 'Document Id should not be null');
        System.assertNotEquals(null, result.get('base64Pdf'), 'Base64 PDF should not be null');

        Id createdDocId = (Id)result.get('documentId');
        Document__c doc = [
            SELECT Id, Loan_Applicant__c, Application__c, File_Name__c, Status__c
            FROM Document__c
            WHERE Id = :createdDocId
            LIMIT 1
        ];
        System.assertEquals('Uploaded', doc.Status__c, 'Document status should be Uploaded');
        System.assertEquals(applicant.Id, doc.Loan_Applicant__c, 'Document applicant mismatch');
        System.assertEquals(app.Id, doc.Application__c, 'Document application mismatch');
    }

    @IsTest
    static void testProcessPDF_NoLink() {
 
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '22AAAAA0000A1Z5', true);

        Test.startTest();
        Map<String, Object> result = SHF_Employment_Verification_PDF_Service.processEmploymentVerificationPDF(
            applicant.Id,
            null
        );
        Test.stopTest();

        System.assert(result.containsKey('isSuccess') && result.containsKey('message'), 'Result must contain isSuccess and message');
        System.assertEquals(false, (Boolean)result.get('isSuccess'));
        System.assertEquals('No PDF link provided.', (String)result.get('message'));
        System.assertEquals(null, result.get('documentId'), 'documentId should be null on failure');
        System.assertEquals(null, result.get('base64Pdf'), 'base64Pdf should be null on failure');
    }

    @IsTest
    static void testProcessPDF_ApplicantNotFound() {
   
        Test.startTest();
        Map<String, Object> result = SHF_Employment_Verification_PDF_Service.processEmploymentVerificationPDF(
            Id.valueOf('003000000000000AAA'), // Nonexistent Id
            'https://example.com/test.pdf'
        );
        Test.stopTest();

        System.assert(result.containsKey('isSuccess') && result.containsKey('message'), 'Result must contain isSuccess and message');
        System.assertEquals(false, (Boolean)result.get('isSuccess'));
        System.assertEquals('Loan Applicant not found.', (String)result.get('message'));
        System.assertEquals(null, result.get('documentId'), 'documentId should be null on failure');
        System.assertEquals(null, result.get('base64Pdf'), 'base64Pdf should be null on failure');
    }

    @IsTest
    static void testProcessPDF_FailedDownload() {
        // Arrange
        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'Applicant', '22AAAAA0000A1Z5', true);

        // Act
        Test.setMock(HttpCalloutMock.class, new MockFailedResponse());
        Test.startTest();
        Map<String, Object> result = SHF_Employment_Verification_PDF_Service.processEmploymentVerificationPDF(
            applicant.Id,
            'https://example.com/missing.pdf'
        );
        Test.stopTest();

        System.assert(result.containsKey('isSuccess') && result.containsKey('message'), 'Result must contain isSuccess and message');
        System.assertEquals(false, (Boolean)result.get('isSuccess'));
        System.assert(
            ((String) result.get('message')).contains('Failed to download PDF'),
            'Expected message to mention failed download'
        );
        System.assertEquals(null, result.get('documentId'), 'documentId should be null on failure');
        System.assertEquals(null, result.get('base64Pdf'), 'base64Pdf should be null on failure');
    }
}