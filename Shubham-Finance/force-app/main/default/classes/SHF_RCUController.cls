public with sharing class SHF_RCUController {
	@AuraEnabled
    public static List<User> getRCUVendors(String loanApplicationId){
        try{
            if(String.isNotBlank(loanApplicationId) ){
               List<Application__c> loanApplicationList = [SELECT Id, Name, Branch__c FROM Application__c WHERE Id =: loanApplicationId 
                                                                AND Branch__c != null];
                if(!loanApplicationList.isEmpty()){
                    Set<Id> accountIds = new Set<Id>();
                    for(Branch_Mapping__c vendorAccount : [SELECT Id, Name, Branch_Master__c,Vendor__c, Vendor__r.Type__c
                                                           FROM Branch_Mapping__c 
                                                           WHERE Branch_Master__c != null  AND Branch_Master__c =: loanApplicationList[0].Branch__c
                                                           AND Vendor__c != null AND Vendor__r.Type__c != null 
                                                           AND Vendor__r.Type__c = 'RCU Vendor' AND Vendor__r.RecordType.DeveloperName = 'Vendor' ]){
                                                               accountIds.add(vendorAccount.Vendor__c);
                                                           }
                    if(!accountIds.isEmpty()){
                        Set<Id> contactIds = new Set<Id>();
                        for(Contact conObj : [SELECT Id, Name, AccountId from Contact WHERE AccountId != null 
                                                      AND AccountId =: accountIds]){
                            contactIds.add(conObj.Id);
                        }
                        
                        if(!contactIds.isEmpty()){
                            List<User> rcuVendorsList = [SELECT Id, contactId, Name FROM User WHERE contactId != null AND contactId =: contactIds ];
                            system.debug('rcuVendorsList-> ' + rcuVendorsList);
                            if(!rcuVendorsList.isEmpty()){
                                RETURN rcuVendorsList;
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
            system.debug( e.getMessage());
        }
        return null;
    }
    @AuraEnabled
    public static ResponseWrapper initiateRCUtoVendor(List<String> docIds, String applicationId, String rcuType, String comments) {
        ResponseWrapper res = new ResponseWrapper();
        try {
            if (docIds.isEmpty() || String.isBlank(applicationId)) {
                res.isSuccess = false;
                res.responseBody = 'Missing required input parameters.';
                return res;
            }
            String queueName = (rcuType == 'Borrower' ? 'RCU_Managers_Borrower' : 'RCU_Managers_Documents');
            Id queueId = SHF_CommonUtil.getGroupIdByDeveloperName(queueName, 'Queue');
            if (queueId == null) {
                res.isSuccess = false;
                res.responseBody = 'Queue RCU_Managers_Documents not found.';
                return res;
            }

            // Create Verification__c record
            Verification__c verification = new Verification__c();
            verification.Status__c = 'Sampled';
            verification.Type__c = rcuType;
            verification.Comments__c = comments;
            verification.Application__c = applicationId;
            verification.RecordTypeId = Schema.SObjectType.Verification__c.getRecordTypeInfosByDeveloperName().get('RCU').getRecordTypeId();
            verification.OwnerId = queueId;
            insert verification;

            // Link Document__c records to Verification__c
            List<Document__c> docsToUpdate = [
                SELECT Id 
                FROM Document__c 
                WHERE Id IN :docIds
            ];
            List<Document_Activity__c> docActivities = new List<Document_Activity__c>();
            for (Document__c doc : docsToUpdate) {                
                docActivities.add(new Document_Activity__c(
                    Document__c = doc.Id,
                    Verification__c = verification.Id,
                    RCU_Verification_Status__c = 'Sampled'
                ));
            }
            System.debug('docActivities = '+docActivities);
            INSERT docActivities;

            // TODO: Trigger bell + email notifications via flow/process builder or platform event

            res.isSuccess = true;
            res.responseBody = 'Successfully initiated RCU Vendor activity.';
            res.recordId = verification.Id;
            return res;
        } catch (Exception e) {
            res.isSuccess = false;
            res.responseBody = 'Error: ' + e.getMessage();
            return res;
        }
    }

    public class ResponseWrapper {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String responseBody;
         @AuraEnabled public String recordId;
    }
}