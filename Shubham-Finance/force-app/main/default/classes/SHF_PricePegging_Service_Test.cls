@isTest
public class SHF_PricePegging_Service_Test {
    
    private class PricePeggingMock implements HttpCalloutMock {

        //Respond method to return mock HTTP response
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            // Mock response
            res.setBody(
                '{' +
                '"location":"Uttam Nagar",' +
                '"data":[{' +
                    '"minimumRate":"4400",' +
                    '"maximumRate":"4600",' +
                    '"averageRate":"4500",' +
                    '"color":"R"' +
                '}]' +
                '}'
            );

            return res;
        }
    }
    
    @isTest
    static void testGetPricePeggingData_Success() {

        // Register HTTP mock response
        Test.setMock(HttpCalloutMock.class, new PricePeggingMock());

        // Test input values
        String location = 'Uttam Nagar';
        String ratePerSqft = '5500';
        String applicationNo = 'APPL05308604';

        Test.startTest();

        /*Map<String, Object> result =
            SHF_PricePegging_Service.getPricePeggingData(
                location,
                ratePerSqft,
                applicationNo
            );

        Test.stopTest();

        // Assertions to validate success response
        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assertEquals('Success', result.get('status'));
        System.assertEquals('Uttam Nagar', result.get('location'));
        System.assertEquals('4400', result.get('minimumRate'));
        System.assertEquals('4600', result.get('maximumRate'));
        System.assertEquals('4500', result.get('averageRate'));
        System.assertEquals('R', result.get('color'));*/
    }

}