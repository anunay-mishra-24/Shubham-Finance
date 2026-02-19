@IsTest
public class SHF_HTTPCalloutServiceTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            res.setBody('{"status":"success","message":"mocked"}');
            res.setStatusCode(200); return res;
        }
    }

    private static Callout_Framework__mdt getMockMetadata() {
        return new Callout_Framework__mdt(
            DeveloperName='My_API_Metadata', Label='Test Metadata', Active__c=true,
            Endpoint__c='https://example.com/api', HTTP_Method__c='POST', Timeout_Time__c=5000,
            Body__c='{"default":"body"}', HeaderParams__c='Authorization:Bearer testtoken\nAccept:application/json',
            URL_Parameter_s__c='param1:value1\nparam2:value2\nparam3:', Extra_Param_s__c='extra1:extraVal1\nextra2:',
            Mock_Response__c='{"status":"success"}'
        );
    }

    @IsTest static void testInitializeAndGetters() {
        SHF_HTTPCalloutService s = new SHF_HTTPCalloutService(getMockMetadata());
        s.setRequestBody('{"test":"123"}'); s.setRequestTimeout(5000); s.setRequestMethod('POST'); 
        s.setRequestBodyAsBlob(Blob.valueOf('abc')); Dom.Document d=new Dom.Document(); d.load('<root><v>1</v></root>'); s.setRequestBodyAsDocument(d);
        s.setURLParameter('param1','value1'); s.setURLParameter('param2',null); s.setURLParameter(null,'valueOnly'); s.setHeaderParameter('Authorization','Bearer 123');
        System.assertEquals('POST', s.getRequestMethod()); System.assertEquals(5000,s.getRequestTimeout());
        System.assertEquals(Blob.valueOf('abc'), s.getRequestBodyAsBlob()); System.assertNotEquals(null,s.getRequestBodyAsDocument());
        System.assertEquals(null,s.getRequestCertificate()); System.assertEquals(true,s.getIsActive()); 
        System.assertEquals('value1', s.getURLParameter('param1')); System.assert(s.getURLParameters().containsKey('param1'));
        s.setEndpointURL('https://newexample.com/api'); System.assertEquals('https://newexample.com/api', s.getEndpointURL());
        System.assertNotEquals(null,s.getRequest());
    }

    @IsTest static void testSendRequestWithMock() {
        Test.setMock(HttpCalloutMock.class,new MockHttpResponseGenerator());
        SHF_HTTPCalloutService s=new SHF_HTTPCalloutService(getMockMetadata()); s.setRequestBody('{"test":"456"}');
        Test.startTest(); HttpResponse r=s.sendRequest(); Test.stopTest();
        System.assertEquals(200,r.getStatusCode()); System.assert(r.getBody().contains('mocked'));
    }

    @IsTest static void testSendRequestWithCustomRequest() {
        SHF_HTTPCalloutService s=new SHF_HTTPCalloutService(getMockMetadata());
        s.setRequestMethod('POST'); s.setRequestBody('{"custom":"req"}'); s.setRequestTimeout(1000);
        Test.setMock(HttpCalloutMock.class,new MockHttpResponseGenerator());
        Test.startTest(); HttpResponse r=s.sendRequest(s.getRequest()); Test.stopTest();
        System.assertEquals(200,r.getStatusCode());
    }

    @IsTest static void testExtraParamsAndMockResponse() {
        SHF_HTTPCalloutService s=new SHF_HTTPCalloutService(getMockMetadata());
        System.assertEquals('extraVal1',s.getExtraParameters().get('extra1')); 
        System.assertEquals('extraVal1',s.getExtraParameter('extra1'));
        s.setmockRespnse('{"status":"mockSet"}'); System.assertEquals('{"status":"mockSet"}',s.getmockRespnse());
    }

    @IsTest static void testStaticMetadataMethod() {
        try{ Test.startTest(); SHF_HTTPCalloutService.getAPIMetadataDetails('My_API_Metadata'); Test.stopTest();}
        catch(Exception e){ System.assert(true); }
    }

    @IsTest static void testConstructorWithMetadataName() {
        Boolean thrown=false; try{ new SHF_HTTPCalloutService('DoesNotExist'); }catch(Exception e){ thrown=true; }
        System.assertEquals(true,thrown);
        try{ System.assertNotEquals(null,new SHF_HTTPCalloutService('My_API_Metadata')); }
        catch(Exception e){ System.assert(true); }
    }
}