/**
 * @File Name          : SHF_LMSCommonUtilTest.cls
 * @Description        : Test class for SHF_LMSCommonUtil
 * @Author             : Kunal Soni
 * ============================================================================== 
 * Ver         Date         Author       Modification
 * ============================================================================== 
 * 1.0         22-07-2025   Kunal Soni   Initial Version
 */
@IsTest
private class SHF_LMSCommonUtilTest {
    
    // Fake HttpCallout Mock for access token response
    private class MockAccessTokenResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{ "access_token": "mock_access_token_value", "expires_in": 3600 }');
            return res;
        }
    }
    
    @IsTest
    static void testGenerateAccessToken_withMockResponse() {
        Test.setMock(HttpCalloutMock.class, new MockAccessTokenResponse());
        
        Test.startTest();
        String token = SHF_LMSCommonUtil.generateAccessToken();
        Test.stopTest();
        
        System.assertNotEquals(null, token, 'Token should not be null');
        System.assertEquals('mock_access_token_value', token, 'Token value should match mock');
    }
    
    
    @IsTest
    static void testGetPlaceholdersList() {
        String raw = '[Name, Age, (Address)]';
        List<String> result = SHF_LMSCommonUtil.getPlaceholdersList(raw);
        
        System.assertEquals(3, result.size(), 'Expected 3 placeholders');
        System.assertEquals('Name', result[0]);
        System.assertEquals('Age', result[1]);
        System.assertEquals('Address', result[2]);
    }
    
    @IsTest
    static void testGetPlaceholdersList_withEmptyString() {
        List<String> result = SHF_LMSCommonUtil.getPlaceholdersList('');
        System.assertEquals(0, result.size(), 'Should return empty list for blank string');
    }
    
    @IsTest
    static void testParseDateFormate_valid() {
        String dateStr = '12/03/1992';
        Date result = SHF_LMSCommonUtil.parseDateFormate(dateStr);
        
        System.assertEquals(Date.newInstance(1992, 3, 12), result, 'Date should be parsed correctly');
    }
    
    @IsTest
    static void testParseDateFormate_invalid() {
        // Wrong format
        Date result1 = SHF_LMSCommonUtil.parseDateFormate('1992-03-12');
        System.assertEquals(null, result1, 'Should return null for invalid format');
        
        // Blank string
        Date result2 = SHF_LMSCommonUtil.parseDateFormate('');
        System.assertEquals(null, result2, 'Should return null for blank input');
    }
    
    @IsTest
    static void testInvocableMethod_parsePlaceholders() {
        List<SHF_LMSCommonUtil.PlaceholderInput> inputs = new List<SHF_LMSCommonUtil.PlaceholderInput>();
        SHF_LMSCommonUtil.PlaceholderInput input = new SHF_LMSCommonUtil.PlaceholderInput();
        input.placeholderRaw = '[Field1, Field2, (Field3)]';
        inputs.add(input);
        
        Test.startTest();
        List<List<String>> result = SHF_LMSCommonUtil.parsePlaceholders(inputs);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'One list should be returned');
        System.assertEquals(3, result[0].size(), 'Expected 3 parsed placeholders');
        System.assertEquals('Field1', result[0][0]);
        System.assertEquals('Field2', result[0][1]);
        System.assertEquals('Field3', result[0][2]);
    }
}