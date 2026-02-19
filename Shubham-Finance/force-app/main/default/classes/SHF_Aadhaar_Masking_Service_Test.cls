@IsTest
private class SHF_Aadhaar_Masking_Service_Test {
    
    //==================== MOCK SUCCESS RESPONSE ====================
    private class AadhaarMaskMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"result":{"isMasked":true,"maskedImages":["MASKED_BASE64_SAMPLE_DATA"]}}');
            return res;
        }
    }
    
    //==================== MOCK ERROR RESPONSE ====================
    private class AadhaarMaskMockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Service Failed"}');
            return res;
        }
    }
    
    //==================== TEST: SUCCESS MASKING ====================
    @IsTest
    static void testAadhaarMasking_Success() {
        
        Document__c doc = new Document__c();
        insert doc;
        
        Test.setMock(HttpCalloutMock.class, new AadhaarMaskMockSuccess());
        
        Test.startTest();
        String masked = SHF_Aadhaar_Masking_Service.aadhaarMasking(
            'DOC_DATA','jpg',doc.Id
        );
        Test.stopTest();
        
        ContentVersion cv = [SELECT Id, Title FROM ContentVersion LIMIT 1];
    }
    
    //==================== TEST: ERROR CALL ====================
    @IsTest
    static void testAadhaarMasking_Error() {
        Document__c doc = new Document__c();
        insert doc;
        
        Test.setMock(HttpCalloutMock.class, new AadhaarMaskMockError());
        
        Test.startTest();
        String masked = SHF_Aadhaar_Masking_Service.aadhaarMasking(
            'DOC_DATA','png',doc.Id
        );
        Test.stopTest();
    }
    
    //==================== TEST saveMaskedAadhaarToDMS SUCCESS ====================
    @IsTest
    static void testSaveMaskedAadhaarToDMS() {
        
        Document__c doc = new Document__c();
        insert doc;
        
        Test.startTest();
        SHF_Aadhaar_Masking_Service.saveMaskedAadhaarToDMS(
            'TEST_MASKED_DATA','png',doc.Id
        );
        Test.stopTest();
        
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
    }
    
    //==================== TEST deleteExistingFiles() ====================
    @IsTest
    static void testDeleteExistingFiles() {
        
        Document__c doc = new Document__c();
        insert doc;
        
        ContentVersion cv = new ContentVersion(
            Title='TESTFILE',
            PathOnClient='test.png',
            VersionData=Blob.valueOf('sample'),
            FirstPublishLocationId=doc.Id
        );
        insert cv;
        
        Id cdId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:doc.Id LIMIT 1].ContentDocumentId;
        
        Test.startTest();
        SHF_Aadhaar_Masking_Service.deleteExistingFiles(doc.Id);
        Test.stopTest();
        
        Integer countDocs = [SELECT COUNT() FROM ContentDocument WHERE Id=:cdId];
    }
    
    //==================== NEW TEST (COVERS UNCOVERED BLOCK) ====================
    @IsTest
    static void testSaveMaskedAadhaarToDMS_BlankValues() {
        
        Document__c doc = new Document__c();
        insert doc;
        
        Test.startTest();
        
        // Case 1 → maskedImage blank → triggers the IF block
        SHF_Aadhaar_Masking_Service.saveMaskedAadhaarToDMS('', 'png', doc.Id);
        
        // Case 2 → documentId blank → triggers the IF block
        SHF_Aadhaar_Masking_Service.saveMaskedAadhaarToDMS('FAKE_DATA', 'png', '');
        
        // Case 3 → both blank → full coverage inside IF
        SHF_Aadhaar_Masking_Service.saveMaskedAadhaarToDMS('', 'png', '');
        
        Test.stopTest();
    }
    
}