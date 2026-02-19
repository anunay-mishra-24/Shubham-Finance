@IsTest
public class SHF_CreateCollateral_Service_Test {

    // -------------------------------------------------
    // Mock for BOTH Access Token + Create Collateral API
    // -------------------------------------------------
    public class MultiCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            String endpoint = req.getEndpoint();

            // ---- Access Token API ----
            if (endpoint.contains('oauthnew') || endpoint.contains('token')) {
                res.setBody(
                    '{"access_token":"9f8e5645-08d4-4b8a-9b5f-98939864685a",' +
                    '"token_type":"bearer",' +
                    '"expires_in":614096}'
                );
                return res;
            }

            // ---- Create Collateral API ----
            res.setBody(
                '{' +
                '"status": "SUCCESS",' +
                '"requestReferenceNumber": "001",' +
                '"globalCollateralNumber": "CMS00031560",' +
                '"referenceNumber": "APPL00000203",' +
                '"collateralType": "Property",' +
                '"collateralSubType": "BuilderConstructedProperty",' +
                '"globalCollateralCurrentVersion": "0",' +
                '"errorCode": null,' +
                '"errorDesc": null,' +
                '"sellerResponseList": [],' +
                '"userName": "mCAS",' +
                '"userId": null,' +
                '"lastUpdatedTimeStamp": 1753440935332,' +
                '"externalCollateralNumber": null,' +
                '"collateralNumber": null' +
                '}'
            );

            return res;
        }
    }

    // -------------------------------------------------
    // Test Method
    // -------------------------------------------------
    @IsTest
    static void testCreateCollateral_Success() {

        // Register mock (handles BOTH callouts)
        Test.setMock(HttpCalloutMock.class, new MultiCalloutMock());

        // -----------------------------
        // Test Data Setup
        // -----------------------------
        Application__c app = new Application__c(Name = 'Test Application');
        insert app;

        Builder_Master__c builder = new Builder_Master__c(Name = 'Test Builder');
        insert builder;

        Builder_Project_Master__c project = new Builder_Project_Master__c(
            Name = 'Test Project',
            Project_Code__c = 'PRJ001'
        );
        insert project;

        Collateral__c collateral = new Collateral__c(
            Application__c = app.Id,
            Property_Type__c = 'Flat',
            Built_Up_Area__c = 120,
            Carpet_Area__c = 90,
            Property_cost_INR__c = 5500000,
            Company_Name__c = builder.Id,
            Project_Name__c = project.Id
        );
        insert collateral;

        Collateral_Seller_Owner__c seller = new Collateral_Seller_Owner__c(
            Collateral__c = collateral.Id,
            Name = 'Test Seller',
            ownerType__c = 'Individual',
            ownershipStatus__c = 'Owned',
            Percent_Share__c = 100
        );
        insert seller;

        SRO_Master__c sro = new SRO_Master__c(
            Name = 'Test SRO',
            SRO_Code__c = 'SRO001'
        );
        insert sro;

        Collateral_Agreement__c agreement = new Collateral_Agreement__c(
            Collateral__c = collateral.Id,
            Agreement_Type__c = 'Sale',
            Agreement_Value_INR__c = 5500000,
            Registration_Date__c = Date.today(),
            SRO_Master__c = sro.Id
        );
        insert agreement;

        // -----------------------------
        // Execute
        // -----------------------------
        Test.startTest();
        String result =
            SHF_CreateCollateral_Service.createCollateral(collateral.Id, null);
        Test.stopTest();

        // -----------------------------
        // Assertions
        // -----------------------------
        Collateral__c updatedCollateral = [
            SELECT Global_Collateral_Number__c
            FROM Collateral__c
            WHERE Id = :collateral.Id
        ];

        /*System.assertEquals(
            'CMS00031560',
            updatedCollateral.Global_Collateral_Number__c,
            'Global Collateral Number should be updated from API response'
        );*/
    }
}