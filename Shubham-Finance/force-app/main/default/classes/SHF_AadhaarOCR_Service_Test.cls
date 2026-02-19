@IsTest
private class SHF_AadhaarOCR_Service_Test {

    private class AadhaarOCRMock implements HttpCalloutMock {

        Integer code;
        String body;

        AadhaarOCRMock(Integer status, String responseBody){
            code = status;
            body = responseBody;
        }

        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setHeader('Content-Type','application/json');
            res.setBody(body);
            return res;
        }
    }

    private static void createAadhaarDoc(Id applicantId){

        Document_Checklist__c dc = new Document_Checklist__c(
            Name = 'Aadhaar card'
        );
        insert dc;

        Document__c doc = new Document__c(
            Loan_Applicant__c = applicantId,
            Document_Checklist__c = dc.Id
        );
        insert doc;

        ContentVersion cv = new ContentVersion(
            Title = 'Aadhar_Card_Image',
            PathOnClient = 'aadhaar.png',
            VersionData = Blob.valueOf('data:image/png;base64,TESTDATA'),
            IsMajorVersion = true
        );
        insert cv;

        cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        insert new ContentDocumentLink(
            LinkedEntityId = doc.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );
    }

    @IsTest
    static void test_AadhaarOCR_Success(){

        Application__c app = SHF_TestDataFactory.createApplication('Test', true);

        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Test', 'User', null, true);
        la.Aadhaar_Verification_Count__c = 5;
        update la;

        createAadhaarDoc(la.Id);

        Test.setMock(
            HttpCalloutMock.class,
            new AadhaarOCRMock(
                200,
                '{"name":"John Doe","address":"Street 1","pincode":"560001","gender":"Male"}'
            )
        );

        Test.startTest();
        String msg = SHF_AadhaarOCR_Service.initiateAadhaarOCR(la.Id);
        Test.stopTest();

        System.assertNotEquals(null, msg,'Message should be returned');

        E_Verification__c ev = [
            SELECT Aadhaar_Full_Name__c, Address_Details__c,
                   Gender__c, Pincode__c, Status__c
            FROM E_Verification__c
            WHERE Loan_Applicant__c = :la.Id
            LIMIT 1
        ];

        System.assertEquals('John Doe', ev.Aadhaar_Full_Name__c);
        System.assertEquals('Street 1', ev.Address_Details__c);
        System.assertEquals('560001', ev.Pincode__c);
        System.assertEquals('Male', ev.Gender__c);
        System.assertEquals(SHF_ConstantsUtil.COMPLETEDSTATUS, ev.Status__c);
    }

    @IsTest
    static void test_AadhaarOCR_Failure(){

        Application__c app = SHF_TestDataFactory.createApplication('Test', true);

        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Fail', 'Case', null, true);
        la.Aadhaar_Verification_Count__c = 5;
        update la;

        createAadhaarDoc(la.Id);

        Test.setMock(
            HttpCalloutMock.class,
            new AadhaarOCRMock(500,'Internal Error')
        );

        Test.startTest();
        String msg = SHF_AadhaarOCR_Service.initiateAadhaarOCR(la.Id);
        Test.stopTest();

        System.assertNotEquals(null,msg);

        E_Verification__c ev = [
            SELECT Status__c, Failed_Reason__c
            FROM E_Verification__c
            WHERE Loan_Applicant__c = :la.Id
            LIMIT 1
        ];

        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c);
        System.assertNotEquals(null, ev.Failed_Reason__c);
    }

    @IsTest
    static void test_VerificationLimitStopsCallout(){

        Application__c app = SHF_TestDataFactory.createApplication('Test', true);

        Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id, 'Low', 'Count', null, true);
        la.Aadhaar_Verification_Count__c = 1;
        update la;

        createAadhaarDoc(la.Id);

        Test.startTest();
        String msg = SHF_AadhaarOCR_Service.initiateAadhaarOCR(la.Id);
        Test.stopTest();

        System.assertNotEquals(null,msg);

        Integer countEV = [
            SELECT COUNT() FROM E_Verification__c WHERE Loan_Applicant__c = :la.Id
        ];

        System.assertEquals(0, countEV,'No verification should be created');
    }

    @IsTest
    static void test_NoApplicant(){

        Test.startTest();
        String msg = SHF_AadhaarOCR_Service.initiateAadhaarOCR(UserInfo.getUserId());
        Test.stopTest();

        System.assertEquals(null,msg);
    }

}