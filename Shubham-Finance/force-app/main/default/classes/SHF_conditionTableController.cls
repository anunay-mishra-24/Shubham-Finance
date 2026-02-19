/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : SHF_conditionTableController
* Author          : Mansur
* Created Date    : Feb 3, 2026
* Last Modified By: <YourName>
* Last Modified On: Feb 3, 2026
* Description     : This class implements for......
*  
* Change History  :
*  Date          │  Mansur     │   Change
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*  Feb 3, 2026  │ Mansur   │ Initial version
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/

public with sharing class SHF_conditionTableController {
    
    @AuraEnabled(cacheable=true)
    public static List<Document__c> getDocuments(String applicationId,String activityHistoryId) {
        if (String.isBlank(applicationId) && String.isBlank(activityHistoryId)) {
            return new List<Document__c>();
        }
        List<Document__c> docList =	new SHF_DocumentsSelector().selectByApplicationIdAndActivityId(new Set<Id>{applicationId} , new Set<Id>{activityHistoryId});
        system.debug('docList > ' + docList);
        return docList;
    }
    
    @AuraEnabled
    public static String updateDocumentStatus(List<Id> recordIds, String decision) {
        List<Document__c> docs = new List<Document__c>();
        Set<Id> recordIdSet = new Set<Id>();
        if(!recordIds.isEmpty()){
            recordIdSet.addAll(recordIds);
            List<Document__c> docList =  new SHF_DocumentsSelector().selectByDocIds(recordIdSet);
            for ( Document__c doc : docList) {
                Document__c document = new Document__c();
                document.Id = doc.Id;
                if(decision == SHF_ConstantsUtil.APPROVE){
                    document.Sanction_Condition_Status__c = doc.Requested_Status__c;
                }else{
                    document.Sanction_Condition_Status__c = SHF_ConstantsUtil.PENDING;
                }
                docs.add(document);
            }
        }
        if(!docs.isEmpty()){
            update docs;
            return 'Success';
        }
        return '';
    }  
}