/**
* @File Name     : SHF_DMS_Service_Test.cls
* @Description   : Test class for SHF_DMS_Service
* @Author        : Riteek Tiwari
* ============================================================================== 
* Ver   Date          Author        Modification
* ============================================================================== 
* 1.0   02-09-2025    Riteek Tiwari Initial Version
*/
@IsTest
public class SHF_DMS_Service_Test {

    
    private class DmsHttpMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "SUCCESS","documentId": "bf84c09c-8a8c-4490-b917-4c36052ab445","version": "1.0","message": "File created.","Encrypted Text:": "URDHhr6MObxc6YgWP2aQDqn8PsDFNWjaQYf/OW1pBkg="}');
            return res;
        }
    }
     private class DmsHttpMockSuccess1 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setStatus('OK');
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "SUCCESS","documentId": "bf84c09c-8a8c-4490-b917-4c36052ab445","version": "1.0","message": "File created.","Encrypted Text:": "URDHhr6MObxc6YgWP2aQDqn8PsDFNWjaQYf/OW1pBkg="}');
            return res;
        }
    }
    private class DmsHttpMockSuccess3 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"SUCCESS","documentId":"f546af36-a8ed-497c-a44f-ac0ee829f28a","version":"0.0","message":"Document found.","fileNo":"APPL10101023","base64content":"JVBERi0xLjQKJcOiw6MKMSAwIG9iago8PAovVGl0bGUgKCkKL0NyZWF0b3IgKP7/AHcAawBoAHQAbQBsAHQAbwBwAGQAZgAgADAALgAxADIALgA1KQovUHJvZHVjZXIgKP7/AFEAdAAgADUALgAxADIALgA4KQovQ3JlYXRpb25EYXRlIChEOjIwMjUwNzA0MDg1NzMzWikKPj4KZW5kb2JqCjIgMCBvYmoKPDwKL1R5cGUgL0NhdGFsb2cKL1BhZ2VzIDMgMCBSCj4+CmVuZG9iago0IDAgb2JqCjw8Ci9UeXBlIC9FeHRHU3RhdGUKL1NBIHRydWUKL1NNIDAuMDIKL2NhIDEuMAovQ0EgMS4wCi9BSVMgZmFsc2UKL1NNYXNrIC9Ob25lPj4KZW5kb2JqCjUgMCBvYmoKWy9QYXR0ZXJuIC9EZXZpY2VSR0JdCmVuZG9iago4IDAgb2JqCjw8Ci9UeXBlIC9YT2J/jPmeZWX8RNHTxFqImhkktjFHJQZlj/hG4NeEmowT/ZIDAwMDAwIG4gCjAwMDA2MjA4MzEgMDAwMDAgbiAKdHJhaWxlcgo8PAovU2l6ZSAyOSAKL0luZm8gMSAwIFIKL1Jvb3QgMiAwIFIKPj4Kc3RhcnR4cmVmCjYyMTk2NCAKJSVFT0YK","Encrypted Text:":"URDHhr6MObxc6YgWP2aQDqn8PsDFNWjaQYf/OW1pBkg="}');
            return res;
        }
    }

    // Mock callout throwing error
    private class DmsHttpMockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated callout failure');
        }
    }
    @IsTest
    static void testCreateDocSuccess() {
        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);
        Loan_Applicant__c loanApplicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'firstName', 'lastName', '27AAACB2230M1ZL', false);
        loanApplicant.Applicant_Type__c = 'Primary Applicant';
        Insert loanApplicant;
        
        Document__c doc = new Document__c();
        doc.Document_Category__c = 'others';
        doc.name = 'Test';
        doc.Application__c = app.Id;
        insert doc;

        Test.setMock(HttpCalloutMock.class, new DmsHttpMockSuccess());

        Test.startTest();
        SHF_DMS_Service.createDoc('Others', 'BASE64STRING', app.Id, doc.Id);
        Test.stopTest();

        List<Document__c> docs = [
            SELECT Id, Document_Category__c, DMS_Document_ID__c, Document_Version__c
            FROM Document__c
            WHERE Application__c = :app.Id
        ];
    }
      @IsTest
    static void testCreateDocSuccess1() {
        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);
        Loan_Applicant__c loanApplicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'firstName', 'lastName', '27AAACB2230M1ZL', false);
        loanApplicant.Applicant_Type__c = 'Primary Applicant';
        Insert loanApplicant;
        
        Document__c doc = new Document__c();
        doc.Document_Category__c = 'others';
        doc.name = 'Test';
        doc.Application__c = app.Id;
        insert doc;
        List<SHF_DMS_Service.DocumentInput> docinputsList = new List<SHF_DMS_Service.DocumentInput>();
       SHF_DMS_Service.DocumentInput docinput = new SHF_DMS_Service.DocumentInput();
        docinput.docId=doc.Id;
            docinput.loanApplicantId =app.Id;
            docinput.base64Doc='BASE64STRING';
            docinput.docCategory ='Others';
            docinputsList.add(docinput);

        Test.setMock(HttpCalloutMock.class, new DmsHttpMockSuccess1());

        Test.startTest();
        SHF_DMS_Service.invokeCreateDoc(docinputsList);
        Test.stopTest();
    }
    
    @IsTest
    static void testexportDoc() {
        Application__c app = SHF_TestDataFactory.createApplication('Test App', true);
        
        Document__c doc = new Document__c();
        doc.Document_Category__c = 'others';
        doc.name = 'Test';
        doc.Application__c = app.Id;
        insert doc;

        Test.setMock(HttpCalloutMock.class, new DmsHttpMockSuccess3());

        Test.startTest();
        SHF_DMS_Service.exportDoc(doc.Id);
        Test.stopTest();
    }
}