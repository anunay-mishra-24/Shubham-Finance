@IsTest
public class SHF_PublicSiteDocumentController_Test {@testSetup
    static void setupTestData() {

        RecordType appRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Application__c' LIMIT 1];
        Application__c app = new Application__c(Name = 'Test App',RecordTypeId = appRt.Id);
        insert app;
        Application__c emptyApp = new Application__c(Name = 'Empty App');
        insert emptyApp;
        Application__c expiredApp = new Application__c(
            Name = 'Expired App',
            RecordTypeId = appRt.Id,
            Public_Site_Upload_SMS_Link_Time__c = System.now().addDays(-2)
        );
        insert expiredApp;
        
        Application__c activeApp = new Application__c(
            Name = 'Active App',
            RecordTypeId = appRt.Id,
            Public_Site_Upload_SMS_Link_Time__c = System.now()
        );
        insert activeApp;

       
       Loan_Applicant__c applicant =  SHF_TestDataFactory.createLoanApplicant(expiredApp.Id,'John','Doe','27AAAAA0000A1Z5',false);
            applicant.Applicant_Type__c = 'Primary Applicant';
            applicant.Mobile_Number__c = '9999999999';
            applicant.IsFinancial_Applicant__c = 'Yes';   
            insert applicant;
        
          List<Document__c> docList = new List<Document__c>();
        Document__c doc1 = SHF_TestDataFactory.createDocument(app.Id, null, 'Income Proof', 'Income Proof', 'QDE', 'Not Uploaded', false); 
        doc1.Selected_for_Public_Site_Upload__c = false;
        docList.add(doc1);
        Document__c doc2 = SHF_TestDataFactory.createDocument(app.Id, applicant.Id, 'Income Proof', 'Income Proof', 'QDE', 'Not Uploaded', false); 
        doc2.Selected_for_Public_Site_Upload__c = false;
        docList.add(doc2);
        insert docList;
        
    }
    
   @isTest
static void testGetPreDisbursementDocumentsRecords() {

  
    Application__c app = [SELECT Id FROM Application__c WHERE Name = 'Test App' LIMIT 1];
    Application__c emptyApp = [SELECT Id FROM Application__c WHERE Name = 'Empty App' LIMIT 1];

    Test.startTest();
    SHF_PublicSiteDocumentController.ResponseWrapper response = SHF_PublicSiteDocumentController.getPreDisbursementDocumentsRecords(app.Id);
    Test.stopTest();

    System.assertEquals(true, response.isSuccess, 'Response should be successful');
    System.assertEquals(2, response.totalRecords, 'Should return 2 records');
    System.assertNotEquals(null, response.responseBody, 'Response body should not be null');

    
    List<Document__c> docs = (List<Document__c>) JSON.deserialize(response.responseBody,List<Document__c>.class);
    System.assertEquals(2, docs.size(), 'Deserialized list should contain 2 documents');

    Test.startTest();
    SHF_PublicSiteDocumentController.ResponseWrapper emptyResponse = SHF_PublicSiteDocumentController.getPreDisbursementDocumentsRecords(emptyApp.Id);
    Test.stopTest();

    System.assertEquals(false, emptyResponse.isSuccess, 'Response should be false for empty data');
    System.assertEquals(0, emptyResponse.totalRecords, 'Total records should be 0');
    System.assertEquals('No document records found', emptyResponse.responseBody);
}


   @isTest
    static void testGetNotUploadedDocumentsRecords() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Application__c  emptyApp = [SELECT Id FROM Application__c WHERE Name = 'Empty App'];
        
