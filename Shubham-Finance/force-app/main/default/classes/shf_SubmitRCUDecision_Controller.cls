/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : shf_SubmitRCUDecision_Controller
 * Author          : David
 * Created Date    : Feb 6, 2026
 * Last Modified By: David 
 * Last Modified On: Feb 6, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Feb 6, 2026  │ David Saini   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class shf_SubmitRCUDecision_Controller {

	@AuraEnabled(cacheable=true)
	public static Boolean getQueriesForRCU(Id verificationId) {
		try{
			Boolean queryDecision ;
			List<Query__c> queryList = [SELECT Id,Query_Status__c,Verification__c FROM Query__c WHERE Verification__c =: verificationId];
            if(queryList.size() == 0) {
                queryDecision = true;
            }
            else {
                for(Query__c query : queryList) {
                    if(query.Query_Status__c == 'Completed') {
                        queryDecision = false; 
                    }
                }
            }
			return queryDecision;
		}
		catch(Exception e) {
			System.debug( 'ERROR: ' + e.getMessage());
			return false;
		}
	}
	@AuraEnabled
    public static String updateRCUDecision(Id verificationId,String rcuDecision,String comment) {
        try {
             // 2️⃣ Object-level security check
            if (!Schema.sObjectType.Verification__c.isUpdateable()) {
                throw new AuraHandledException(
                    'You do not have permission to update verification records.'
                );
            }

            // 3️⃣ Field-level security checks
            Map<String, Schema.SObjectField> fieldMap =
                Schema.SObjectType.Verification__c.fields.getMap();

            if (!fieldMap.get('RCU_Decision__c').getDescribe().isUpdateable()) {
                throw new AuraHandledException(
                    'You do not have permission to update RCU Decision.'
                );
            }

            // if (fieldMap.containsKey('Comment__c') &&
            //     !fieldMap.get('Comment__c').getDescribe().isUpdateable()) {
            //     throw new AuraHandledException(
            //         'You do not have permission to update Comment.'
            //     );
            // }

            Verification__c verification = [
                SELECT Id
                FROM Verification__c
                WHERE Id = :verificationId
                LIMIT 1
            ];

            verification.RCU_Decision__c = rcuDecision;
            verification.RCU_Status__c = 'Completed';
            // verification.Comment__c = comment;

            update verification;
            return 'Success';

        }
		catch (Exception e) {
            // Catch-all (never expose system error details to UI)
            throw new AuraHandledException(
                'Unexpected error occurred while updating RCU decision.'
            );
        }
    }
    @AuraEnabled(cacheable=true)
	public static String getRCURecord(Id verificationId) {
        try {
            String message;
            List<Verification__c> verificationList = [SELECT Id, Name, Type__c From Verification__c WHERE Id =:verificationId AND RCU_Status__c = 'Completed' LIMIT 1];
            if(verificationList.size() > 0){
                message = 'RCU Decision already Submitted';
            }
            else {
                message = 'RCU Decision not Submitted';
            }
            return message;
        }
        catch(exception e) {
            throw new AuraHandledException(
                'Unexpected error occurred while retrieving RCU record.'+ e
            );
        }
    }
}