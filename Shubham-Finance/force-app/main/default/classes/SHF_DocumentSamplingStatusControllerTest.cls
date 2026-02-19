/**
 * @File Name : SHF_DocumentSamplingStatusControllerTest.cls
 * @Description :
 * @Author : Anand
 * @Last Modified By :
 * @Last Modified On : December 30, 2025
 * @Modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | December 30, 2025 |   | Initial Version
 **/

@IsTest
public class SHF_DocumentSamplingStatusControllerTest {
    
    @TestSetup
    static void setupData() {
        
        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);
        
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(
            app.Id, 'Test', 'User', '27AAACB2230M1ZL', true
            );
        
        Verification__c verification = SHF_TestDataFactory.createVerification(
            app.Id, UserInfo.getUserId(), 'Sampled', 'Document', null, true
            );
        
        Verification_Activity__c vAct = SHF_TestDataFactory.createVerificationActivity(
            verification.Id,
        UserInfo.getUserId(),
        true
            );
        
        Document__c doc = SHF_TestDataFactory.createDocument(
            app.Id, applicant.Id, 'Loan Specific Documents', 'Income Proof', 'QDE', 'Not Uploaded', true
            );
        doc.File_Name__c  = 'RCU Seller report - 233';
        doc.RCU_Required__c = false;
        
        update doc;
        
        Document_Activity__c da = new Document_Activity__c(
            Verification__c = verification.Id,
        Verification_Activity__c = vAct.Id,
        Document__c = doc.Id,
        RCU_Verification_Status__c = 'Pending For Verification',
        Pick_up_Criteria__c = 'Sampled',
        Decision__c = 'RCU Positive',
        Comments__c = 'Created for Testing'
            );
        
        insert da;
    }
    
    @IsTest
    static void testGetSampledDocumentRecord() {
        
        Verification_Activity__c ver = [SELECT Id FROM Verification_Activity__c LIMIT 1];
        
        System.debug('ver-->'+ ver);
        Test.startTest();
        List<Document_Activity__c> result =
            SHF_DocumentSamplingStatusController.getSampledDocumentRecord(ver.Id);
        Test.stopTest();
        
        System.assert(result.size() > 0, 'Record(s) must be returned.');
        System.debug('result-->'+ result);
        System.assertEquals(
            ver.Id,
        result[0].Verification_Activity__c,
        'Returned record should match verification Id'
            );
    }
    
    @IsTest
    static void testSaveFCUDecision() {
        
            Document_Activity__c da = [
                SELECT Id, Document__c, Verification__c, Verification_Activity__c,
                        RCU_Verification_Status__c, Pick_up_Criteria__c, Decision__c,
                        Comments__c, Completion_Date_Time__c, Document__r.Status__c,
                        Document__r.Document_Category__c, Document__r.File_Name__c,
                        Document__r.RCU_Required__c, Referred_By__c
                FROM Document_Activity__c
                LIMIT 1
            ];
        
            da.Decision__c = 'Approved';
            da.Comments__c = 'Verified & Approved';
        
            String payLoad = JSON.serialize(new List<Document_Activity__c>{ da });
        
            Test.startTest();
            String response = SHF_DocumentSamplingStatusController.saveFCUDecision(payLoad);
            Test.stopTest();
        
            System.assertEquals('SUCCESS', response, 'Must return SUCCESS after upsert');
        
            Document_Activity__c updatedRecord = [
                SELECT Decision__c, Comments__c
                FROM Document_Activity__c
                WHERE Id =: da.Id LIMIT 1
            ];
        
            System.assertEquals('Approved', updatedRecord.Decision__c);
            System.assertEquals('Verified & Approved', updatedRecord.Comments__c);
    }
    
}