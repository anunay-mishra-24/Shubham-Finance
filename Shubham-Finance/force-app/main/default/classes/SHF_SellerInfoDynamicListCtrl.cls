public with sharing class SHF_SellerInfoDynamicListCtrl {
    @AuraEnabled
    public static GenericDataTableController.DataTableResponse returnRelatedRecords(String verificationId, String metadataName, String query, String queryParameters){
        Verification__c verification = [select id,Application__c from Verification__c where id =: verificationId];
        String applicationId = verification.Application__c;
        List<Collateral_Application__c> collateralAppList = [select id,Application__c,Collateral__c from Collateral_Application__c where Application__c =: applicationId];
        Set<String> collateralIds = new Set<String>();
        for(Collateral_Application__c collateralApp : collateralAppList){
            collateralIds.add(collateralApp.Collateral__c);
        }

        GenericDataTableController genericDTObj = new GenericDataTableController();
        
      
        system.debug('queery '+query);
        system.debug('metadataName '+metadataName);
        genericDTObj.METADATA_NAME = metadataName;
        genericDTObj.IDS_SET = new Set<String>();
        genericDTObj.IS_READ_ONLY = false;
        if(String.isNotBlank(queryParameters)){
            genericDTObj.IDS_SET.addAll(queryParameters.split(';'));
        }
        genericDTObj.IDS_SET.addAll(collateralIds);
        genericDTObj.WHERE_CLAUSE = query;
        system.debug('genericDTObj - '+genericDTObj);
        // system.debug('genericDTObj table - '+genericDTObj.getTable());
        return genericDTObj.getTable(applicationId);
    }
}