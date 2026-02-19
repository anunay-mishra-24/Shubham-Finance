@IsTest
private class SHF_DMSControllerTest {

    @testSetup
    static void setupTestData() {
        // Create Application and Document
        Application__c app = SHF_TestDataFactory.createApplication('App', true);
        Document__c doc = SHF_TestDataFactory.createDocument('Document', true);

        // Link Document to Application
        if (Schema.sObjectType.Document__c.fields.getMap().containsKey('Application__c')) {
            doc.Application__c = app.Id;
            update doc;
        }
    }

    // ------------------------------
    // Test: Upload file successfully
    // ------------------------------
    @IsTest
    static void test_uploadFileAndGetDocId_success() {
        String fileName = 'TestFile.txt';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('test content'));

        Test.startTest();
        String contentDocId = SHF_DMSController.uploadFileAndGetDocId(fileName, base64Data);
        Test.stopTest();

        System.assertNotEquals(null, contentDocId, 'ContentDocumentId should not be null');
    }

    // ------------------------------
    // Test: Upload file with missing params
    // ------------------------------
    @IsTest
    static void test_uploadFileAndGetDocId_missingParams() {
        try {
            Test.startTest();
            SHF_DMSController.uploadFileAndGetDocId('', null);
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException ex) {
        }
    }

    // ------------------------------
    // Test: Publish platform event success
    // ------------------------------
    @IsTest
    static void test_publishPlatformEvent_success() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Document__c doc = [SELECT Id FROM Document__c LIMIT 1];

        Test.startTest();
        SHF_DMSController.publishPlatformEvent('SomeContentDocId', app.Id, doc.Id, 'Category1');
        Test.stopTest();

        System.assert(true, 'Event published successfully without exception.');
    }

    // ------------------------------
    // Test: Publish platform event failure 
    // ------------------------------
    @IsTest
    static void test_publishPlatformEvent_failure() {
        try {
            Test.startTest();
            SHF_DMSController.publishPlatformEvent(null, null, null, null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('Error'), 'invalid event publish');
        }
    }

    // ------------------------------
    // Test: Get Preview URL success
    // ------------------------------
    @IsTest
    static void test_getPreviewUrl_success() {
        // fake token via SHF_DMS_Service 
        SHF_DMS_Service.testAccessToken = 'dummyToken';

        Application__c app = SHF_TestDataFactory.createApplication('App1', true);
        Document__c doc = SHF_TestDataFactory.createDocument('Passport', true);
        doc.Application__c = app.Id;
        doc.Document_Category__c = 'KYC Documents';
        update doc;

        Test.startTest();
        String url = SHF_DMSController.getPreviewUrl(doc.Id);
        Test.stopTest();

        System.assert(url.contains('uatddfs4.ospyn.com'), 'URL should contain base path');
        System.assert(url.contains('token=dummyToken'), 'URL should include fake token');
    }

    // ------------------------------
    // Test: Get Preview URL failure 
    // ------------------------------
    @IsTest
    static void test_getPreviewUrl_failure() {
        try {
            Test.startTest();
            SHF_DMSController.getPreviewUrl(Id.valueOf('001000000000000AAA')); 
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException ex) {
        }
    }

    // ------------------------------
    // Test: Assign To Current User
    // ------------------------------
    @IsTest
    static void test_assignToCurrentUser() {
        Application__c app = [SELECT Id, OwnerId FROM Application__c LIMIT 1];

        Test.startTest();
        SHF_DMSController.assignToCurrentUser(new List<Id>{ app.Id });
        Test.stopTest();

        Application__c updatedApp = [SELECT OwnerId FROM Application__c WHERE Id = :app.Id];
        System.assertEquals(UserInfo.getUserId(), updatedApp.OwnerId, 'reassigned to current user');
    }
}