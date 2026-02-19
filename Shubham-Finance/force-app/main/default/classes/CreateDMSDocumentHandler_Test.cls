/**
* @File Name          : CreateDMSDocumentHandler_Test.cls
* @Description        : 
* @Author             : Akshi 
* @Test Class         : 
*==============================================================================
* Ver         Date         Author     Modification
*==============================================================================
* 1.0 
**/

@IsTest
private class CreateDMSDocumentHandler_Test {
    
    @TestSetup
    static void setupData() {
        // Create a dummy ContentVersion so handler can find it later
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Sample content'),
            IsMajorVersion = true
        );
        insert cv;
    }
    
    @IsTest
    static void testAfterInsert_withValidEvent() {
        // Get the ContentDocumentId from inserted ContentVersion
        ContentVersion cv = [
            SELECT ContentDocumentId, Id 
            FROM ContentVersion 
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Fire the platform event with Base__c = ContentDocumentId
        Create_DMS_Document__e evt = new Create_DMS_Document__e(
            Base__c = cv.ContentDocumentId,
            Document_Category__c = 'KYC',
            Loan_Application_ID__c = Id.valueOf(UserInfo.getUserId()), // dummy Id just for test
            Document_ID__c = Id.valueOf(UserInfo.getUserId()) // dummy Id
        );
        Database.SaveResult sr = EventBus.publish(evt);
        
        Test.stopTest(); 
        
        System.assert(sr.isSuccess(), 'Event should be published successfully');
    }
    
    @IsTest
    static void testAfterInsert_withNoMatchingContentVersion() {
        Test.startTest();
        
        // Event with a Base__c that doesn't exist in ContentVersion
        Create_DMS_Document__e evt = new Create_DMS_Document__e(
            Base__c = '999999999999AAA',
            Document_Category__c = 'Income',
            Loan_Application_ID__c = Id.valueOf(UserInfo.getUserId()),
            Document_ID__c = Id.valueOf(UserInfo.getUserId())
        );
        Database.SaveResult sr = EventBus.publish(evt);
        
        Test.stopTest();
        
        System.assert(sr.isSuccess(), 'Event without matching ContentVersion should still succeed');
    }
}