        Test.startTest();
        SHF_PublicSiteDocumentController.ResponseWrapper res = SHF_PublicSiteDocumentController.getNotUploadedDocumentsRecords(app.Id);
        SHF_PublicSiteDocumentController.ResponseWrapper res1 = SHF_PublicSiteDocumentController.getNotUploadedDocumentsRecords(emptyApp.Id);
        Test.stopTest();          
        System.assertEquals(true, res.isSuccess);
        System.assertEquals(0, res1.totalRecords);   
    }
    
    @IsTest
    static void testSendLinkToCustomer_AllBranches() {

        Application__c expiredApp = [SELECT Id FROM Application__c WHERE Name = 'Expired App' LIMIT 1];
        Loan_Applicant__c applicant = [SELECT Id, Name, Mobile_Number__c FROM Loan_Applicant__c WHERE Application__c = :expiredApp.Id LIMIT 1];
        List<Map<String, Object>> wrapperList = new List<Map<String, Object>>();

        
        Map<String, Object> applicantMap = new Map<String, Object>{
            'Id' => applicant.Id,
            'Name' => applicant.Name,
            'Mobile_Number__c' => applicant.Mobile_Number__c
        };

        Map<String, Object> doc1 = new Map<String, Object>{
            'Application__c' => expiredApp.Id,
            'Document_Category__c' => 'Income Proof',
            'Type__c' => 'Income Proof',
            'Loan_Applicant__r' => applicantMap
        };
        wrapperList.add(doc1);
       
        Map<String, Object> doc2 = new Map<String, Object>{
            'Application__c' => expiredApp.Id,
            'Document_Category__c' => 'Loan Specific Documents',
            'Type__c' => 'Income Proof'
        };
        wrapperList.add(doc2);
     
        Map<String, Object> doc3 = new Map<String, Object>{
            'Application__c' => expiredApp.Id,
            'Document_Category__c' => 'Other',
            'Type__c' => 'Special Condition'
        };
        wrapperList.add(doc3);

        String jsonInput = JSON.serialize(wrapperList);

        Test.startTest();
        SHF_PublicSiteDocumentController.sendLinkToCustomer(jsonInput);
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testSendLinkToCustomer_AlreadyActive() {

        Application__c activeApp = [SELECT Id FROM Application__c WHERE Name = 'Active App' LIMIT 1];
        List<Map<String, Object>> wrapperList = new List<Map<String, Object>>();

        Map<String, Object> doc = new Map<String, Object>{
            'Application__c' => activeApp.Id,
            'Document_Category__c' => 'Income Proof',
            'Type__c' => 'Income Proof'
        };
        wrapperList.add(doc);

        String jsonInput = JSON.serialize(wrapperList);
        Test.startTest();

        try {
            SHF_PublicSiteDocumentController.sendLinkToCustomer(jsonInput);
            System.assert(false, 'Exception expected');
        } 
        catch (AuraHandledException e) {
            System.assertEquals('A document upload link for customer is already active.',e.getMessage());
        }
        Test.stopTest();
    }
        
    @isTest
    static void testCaptureSendSmsTime_Success() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Boolean exceptionThrown = false;
              try {
                    Test.startTest();
                    SHF_PublicSiteDocumentController.captureSendSmsTime(app.Id);
                    SHF_PublicSiteDocumentController.captureSendSmsTime(null);
                    Test.stopTest();
              } catch (AuraHandledException ex) {
                  exceptionThrown = true;
              }
        
        Application__c updatedApp = [SELECT Public_Site_Upload_SMS_Link_Time__c FROM Application__c WHERE Id = :app.Id];
        System.assertNotEquals(null, updatedApp.Public_Site_Upload_SMS_Link_Time__c,'Public_Site_Upload_SMS_Link_Time__c should be updated');
        System.assertEquals(true, exceptionThrown,'AuraHandledException should be thrown when Application Id is null');
    }
    
          
    
    @isTest
    static void testUploadForPublicSiteTrue() {
        Document__c doc = [SELECT Id, Selected_for_Public_Site_Upload__c FROM Document__c LIMIT 1];
        
        Test.startTest();
        SHF_PublicSiteDocumentController.uploadForPublicSiteTrue(new List<Id>{ doc.Id });
        Test.stopTest();
        
        Document__c updatedDoc = [SELECT Selected_for_Public_Site_Upload__c FROM Document__c WHERE Id = :doc.Id];
        System.assertEquals(true, updatedDoc.Selected_for_Public_Site_Upload__c, 'Document should be marked as selected for public site upload');
    }
            }