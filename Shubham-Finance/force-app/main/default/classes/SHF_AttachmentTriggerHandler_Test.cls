@isTest
public class SHF_AttachmentTriggerHandler_Test {

    private static String getValidStatusValue() {
        Schema.DescribeFieldResult f = Document__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> entries = f.getPicklistValues();
        return entries[0].getValue(); 
    }

    @isTest
    static void test_updateCreatedDocumentStatus() {

        String validStatus = getValidStatusValue();

        Document__c doc = new Document__c(
            Status__c = validStatus
        );
        insert doc;

        Attachment att = new Attachment(
            Name = 'Test Attachment',
            Body = Blob.valueOf('test'),
            ParentId = doc.Id
        );
        insert att;

        List<Attachment> newList = [
            SELECT Id, ParentId
            FROM Attachment
            WHERE ParentId = :doc.Id
        ];

        Test.startTest();
        SHF_AttachmentTriggerHandler.updateCreatedDocumentStatus(newList);
        Test.stopTest();

        Document__c updatedDoc = [
            SELECT Status__c
            FROM Document__c
            WHERE Id = :doc.Id
        ];

        System.assertEquals('Uploaded', updatedDoc.Status__c);
    }

    @isTest
    static void test_noUpdateWhenNonDocumentParent() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Attachment att = new Attachment(
            Name = 'Test Attachment',
            Body = Blob.valueOf('test'),
            ParentId = acc.Id
        );
        insert att;

        List<Attachment> newList = [
            SELECT Id, ParentId
            FROM Attachment
            WHERE ParentId = :acc.Id
        ];

        Test.startTest();
        SHF_AttachmentTriggerHandler.updateCreatedDocumentStatus(newList);
        Test.stopTest();

        System.assert(true);
    }
}