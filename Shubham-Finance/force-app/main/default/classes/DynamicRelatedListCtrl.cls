/*
 *This class used to create methods for dynamicRelatedList LWC.
 */
public with sharing class DynamicRelatedListCtrl {
    @AuraEnabled
    public static GenericDataTableController.DataTableResponse returnRelatedRecords(String applicationId, String metadataName, String query, String queryParameters){
        GenericDataTableController genericDTObj = new GenericDataTableController();
        if (applicationId != null) {

        SObjectType objType = ((Id)applicationId).getSObjectType();
        System.debug('### Object Type: ' + objType);
        if (objType == Verification__c.SObjectType) {
        Verification__c ver = [SELECT Application__c FROM Verification__c WHERE Id = :applicationId LIMIT 1];
        applicationId = ver.Application__c;
       }
    }

      
        system.debug('queery '+query);
        system.debug('metadataName '+metadataName);
        genericDTObj.METADATA_NAME = metadataName;
        genericDTObj.IDS_SET = new Set<String>();
        genericDTObj.IS_READ_ONLY = false;
        if(String.isNotBlank(queryParameters)){
            genericDTObj.IDS_SET.addAll(queryParameters.split(';'));
        }
        genericDTObj.IDS_SET.add(applicationId);
        genericDTObj.WHERE_CLAUSE = query;
        system.debug('genericDTObj'+genericDTObj);
        system.debug('gettable dataeee '+ genericDTObj.getTable(applicationId));
        return genericDTObj.getTable(applicationId); //edited by mansur on 16-01-2026
    }
    @AuraEnabled
    public static string deleteRecord(List<Id> recordIds){
        String msg = '';
        try {
            List<SObject> recordsToDelete = new List<SObject>();
            if (recordIds == null || recordIds.isEmpty()) {
                msg =  'Error: No record IDs provided';
            }
            String objectType = recordIds[0].getSObjectType().getDescribe().getName();
            
            for(Id recordId : recordIds){
                // Create an SObject instance and set its ID for deletion
                SObject record = (SObject) Type.forName(objectType).newInstance();
                record.Id = recordId;
                recordsToDelete.add(record);
            }
            if(!recordsToDelete.isEmpty()){
                delete recordsToDelete;
                msg =  'Records deleted successfully';
            }else{
                msg =  'Error in Records deletion';
            }
        } catch (Exception e) {
            system.debug('line no > ' + e.getLineNumber() + ' error message > ' + e.getMessage());
            msg = 'Error: ' + e.getMessage();
        }
        return msg;
    }
    @AuraEnabled(cacheable=true)
    public static DeviationAuthResponse getDeviationOwner(List<Id> deviationIdList , String curruntUserId){
        DeviationAuthResponse response = new DeviationAuthResponse();
         response.isAuthorizeToDelete = true;
        Set<Id> deviationIdSet = new Set<Id>(deviationIdList);
        if(!deviationIdList.isEmpty() && curruntUserId != null){
             for(Deviation_and_Sanction_Condition__c deviation :  new SHF_DeviationAndSanctionSelector().selectByIds(deviationIdSet)){
                 if(deviation.CreatedById != curruntUserId){
                    response.isAuthorizeToDelete = false;
                 response.unauthorizedDeviationNames.add(deviation.Name);
                 }
                 
                }
             }

        else{
            response.isAuthorizeToDelete = false;
        }
        return response;
       
    }

     @AuraEnabled
    public static String softDeleteRecords(List<Id> deviationIdList , String curruntUserId){
        String msg  = '';
         Set<Id> deviationIdSet = new Set<Id>(deviationIdList);
        try{
       List <Deviation_and_Sanction_Condition__c> deviationList = new List <Deviation_and_Sanction_Condition__c>();
        if(!deviationIdList.isEmpty() && curruntUserId != null){
             for(Deviation_and_Sanction_Condition__c deviation :  new SHF_DeviationAndSanctionSelector().selectByIds(deviationIdSet)){
                Deviation_and_Sanction_Condition__c d = new Deviation_and_Sanction_Condition__c();
                d.Is_Delete__c = true;
                d.Decision_By__c = curruntUserId;
                d.id = deviation.Id;
                deviationList.add(d);
             }
        }else{
           msg = 'error';
        }
        if(!deviationList.isEmpty()){
            update deviationList;
            msg  = 'success';
        }
        }catch(exception e){
              system.debug('line no > ' + e.getLineNumber() + ' error message > ' + e.getMessage());
            msg = 'Error: ' + e.getMessage();
        }
        return msg;
    }
    public class DeviationAuthResponse {
        @AuraEnabled public Boolean isAuthorizeToDelete;
        @AuraEnabled public List<String> unauthorizedDeviationNames = new List<String>();
    }
}