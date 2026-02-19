/**
* @File Name : ShfVerificationComponentCtrl.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 20, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 20, 2025 |   | Initial Version
**/

public class ShfVerificationComponentCtrl {
	@AuraEnabled
	public static List<Verification__c> getVerificationRecords(String recordId){
		return [SELECT Id, Name, Status__c, Application__c, Type__c,FCU_Manager_Decision__c,
				Verifier_Name__r.Name, LastModifiedDate, Result__c,
				RecordTypeId, RecordType.Name
				FROM Verification__c 
				WHERE Application__c =: recordId];
	}

	@AuraEnabled
	public static Verification__c saveVerificationRecord(Verification__c verificationRec){
		try{
			List<Verification__c> verificationList = [SELECT Id FROM Verification__c
													 WHERE RecordTypeId =: verificationRec.RecordTypeId
													 AND Type__c =: verificationRec.Type__c
													 AND Application__c =: verificationRec.Application__c
													 AND Status__c != 'Sampled'];
			System.debug('*** '+ verificationRec.RecordTypeId +' = '+ verificationRec.Type__c +' = '+ verificationRec.Application__c);
			System.debug('*** '+ verificationList);
			if(!verificationList.isEmpty()){
				throw newMessageException('You can only create a new verification activity after the previous one is closed.');
			}
            INSERT verificationRec;
        }catch(Exception e){
            throw newMessageException(e.getMessage());
        }
        return verificationRec;
	}

	private static AuraHandledException newMessageException(String msg){
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
}