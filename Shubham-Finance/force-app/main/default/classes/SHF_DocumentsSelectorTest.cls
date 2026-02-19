/**
* @File Name          : SHF_DocumentsSelectorTest.cls
* @Description        : Test class for SHF_DocumentsSelector
* @Author             : Kunal Soni
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         25-09-2025              Kunal Soni              Initial Version
*/
@IsTest
private class SHF_DocumentsSelectorTest {

    @TestSetup
    static void setupTestData() {
        List<Document__c> docs = new List<Document__c>();

        docs.add(new Document__c(
            Name = 'PAN Card',
            Document_Category__c = 'KYC Documents'
        ));
        docs.add(new Document__c(
            Name = 'Aadhar Card',
            Document_Category__c = 'Income Proof'
        ));
        docs.add(new Document__c(
            Name = 'Driving License',
            Document_Category__c = 'Property Documents'
        ));

        insert docs;
    }

    @IsTest
    static void testGetSObjectFieldListAndType() {
        SHF_DocumentsSelector selector = new SHF_DocumentsSelector();

        // Verify fields list
        List<Schema.SObjectField> fields = selector.getSObjectFieldList();
        System.assert(!fields.isEmpty(), 'Field list should not be empty');
        System.assertEquals(Document__c.Id, fields[0], 'First field should be Id');

        // Verify SObject type
        System.assertEquals(Document__c.SObjectType, selector.getSObjectType(), 'SObjectType should be Document__c');
    }

    @IsTest
    static void testSelectByIdsApplicantName() {
        List<Document__c> insertedDocs = [SELECT Id, Name FROM Document__c LIMIT 2];
        Set<Id> ids = new Set<Id>();
        for (Document__c doc : insertedDocs) {
            ids.add(doc.Id);
        }

        SHF_DocumentsSelector selector = new SHF_DocumentsSelector();
        List<Document__c> results = selector.selectByIdsApplicantName(ids);

        System.assertEquals(insertedDocs.size(), results.size(), 'Number of results should match');
        System.assertNotEquals(null, results[0].Name, 'Name field should be populated');
    }

	@IsTest
    static void testSelectByDocumentCategory() {
        SHF_DocumentsSelector selector = new SHF_DocumentsSelector();
        List<Document__c> idProofDocs = selector.selectByDocumentCategory('ID Proof');

        for (Document__c doc : idProofDocs) {
            System.assertEquals('ID Proof', doc.Document_Category__c, 'Category should match ID Proof');
        }
    }
}