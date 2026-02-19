/**
* @File Name          : SHF_LMS_CreateCollateral_Service_v2.cls
* @Description        : API to create collateral on LMS
* @Author             : David Saini
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       17-07-2025      David Saini       Initial Version
*/
public with sharing class SHF_LMS_CreateCollateral_Service_v2 {
    public SHF_HTTPCalloutService service;
    
    @AuraEnabled
    public static String createCollateral(String colleteralId ,String loanId) {
        Savepoint sp;
        String message = '';
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Collateral__c.SObjectType});
            Callout_Framework__mdt metadata = SHF_CommonUtil.getCalloutMetadata('Create_Collateral_API').get('Create_Collateral_API');
            String accesstoken = SHF_LMSCommonUtil.generateAccessToken();
            System.debug('Access token :: '+accesstoken);
            if(String.isNotBlank(accessToken)){
                String requestBody = generateRequestJSON(colleteralId);
                SHF_HTTPCalloutService callout = new SHF_HTTPCalloutService('Create_Collateral_API');
                callout.setRequestMethod(metadata.HTTP_Method__c);
                callout.setEndpointURL(metadata.Endpoint__c);
                callout.setRequestBody(requestBody);
                callout.setHeaderParameter('access_token',accesstoken);
                callout.setHeaderParameter('Content-Type', 'application/json');
                

                
                HttpResponse response;
                if (metadata.Active__c) {
                    response = callout.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setBody(callout.getmockRespnse());
                    response.setStatusCode(200);
                }
                
                String responseBody = response.getBody();
                
                if (response.getStatusCode() == 200 && String.isNotBlank(responseBody)) {
                    Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    System.debug('responseBody: ' + res);
                    String globalCollateralNumber = (String) res.get('globalCollateralNumber');
                    Collateral__c collateral = new Collateral__c();
                    collateral.Id = colleteralId;
                    collateral.Global_Collateral_Number__c = globalCollateralNumber;
                    uow.registerDirty(collateral);
                    uow.commitWork();
                }
                
                String reqBodyLog = callout.getRequestBody();
                if (reqBodyLog != null && reqBodyLog.length() > 5000) {
                    reqBodyLog = reqBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Request Body: ' + reqBodyLog);
                
                Logger.info('Response Status Code: ' + response.getStatusCode());
                Logger.info('Response Status: ' + response.getStatus());
                Logger.info('Response Endpoint : '+callout.getEndpointURL());
                Logger.info('Response Method : '+callout.getRequestMethod());
                system.debug('Response Status: ' + response.getStatus());
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    message = 'Success';
                }
                else{
                    Logger.error('Getting this error : ' );
                }
                String respBodyLog = response.getBody();
                if (respBodyLog != null && respBodyLog.length() > 5000) {
                    respBodyLog = respBodyLog.substring(0, 5000) + '... [TRUNCATED]';
                }
                Logger.info('Response Body: ' + respBodyLog);
                system.debug('Response Body: ' + respBodyLog);
            }
            else{
                Logger.error('Access token is blank');
                return 'Access token is blank';
            }
        } catch (Exception e) {
            if (sp != null) {
                Database.rollback(sp);
            }
            System.debug('Error in Create_Collateral_API: ' + e);
            Logger.error('Error: ' + e.getMessage()+e.getLineNumber());
        } finally {
            Logger.saveLog();
        }
        system.debug('message : '+message);
        return message;
    }

    public static String generateRequestJSON(String collateralId) {

        Collateral__c collateral =
            new SHF_CollateralSelector().selectByCollateralId(collateralId);
            

        Collateral_Seller_Owner__c collSeller = [
            SELECT Id, Name, ownerType__c, ownershipStatus__c, ownershipDates__c, Percent_Share__c
            FROM Collateral_Seller_Owner__c
            WHERE Collateral__c = :collateral.Id
            LIMIT 1
        ];

        System.debug('COllateral id :: '+collateralId);
        Collateral_Agreement__c collAgreement = [
            SELECT Id, Remarks__c, Agreement_Type__c, Agreement_Value_INR__c,
                Amenities_Agreement_Value_INR__c, Sale_Deed_Number__c,
                Sale_Deed_Date__c, SRO_Master__c, SRO_Master__r.SRO_Code__c,
                SRO_Master__r.Name, Registration_Date__c, Registration_Number__c
            FROM Collateral_Agreement__c
            WHERE Collateral__c = :collateralId
            LIMIT 1
        ];
        System.debug('COllateral id :: '+collateralId);

        String requestJson = '';
        requestJson += '{';

        requestJson += '"productProcessor":"LMS",';
        requestJson += '"requestReferenceNumber":"",';

        // ================= collParameterVO =================
        requestJson += '"collParameterVO":{';
        requestJson += '"collateralValue":{';
        requestJson += '"amount":0,';
        requestJson += '"currencyCode":"INR"';
        requestJson += '},';
        requestJson += '"collateralTypeCode":"Property",';
        requestJson += '"collateralSubTypeCode":"50506",';
        requestJson += '"sourceSystem":"LMS",';
        requestJson += '"globalCollateralNumber":"",';
        requestJson += '"referenceNumber":"",';
        requestJson += '"description":"",';
        requestJson += '"collateralReferenceNumber":""';
        requestJson += '},';

        // ================= propertyDetailsVO =================
        requestJson += '"propertyDetailsVO":{';
        requestJson += '"propertyDescription":"",';
        requestJson += '"propertyTypeCode":"",';
        requestJson += '"natureOfPropertyCode":"",';

        // -------- contractorDetailsVO --------
        requestJson += '"contractorDetailsVO":{';
        requestJson += '"architect":"",';
        requestJson += '"contrctor":"",';
        requestJson += '"costOfHome":{';
        requestJson += '"amount":0,';
        requestJson += '"currencyCode":"INR"';
        requestJson += '},';
        requestJson += '"costOfLand":{';
        requestJson += '"amount":0,';
        requestJson += '"currencyCode":"INR"';
        requestJson += '},';
        requestJson += '"costOfConstruction":{';
        requestJson += '"amount":0,';
        requestJson += '"currencyCode":"INR"';
        requestJson += '}';
        requestJson += '},';

        // -------- builderDetailsVO --------
        requestJson += '"builderDetailsVO":{';
        requestJson += '"builderConstructed":false,';
        requestJson += '"builderCompanyCode":"",';
        requestJson += '"builderProjectCode":"",';
        requestJson += '"buildingCode":"",';
        requestJson += '"buildingWingCode":"",';
        requestJson += '"builderGroupCode":"",';
        requestJson += '"floorNumber":0,';
        requestJson += '"flatNumber":0';
        requestJson += '},';

        // -------- propertyOtherDetailsVO --------
        requestJson += '"propertyOtherDetailsVO":{';
        requestJson += '"propertyClassificationCode":"",';
        requestJson += '"propertyOwnershipCode":"",';
        requestJson += '"totalArea":{';
        requestJson += '"areaValue":0,';
        requestJson += '"muCode":""';
        requestJson += '},';
        requestJson += '"constructionArea":{';
        requestJson += '"areaValue":0,';
        requestJson += '"muCode":""';
        requestJson += '},';
        requestJson += '"propertyPurposeCode":"",';
        requestJson += '"age":0,';
        requestJson += '"residualAgeCode":"",';
        requestJson += '"consideredValueCode":""';
        requestJson += '},';

        // -------- sellerDetailsVO --------
        requestJson += '"sellerDetailsVO":[{';
        requestJson += '"sellerDetailsBlock":{';
        requestJson += '"sellerName":"",';
        requestJson += '"presentRegisteredOwner":"",';
        requestJson += '"tctNumber":"",';
        requestJson += '"lotNumber":"",';
        requestJson += '"otherRemarks":"",';
        requestJson += '"percentageShare":0,';
        requestJson += '"dobIncopDate":"2026-02-10T10:24:47Z"';
        requestJson += '},';
        requestJson += '"address":[{';
        requestJson += '"accomodationTypeCode":"",';
        requestJson += '"addressLine1":"",';
        requestJson += '"addressLine2":"",';
        requestJson += '"addressLine3":"",';
        requestJson += '"addressLine4":"",';
        requestJson += '"addressTypeCode":"",';
        requestJson += '"areaCode":"",';
        requestJson += '"cityCode":"",';
        requestJson += '"countryISOCode":"",';
        requestJson += '"districtCode":"",';
        requestJson += '"fullAddress":"",';
        requestJson += '"landMark":"",';
        requestJson += '"stateCode":"",';
        requestJson += '"village":"",';
        requestJson += '"zipcode":""';
        requestJson += '}],';
        requestJson += '"bankDetails":[{';
        requestJson += '"bank":"",';
        requestJson += '"bankBranch":"",';
        requestJson += '"ifsc":"",';
        requestJson += '"accountType":"",';
        requestJson += '"accountNumber":"",';
        requestJson += '"defaultBank":true';
        requestJson += '}],';
        requestJson += '"identificationNumber":"",';
        requestJson += '"identificationDetailsVO":[{';
        requestJson += '"identificationType":"",';
        requestJson += '"identificationNumber":"",';
        requestJson += '"issuingCountry":"",';
        requestJson += '"issueDate":"2026-02-10T10:24:47Z",';
        requestJson += '"expiryDate":"2026-02-10T10:24:47Z"';
        requestJson += '}],';
        requestJson += '"sellerIndvNonIndv":""';
        requestJson += '}],';

        // -------- collateral address --------
        requestJson += '"address":{';
        requestJson += '"accomodationTypeCode":"",';
        requestJson += '"addressLine1":"",';
        requestJson += '"addressLine2":"",';
        requestJson += '"addressLine3":"",';
        requestJson += '"addressLine4":"",';
        requestJson += '"addressTypeCode":"",';
        requestJson += '"areaCode":"",';
        requestJson += '"cityCode":"",';
        requestJson += '"countryISOCode":"",';
        requestJson += '"districtCode":"",';
        requestJson += '"fullAddress":"",';
        requestJson += '"intraRegionCode":"",';
        requestJson += '"landMark":"",';
        requestJson += '"taluka":"",';
        requestJson += '"stateCode":"",';
        requestJson += '"village":"",';
        requestJson += '"zipcode":""';
        requestJson += '},';

        // -------- ownership --------
        requestJson += '"propertyOwnershipDetailVO":[{';
        requestJson += '"ownershipStatus":"",';
        requestJson += '"ownerName":"",';
        requestJson += '"percentShare":0,';
        requestJson += '"ownershipFrom":"2026-02-10T10:24:47Z",';
        requestJson += '"ownershipTill":"2026-02-10T10:24:47Z",';
        requestJson += '"ownerType":""';
        requestJson += '}],';

        requestJson += '"propertyCostBreakUpVO":[{';
        requestJson += '"particularsCode":"",';
        requestJson += '"description":"",';
        requestJson += '"cost":{';
        requestJson += '"amount":0,';
        requestJson += '"currencyCode":"INR"';
        requestJson += '}';
        requestJson += '}],';

        requestJson += '"propertyCost":{';
        requestJson += '"amount":0,';
        requestJson += '"currencyCode":"INR"';
        requestJson += '},';

        requestJson += '"marketValue":{';
        requestJson += '"amount":0,';
        requestJson += '"currencyCode":"INR"';
        requestJson += '}';

        requestJson += '},'; // propertyDetailsVO end

        // ================= collateralInvestigationVO =================
        requestJson += '"collateralInvestigationVO":{';
        requestJson += '"valuationVO":{';
        requestJson += '"finalEvaluatedValue":{';
        requestJson += '"amount":0,';
        requestJson += '"currencyCode":"INR"';
        requestJson += '},';
        requestJson += '"acceptedValue":{';
        requestJson += '"amount":0,';
        requestJson += '"currencyCode":"INR"';
        requestJson += '},';
        requestJson += '"lastValuationDate":"2026-02-10T10:24:47Z"';
        requestJson += '}';
        requestJson += '}';

        requestJson += '}';

        System.debug('Collateral Create Request JSON => ' + requestJson);
        return requestJson;
    }


}