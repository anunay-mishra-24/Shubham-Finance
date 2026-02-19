/**
* @File Name : SHF_riskScoreMasterSelector.cls
* @Description : 
* @Author : mansur
* @Last Modified By :
* @Last Modified On : October 23, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 23, 2025 |   | Initial Version
**/

public class SHF_riskScoreMasterSelector extends fflib_SObjectSelector {
	 public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Risk_Score_Master__c.Id,
               
			    Risk_Score_Master__c.Name,
				 Risk_Score_Master__c.Effective_Date__c,
				  Risk_Score_Master__c.IsActive__c,
				   Risk_Score_Master__c.Thik_Weight__c,
				    Risk_Score_Master__c.Thin_Weight__c

                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Risk_Score_Master__c.sObjectType;
    }
	// Added by mansur - Fetch all related data of application
    public List<Risk_Score_Master__c> getAllRelatedDataOfChild(){
        fflib_QueryFactory query = newQueryFactory();
        //getting all applicant related to data
        fflib_SObjectSelector riskDetailSelector = new SHF_riskScoreDetailSelector();
        riskDetailSelector.addQueryFactorySubselect(query, 'Risks_Score_Details__r');
        return (List<Risk_Score_Master__c>) Database.query( query.toSOQL() );
    }
}