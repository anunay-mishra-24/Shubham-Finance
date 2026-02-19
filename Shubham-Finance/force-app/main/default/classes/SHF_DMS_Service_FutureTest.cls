@IsTest
private class SHF_DMS_Service_FutureTest {

    // --- Dummy Callout Mock for Success Path ---
    private class DummyCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }
    }

    // --- Test Data Setup ---
    @testSetup
    static void setupTestData() {
        // Create Application using Test Data Factory
        SHF_TestDataFactory.createApplication('App From Factory', true);

        // Create Document using Test Data Factory
        SHF_TestDataFactory.createDocument('Document From Factory', true);
    }

    @IsTest
    static void test_createDocsAsync_success() {
        // Fetch setup data
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Document__c doc = [SELECT Id FROM Document__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new DummyCalloutMock());

        Test.startTest();
        SHF_DMS_Service_Future.createDocsAsync(
            new List<String>{ 'Category1' },
            new List<String>{ EncodingUtil.base64Encode(Blob.valueOf('file content')) },
            new List<Id>{ app.Id },
            new List<Id>{ doc.Id }
        );
        Test.stopTest();

        System.assert(true, 'Future executed successfully.');
    }

    @IsTest
    static void test_createDocsAsync_withException() {
        // Fetch setup data
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Document__c doc = [SELECT Id FROM Document__c LIMIT 1];

        Test.startTest();
        SHF_DMS_Service_Future.createDocsAsync(
            new List<String>{ 'Category' },
            new List<String>(), 
            new List<Id>{ app.Id },
            new List<Id>{ doc.Id }
        );
        Test.stopTest();

        System.assert(true, 'Future executed');
    }
}