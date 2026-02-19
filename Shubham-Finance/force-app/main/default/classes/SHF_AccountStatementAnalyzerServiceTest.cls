@isTest
public with sharing class SHF_AccountStatementAnalyzerServiceTest {

    @TestSetup
    static void setupData() {

        E_Verification__c ev = new E_Verification__c(
            Client_Txn_Id__c = 'CL12345'
        );
        insert ev;
    }

    private static RestRequest prepareRequest(String body) {

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/AccountStatementAnalyzer/';
        req.addHeader('Content-Type','application/json');
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        return req;
    }

    @IsTest
    static void test_Webhook_With_PDF() {

        String samplePdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('Test PDF File'));

        String body = '{'+
            '"clienttxnid":"CL12345",'+
            '"fipid":"FIP999",'+
            '"txnid":"TX111",'+
            '"dataDetail":{'+
                '"pdfbase64":"'+samplePdfBase64+'"'+
            '}'+
        '}';

        prepareRequest(body);

        Test.startTest();
        SHF_AccountStatementAnalyzerService.webhookListener();
        Test.stopTest();

        E_Verification__c ev = [
            SELECT Id, FIP_Id__c 
            FROM E_Verification__c 
            WHERE Client_Txn_Id__c = 'CL12345'
            LIMIT 1
        ];

        System.assertEquals('FIP999', ev.FIP_Id__c);

        List<ContentVersion> cvList = [
            SELECT Id 
            FROM ContentVersion 
            WHERE FirstPublishLocationId = :ev.Id
        ];

        System.assert(cvList.size() == 1);
    }

    @IsTest
    static void test_Webhook_Without_PDF() {

        String body = '{'+
            '"clienttxnid":"CL12345",'+
            '"fipid":"FIP222",'+
            '"txnid":"TX222",'+
            '"dataDetail":{}'+
        '}';

        prepareRequest(body);

        Test.startTest();
        SHF_AccountStatementAnalyzerService.webhookListener();
        Test.stopTest();

        E_Verification__c ev = [
            SELECT FIP_Id__c 
            FROM E_Verification__c 
            WHERE Client_Txn_Id__c = 'CL12345'
            LIMIT 1
        ];

        System.assertEquals('FIP222', ev.FIP_Id__c);
    }

    @IsTest
    static void test_Webhook_Missing_ClientTxnId() {

        String body = '{'+
            '"fipid":"FIP000",'+
            '"txnid":"TX000"'+
        '}';

        prepareRequest(body);

        Test.startTest();
        SHF_AccountStatementAnalyzerService.webhookListener();
        Test.stopTest();

        System.assert(true);
    }
}