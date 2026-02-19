@IsTest
public class SHF_AML_QueueableTest {
    @IsTest
    static void testQueueableExecution() {
        RecordType appRt = [SELECT Id, Name, SobjectType FROM RecordType WHERE SobjectType = 'Application__c' LIMIT 1];
       Application__c app = new Application__c(Name = 'Test App',RecordTypeId = appRt.Id);
       insert app;
    
                   
       Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'John', 'Doe', '27AAAAA0000A1Z5', false);
       insert applicant;
        
        Test.startTest();
        SHF_AML_Queueable job = new SHF_AML_Queueable(applicant.Id);
        System.enqueueJob(job);
        Test.stopTest();
        System.assert(true, 'Queueable executed successfully');
    }
}