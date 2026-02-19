/**
* @File Name : shf_QueryController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 1, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 1, 2025 |   | Initial Version
**/

public class shf_QueryController {
	@AuraEnabled(cacheable=true)
    public static List<Query__c> getQueriesForVerificationActivity(Id verificationActivityId) {
        return [
            SELECT Id, Name, Subject__c, Query_Status__c, Type_of_Query__c, Type_of_User__c, 
                   Assigned_to__c, Assigned_to__r.Name, CreatedDate
            FROM Query__c
            WHERE Verification_Activity__c = :verificationActivityId
            ORDER BY CreatedDate DESC
        ];
    }
}