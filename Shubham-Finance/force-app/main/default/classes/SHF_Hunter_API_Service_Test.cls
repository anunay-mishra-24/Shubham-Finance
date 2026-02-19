@IsTest
public with sharing class SHF_Hunter_API_Service_Test {
   private class HunterSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml; charset=UTF-8');

            String innerXml =
                '<Result>' +
                    '<MatchSummary matches="2">' +
                        '<TotalMatchScore>75</TotalMatchScore>' +
                    '</MatchSummary>' +
                    '<ErrorWarnings>' +
                        '<Errors errorCount="0"/>' +
                        '<Warnings>' +
                            '<Warning>' +
                                '<Number>101</Number>' +
                                '<Message>Sample warning</Message>' +
                                '<Values>' +
                                    '<Value>1</Value>' +
                                    '<Value>0</Value>' +
                                '</Values>' +
                            '</Warning>' +
                        '</Warnings>' +
                    '</ErrorWarnings>' +
                '</Result>';

            String escapedInner = innerXml.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')
                                 .replace('\'', '&apos;');

            String soap =
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                'xmlns:web="http://www.mclsoftware.co.uk/HunterII/WebServices">' +
                    '<soapenv:Header/>' +
                    '<soapenv:Body>' +
                        '<web:MatchResponse>' +
                            '<web:MatchResult>' + escapedInner + '</web:MatchResult>' +
                        '</web:MatchResponse>' +
                    '</soapenv:Body>' +
                '</soapenv:Envelope>';

            res.setBody(soap);
            return res;
        }
    }

    private class HunterError500Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'text/plain');
            res.setBody('Internal Server Error');
            return res;
        }
    }

    private class HunterMissingNodesMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml');

            res.setBody(
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                'xmlns:web="http://www.mclsoftware.co.uk/HunterII/WebServices">' +
                    '<soapenv:Header/>' +
                    '<soapenv:Body>' +
                        '<web:MatchResponse/>' +
                    '</soapenv:Body>' +
                '</soapenv:Envelope>'
            );
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        // Create minimal Application using factory, then enrich required Hunter fields
        Application__c app = SHF_TestDataFactory.createApplication('APP-001', true);
        // Ensure required numeric fields expected by service
        app.Applied_Loan_Amount__c = 100000;
        app.Tenure__c = 12;
        update app;

        // Create Loan Applicant via factory and set required Hunter fields
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(app.Id, 'John', 'Doe', null, true);
        applicant.Date_of_Birth__c = Date.newInstance(1990, 1, 1);
        applicant.Mobile_Number__c = '9999999999';
        applicant.Aadhar_Number__c = '123412341234';
        applicant.Pan_Number__c = 'ABCDE1234F';
        update applicant;

        // Create Residential and Permanent addresses with fields required by service.getMissingMandatoryFields
        List<Address__c> addrs = new List<Address__c>{
        new Address__c(
          Loan_Applicant__c = applicant.Id,
          Mailing_Address__c = 'Residential Address',
          Address_Line_1__c = '123 Street',
          Pincode__c = '201301'
       ),
        new Address__c(
          Loan_Applicant__c = applicant.Id,
          Mailing_Address__c = 'Permanent Address',
          Address_Line_1__c = '456 Avenue',
          Pincode__c = '201301'
       )
        };
        insert addrs;
    }

    @IsTest
    static void test_callHunterAPI_success() {
        Test.setMock(HttpCalloutMock.class, new HunterSuccessMock());

        Loan_Applicant__c la = [SELECT Id FROM Loan_Applicant__c LIMIT 1];

        Test.startTest();
        String resultJson = SHF_Hunter_API_Service.callHunterAPI(la.Id);
        Test.stopTest();

        System.assert(resultJson.containsIgnoreCase('success'));

        la = [SELECT Hunter_Verification__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertNotEquals(null, la.Hunter_Verification__c);

        E_Verification__c ev = [
            SELECT Status__c, Hunter_Match__c, Hunter_Total_Match_Score__c,
                   Warning_Code__c, Warning_Message__c
            FROM E_Verification__c
            WHERE Id = :la.Hunter_Verification__c
        ];

        System.assertEquals(SHF_ConstantsUtil.COMPLETEDSTATUS, ev.Status__c);
        System.assertEquals('2', ev.Hunter_Match__c);
        System.assertEquals('75', ev.Hunter_Total_Match_Score__c);
        System.assertEquals('101', ev.Warning_Code__c);
    }

    @IsTest
    static void test_callHunterAPI_httpError() {
        Test.setMock(HttpCalloutMock.class, new HunterError500Mock());

        Loan_Applicant__c la = [SELECT Id FROM Loan_Applicant__c LIMIT 1];

        Test.startTest();
        String resultJson = SHF_Hunter_API_Service.callHunterAPI(la.Id);
        Test.stopTest();

        System.assert(resultJson.containsIgnoreCase('failed'));

        la = [SELECT Hunter_Verification__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        E_Verification__c ev = [
            SELECT Status__c, Failed_Reason__c
            FROM E_Verification__c
            WHERE Id = :la.Hunter_Verification__c
        ];

        System.assertEquals(SHF_ConstantsUtil.FAILED_STATUS, ev.Status__c);
    }

    @IsTest
    static void test_callHunterAPI_missingNodes() {
        Test.setMock(HttpCalloutMock.class, new HunterMissingNodesMock());

        Loan_Applicant__c la = [SELECT Id FROM Loan_Applicant__c LIMIT 1];

        Test.startTest();
        String resultJson = SHF_Hunter_API_Service.callHunterAPI(la.Id);
        Test.stopTest();

        System.assert(resultJson.containsIgnoreCase('missing'));

        la = [SELECT Hunter_Verification__c FROM Loan_Applicant__c WHERE Id = :la.Id];
        System.assertNotEquals(null, la.Hunter_Verification__c);
    }

    @IsTest
    static void test_applicantNotFound() {
        Test.setMock(HttpCalloutMock.class, new HunterSuccessMock());

        Id fakeApplicantId = 'a0B000000000001AAA';

        Test.startTest();
        String resultJson = SHF_Hunter_API_Service.callHunterAPI(fakeApplicantId);
        Test.stopTest();

        System.assert(resultJson.contains('Loan Applicant not found'));
    }
}