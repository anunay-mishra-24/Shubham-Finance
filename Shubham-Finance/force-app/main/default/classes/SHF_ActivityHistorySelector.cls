/**
* @File Name : SHF_ActivityHistorySelector.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 26, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 26, 2025 |   | Initial Version
**/

public class SHF_ActivityHistorySelector  extends fflib_SObjectSelector {
	 public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            Activity_History__c.Id,
                Activity_History__c.Name,
				Activity_History__c.Application__c,
				Activity_History__c.Application_Name__c,
				Activity_History__c.OwnerId,
				Activity_History__c.Recommendation_by_the_credit_user__c,
				Activity_History__c.Recommended_Loan_Amount__c ,
				Activity_History__c.Comments__c,
                Activity_History__c.Committee_Approval_Status__c
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Activity_History__c.SObjectType; 
    }

	 public List<Activity_History__c> selectByIds(Set<Id> recordIds) {    
        fflib_QueryFactory query = new fflib_QueryFactory(Activity_History__c.sObjectType);
       // query.selectField('City_Master__r.Name'); 
        query.setCondition('Id IN : recordIds');
		// query.setCondition('Id IN : recordIds AND RecordType.Name = \'Activity History for Committee\' ');
        return (List<Activity_History__c>) Database.query(query.toSOQL());
    }

     public List<Activity_History__c> selectNegotiatedRecordByApplicationId(Set<Id> applicationId) {    
        fflib_QueryFactory query = new fflib_QueryFactory(Activity_History__c.sObjectType);
        //query.setCondition('Application__c  IN : applicationId AND RecordTypeId =:SHF_ConstantsUtil.ACTIVITY_HISTORY_FOR_Negotiation_RECORDTYPEID');
		 query.setCondition('Application__c IN : applicationId AND RecordType.Name = \'Activity History for Negotiation\' ');
        return (List<Activity_History__c>) Database.query(query.toSOQL());
    }
	 
}