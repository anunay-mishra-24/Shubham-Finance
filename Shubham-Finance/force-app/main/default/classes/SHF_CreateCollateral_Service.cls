/**
* @File Name          : SHF_CreateCollateral_Service.cls
* @Description        : API to create collateral on LMS
* @Author             : David Saini
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       17-07-2025      David Saini       Initial Version
*/
public with sharing class SHF_CreateCollateral_Service {
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
                String requestBody = generateRequestJSON(colleteralId,metadata.Body__c);
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

    public static String generateRequestJSON(String collateralId, String reqBody) {

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

        reqBody = reqBody
            .replace('<applicationNumber>', collateral.Application__c != null ? collateral.Application__c : '')
            .replace('<collateralSubTypeCode>', collateral.Collateral_Sub_Type_Property_Details__c != null ? collateral.Collateral_Sub_Type_Property_Details__c : '')
            .replace('<collateralTypeCode>', collateral.Property_Type__c != null ? collateral.Property_Type__c : '')
            .replace('<description>', collateral.Property_Description__c != null ? collateral.Property_Description__c : '')
            .replace('<natureOfPropertyCode>', collateral.Nature_of_Property__c != null ? collateral.Nature_of_Property__c : '')
            .replace('<assetTypeCode>', collateral.Type_Of_Purchase__c != null ? collateral.Type_Of_Purchase__c : '')
            .replace('<propertyClassificationCode>', collateral.Property_Classification__c != null ? collateral.Property_Classification__c : '')
            .replace('<builtUpArea>', collateral.Built_Up_Area__c != null ? String.valueOf(collateral.Built_Up_Area__c) : '')
            .replace('<carpetArea>', collateral.Carpet_Area__c != null ? String.valueOf(collateral.Carpet_Area__c) : '')
            .replace('<propertyPurposeCode>', collateral.Type_of_property__c != null ? collateral.Type_of_property__c : '')
            .replace('<residualAgeCode>', collateral.Residual_Age_of_Property__c != null ? String.valueOf(collateral.Residual_Age_of_Property__c) : '')
            .replace('<propertyOwnershipCode>', collateral.Property_Ownership__c != null ? collateral.Property_Ownership__c : '')
            .replace('<amount>', collateral.Property_cost_INR__c != null ? String.valueOf(collateral.Property_cost_INR__c) : '')
            .replace('<addressTypeCode>', collateral.Address_Type__c != null ? collateral.Address_Type__c : '')
            .replace('<addressLine2>', collateral.Address_Line_2__c != null ? collateral.Address_Line_2__c : '')
            .replace('<zipcode>', collateral.Pincode__c != null ? collateral.Pincode__c : '')
            .replace('<stateCode>', collateral.State__c != null ? collateral.State__c : '')
            .replace('<cityCode>', collateral.City__c != null ? collateral.City__c : '')
            .replace('<ownerType>', collSeller.ownerType__c != null ? collSeller.ownerType__c : '')
            .replace('<ownershipStatus>', collSeller.ownershipStatus__c != null ? collSeller.ownershipStatus__c : '')
            .replace('<ownerName>', collSeller.Name != null ? collSeller.Name : '')
            .replace('<ownershipFrom>', collSeller.ownershipDates__c != null ? String.valueOf(collSeller.ownershipDates__c) : '')
            .replace('<percentShare>', collSeller.Percent_Share__c != null ? String.valueOf(collSeller.Percent_Share__c) : '')
            .replace('<agreementRemarks>', collAgreement.Remarks__c != null ? collAgreement.Remarks__c : '')
            .replace('<agreementType>', collAgreement.Agreement_Type__c != null ? collAgreement.Agreement_Type__c : '')
            .replace('<agreementAmount>', collAgreement.Agreement_Value_INR__c != null ? String.valueOf(collAgreement.Agreement_Value_INR__c) : '')
            .replace('<amenitiesAmount>', collAgreement.Amenities_Agreement_Value_INR__c != null ? String.valueOf(collAgreement.Amenities_Agreement_Value_INR__c) : '')
            .replace('<registrationDate>', collAgreement.Registration_Date__c != null ? String.valueOf(collAgreement.Registration_Date__c) : '')
            .replace('<registrationNumber>', collAgreement.Registration_Number__c != null ? collAgreement.Registration_Number__c : '')
            .replace('<saleDeedDate>', collAgreement.Sale_Deed_Date__c != null ? String.valueOf(collAgreement.Sale_Deed_Date__c) : '')
            .replace('<saleDeedNumber>', collAgreement.Sale_Deed_Number__c != null ? String.valueOf(collAgreement.Sale_Deed_Number__c) : '')
            .replace('<sro>', collAgreement.SRO_Master__r.SRO_Code__c != null ? collAgreement.SRO_Master__r.SRO_Code__c : '')
            .replace('<sroName>', collAgreement.SRO_Master__r.Name != null ? collAgreement.SRO_Master__r.Name : '')
            .replace('<builderCompanyCode>', collateral.Company_Name__r.Builder_Code__c != null ? collateral.Company_Name__r.Builder_Code__c : '')
            .replace('<builderProjectCode>', collateral.Project_Name__r.Project_Code__c != null ? collateral.Project_Name__r.Project_Code__c : '')
            .replace('<buildingCode>', collateral.Project_Name__r.Project_Code__c != null ? collateral.Project_Name__r.Project_Code__c : '');

        System.debug('reqBody --> ' + reqBody);
        return reqBody;
    }

}